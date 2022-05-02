use DMAUpload
go

set quoted_identifier on
go
set ansi_nulls on
go
set ansi_padding on
go

create or alter procedure dbo.MorningstarDatawarehouseCapitalUnpivot
       @TaskID int,
       @JobID int,
       @Debug tinyint = 0,
       @DebugSingleSymbol varchar(30) = null
as
/*******************************************************************************************************
*   DMAUpload.dbo.MorningstarDatawarehouseCapitalUnpivot 
*   Creator:       Andrew Horton
*   Date:          2021/08/11
*
*   Project:       025866: Morningstar DW Operations
*   Project Mgr:   Nandini Sivaram
*   TaskID:        8512
*   QueryID:       4028006
*
*   Notes:         This is a partial replacement for QID 402800, which handles all unpivoting of breakdowns into vertical tables
                   This proc separates the Capital Breakdown out into its own workoff and optimizes the code

                   It also changes the logic of how the Datestamp column is populated, moving from copying it from the source table to generating it anew
                   This is done as the source table uses delete/insert to populate it and so values change even when there's no data changed
                   Also moved from dynamic construction of the column list to static to avoid dynamic SQL
*                  
*
*   Usage:
        execute DMAUpload.dbo.MorningstarDatawarehouseCapitalUnpivot @TaskID = -1, @JobID = -1, @Debug = 1; 
        execute DMAUpload.dbo.MorningstarDatawarehouseCapitalUnpivot @TaskID = -1, @JobID = -1, @Debug = 1, @DebugSingleSymbol = '$CTCA$LP$$'; 
*
*	Modifications:   
*   Developer Name      Date        Brief description
*   ------------------- ----------- ------------------------------------------------------------
*   
********************************************************************************************************/

---------------------------------------------
-- declare variables
---------------------------------------------

declare @Action nvarchar(200),
    @i int,
    @MaxRows int,
    @BatchIteration smallint,
    @DeleteBatchSize int = 200, -- each InvestmentVehicleID accounts for up to 25 rows in the final table; 5000/25 = 62.5
    @MergeBatchSize int = 10000, -- this will multiply out to a larger number of rows, going above 5000 as otherwise it takes forever
    @Datestamp float,
    @Msg nvarchar(1000);


---------------------------------------------
-- create temp tables
---------------------------------------------

if object_id('tempdb..[#CapitalUnpivotUniverse]') is not null 
begin;
    drop table [#CapitalUnpivotUniverse];
end;

create table [#CapitalUnpivotUniverse] (

	RowID int not null identity(1,1),
    InvestmentVehicleID varchar(30) not null

);

if object_id('tempdb..[#CapitalUnpivotUniverseBatch]') is not null 
begin;
    drop table [#CapitalUnpivotUniverseBatch];
end;

create table [#CapitalUnpivotUniverseBatch] (

    InvestmentVehicleID varchar(30) not null primary key clustered

);


if object_id('tempdb..[#CapitalUnpivotDeletes]') is not null 
begin;
    drop table [#CapitalUnpivotDeletes];
end;

create table [#CapitalUnpivotDeletes] (

	RowID int not null identity(1,1),
    InvestmentVehicleID varchar(30) not null

);

if object_id('tempdb..[#CapitalUnpivotDeletesBatch]') is not null 
begin;
    drop table [#CapitalUnpivotDeletesBatch];
end;

create table [#CapitalUnpivotDeletesBatch] (

    InvestmentVehicleID varchar(30) not null primary key clustered

);


if object_id('tempdb..[#CapitalUnpivotBreakdown]') is not null 
begin;
    drop table [#CapitalUnpivotBreakdown];
end;

create table [#CapitalUnpivotBreakdown] (

    InvestmentVehicleID varchar(30) not null,
    BreakdownName varchar(50) not null,
    BreakdownType    varchar(20) not null,
    BreakdownValue    decimal(9,2)

    primary key clustered (InvestmentVehicleID, BreakdownName, BreakdownType)

);

if object_id('tempdb..[#CapitalUnpivotBreakdownCHANGES]') is not null 
begin;
    drop table [#CapitalUnpivotBreakdownCHANGES];
end;

create table [#CapitalUnpivotBreakdownCHANGES] (

    InvestmentVehicleID varchar(30) not null,
    BreakdownName varchar(50) not null,
    BreakdownType    varchar(20) not null,
    BreakdownValue    decimal(9,2) not null,
    BatchIteration smallint not null,
    DBACTION char(1) not null,

    primary key clustered (InvestmentVehicleID, BreakdownName, BreakdownType, DBACTION)

);



---------------------------------------------
-- set session variables
---------------------------------------------
set nocount on;
---------------------------------------------
-- body of stored procedure
---------------------------------------------
begin try;

    if @DebugSingleSymbol is not null
        begin;
            set @Debug = 1;
        end;

    --Q1. Is Morningstar.dbo.MStarDataWarehouseCapitalBreakdown a RAW or morelike the SOURCE table?
    set @Action = 'Find universe of InvestmentVehicles';
    if @DebugSingleSymbol is null
        begin;

            insert #CapitalUnpivotUniverse (

                InvestmentVehicleID

            )
            select distinct b.FundShareClassID
            from Morningstar.dbo.MStarDataWarehouseCapitalBreakdown b;

        end;
    else
        begin;

            insert #CapitalUnpivotUniverse (

                InvestmentVehicleID

            )
            select distinct b.FundShareClassID
            from Morningstar.dbo.MStarDataWarehouseCapitalBreakdown b
            where b.FundShareClassID = @DebugSingleSymbol;

        end;

    set @Action = 'Find universe of InvestmentVehicles to be deleted';
    --Deletion isn't tested when you use @DebugSingleSymbol
    if @DebugSingleSymbol is null
        begin;

            insert #CapitalUnpivotDeletes (

                InvestmentVehicleID

            )
            select distinct bv.FundShareClassID
            from Morningstar.dbo.MStarDataWarehouseCapitalBreakdownVertical bv
            where not exists (select * from #CapitalUnpivotUniverse uu
                                where uu.InvestmentVehicleID = bv.FundShareClassID);
            /*
              Q2. Is Morningstar.dbo.MStarDataWarehouseCapitalBreakdownVertical morelike the TARGET table?

              O1. 
                  a) The temp table #CapitalUnpivotDeletes is populated by fetching the rows from the
                     "Vertical" (TARGET) table which are NOT present in the temp table #CapitalUnpivotUniverse.
                  b) In other words, the temp table #CapitalUnpivotDeletes contains rows from the
                     "Vertical" (TARGET) table which are NOT present in the "Breakdown" (SOURCE) table.

              Q3. 
                  a) What is the purpose of using the temp table #CapitalUnpivotUniverse to populate the
                  temp table #CapitalUnpivotDeletes?
                  b) Why NOT populate the temp table #CapitalUnpivotDeletes directly by using NOT EXISTS
                     between the "Breakdown" (SOURCE) and the "Vertical" (TARGET) tables?              
            */
        end;


    --delete out InvestmentVehicles that are no longer in the source table 
    if @Debug = 0
    begin;

        set @MaxRows = (select max(RowID) from #CapitalUnpivotDeletes);
        set @i = 1;

        while @i <= @MaxRows   
            begin;

                   set @Action = 'Clear out data for new delete InvestmentVehicle batch';
                   truncate table #CapitalUnpivotDeletesBatch;
            
                   set @Action = 'Define delete InvestmentVehicle batch';
                   insert  #CapitalUnpivotDeletesBatch (
                
                        InvestmentVehicleID

                   )
                   select ud.InvestmentVehicleID
                   from #CapitalUnpivotDeletes ud
                   where ud.RowID >= @i and ud.RowID <= @i + @DeleteBatchSize - 1;

                   set @Action = 'Delete InvestmentVehicle batch';
                   delete bv
                   from Morningstar.dbo.MStarDataWarehouseCapitalBreakdownVertical bv
                   inner join #CapitalUnpivotDeletesBatch udb
                        on bv.FundShareClassID = udb.InvestmentVehicleID;
            /*
              Q4. If the records from the "Vertical" (TARGET) table which are NOT present in the "Breakdown" (SOURCE) table
                  are deleted by the above batching, why are the deletes handled again via the "UNION ALL" method downstream?

            */
                   set @i = @i + @DeleteBatchSize;

            end;
    end;

    --loop through the universe of InvestmentVehicles that are in the source table
    set @MaxRows = (select max(RowID) from #CapitalUnpivotUniverse);
    set @i = 1;
    set @BatchIteration = 1;

    while @i <= @MaxRows   
        begin;

            set @Action = 'Clear out data for new batch';
            truncate table #CapitalUnpivotUniverseBatch;
            truncate table #CapitalUnpivotBreakdown;

            --if the proc is in debug mode accumulate the changes in one table to make output easier
            if @Debug = 0
            begin;
                truncate table #CapitalUnpivotBreakdownCHANGES;
            end;
            
            set @Action = 'Define the batch';
            insert  #CapitalUnpivotUniverseBatch (
                
                InvestmentVehicleID

            )
            select InvestmentVehicleID
            from #CapitalUnpivotUniverse rud
            where RowID >= @i and RowID <= @i + @MergeBatchSize - 1;

            set @Action = 'Unpivot the batch';
            insert #CapitalUnpivotBreakdown
            (
                InvestmentVehicleID,
                BreakdownName,
                BreakdownType,
                BreakdownValue
            )
                select p.FundShareClassID as InvestmentVehicleID, 
                    case 
                        when BreakdownName like '%RescaledLong' then replace(BreakdownName, 'RescaledLong', '')
                        when BreakdownName like '%RescaledShort' then replace(BreakdownName, 'RescaledShort', '')
                        when BreakdownName like '%Long' then replace(BreakdownName, 'Long', '')
                        when BreakdownName like '%Short' then replace(BreakdownName, 'Short', '')
                        when BreakdownName like '%Net' then replace(BreakdownName, 'Net', '')
                        else BreakdownName
                    end,
                    case 
                        when BreakdownName like '%RescaledLong' then 'RescaledLong'
                        when BreakdownName like '%RescaledShort' then 'RescaledShort'
                        when BreakdownName like '%Long' then 'Long'
                        when BreakdownName like '%Short' then 'Short'
                        when BreakdownName like '%Net' then 'Net'
                        else 'Unknown'
                    end,
                    BreakdownValue
                from Morningstar.dbo.MStarDataWarehouseCapitalBreakdown as  p
                inner join #CapitalUnpivotUniverseBatch uub
                    on p.FundShareClassID = uub.InvestmentVehicleID
                cross apply
                (values
                    ('GiantLong',GiantLong),
                    ('LargeLong',LargeLong),
                    ('MediumLong',MediumLong),
                    ('SmallLong',SmallLong),
                    ('MicroLong',MicroLong),
                    ('GiantShort',GiantShort),
                    ('LargeShort',LargeShort),
                    ('MediumShort',MediumShort),
                    ('SmallShort',SmallShort),
                    ('MicroShort',MicroShort),
                    ('GiantNet',GiantNet),
                    ('LargeNet',LargeNet),
                    ('MediumNet',MediumNet),
                    ('SmallNet',SmallNet),
                    ('MicroNet',MicroNet),
                    ('GiantRescaledLong',GiantRescaledLong),
                    ('LargeRescaledLong',LargeRescaledLong),
                    ('MediumRescaledLong',MediumRescaledLong),
                    ('SmallRescaledLong',SmallRescaledLong),
                    ('MicroRescaledLong',MicroRescaledLong),
                    ('GiantRescaledShort',GiantRescaledShort),
                    ('LargeRescaledShort',LargeRescaledShort),
                    ('MediumRescaledShort',MediumRescaledShort),
                    ('SmallRescaledShort',SmallRescaledShort),
                    ('MicroRescaledShort',MicroRescaledShort)
            ) as u(BreakdownName,BreakdownValue)
			where BreakdownValue is not null;

            set @Action = 'Use union all to compare batch data';
            with UnionAllCTE as (
            
                select 
                    ub.InvestmentVehicleID,
                    ub.BreakdownName,
                    ub.BreakdownType,
                    ub.BreakdownValue,
                    'I' as DBACTION -- INSERT
                from #CapitalUnpivotBreakdown ub
                union all
                select 
                    bv.FundShareClassID as InvestmentVehicleID,
                    bv.BreakdownName,
                    bv.BreakdownType,
                    bv.BreakdownValue,
                    'D' as DBACTION -- DELETE
                from Morningstar.dbo.MStarDataWarehouseCapitalBreakdownVertical bv
                inner join #CapitalUnpivotUniverseBatch uub
                    on bv.FundShareClassID = uub.InvestmentVehicleID
                
            )
            insert #CapitalUnpivotBreakdownCHANGES 
            (
                InvestmentVehicleID,
                BreakdownName,
                BreakdownType,
                BreakdownValue,
                BatchIteration,
                DBACTION
            )
            select InvestmentVehicleID,
                BreakdownName,
                BreakdownType,
                BreakdownValue,
                @BatchIteration as BatchIteration,
                max(DBACTION) as DBACTION
            from UnionAllCTE
            group by InvestmentVehicleID,
                BreakdownName,
                BreakdownType,
                BreakdownValue
            having count(*) = 1;


            if exists (select 1 from #CapitalUnpivotBreakdownCHANGES) and @Debug = 0
                begin;

                    --as things stand, the changes table has more data than we actually need, so get rid of the surplus
                    -- DELETE row + INSERT row can be converted to UPDATE
                    set @Action = 'Convert DELETE + INSERT to UPDATE in changes table';
                    update a
                        set a.DBACTION = 'U'
                    from [#CapitalUnpivotBreakdownCHANGES] a
                    where exists (select 1
                        from [#CapitalUnpivotBreakdownCHANGES] b
                        where  a.InvestmentVehicleID = b.InvestmentVehicleID
                            and a.BreakdownType = b.BreakdownType
                            and a.BreakdownName = b.BreakdownName
                            and b.DBACTION = 'D')
		                    and a.DBACTION = 'I';


                    -- Can remove DELETE row when DELETE row + UPDATE row 
                    set @Action = 'Convert DELETE + UPDATE to  just UPDATE in changes table';
                    delete a
                    from [#CapitalUnpivotBreakdownCHANGES] a
                    where exists (select 1
                        from [#CapitalUnpivotBreakdownCHANGES] b
                        where  a.InvestmentVehicleID = b.InvestmentVehicleID
                            and a.BreakdownType = b.BreakdownType
                            and a.BreakdownName = b.BreakdownName
                            and b.DBACTION = 'U')
		                    and a.DBACTION = 'D';

            
                    set @Action = 'Get current date';
                    set @Datestamp = (select DateStamp = convert(float, getdate()) + 2);  

                    set @Action = 'Delete from presenation table';
                    delete bv
                    from Morningstar.dbo.MStarDataWarehouseCapitalBreakdownVertical bv
                    inner join #CapitalUnpivotBreakdownCHANGES ch
                        on bv.FundShareClassID = ch.InvestmentVehicleID
                        and bv.BreakdownType = ch.BreakdownType
                        and bv.BreakdownName = ch.BreakdownName
                    where ch.DBACTION = 'D';

                    set @Action = 'Update presentation table';
                    update bv
                        set BreakdownValue = ch.BreakdownValue,
                            DateStamp = @Datestamp
                    from Morningstar.dbo.MStarDataWarehouseCapitalBreakdownVertical bv
                    inner join #CapitalUnpivotBreakdownCHANGES ch
                        on bv.FundShareClassID = ch.InvestmentVehicleID
                        and bv.BreakdownType = ch.BreakdownType
                        and bv.BreakdownName = ch.BreakdownName
                    where ch.DBACTION = 'U';

                    set @Action = 'Insert into presentation table';
                    insert Morningstar.dbo.MStarDataWarehouseCapitalBreakdownVertical (

                        FundShareClassID,
                        BreakdownName,
                        BreakdownType,
                        BreakdownValue,
                        DateStamp

                    )
                    select
                        ch.InvestmentVehicleID as FundShareClassID,
                        ch.BreakdownName,
                        ch.BreakdownType,
                        ch.BreakdownValue,
                        @Datestamp as DateStamp
                    from #CapitalUnpivotBreakdownCHANGES ch
                    where DBACTION = 'I';

                end;

            set @i = @i + @MergeBatchSize;
            set @BatchIteration = @BatchIteration + 1;

        end;


    if @Debug = 1
        begin;
                    set @Action = 'Convert DELETE + INSERT to UPDATE in changes table (Debug)';
                    update a
                        set a.DBACTION = 'U'
                    from [#CapitalUnpivotBreakdownCHANGES] a
                    where exists (select 1
                        from [#CapitalUnpivotBreakdownCHANGES] b
                        where  a.InvestmentVehicleID = b.InvestmentVehicleID
                            and a.BreakdownType = b.BreakdownType
                            and a.BreakdownName = b.BreakdownName
                            and b.DBACTION = 'D')
		                    and a.DBACTION = 'I';


                    -- Can remove DELETE row when DELETE row + UPDATE row 
                    set @Action = 'Convert DELETE + UPDATE to  just UPDATE in changes table (Debug)';
                    delete a
                    from [#CapitalUnpivotBreakdownCHANGES] a
                    where exists (select 1
                        from [#CapitalUnpivotBreakdownCHANGES] b
                        where  a.InvestmentVehicleID = b.InvestmentVehicleID
                            and a.BreakdownType = b.BreakdownType
                            and a.BreakdownName = b.BreakdownName
                            and b.DBACTION = 'U')
		                    and a.DBACTION = 'D';

                select * from #CapitalUnpivotUniverse;
                select * from #CapitalUnpivotDeletes;
                select * from #CapitalUnpivotBreakdown; -- will only have the last batch
                select * from #CapitalUnpivotBreakdownCHANGES;
        end;

end try
begin catch;


    if @Debug = 1
        begin;
                select * from #CapitalUnpivotUniverse;
                select * from #CapitalUnpivotDeletes;
                select * from #CapitalUnpivotBreakdown; -- will only have the last batch
                select * from #CapitalUnpivotBreakdownCHANGES;
        end;

    set @Msg = 'Error during operation ''' + isnull(@Action,'[null]') + '''' + char(13) + error_message();

    throw 50000, @Msg, 1;

end catch;

drop table #CapitalUnpivotUniverse;
drop table #CapitalUnpivotUniverseBatch;
drop table #CapitalUnpivotDeletes;
drop table #CapitalUnpivotDeletesBatch;
drop table #CapitalUnpivotBreakdown;
drop table #CapitalUnpivotBreakdownCHANGES;

go
---------------------------------------------
-- permissions (don't grant to anyone)
---------------------------------------------