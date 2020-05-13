USE
	YourAss;
GO


-- Empty the procedure cache

DBCC FREEPROCCACHE;
GO



/*** #1 - Non-Parameterized T-SQL Query ***/


-- Execute the query with country "IL"

SELECT
	Id ,
	Name ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	Country = N'IL';
GO


-- View the procedure cache entries

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


-- Execute the query with country "FR"

SELECT
	Id ,
	Name ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	Country = N'FR';
GO


-- View the procedure cache entries

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



/*** #2 - Non-Parameterized Dynamic SQL Query ***/


-- Execute the query with country "IL"

DECLARE
	@Country	AS NCHAR(2)			= N'IL' ,
	@QueryText	AS NVARCHAR(MAX);

SET @QueryText =
	N'
		SELECT
			Id ,
			Name ,
			LastPurchaseDate
		FROM
			Marketing.Customers
		WHERE
			Country = N''' + @Country + N''';
	';

EXECUTE (@QueryText);
GO


-- View the procedure cache entries

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


-- Execute the query with country "FR"

DECLARE
	@Country	AS NCHAR(2)			= N'FR' ,
	@QueryText	AS NVARCHAR(MAX);

SET @QueryText =
	N'
		SELECT
			Id ,
			Name ,
			LastPurchaseDate
		FROM
			Marketing.Customers
		WHERE
			Country = N''' + @Country + N''';
	';

EXECUTE (@QueryText);
GO


-- View the procedure cache entries

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



/*** #3 - Parameterized Dynamic SQL Query ***/


-- Execute the query with country "IL"

DECLARE
	@Country	AS NCHAR(2)			= N'IL' ,
	@QueryText	AS NVARCHAR(MAX) ,
	@Parameters	AS NVARCHAR(MAX);

SET @QueryText =
	N'
		SELECT
			Id ,
			Name ,
			LastPurchaseDate
		FROM
			Marketing.Customers
		WHERE
			Country = @pCountry;
	';

SET @Parameters = N'@pCountry AS NCHAR(2)';

EXECUTE sys.sp_executesql
	@statement	= @QueryText ,
	@params		= @Parameters ,
	@pCountry	= @Country;
GO


-- View the procedure cache entries

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


-- Execute the query with country "FR"

DECLARE
	@Country	AS NCHAR(2)			= N'FR' ,
	@QueryText	AS NVARCHAR(MAX) ,
	@Parameters	AS NVARCHAR(MAX);

SET @QueryText =
	N'
		SELECT
			Id ,
			Name ,
			LastPurchaseDate
		FROM
			Marketing.Customers
		WHERE
			Country = @pCountry;
	';

SET @Parameters = N'@pCountry AS NCHAR(2)';

EXECUTE sys.sp_executesql
	@statement	= @QueryText ,
	@params		= @Parameters ,
	@pCountry	= @Country;
GO


-- View the procedure cache entries

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



/*** #4 - Non-Parameterized Client-Side Query ***/


-- Execute a non-parameterized query from the application with country "IL"

-- View the procedure cache entries

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


-- Execute a non-parameterized query from the application with country "FR"

-- View the procedure cache entries

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



/*** #5 - Parameterized Client-Side Query ***/


-- Execute a parameterized query from the application with country "IL"

-- View the procedure cache entries

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


-- Execute a parameterized query from the application with country "FR"

-- View the procedure cache entries

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



/*** #6 - Stored Procedure ***/


-- Create the "Marketing.usp_CustomersByCountry" stored procedure

CREATE PROCEDURE
	Marketing.usp_CustomersByCountry
(
	@Country AS NCHAR(2)
)
AS

SELECT
	Id ,
	Name ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	Country = @Country;
GO


-- Execute the "Marketing.usp_CustomersByCountry" stored procedure with the parameter "IL"

EXECUTE Marketing.usp_CustomersByCountry
	@Country = N'IL';
GO


-- View the procedure cache entries

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


-- Execute the "Marketing.usp_CustomersByCountry" stored procedure with the parameter "FR"

EXECUTE Marketing.usp_CustomersByCountry
	@Country = N'FR';
GO


-- View the procedure cache entries

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



/*** #7 - Looks-Like-Parameterized T-SQL Query ***/


-- Execute the query with country "IL"

DECLARE
	@Country AS NCHAR(2) = N'IL';

SELECT
	Id ,
	Name ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	Country = @Country;
GO


-- View the procedure cache entries

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


-- Execute the query with country "FR"

DECLARE
	@Country AS NCHAR(2) = N'FR';

SELECT
	Id ,
	Name ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	Country = @Country;
GO


-- View the procedure cache entries

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
