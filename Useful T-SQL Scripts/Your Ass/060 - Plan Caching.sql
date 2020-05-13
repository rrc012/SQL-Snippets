USE
	YourAss;
GO


-- Create the "dbo.CachedPlans" view that retrieves the procedure cache entries

CREATE VIEW
	dbo.CachedPlans
(
	QueryText ,
	QueryPlan ,
	ExecutionCount ,
	ObjectType ,
	Size_KB ,
	LastExecutionTime
)
AS

SELECT
	QueryText			= QueryTexts.text ,
	QueryPlan			= QueryPlans.query_plan ,
	ExecutionCount		= CachedPlans.usecounts ,
	ObjectType			= CachedPlans.objtype ,
	Size_KB				= CachedPlans.size_in_bytes / 1024 ,
	LastExecutionTime	= last_execution_time
FROM
	sys.dm_exec_cached_plans AS CachedPlans
CROSS APPLY
	sys.dm_exec_query_plan (plan_handle) AS QueryPlans
CROSS APPLY
	sys.dm_exec_sql_text (plan_handle) AS QueryTexts
INNER JOIN
	sys.dm_exec_query_stats AS QueryStats
ON
	CachedPlans.plan_handle = QueryStats.plan_handle;
GO


-- View the procedure cache entries

SELECT
	*
FROM
	dbo.CachedPlans;
GO


-- Empty the procedure cache

DBCC FREEPROCCACHE;
GO


-- View the procedure cache entries again to make sure it is empty

SELECT
	*
FROM
	dbo.CachedPlans;
GO


-- Execute the "Customers by Country" query

SELECT
	Id ,
	Name ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	Country = N'IL';
GO


-- View the procedure cache entries again, but this time return only
-- the plan for the "Customers by Country" query

SELECT
	*
FROM
	dbo.CachedPlans
WHERE
	QueryText LIKE N'%Customers%'
AND
	QueryText NOT LIKE N'%sys.dm_exec_cached_plans%'
ORDER BY
	LastExecutionTime ASC;
GO


-- The "Customers by Country" query is executed again, this time it already has a plan in
-- cache, so it doesn't need to be compiled

SELECT
	Id ,
	Name ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	Country = N'IL';
GO


-- View the procedure cache entries again to make sure that the existing
-- execution plan for the "Customers by Country" query is reused

SELECT
	*
FROM
	dbo.CachedPlans
WHERE
	QueryText LIKE N'%Customers%'
AND
	QueryText NOT LIKE N'%sys.dm_exec_cached_plans%'
ORDER BY
	LastExecutionTime ASC;
GO


-- The "Customers by Country" query is executed again, but this time a single space
-- character is added to the query text. Since it's a different text now, it is
-- compiled again.

SELECT
	Id ,
	Name ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	Country = N'IL' ;
GO


-- View the procedure cache entries again to make sure that now there are
-- two different plans for the "Customers by Country" query

SELECT
	*
FROM
	dbo.CachedPlans
WHERE
	QueryText LIKE N'%Customers%'
AND
	QueryText NOT LIKE N'%sys.dm_exec_cached_plans%'
ORDER BY
	LastExecutionTime ASC;
GO


-- The "Customers by Country" query is executed again, but this time with a different
-- value for the country. Since it's a different text now, it is compiled again.

SELECT
	Id ,
	Name ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	Country = N'FR';
GO


-- View the procedure cache entries again to make sure that now there are
-- three different plans for the "Customers by Country" query

SELECT
	*
FROM
	dbo.CachedPlans
WHERE
	QueryText LIKE N'%Customers%'
AND
	QueryText NOT LIKE N'%sys.dm_exec_cached_plans%'
ORDER BY
	LastExecutionTime ASC;
GO
