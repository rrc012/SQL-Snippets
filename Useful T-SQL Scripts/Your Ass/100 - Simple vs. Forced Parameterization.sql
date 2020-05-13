USE
	YourAss;
GO


-- Empty the procedure cache

DBCC FREEPROCCACHE;
GO


-- Search customers by their country

SELECT
	Id ,
	Name ,
	Country ,
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


-- Search customers by their Id

SELECT
	Id ,
	Name ,
	Country ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	Id = 1234;
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


-- Search customers by another Id

SELECT
	Id ,
	Name ,
	Country ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	Id = 2345;
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


-- Display the parameterization type for the "YourAss" database

SELECT
	is_parameterization_forced
FROM
	sys.databases
WHERE
	name = N'YourAss';
GO


-- Change the parameterization type of the database to "FORCED"

ALTER DATABASE
	YourAss
SET
	PARAMETERIZATION FORCED;
GO


-- Search customers by their country

SELECT
	Id ,
	Name ,
	Country ,
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


-- Change the parameterization type of the database back to "SIMPLE"

ALTER DATABASE
	YourAss
SET
	PARAMETERIZATION SIMPLE;
GO


-- Create a template plan guide for the "Customers by Country" query

DECLARE
	@Statement	AS NVARCHAR(MAX) ,
	@Params		AS NVARCHAR(MAX);

EXECUTE sys.sp_get_query_template
	@querytext		=
		N'
			SELECT
				Id ,
				Name ,
				Country ,
				LastPurchaseDate
			FROM
				Marketing.Customers
			WHERE
				Country = N''IL'';
		' ,
	@templatetext	= @Statement	OUTPUT ,
	@parameters		= @Params		OUTPUT;

EXECUTE sys.sp_create_plan_guide
	@name				= N'CustomersByCountryTemplate' ,
	@stmt				= @Statement ,
	@type				= N'TEMPLATE' ,
	@module_or_batch	= NULL ,
	@params				= @Params ,
	@hints				= N'OPTION (PARAMETERIZATION FORCED)';
GO


-- Search for Israeli customers

SELECT
	Id ,
	Name ,
	Country ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	Country = N'IL';
GO


-- Search for French customers

SELECT
	Id ,
	Name ,
	Country ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	Country = N'FR';
GO


-- Search for American customers

SELECT
	Id ,
	Name ,
	Country ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	Country = N'US';
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


-- Drop the "CustomersByCountryTemplate" plan guide

EXECUTE sp_control_plan_guide
	@operation	= N'DROP' ,
	@name		= N'CustomersByCountryTemplate';
GO
