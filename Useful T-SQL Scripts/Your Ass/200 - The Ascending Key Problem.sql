USE
	YourAss;
GO


SET STATISTICS IO ON;
GO


-- Change the compatibility level of the database to 110 (SQL Server 2012)

ALTER DATABASE
	YourAss
SET
	COMPATIBILITY_LEVEL = 110;
GO


-- This query performs bad, because the optimizer estimates only 1 row to be returned from the "Web.PageViews"
-- (instead of ~180,000), based on the old cardinality estimation algorithm

SELECT
	PageViewId		= PageViews.Id ,
	SessionId		= PageViews.SessionId ,
	DateAndTime		= PageViews.DateAndTime ,
	ReferenceCode	= ReferenceCodes.ReferenceCode ,
	CustomerId		= ReferenceCodes.CustomerId ,
	ExpirationDate	= ReferenceCodes.ExpirationDate
FROM
	Web.PageViews AS PageViews
INNER JOIN
	Web.ReferenceCodes AS ReferenceCodes
ON
	PageViews.ReferenceCode = ReferenceCodes.ReferenceCode
WHERE
	PageViews.DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	PageViews.DateAndTime ASC;
GO


-- Show the histogram for the index statistics on the primary key
-- to understand why the optimizer thinks there are no rows in the last week

DBCC SHOW_STATISTICS (N'Web.PageViews' , N'pk_PageViews_c_DateAndTime#Id');
GO


-- One way to improve the way SQL Server handles automatic statistics updates in order to track the changes to the table
-- is to use trace flag 2371, which lowers the threshold to update statistics as the table becomes larger.
-- This is a server wide trace flag, and it should be carefully tested before it is used in production.
-- We are not going to demonstrate the impact of this trace flag here...


-- Change the compatibility level of the database to 120 (SQL Server 2014) in order to enable the new cardinalty estimator

ALTER DATABASE
	VeryLargeTableDemo
SET
	COMPATIBILITY_LEVEL = 120;
GO


-- This time the query performs better due to the new cardinality estimator, and now the optimizer estimates ~54,000 rows
-- to be returned from the "Web.PageViews" table

SELECT
	PageViewId		= PageViews.Id ,
	SessionId		= PageViews.SessionId ,
	DateAndTime		= PageViews.DateAndTime ,
	ReferenceCode	= ReferenceCodes.ReferenceCode ,
	CustomerId		= ReferenceCodes.CustomerId ,
	ExpirationDate	= ReferenceCodes.ExpirationDate
FROM
	Web.PageViews AS PageViews
INNER JOIN
	Web.ReferenceCodes AS ReferenceCodes
ON
	PageViews.ReferenceCode = ReferenceCodes.ReferenceCode
WHERE
	PageViews.DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	PageViews.DateAndTime ASC;
GO


-- If the performance of a specific query becomes worse due to the new cardinality estimator,
-- then you can revert to the old cardinality estimator only for the specific query by using a query hint with trace flag 9481

SELECT
	PageViewId		= PageViews.Id ,
	SessionId		= PageViews.SessionId ,
	DateAndTime		= PageViews.DateAndTime ,
	ReferenceCode	= ReferenceCodes.ReferenceCode ,
	CustomerId		= ReferenceCodes.CustomerId ,
	ExpirationDate	= ReferenceCodes.ExpirationDate
FROM
	Web.PageViews AS PageViews
INNER JOIN
	Web.ReferenceCodes AS ReferenceCodes
ON
	PageViews.ReferenceCode = ReferenceCodes.ReferenceCode
WHERE
	PageViews.DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	PageViews.DateAndTime ASC
OPTION
	(QUERYTRACEON 9481);
GO


-- We can manually update statistics more often, but for a very large table this is a resource intensive
-- and potentially a long running process

UPDATE STATISTICS
	Web.PageViews (pk_PageViews_c_DateAndTime#Id)
WITH
	FULLSCAN;
GO


DBCC SHOW_STATISTICS (N'Web.PageViews' , N'pk_PageViews_c_DateAndTime#Id');
GO


-- Now the optimizer estimates ~180,000 rows to be returned from the "Web.PageViews" table, which is the correct value

SELECT
	PageViewId		= PageViews.Id ,
	SessionId		= PageViews.SessionId ,
	DateAndTime		= PageViews.DateAndTime ,
	ReferenceCode	= ReferenceCodes.ReferenceCode ,
	CustomerId		= ReferenceCodes.CustomerId ,
	ExpirationDate	= ReferenceCodes.ExpirationDate
FROM
	Web.PageViews AS PageViews
INNER JOIN
	Web.ReferenceCodes AS ReferenceCodes
ON
	PageViews.ReferenceCode = ReferenceCodes.ReferenceCode
WHERE
	PageViews.DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	PageViews.DateAndTime ASC;
GO


-- We can, of course, use the default sampling rate instead of a full scan of the table.
-- This will significantly reduce the overhead of the statistics update,
-- but it could also affect the accuracy of cardinality estimation based on this statistics.
-- We are not going to demonstrate this here...

--UPDATE STATISTICS
--	Web.PageViews (pk_PageViews_c_DateAndTime#Id);
--GO


-- Let's go back to the behavior of SQL Server 2012

ALTER DATABASE
	VeryLargeTableDemo
SET
	COMPATIBILITY_LEVEL = 110;
GO


-- Let's simulate the problem again by doing the following:
-- 1. Delete data from the last week
-- 2. Update statistics
-- 3. Insert data from the last week again

DELETE FROM
	Web.PageViews
WHERE
	DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ());
GO


UPDATE STATISTICS
	Web.PageViews
WITH
	FULLSCAN;
GO


INSERT INTO
	Web.PageViews WITH (TABLOCK)
(
	URL ,
	ReferenceCode ,
	SessionId ,
	DateAndTime
)
SELECT
	URL				= N'www.' + REPLICATE (N'x' , ABS (CHECKSUM (NEWID ())) % 90) + N'.com' ,
	ReferenceCode	= ABS (CHECKSUM (NEWID ())) % 1000000 + 1 ,
	SessionId		= ABS (CHECKSUM (NEWID ())) % 1000000 + 1 ,
	DateAndTime		= RandomDateTime
FROM
	Web.RandomDateTimeValues
WHERE
	RandomDateTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	RandomDateTime ASC;
GO


DBCC SHOW_STATISTICS (N'Web.PageViews' , N'pk_PageViews_c_DateAndTime#Id');
GO


-- We are now back with the cardinality estimation of 1 based on the old algorithm in SQL Server 2012

SELECT
	PageViewId		= PageViews.Id ,
	SessionId		= PageViews.SessionId ,
	DateAndTime		= PageViews.DateAndTime ,
	ReferenceCode	= ReferenceCodes.ReferenceCode ,
	CustomerId		= ReferenceCodes.CustomerId ,
	ExpirationDate	= ReferenceCodes.ExpirationDate
FROM
	Web.PageViews AS PageViews
INNER JOIN
	Web.ReferenceCodes AS ReferenceCodes
ON
	PageViews.ReferenceCode = ReferenceCodes.ReferenceCode
WHERE
	PageViews.DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	PageViews.DateAndTime ASC;
GO


-- Another approach we could use in previous versions is to create a filtered statistics to cover only the last week.
-- Such a statistics is much smaller, and thus more accurate and less expensive to create.
-- The following statement will fail, because the filter definition has to be deterministic...

CREATE STATISTICS
	st_PageViews_DateAndTime_Filtered
ON
	Web.PageViews (DateAndTime)
WHERE
	DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
WITH
	FULLSCAN;
GO


-- This statement will succeed, because now the filter definition is deterministic...

DECLARE
	@LastWeek	AS DATETIME2(7)	= DATEADD (WEEK , -1 , SYSDATETIME ()) ,
	@Statement	AS NVARCHAR(MAX);

SET @Statement =
	N'
		CREATE STATISTICS
			st_PageViews_DateAndTime_Filtered
		ON
			Web.PageViews (DateAndTime)
		WHERE
			DateAndTime >= ''' + CAST (@LastWeek AS NVARCHAR(MAX)) + N'''
		WITH
			FULLSCAN;
	';

EXECUTE sys.sp_executesql
	@statement	= @Statement;
GO


DBCC SHOW_STATISTICS (N'Web.PageViews' , N'st_PageViews_DateAndTime_Filtered');
GO


-- The cardinality estimation is still 1 row, and the optimizer doesn't use the new filtered statistics.
-- The reason is that in order to use filtered statistcis, the predicate has to be deterministic as well.

SELECT
	PageViewId		= PageViews.Id ,
	SessionId		= PageViews.SessionId ,
	DateAndTime		= PageViews.DateAndTime ,
	ReferenceCode	= ReferenceCodes.ReferenceCode ,
	CustomerId		= ReferenceCodes.CustomerId ,
	ExpirationDate	= ReferenceCodes.ExpirationDate
FROM
	Web.PageViews AS PageViews
INNER JOIN
	Web.ReferenceCodes AS ReferenceCodes
ON
	PageViews.ReferenceCode = ReferenceCodes.ReferenceCode
WHERE
	PageViews.DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	PageViews.DateAndTime ASC;
GO


-- This query uses a parameter to pass the predicate value instead of a non-deterministic expession as before.
-- This method doesn't work either, because the optimizer has to generate a plan and store it in the plan cache for future reuse,
-- and the plan has to be compatible with any parameter value that might be used in the future.
-- For this reason, the optimizer will never consider filtered statistics when parameters are used for query predicates.

DECLARE
	@LastWeek				AS DATETIME2(7)	= DATEADD (WEEK , -1 , SYSDATETIME ()) ,
	@Statement				AS NVARCHAR(MAX) ,
	@ParametersDefinition	AS NVARCHAR(MAX);

SET @Statement =
	N'
		SELECT
			PageViewId		= PageViews.Id ,
			SessionId		= PageViews.SessionId ,
			DateAndTime		= PageViews.DateAndTime ,
			ReferenceCode	= ReferenceCodes.ReferenceCode ,
			CustomerId		= ReferenceCodes.CustomerId ,
			ExpirationDate	= ReferenceCodes.ExpirationDate
		FROM
			Web.PageViews AS PageViews
		INNER JOIN
			Web.ReferenceCodes AS ReferenceCodes
		ON
			PageViews.ReferenceCode = ReferenceCodes.ReferenceCode
		WHERE
			PageViews.DateAndTime >= @pLastWeek
		ORDER BY
			PageViews.DateAndTime ASC;
	';

SET @ParametersDefinition = N'@pLastWeek AS DATETIME2(7)';

EXECUTE sys.sp_executesql
	@statement	= @Statement ,
	@params		= @ParametersDefinition ,
	@pLastWeek	= @LastWeek;
GO


-- This time the predicate is deterministic and hard-coded, so the optimizer can use the filtered statistics,
-- and we get a very accurate cardinality estimation.

DECLARE
	@LastWeek	AS DATETIME2(7)	= DATEADD (WEEK , -1 , SYSDATETIME ()) ,
	@Statement	AS NVARCHAR(MAX);

SET @Statement =
	N'
		SELECT
			PageViewId		= PageViews.Id ,
			SessionId		= PageViews.SessionId ,
			DateAndTime		= PageViews.DateAndTime ,
			ReferenceCode	= ReferenceCodes.ReferenceCode ,
			CustomerId		= ReferenceCodes.CustomerId ,
			ExpirationDate	= ReferenceCodes.ExpirationDate
		FROM
			Web.PageViews AS PageViews
		INNER JOIN
			Web.ReferenceCodes AS ReferenceCodes
		ON
			PageViews.ReferenceCode = ReferenceCodes.ReferenceCode
		WHERE
			PageViews.DateAndTime >= ''' + CAST (@LastWeek AS NVARCHAR(MAX)) + N'''
		ORDER BY
			PageViews.DateAndTime ASC;
		';

EXECUTE sys.sp_executesql
	@statement	= @Statement;
GO


-- We can use the undocumented trace flag 9204 combined with the undocumented trace flag 3604
-- to show the statistics that have been used by the optimizer

DECLARE
	@LastWeek	AS DATETIME2(7)	= DATEADD (WEEK , -1 , SYSDATETIME ()) ,
	@Statement	AS NVARCHAR(MAX);

SET @Statement =
	N'
		SELECT
			PageViewId		= PageViews.Id ,
			SessionId		= PageViews.SessionId ,
			DateAndTime		= PageViews.DateAndTime ,
			ReferenceCode	= ReferenceCodes.ReferenceCode ,
			CustomerId		= ReferenceCodes.CustomerId ,
			ExpirationDate	= ReferenceCodes.ExpirationDate
		FROM
			Web.PageViews AS PageViews
		INNER JOIN
			Web.ReferenceCodes AS ReferenceCodes
		ON
			PageViews.ReferenceCode = ReferenceCodes.ReferenceCode
		WHERE
			PageViews.DateAndTime >= ''' + CAST (@LastWeek AS NVARCHAR(MAX)) + N'''
		ORDER BY
			PageViews.DateAndTime ASC
		OPTION
			(QUERYTRACEON 3604 , QUERYTRACEON 9204);
		';

EXECUTE sys.sp_executesql
	@statement	= @Statement;
GO


SELECT
	PageViewId		= PageViews.Id ,
	SessionId		= PageViews.SessionId ,
	DateAndTime		= PageViews.DateAndTime ,
	ReferenceCode	= ReferenceCodes.ReferenceCode ,
	CustomerId		= ReferenceCodes.CustomerId ,
	ExpirationDate	= ReferenceCodes.ExpirationDate
FROM
	Web.PageViews AS PageViews
INNER JOIN
	Web.ReferenceCodes AS ReferenceCodes
ON
	PageViews.ReferenceCode = ReferenceCodes.ReferenceCode
WHERE
	PageViews.DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	PageViews.DateAndTime ASC
OPTION
	(QUERYTRACEON 3604 , QUERYTRACEON 9204);
GO


-- Now, let's go back into the future and change the compatibility level to 120 (SQL Server 2014) again

ALTER DATABASE
	VeryLargeTableDemo
SET
	COMPATIBILITY_LEVEL = 120;
GO


-- Thanks to the new algorithm in SQL Server 2014, the optimizer can now use filtered statistics
-- even when the query predicate is non-deterministic

SELECT
	PageViewId		= PageViews.Id ,
	SessionId		= PageViews.SessionId ,
	DateAndTime		= PageViews.DateAndTime ,
	ReferenceCode	= ReferenceCodes.ReferenceCode ,
	CustomerId		= ReferenceCodes.CustomerId ,
	ExpirationDate	= ReferenceCodes.ExpirationDate
FROM
	Web.PageViews AS PageViews
INNER JOIN
	Web.ReferenceCodes AS ReferenceCodes
ON
	PageViews.ReferenceCode = ReferenceCodes.ReferenceCode
WHERE
	PageViews.DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	PageViews.DateAndTime ASC;
GO


-- Unfortunately, the undocumented trace flag 9204 doesn't work in SQL Server 2014.
-- This is a great example for what "undocumented" means...

SELECT
	PageViewId		= PageViews.Id ,
	SessionId		= PageViews.SessionId ,
	DateAndTime		= PageViews.DateAndTime ,
	ReferenceCode	= ReferenceCodes.ReferenceCode ,
	CustomerId		= ReferenceCodes.CustomerId ,
	ExpirationDate	= ReferenceCodes.ExpirationDate
FROM
	Web.PageViews AS PageViews
INNER JOIN
	Web.ReferenceCodes AS ReferenceCodes
ON
	PageViews.ReferenceCode = ReferenceCodes.ReferenceCode
WHERE
	PageViews.DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	PageViews.DateAndTime ASC
OPTION
	(QUERYTRACEON 3604 , QUERYTRACEON 9204);
GO


-- Let's drop the filtered statistics

DROP STATISTICS
	Web.PageViews.st_PageViews_DateAndTime_Filtered;
GO


-- Let's simulate the problem again by doing the following:
-- 1. Delete data from the last week
-- 2. Update statistics
-- 3. Insert data from the last week again

DELETE FROM
	Web.PageViews
WHERE
	DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ());
GO


-- This time we change the statistics to use incremental statistics

UPDATE STATISTICS
	Web.PageViews (pk_PageViews_c_DateAndTime#Id)
WITH
	FULLSCAN ,
	INCREMENTAL = ON;
GO


DBCC SHOW_STATISTICS (N'Web.PageViews' , N'pk_PageViews_c_DateAndTime#Id');
GO


INSERT INTO
	Web.PageViews WITH (TABLOCK)
(
	URL ,
	ReferenceCode ,
	SessionId ,
	DateAndTime
)
SELECT
	URL				= N'www.' + REPLICATE (N'x' , ABS (CHECKSUM (NEWID ())) % 90) + N'.com' ,
	ReferenceCode	= ABS (CHECKSUM (NEWID ())) % 1000000 + 1 ,
	SessionId		= ABS (CHECKSUM (NEWID ())) % 1000000 + 1 ,
	DateAndTime		= RandomDateTime
FROM
	Web.RandomDateTimeValues
WHERE
	RandomDateTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	RandomDateTime ASC;
GO


-- Surprisingly, the optimizer now has a good estimation of ~180,000, which is the actual value.
-- This is because the number of rows per partition in the last week exceeded the threshold and invalidated the statistics
-- for these partitions, so during query optimization, the incremental statistics for these partitions were recalculated
-- and merged into the table statistics.

SELECT
	PageViewId		= PageViews.Id ,
	SessionId		= PageViews.SessionId ,
	DateAndTime		= PageViews.DateAndTime ,
	ReferenceCode	= ReferenceCodes.ReferenceCode ,
	CustomerId		= ReferenceCodes.CustomerId ,
	ExpirationDate	= ReferenceCodes.ExpirationDate
FROM
	Web.PageViews AS PageViews
INNER JOIN
	Web.ReferenceCodes AS ReferenceCodes
ON
	PageViews.ReferenceCode = ReferenceCodes.ReferenceCode
WHERE
	PageViews.DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	PageViews.DateAndTime ASC;
GO


DBCC SHOW_STATISTICS (N'Web.PageViews' , N'pk_PageViews_c_DateAndTime#Id');
GO


-- Now let's insert additional data of 3 hours from yesterday (~3,000 rows)

INSERT INTO
	Web.PageViews WITH (TABLOCK)
(
	URL ,
	ReferenceCode ,
	SessionId ,
	DateAndTime
)
SELECT
	URL				= N'www.' + REPLICATE (N'x' , ABS (CHECKSUM (NEWID ())) % 90) + N'.com' ,
	ReferenceCode	= ABS (CHECKSUM (NEWID ())) % 1000000 + 1 ,
	SessionId		= ABS (CHECKSUM (NEWID ())) % 1000000 + 1 ,
	DateAndTime		= RandomDateTime
FROM
	Web.RandomDateTimeValues
WHERE
	RandomDateTime >= CAST (DATEADD (DAY , -1 , CAST (SYSDATETIME () AS DATE)) AS DATETIME2(7))
AND
	RandomDateTime < DATEADD (HOUR , 3 , CAST (DATEADD (DAY , -1 , CAST (SYSDATETIME () AS DATE)) AS DATETIME2(7)))
ORDER BY
	RandomDateTime ASC;
GO


-- We see that the actual number of rows has increased by approximately 3,000 rows, but the estimated number of rows hasn't changed.
-- This is because the number of changes in yesterday's partition didn't exceed the threshold (500 + 20%),
-- so the incremental statistcis for the partition wasn't updated automatically.

SELECT
	PageViewId		= PageViews.Id ,
	SessionId		= PageViews.SessionId ,
	DateAndTime		= PageViews.DateAndTime ,
	ReferenceCode	= ReferenceCodes.ReferenceCode ,
	CustomerId		= ReferenceCodes.CustomerId ,
	ExpirationDate	= ReferenceCodes.ExpirationDate
FROM
	Web.PageViews AS PageViews
INNER JOIN
	Web.ReferenceCodes AS ReferenceCodes
ON
	PageViews.ReferenceCode = ReferenceCodes.ReferenceCode
WHERE
	PageViews.DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	PageViews.DateAndTime ASC;
GO


DBCC SHOW_STATISTICS (N'Web.PageViews' , N'pk_PageViews_c_DateAndTime#Id');
GO


-- This query displays information about the partitions in the "Web.PageViews" table
-- Notice that the number of the partition that stores yesterday's data is 180

SELECT
	PartitionId				= Partitions.partition_id ,
	PartitionNumber			= Partitions.partition_number ,
	NumberOfRows			= Partitions.rows ,
	PartitionMinValue		= PartitionRangeValues.value ,
	IsBoundaryValueOnRight	= PartitionFunctions.boundary_value_on_right ,
	DestinationFilegroup	= Filegroups.name
FROM
	sys.partitions AS Partitions
INNER JOIN
	sys.indexes AS Indexes
ON
	Partitions.object_id = Indexes.object_id
AND
	Partitions.index_id = Indexes.index_id
LEFT OUTER JOIN
	sys.partition_range_values AS PartitionRangeValues
ON
	Partitions.partition_number = PartitionRangeValues.boundary_id + 1
LEFT OUTER JOIN
	sys.partition_functions AS PartitionFunctions
ON
	PartitionRangeValues.function_id = PartitionFunctions.function_id
INNER JOIN
	sys.destination_data_spaces AS DestinationDataSpaces
ON
	Partitions.partition_number = DestinationDataSpaces.destination_id
INNER JOIN
	sys.partition_schemes AS PartitionSchemes
ON
	DestinationDataSpaces.partition_scheme_id = PartitionSchemes.data_space_id
INNER JOIN
	sys.filegroups AS Filegroups
ON
	DestinationDataSpaces.data_space_id = Filegroups.data_space_id
WHERE
	Partitions.object_id = OBJECT_ID (N'Web.PageViews')
AND
	(PartitionFunctions.name = N'pf_EveryDay' OR PartitionFunctions.function_id IS NULL)
AND
	PartitionSchemes.name = N'ps_EveryDay'
AND
	Indexes.index_id = 1
ORDER BY
	PartitionNumber ASC;
GO


-- Now we can update only the incremental statistics for partition 180 (yesterday)
-- Notice that you have to specify "WITH RESAMPLE"

UPDATE STATISTICS
	Web.PageViews (pk_PageViews_c_DateAndTime#Id)
WITH
	RESAMPLE
ON
	PARTITIONS (180);
GO


DBCC SHOW_STATISTICS (N'Web.PageViews' , N'pk_PageViews_c_DateAndTime#Id');
GO


-- Now the optimizer has a different cardinality estimation, not necessarily better...

SELECT
	PageViewId		= PageViews.Id ,
	SessionId		= PageViews.SessionId ,
	DateAndTime		= PageViews.DateAndTime ,
	ReferenceCode	= ReferenceCodes.ReferenceCode ,
	CustomerId		= ReferenceCodes.CustomerId ,
	ExpirationDate	= ReferenceCodes.ExpirationDate
FROM
	Web.PageViews AS PageViews
INNER JOIN
	Web.ReferenceCodes AS ReferenceCodes
ON
	PageViews.ReferenceCode = ReferenceCodes.ReferenceCode
WHERE
	PageViews.DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	PageViews.DateAndTime ASC;
GO


-- It is also possible to instruct SQL Server to automatically create incremental statistics for partitioned tables

--ALTER DATABASE
--	VeryLargeTableDemo
--SET
--	AUTO_CREATE_STATISTICS ON (INCREMENTAL = ON);
--GO
