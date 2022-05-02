use Sandbox;
go

set quoted_identifier on;
go
set ansi_nulls on;
go

create or alter procedure dbo.CompanyPhoneWorkoff
	@OverrideSizeCheck bit = 0
as
begin;
	/*******************************************************************************************************
	*   Sandbox.dbo.CompanyPhoneWorkoff 
	*   Creator:	Shane    
	*   Date:		02/09/2022      
	*
	*   Notes:		Best practice workoff
	*                  
	*
	*   Usage:

			execute Sandbox.dbo.CompanyPhoneWorkoff;
	
	*
	*   Unit Tests:

		execute [Sandbox].[tSQLt].[Run] 
			@TestName = N'[dbo.CompanyPhoneWorkoff]';

	*
	*
	*	Modifications:   
	*   Developer Name      Date        Brief description
	*   ------------------- ----------- ------------------------------------------------------------
	*   
	********************************************************************************************************/
	---------------------------------------------
	-- set session variables
	---------------------------------------------
	set nocount on;
	
	begin try;
		---------------------------------------------
		-- declare variables
		---------------------------------------------
		declare @Proc nvarchar(500) = cast(db_name(db_id()) as nvarchar(250)) + N'.' + cast(object_schema_name(@@procid, db_id()) as nvarchar(250)) + N'.' + cast(object_name(@@procid, db_id()) as nvarchar(250)),
                  @Msg nvarchar(2500),
                  @RawCt int,
                  @PresCt int,
                  @RawPercent int,
                  @LoopCt int = 1,
                  @ChangeCt int,
                  @BatchCt smallint = 1000;

		---------------------------------------------
		-- create temp tables
		---------------------------------------------
		drop table if exists #CompanyPhoneChanges;

		--Same table definition as presentation table plus RID and DBAction columns
		create table #CompanyPhoneChanges
		(
           RID int identity(1,1) not null,
           DBAction char(1) not null,
           CompanyId int not null,
           Phone varchar(12) not null		
           primary key clustered (RID) --use this as PKC for batching
		);

		drop table if exists #CompanyPhone;

		--Same table definition as presentation table plus DBAction column
		create table #CompanyPhone
		(
           DBAction char(1) not null,
           CompanyId int not null,
           Phone varchar(12) not null		
		 primary key clustered (CompanyId) --make this PKC match the PKC on presentation table for performance and to reduce blocking
		);

		---------------------------------------------
		-- body of stored procedure
		---------------------------------------------
		/********************************************************
		Sanity check to help ensure our raw data is good
		********************************************************/
		if @OverrideSizeCheck = 0
		begin
			select @RawCt = count(*)
			  from Sandbox.dbo.CompanyPhoneRaw;

			select @PresCt = count(*)
			  from Sandbox.dbo.CompanyPhone;

			--check for divide by zero case
			if @PresCt > 0
			begin
				set @RawPercent = @RawCt * 100.0/@PresCt;
	
				--Check if raw data is at least 85% of presentation data
				if @RawPercent < 85
				begin
					set @Msg = N'The raw table Sandbox.dbo.CompanyPhoneRaw has less than 85 percent of the presentation table Sandbox.dbo.CompanyPhone. Currently it is ' + cast(@RawPercent as nvarchar(10)) + ' percent.';
					throw 51000, @Msg, 1;
				end;
			end;
		end;

		/********************************************************
		Find changes
		********************************************************/
          with cte as
          (
           select 'I' as DBAction, --Data in Raw table we want to insert
                  CompanyId,
                  Phone
             from Sandbox.dbo.CompanyPhoneRaw
            union all
           select 'D' as DBAction, --Data in Presentation table we want to delete
                  CompanyId,
                  Phone --excluding date columns that we set and are not coming in the feed
             from Sandbox.dbo.CompanyPhone
          )--/*
		insert into #CompanyPhoneChanges
		(
                 DBAction,
                 CompanyId,
                 Phone
		)--*/
		select min(DBAction) as DBAction,
			  CompanyId,
			  Phone
		  from cte
		 group by CompanyId, Phone
		having count(*) = 1
		 order by CompanyId, DBAction; --Order by PKC of presentation table plus DBAction

		/********************************************************
		Change I and D to U for updates
		********************************************************/
          update a
             set a.DBAction = 'U' --Data we want to use to update
        --select a.*
            from #CompanyPhoneChanges a
           where a.DBAction = 'I' --Change data from the raw table with the I to a U 
             and exists (select *
                           from #CompanyPhoneChanges aa
                          where aa.DBAction = 'D'
                            and aa.CompanyId = a.CompanyId); --Needs to be all the columns of the presentation table PKC

          delete a
        --select a.*
            from #CompanyPhoneChanges a
           where a.DBAction = 'D' --Remove the D from the presentation table when there is a U 
             and exists (select *
                           from #CompanyPhoneChanges aa
                          where aa.DBAction = 'U'
                            and aa.CompanyId = a.CompanyId); --Needs to be all the columns of the presentation table PKC

		/********************************************************
		Batch the changes
		********************************************************/
		select @ChangeCt = max(RID)
		  from #CompanyPhoneChanges;

		while @LoopCt <= @ChangeCt
		begin
			truncate table #CompanyPhone;

			insert into #CompanyPhone
			(
				DBAction,
				CompanyId,
				Phone
			)
			select DBAction,
                      CompanyId,
                      Phone
			  from #CompanyPhoneChanges
			 where RID between @LoopCt and @LoopCt + @BatchCt - 1; --need the minus one so we batch between 1 and 1000 not 1001

			--apply deletes
			delete a
             --select a.*
                 from Sandbox.dbo.CompanyPhone a
                where exists (select *
                                from #CompanyPhone aa
                               where aa.DBAction = 'D'
                                 and aa.CompanyId = a.CompanyId);--Must use PK columns

			--apply updates
			update a
			   set a.Phone = b.Phone, --update all columns not in the PK
                      a.UpdateDate = getdate()
             --select a.*, b.Phone
			  from Sandbox.dbo.CompanyPhone a
                      inner join #CompanyPhone b on b.CompanyId = a.CompanyId --must join on PK
                             and b.DBAction = 'U';

			--apply inserts
			insert into Sandbox.dbo.CompanyPhone
			(
				CompanyId,
				Phone
			)
			select CompanyId,
                      Phone
			  from #CompanyPhone a
			 where a.DBAction = 'I';

			set @LoopCt += @BatchCt;
		end;
	end try

	begin catch;
		set @Msg = @Proc + N' - ' + error_message();

		throw 51000, @Msg, 1;

	end catch;

	return;
end;