use Sandbox;
go

---------------------------------------------
-- declare variables
---------------------------------------------
declare @WorkoffName varchar(125),
        @message varchar(500),
        @currentdate datetime = getdate(),
	   @Action nvarchar(200),
        @ChangesRowCnt int,
        @InsertsRowCnt int,
        @BatchStartRow int,
        @Iteration int,
        @BatchSize int = 100000;
		
---------------------------------------------
-- create temp tables
---------------------------------------------
drop table if exists #CompanyPhoneChanges;

--Same table definition as presentation table plus RID and DBAction columns
create table #CompanyPhoneChanges
(
 RID int null,
 DBAction char(1) not null,
 CompanyId int not null,
 Phone varchar(12) not null		
 unique clustered (CompanyId, Phone, DBAction) --use this as PKC for batching
);

---------------------------------------------
-- body of stored procedure
---------------------------------------------
set @currentdate = getdate();
set @Action = N'Perform UNION ALL diff to find data changes';

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
)
insert into #CompanyPhoneChanges
(
	DBAction,
	CompanyId,
	Phone
)
select max(DBAction) as DBAction,
	  CompanyId,
	  Phone
  from cte
 group by CompanyId, Phone
having count(*) = 1
 order by CompanyId, DBAction; --Order by PKC of presentation table plus DBAction

--as things stand, the changes table has more data than we actually need, so get rid of the surplus
-- DELETE row + INSERT row can be converted to UPDATE
set @Action = N'Convert DELETE + INSERT to UPDATE in changes table';

update a
   set a.DBACTION = 'U'
  from #CompanyPhoneChanges a
 where a.DBACTION = 'I'
   and exists (select 1
                 from #CompanyPhoneChanges b
                where a.CompanyId = b.CompanyId
                  and b.DBACTION = 'D');

-- delete row with an update row created above, which means the delete row is redundant and we can get rid of it
set @Action = N'Remove DELETEs';
delete a
  from #CompanyPhoneChanges a
 where a.DBACTION = 'D'
   and exists (select 1
                 from #CompanyPhoneChanges b
                where a.CompanyId = b.CompanyId
                  and b.DBACTION = 'U');

set @Action = N'Determine if there''s any data at all';
select ChangedRowsCnt = count(*), 
       InsertRowsCnt  = sum(case when DBACTION = 'I' then 1 else 0 end)           
  from #CompanyPhoneChanges;

select @ChangesRowCnt = count(*), 
       @InsertsRowCnt = sum(case when DBACTION = 'I' then 1 else 0 end)           
  from #CompanyPhoneChanges;

--if there are no data changes, there's no point in taking this any further
if @ChangesRowCnt = 0 
    return;
    
with cte as
(
select CompanyId,
       Phone,
       row_number() over(partition by DBACTION order by CompanyId) as RowID
  from #CompanyPhoneChanges
)
update ch
   set ch.RID = cte.RowID
  from #CompanyPhoneChanges ch
       inner join cte on	cte.CompanyId = ch.CompanyId;
      	
set @Action = N'Initiate inserts loop';
set @BatchStartRow = 1;
set @Iteration = 1;

while (@BatchStartRow <= @InsertsRowCnt)
begin;
      set @Action = N'Insert to presentation table';

      insert into Sandbox.dbo.CompanyPhone 
      (
             CompanyId,
             Phone,
             InsertDate
      )
      select CompanyId,
             Phone,
             getdate()
        from #CompanyPhoneChanges
       where DBACTION = 'I'
         and RID between @BatchStartRow and @BatchStartRow + @BatchSize - 1;

      set @BatchStartRow = @BatchStartRow + @BatchSize;
      set @Iteration = @Iteration + 1;

end;