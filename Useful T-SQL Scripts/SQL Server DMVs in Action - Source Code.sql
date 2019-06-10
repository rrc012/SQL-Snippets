/***************************************************************************
Database	  : 
Name		  : SQL Server DMVs in Action - Source Code
Purpose     : 
Used By     : 
Author      : IAN STIRK
Created     : 2005-01-01
****************************************************************************
Contents
****************************************************************************
S.No    Name
----------------------------------------------------------------------------
1	   
  1.1   A simple monitor
  1.2   Find your slowest queries
  1.3   Find those missing indexes
  1.4   Identify what SQL is running now
  1.5   Quickly find a cached plan
2
  2.1   Restricting output to a given database
  2.2   Top 10 longest-running queries on server
  2.3   Looping over all databases on a server pattern
  2.4   Quickly find the most-used cached plans—simple version
  2.5   Extracting the Individual Query from the Parent Query
  2.6   Identify the database of ad hoc queries and stored procedures
  2.7   Example of printing the content of large variables
3
  3.1   Identifying the most important missing indexes
  3.2   The most-costly unused indexes
  3.3   The top high-maintenance indexes
  3.4   The most-used indexes
  3.5   The most-fragmented indexes
  3.6   Identifying indexes used by a given routine
  3.7   The databases with the most missing indexes
  3.8   Indexes that aren’t used at all
  3.9   What is the state of your statistics?
4
  4.1   How to find a cached plan
  4.2   Finding where a query is used
  4.3   The queries that take the longest time to run
  4.4   The queries spend the longest time being blocked
  4.5   The queries that use the most CPU
  4.6   The queries that use the most I/O
  4.7   The queries that have been executed the most often
  4.8   Finding when a query was last run
  4.9   Finding when a table was last inserted
5
  5.1   Finding queries with missing statistics
  5.2   Finding your default statistics options
  5.3   Finding disparate columns with different data types
  5.4   Finding queries that are running slower than normal
  5.5   Finding unused stored procedures
  5.6   Which queries run over a given time period
  5.7   Amalgamated DMV snapshots
  5.8   What queries are running now
  5.9   Determining your most-recompiled queries
6
  6.1   Why are you waiting?
  6.2   Why are you waiting? (snapshot version)
  6.3   Why your queries are waiting
  6.4   What is blocked?
  6.5   Effect of queries on performance counters
  6.6   Changes in performance counters and wait states
  6.7   Queries that change performance counters and wait states
  6.8   Recording DMV snapshots periodically
7
  7.1   C# code to create regex functionality for use within SQL Server
  7.2   Enabling CLR integration within SQL Server
  7.3   Using the CLR regular expression functionality
  7.4   The queries that spend the most time in the CLR
  7.5   The queries that spend the most time in the CLR (snapshot version)
  7.6   Relationships between DMVs and CLR queries
  7.7   Obtaining information about SQL CLR assemblies
8
  8.1   Transaction processing pattern
  8.2   Creating the sample database and table
  8.3   Starting an open transaction
  8.4   Selecting data from a table that has an open transaction against it
  8.5   Observing the current locks
  8.6   Template for handling deadlock retries
  8.7   Information contained in sessions, connections, and requests
  8.8   How to discover which locks are currently held
  8.9   How to identify contended resources
  8.10  How to identify contended resources, including SQL query details
  8.11  How to find an idle session with an open transaction
  8.12  What’s being blocked by idle sessions with open transactions
  8.13  What’s blocked by active sessions with open transactions
  8.14  What’s blocked—active and idle sessions with open transactions
  8.15  What has been blocked for more than 30 seconds
9
  9.1   Amount of space (total, used, and free) in tempdb
  9.2   Total amount of space (data, log, and log used) by database
  9.3   Tempdb total space usage by object type
  9.4   Space usage by session
  9.5   Space used and reclaimed in tempdb for completed batches
  9.6   Space usage by task
  9.7   Space used and not reclaimed in tempdb for active batches
  9.8   Indexes under the most row-locking pressure
  9.9   Indexes with the most lock escalations
  9.10  Indexes with the most unsuccessful lock escalations
  9.11  Indexes with the most page splits
  9.12  Indexes with the most latch contention
  9.13  Indexes with the most page I/O-latch contention
  9.14  Indexes under the most row-locking pressure—snapshot version
  9.15  Determining how many rows are inserted/deleted/updated/selected
10
  10.1  CLR function to extract the routine name
  10.2  Recompile routines that are running slower than normal
  10.3  Rebuild/reorganize for a given database
  10.4  Rebuild/reorganize for all databases on a given server
  10.5  Intelligently update statistics—simple version
  10.6  Intelligently update statistics—time-based version
  10.7  Update statistics used by a SQL routine or a time interval
  10.8  Automatically create any missing indexes
  10.9  Automatically disable or drop unused indexes
11
  11.1  Finding everyone’s last-run query
  11.2  Generic performance test harness
  11.3  Determining the performance impact of a system upgrade
  11.4  Estimating when a job will finish
  11.5  Who’s doing what and when?
  11.6  Determining where your query spends its time
  11.7  Memory used per database
  11.8  Memory used by objects in the current database
  11.9  I/O stalls at the database level
  11.10 I/O stalls at the file level
  11.11 Average read/write times per file, per database
  11.12 Simple trace utility
***************************************************************************/

-- Code for dbo.dba_WhatSQLIsExecuting
CREATE PROC dbo.dba_WhatSQLIsExecuting
AS
/*---------------------------------------------------------------------
Purpose: Shows what individual SQL statements are running.

Parameters: None.

Revision History:
12/08/2007	Ian_Stirk@yahoo.com Initial version

Example Usage: EXEC YourServerName.master.dbo.dba_WhatSQLIsExecuting;	 
---------------------------------------------------------------------*/
BEGIN

     SET NOCOUNT ON;
     
	-- Do not lock anything, and do not get held up by any locks.
     SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	-- What SQL Statements Are Currently Running?
	SELECT Spid = session_Id,
		  ecid,
		  [Database] = DB_NAME(sp.dbid),
		  [User] = nt_username,
		  [Status] = er.status,
		  Wait = wait_type,
		  [Individual Query] = SUBSTRING (qt.text, er.statement_start_offset/2, 
			                             (CASE WHEN er.statement_end_offset = -1 
				                              THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
			                                   ELSE er.statement_end_offset
								     END - er.statement_start_offset
								    )/2
								   ),
		 [Parent Query] = qt.text,
		 Program = program_name,
		 Hostname,
		 nt_domain,
		 start_time
	 FROM sys.dm_exec_requests AS er 
	      INNER JOIN sys.sysprocesses AS sp ON er.session_id = sp.spid
	      CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
	WHERE session_Id > 50			-- Ignore system spids. 
	  AND session_Id NOT IN (@@SPID)	-- Ignore this current statement.
	ORDER BY 1, 2;
END
GO

----------------------------------------------------------------------------------------------------------- 
-- Code for dbo.dba_GetSQLForSpid
CREATE FUNCTION dbo.dba_GetSQLForSpid
(
   @spid SMALLINT
)
RETURNS NVARCHAR(4000)
/*-------------------------------------------------
Purpose:    Returns the SQL text for a given spid.

Parameters: @spid - SQL Server process ID.

Returns:    @SqlText - SQL text for a given spid.

Revision History:
01/12/2006   Ian_Stirk@yahoo.com Initial version

Example Usage:
SELECT dbo.dba_GetSQLForSpid(51);
SELECT dbo.dba_GetSQLForSpid(spid) AS [SQL text],
       *
  FROM sys.sysprocesses WITH (NOLOCK);
--------------------------------------------------*/
BEGIN

   DECLARE @SqlHandle BINARY(20),
           @SqlText NVARCHAR(4000);

   -- Get sql_handle for the given spid.
   SELECT @SqlHandle = sql_handle 
     FROM sys.sysprocesses WITH (NOLOCK)
    WHERE spid = @spid;

   -- Get the SQL text for the given sql_handle.
   SELECT @SqlText = [text]
     FROM sys.dm_exec_sql_text(@SqlHandle);

   RETURN @SqlText; 
END
GO

-----------------------------------------------------------------------------------------------------------
-- Code for dbo.dba_BlockTracer
CREATE PROC dbo.dba_BlockTracer
AS
/*--------------------------------------------------
Purpose: Shows details of the root blocking process,
         together with details of any blocked processed

Parameters: None. 

Revision History:
19/07/2007   Ian_Stirk@yahoo.com Initial version 

Example Usage:
EXEC YourServerName.master.dbo.dba_BlockTracer;
--------------------------------------------------*/
BEGIN

   SET NOCOUNT ON;

   -- Do not lock anything, and do not get held up by any locks. 
   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

   -- If there are blocked processes...
   IF EXISTS(SELECT 1 FROM sys.sysprocesses WHERE blocked != 0) 
   BEGIN
      -- Identify the root-blocking spid(s)
      SELECT
             DISTINCT
             t1.spid AS [Root blocking spids],
             t1.loginame AS [Owner],
             master.dbo.dba_GetSQLForSpid(t1.spid) AS 'SQL Text',
             t1.cpu,
             t1.physical_io,
             DatabaseName = DB_NAME(t1.[dbid]),
             t1.[program_name],
             t1.hostname,
             t1.[status],
             t1.cmd,
             t1.blocked,
             t1.ecid
        FROM sys.sysprocesses AS t1
             INNER JOIN sys.sysprocesses AS t2 ON t1.spid = t2.blocked
                    AND t1.ecid = t2.ecid
       WHERE t1.blocked = 0 
       ORDER BY t1.spid, t1.ecid; 

      -- Identify the spids being blocked.
      SELECT t2.spid AS 'Blocked spid',
             t2.blocked AS 'Blocked By',
             t2.loginame AS [Owner],
             master.dbo.dba_GetSQLForSpid(t2.spid) AS 'SQL Text',
             t2.cpu,
             t2.physical_io,
             DatabaseName = DB_NAME(t2.[dbid]),
             t2.[program_name],
             t2.hostname,
             t2.[status],
             t2.cmd,
             t2.ecid
        FROM sys.sysprocesses t1
             INNER JOIN sys.sysprocesses AS t2 ON t1.spid = t2.blocked
                    AND t1.ecid = t2.ecid
       ORDER BY t2.blocked, t2.spid, t2.ecid;
   END
   ELSE 
        PRINT 'No processes blocked.' -- No blocked processes.
END
GO

-------------------------------------------------------------------------------
-- Listing 1.1 A simple monitor
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

WAITFOR TIME '19:00:00'
GO

PRINT GETDATE()
EXEC master.dbo.dba_BlockTracer;

IF @@ROWCOUNT > 0
BEGIN
	SELECT GETDATE() AS TIME
	EXEC master.dbo.dba_WhatSQLIsExecuting;
END

WAITFOR DELAY '00:00:15';
GO 500

-- Listing 1.2 Find your slowest queries
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
       CAST(qs.total_elapsed_time / 1000000.0 AS DECIMAL(28, 2)) AS [Total Elapsed Duration (s)],
       qs.execution_count,
       SUBSTRING (qt.text,
	             (qs.statement_start_offset/2) + 1,
                  (
	              (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2
	             ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName,
       qp.query_plan
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
       CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
       INNER JOIN sys.dm_exec_cached_plans AS cp ON qs.plan_handle=cp.plan_handle
 ORDER BY total_elapsed_time DESC;

-- Listing 1.3 Find those missing indexes
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
       ROUND(s.avg_total_user_cost * s.avg_user_impact * (s.user_seeks + s.user_scans),0) AS [Total Cost],
       s.avg_user_impact,
       d.[statement] AS TableName,
       d.equality_columns,
       d.inequality_columns,
       d.included_columns
  FROM sys.dm_db_missing_index_groups AS g
       INNER JOIN sys.dm_db_missing_index_group_stats AS s ON s.group_handle = g.index_group_handle
       INNER JOIN sys.dm_db_missing_index_details AS d ON d.index_handle = g.index_handle
 ORDER BY [Total Cost] DESC;

-- Listing 1.4 Identify what SQL is running now
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT er.session_Id AS [Spid],
       sp.ecid,
       DB_NAME(sp.dbid) AS [Database],
       sp.nt_username,
       er.status,
       er.wait_type,
       SUBSTRING (qt.text,
	             (er.statement_start_offset/2) + 1,
                  (
			    (CASE WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE er.statement_end_offset END - er.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       sp.program_name,
       sp.Hostname,
       sp.nt_domain,
       er.start_time
  FROM sys.dm_exec_requests AS er
       INNER JOIN sys.sysprocesses AS sp ON er.session_id = sp.spid
       CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
 WHERE session_Id > 50
   AND session_Id NOT IN (@@SPID)
 ORDER BY session_Id, ecid;

-- Listing 1.5 Quickly find a cached plan
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
	  st.text AS [SQL],
	  cp.cacheobjtype,
	  cp.objtype,
	  COALESCE(DB_NAME(st.dbid), DB_NAME(CAST(pa.value AS INT)) + '*', 'Resource') AS [DatabaseName],
	  cp.usecounts AS [Plan usage],
	  qp.query_plan
  FROM sys.dm_exec_cached_plans AS cp
       CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
       CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
       OUTER APPLY sys.dm_exec_plan_attributes(cp.plan_handle) AS pa
 WHERE pa.attribute = 'dbid'
  AND st.text LIKE '%CREATE PROCEDURE%';

-- Listing 2.1 Restricting output to a given database
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT SUM(qs.total_logical_reads) AS [Total Reads],
	  SUM(qs.total_logical_writes) AS [Total Writes],
	  DB_NAME(qt.dbid) AS DatabaseName
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
 WHERE DB_NAME(qt.dbid) = 'ParisDev'
 GROUP BY DB_NAME(qt.dbid);

-- Listing 2.2 Top 10 longest-running queries on server
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 10
	  qs.total_elapsed_time AS [Total Time],
	  qs.execution_count AS [Execution count],
	  SUBSTRING (qt.text,
	             (qs.statement_start_offset/2) + 1,
	             (
			    (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
	  qt.text AS [Parent Query],
	  DB_NAME(qt.dbid) AS DatabaseName,
	  qp.query_plan
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
       CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
 ORDER BY [Total Time] DESC;

-- Listing 2.3 Looping over all databases on a server pattern
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#TempUsage', 'U') IS NOT NULL DROP TABLE #TempUsage;
SELECT DB_NAME() AS DatabaseName,
	  SCHEMA_NAME(o.Schema_ID) AS SchemaName,
	  OBJECT_NAME(s.[object_id]) AS TableName,
	  i.name AS IndexName,
	  (s.user_seeks + s.user_scans + s.user_lookups) AS [Usage],
	  s.user_updates,
	  i.fill_factor
  INTO #TempUsage
  FROM sys.dm_db_index_usage_stats s
       INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id]
              AND s.index_id = i.index_id
       INNER JOIN sys.objects o ON i.object_id = O.object_id
 WHERE 1 = 2;

EXEC sp_MSForEachDB 
'USE [?];
INSERT INTO #TempUsage
SELECT TOP 10
	  DB_NAME() AS DatabaseName,
	  SCHEMA_NAME(o.Schema_ID) AS SchemaName,
	  OBJECT_NAME(s.[object_id]) AS TableName,
	  i.name AS IndexName,
	  (s.user_seeks + s.user_scans + s.user_lookups) AS [Usage],
	  s.user_updates,
	  i.fill_factor
  FROM sys.dm_db_index_usage_stats s
       INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id]
       	    AND s.index_id = i.index_id
       INNER JOIN sys.objects o ON i.object_id = O.object_id
 WHERE s.database_id = DB_ID()
   AND i.name IS NOT NULL
   AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
 ORDER BY [Usage] DESC';

SELECT TOP 10 * FROM #TempUsage ORDER BY [Usage] DESC;

-- Listing 2.4 Quickly find the most-used cached plans—simple version
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 10
	  st.text AS [SQL],
	  DB_NAME(st.dbid) AS DatabaseName,
	  cp.usecounts AS [Plan usage],
	  qp.query_plan
  FROM sys.dm_exec_cached_plans AS cp
       CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
       CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
 WHERE st.text LIKE '%CREATE PROCEDURE%'
 ORDER BY cp.usecounts DESC;

-- Listing 2.5 Extracting the Individual Query from the Parent Query
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
	  qs.execution_count,
	  SUBSTRING (qt.text, (qs.statement_start_offset/2) + 1,
	             (
			    (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
	  qt.text AS [Parent Query],
	  DB_NAME(qt.dbid) AS DatabaseName
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
 ORDER BY execution_count DESC;

-- Listing 2.6 Identify the database of ad hoc queries and stored procedures
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
	  st.text AS [SQL],
	  cp.cacheobjtype,
	  cp.objtype,
	  COALESCE(DB_NAME(st.dbid), DB_NAME(CAST(pa.value AS INT))+'*', 'Resource') AS [DatabaseName],
	  cp.usecounts AS [Plan usage],
	  qp.query_plan
  FROM sys.dm_exec_cached_plans AS cp
       CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
       CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
       OUTER APPLY sys.dm_exec_plan_attributes(cp.plan_handle) AS pa
 WHERE pa.attribute = 'dbid'
 ORDER BY cp.usecounts DESC;

-- Listing 2.7 Example of printing the content of large variables
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

DECLARE @StartOffset INT = 0,
        @Length INT = 4000,
        @DynamicSQL NVARCHAR(MAX) = '';

IF OBJECT_ID('tempdb..#TableDetails', 'U') IS NOT NULL DROP TABLE #TableDetails;
SELECT TABLE_CATALOG,
       TABLE_SCHEMA,
	  TABLE_NAME
  INTO #TableDetails
  FROM INFORMATION_SCHEMA.tables
 WHERE TABLE_TYPE = 'BASE TABLE';

SELECT @DynamicSQL = @DynamicSQL + CHAR(10)
	              + ' SELECT COUNT_BIG(*) AS [TableName: '
	              + TABLE_CATALOG + '.' + TABLE_SCHEMA + '.' + TABLE_NAME
	              + '] FROM ' + QUOTENAME(TABLE_CATALOG) + '.'
	              + QUOTENAME(TABLE_SCHEMA) + '.' + QUOTENAME(TABLE_NAME)
  FROM #TableDetails;

--EXECUTE sp_executesql @DynamicSQL
WHILE (@StartOffset < LEN(@DynamicSQL))
BEGIN
	PRINT SUBSTRING(@DynamicSQL, @StartOffset, @Length);
	SET @StartOffset += @Length;
END

PRINT SUBSTRING(@DynamicSQL, @StartOffset, @Length);

-- Listing 3.1 Identifying the most important missing indexes
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
	  ROUND(s.avg_total_user_cost * s.avg_user_impact * (s.user_seeks + s.user_scans),0) AS [Total Cost],
       d.[statement] AS [Table Name],
       equality_columns,
       inequality_columns,
       included_columns
  FROM sys.dm_db_missing_index_groups AS g
       INNER JOIN sys.dm_db_missing_index_group_stats AS s ON s.group_handle = g.index_group_handle
       INNER JOIN sys.dm_db_missing_index_details AS d ON d.index_handle = g.index_handle
 ORDER BY [Total Cost] DESC;

-- Listing 3.2 The most-costly unused indexes
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#TempUnusedIndexes', 'U') IS NOT NULL DROP TABLE #TempUnusedIndexes;
SELECT DB_NAME() AS DatabaseName,
	  SCHEMA_NAME(o.Schema_ID) AS SchemaName,
	  OBJECT_NAME(s.[object_id]) AS TableName,
	  i.name AS IndexName,
	  s.user_updates,
	  s.system_seeks + s.system_scans + s.system_lookups AS [System usage]
  INTO #TempUnusedIndexes
  FROM sys.dm_db_index_usage_stats AS s
       INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
              AND s.index_id = i.index_id
       INNER JOIN sys.objects AS o ON i.object_id = O.object_id
 WHERE 1 = 2;

EXEC sp_MSForEachDB
'USE [?];
INSERT INTO #TempUnusedIndexes
SELECT TOP 20
       DB_NAME() AS DatabaseName,
       SCHEMA_NAME(o.Schema_ID) AS SchemaName,
       OBJECT_NAME(s.[object_id]) AS TableName,
       i.name AS IndexName,
       s.user_updates,
       s.system_seeks + s.system_scans + s.system_lookups AS [System usage]
  FROM sys.dm_db_index_usage_stats s
       INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id]
              AND s.index_id = i.index_id
       INNER JOIN sys.objects o ON i.object_id = O.object_id
 WHERE s.database_id = DB_ID()
   AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
   AND s.user_seeks = 0
   AND s.user_scans = 0
   AND s.user_lookups = 0
   AND i.name IS NOT NULL
 ORDER BY s.user_updates DESC;'

SELECT TOP 20 * FROM #TempUnusedIndexes ORDER BY [user_updates] DESC;

-- Listing 3.3 The top high-maintenance indexes
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#TempMaintenanceCost', 'U') IS NOT NULL DROP TABLE #TempMaintenanceCost;
SELECT DB_NAME() AS DatabaseName,
       SCHEMA_NAME(o.Schema_ID) AS SchemaName,
       OBJECT_NAME(s.[object_id]) AS TableName,
       i.name AS IndexName,
       (s.user_updates ) AS [update usage],
       (s.user_seeks + s.user_scans + s.user_lookups) AS [Retrieval usage],
       (s.user_updates) - (s.user_seeks + s.user_scans + s.user_lookups) AS [Maintenance cost],
       s.system_seeks + s.system_scans + s.system_lookups AS [System usage],
       s.last_user_seek,
       s.last_user_scan,
       s.last_user_lookup
  INTO #TempMaintenanceCost
  FROM sys.dm_db_index_usage_stats AS s
       INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
              AND s.index_id = i.index_id
       INNER JOIN sys.objects AS o ON i.object_id = O.object_id
 WHERE 1 = 2;

EXEC sp_MSForEachDB
'USE [?];
INSERT INTO #TempMaintenanceCost
SELECT TOP 20
       DB_NAME() AS DatabaseName,
       SCHEMA_NAME(o.Schema_ID) AS SchemaName,
       OBJECT_NAME(s.[object_id]) AS TableName,
       i.name AS IndexName,
       (s.user_updates ) AS [update usage],
       (s.user_seeks + s.user_scans + s.user_lookups) AS [Retrieval usage],
       (s.user_updates) - (s.user_seeks + s.user_scans + s.user_lookups) AS [Maintenance cost],
       s.system_seeks + s.system_scans + s.system_lookups AS [System usage],
       s.last_user_seek,
       s.last_user_scan,
       s.last_user_lookup
  FROM sys.dm_db_index_usage_stats AS s
       INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
              AND s.index_id = i.index_id
       INNER JOIN sys.objects AS o ON i.object_id = O.object_id
 WHERE s.database_id = DB_ID()
   AND i.name IS NOT NULL
   AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
   AND (s.user_seeks + s.user_scans + s.user_lookups) > 0
 ORDER BY [Maintenance cost] DESC;'

SELECT TOP 20 * FROM #TempMaintenanceCost ORDER BY [Maintenance cost] DESC;

-- Listing 3.4 The most-used indexes
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#TempUsage', 'U') IS NOT NULL DROP TABLE #TempUsage;
SELECT DB_NAME() AS DatabaseName,
       SCHEMA_NAME(o.Schema_ID) AS SchemaName,
       OBJECT_NAME(s.[object_id]) AS TableName,
       i.name AS IndexName,
       (s.user_seeks + s.user_scans + s.user_lookups) AS [Usage],
       s.user_updates,
       i.fill_factor
  INTO #TempUsage
  FROM sys.dm_db_index_usage_stats AS s
       INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
              AND s.index_id = i.index_id
       INNER JOIN sys.objects AS o ON i.object_id = O.object_id
 WHERE 1 = 2;

EXEC sp_MSForEachDB
'USE [?];
INSERT INTO #TempUsage
SELECT TOP 20
       DB_NAME() AS DatabaseName,
       SCHEMA_NAME(o.Schema_ID) AS SchemaName,
       OBJECT_NAME(s.[object_id]) AS TableName,
       i.name AS IndexName,
       (s.user_seeks + s.user_scans + s.user_lookups) AS [Usage],
       s.user_updates,
       i.fill_factor
  FROM sys.dm_db_index_usage_stats s
       INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id]
              AND s.index_id = i.index_id
       INNER JOIN sys.objects o ON i.object_id = O.object_id
 WHERE s.database_id = DB_ID()
   AND i.name IS NOT NULL
   AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
 ORDER BY [Usage] DESC;'

SELECT TOP 20 * FROM #TempUsage ORDER BY [Usage] DESC;

-- Listing 3.5 The most-fragmented indexes
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#TempFragmentation', 'U') IS NOT NULL DROP TABLE #TempFragmentation;
SELECT DB_NAME() AS DatbaseName,
       SCHEMA_NAME(o.Schema_ID) AS SchemaName,
       OBJECT_NAME(s.[object_id]) AS TableName,
       i.name AS IndexName,
       ROUND(s.avg_fragmentation_in_percent,2) AS [Fragmentation %]
  INTO #TempFragmentation
  FROM sys.dm_db_index_physical_stats(db_id(),null, null, null, null) AS s
       INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
              AND s.index_id = i.index_id
       INNER JOIN sys.objects AS o ON i.object_id = O.object_id
WHERE 1 = 2;

EXEC sp_MSForEachDB
'USE [?];
INSERT INTO #TempFragmentation
SELECT TOP 20
       DB_NAME() AS DatbaseName,
       SCHEMA_NAME(o.Schema_ID) AS SchemaName,
       OBJECT_NAME(s.[object_id]) AS TableName,
       i.name AS IndexName,
       ROUND(s.avg_fragmentation_in_percent,2) AS [Fragmentation %]
  FROM sys.dm_db_index_physical_stats(db_id(),null, null, null, null) AS s
       INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
              AND s.index_id = i.index_id
       INNER JOIN sys.objects AS o ON i.object_id = O.object_id
 WHERE s.database_id = DB_ID()
   AND i.name IS NOT NULL
   AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
 ORDER BY [Fragmentation %] DESC;'

SELECT TOP 20 * FROM #TempFragmentation ORDER BY [Fragmentation %] DESC;

-- Listing 3.6 Identifying indexes used by a given routine
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#IndexStatsPre', 'U') IS NOT NULL DROP TABLE #IndexStatsPre;
IF OBJECT_ID('tempdb..#IndexStatsPost', 'U') IS NOT NULL DROP TABLE #IndexStatsPost;
SELECT SchemaName = ss.name,
       TableName = st.name,
       IndexName = ISNULL(si.name, ''),
       IndexType = si.type_desc,
       user_updates = ISNULL(ius.user_updates, 0),
       user_seeks = ISNULL(ius.user_seeks, 0),
       user_scans = ISNULL(ius.user_scans, 0),
       user_lookups = ISNULL(ius.user_lookups, 0),
       ssi.rowcnt,
       ssi.rowmodctr,
       si.fill_factor
  INTO #IndexStatsPre
  FROM sys.dm_db_index_usage_stats AS ius
       RIGHT JOIN sys.indexes AS si ON ius.[object_id] = si.[object_id]
              AND ius.index_id = si.index_id
       INNER JOIN sys.sysindexes AS ssi ON si.object_id = ssi.id
              AND si.name = ssi.name
       INNER JOIN sys.tables AS st ON st.[object_id] = si.[object_id]
       INNER JOIN sys.schemas AS ss ON ss.[schema_id] = st.[schema_id]
 WHERE ius.database_id = DB_ID()
   AND OBJECTPROPERTY(ius.[object_id], 'IsMsShipped') = 0;

SELECT SchemaName = ss.name,
       TableName = st.name,
       IndexName = ISNULL(si.name, ''),
       IndexType = si.type_desc,
       user_updates = ISNULL(ius.user_updates, 0),
       user_seeks = ISNULL(ius.user_seeks, 0),
       user_scans = ISNULL(ius.user_scans, 0),
       user_lookups = ISNULL(ius.user_lookups, 0),
       ssi.rowcnt,
       ssi.rowmodctr,
       si.fill_factor
  INTO #IndexStatsPost
  FROM sys.dm_db_index_usage_stats AS ius
       RIGHT JOIN sys.indexes AS si ON ius.[object_id] = si.[object_id]
              AND ius.index_id = si.index_id
       INNER JOIN sys.sysindexes AS ssi ON si.object_id = ssi.id
              AND si.name = ssi.name
       INNER JOIN sys.tables AS st ON st.[object_id] = si.[object_id]
       INNER JOIN sys.schemas AS ss ON ss.[schema_id] = st.[schema_id]
 WHERE ius.database_id = DB_ID()
   AND OBJECTPROPERTY(ius.[object_id], 'IsMsShipped') = 0;

SELECT DB_NAME() AS DatabaseName,
       po.[SchemaName],
       po.[TableName],
       po.[IndexName],
       po.[IndexType],
       po.user_updates - ISNULL(pr.user_updates, 0) AS [User Updates],
       po.user_seeks - ISNULL(pr.user_seeks, 0) AS [User Seeks],
       po.user_scans - ISNULL(pr.user_scans, 0) AS [User Scans],
       po.user_lookups - ISNULL(pr.user_lookups , 0) AS [User Lookups],
       po.rowcnt - pr.rowcnt AS [Rows Inserted],
       po.rowmodctr - pr.rowmodctr AS [Updates I/U/D],
       po.fill_factor
  FROM #IndexStatsPost AS po
       LEFT JOIN #IndexStatsPre AS pr ON pr.SchemaName = po.SchemaName
             AND pr.TableName = po.TableName
             AND pr.IndexName = po.IndexName
             AND pr.IndexType = po.IndexType
 WHERE ISNULL(pr.user_updates, 0) != po.user_updates
    OR ISNULL(pr.user_seeks, 0) != po.user_seeks
    OR ISNULL(pr.user_scans, 0) != po.user_scans
    OR ISNULL(pr.user_lookups, 0) != po.user_lookups
 ORDER BY po.[SchemaName], po.[TableName], po.[IndexName];

-- Listing 3.7 The databases with the most missing indexes
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT DB_NAME(database_id) AS DatabaseName,
	  COUNT(*) AS [Missing Index Count]
  FROM sys.dm_db_missing_index_details
 GROUP BY DB_NAME(database_id)
 ORDER BY [Missing Index Count] DESC;

-- Listing 3.8 Indexes that aren’t used at all
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#TempNeverUsedIndexes', 'U') IS NOT NULL DROP TABLE #TempNeverUsedIndexes;
SELECT DB_NAME() AS DatbaseName,
       SCHEMA_NAME(O.Schema_ID) AS SchemaName,
       OBJECT_NAME(I.object_id) AS TableName,
       I.name AS IndexName
  INTO #TempNeverUsedIndexes
  FROM sys.indexes AS I
       INNER JOIN sys.objects AS O ON I.object_id = O.object_id
 WHERE 1 = 2;

EXEC sp_MSForEachDB
'USE [?];
INSERT INTO #TempNeverUsedIndexes
SELECT DB_NAME() AS DatbaseName,
       SCHEMA_NAME(O.Schema_ID) AS SchemaName,
       OBJECT_NAME(I.object_id) AS TableName,
       I.NAME AS IndexName
  FROM sys.indexes AS I
       INNER JOIN sys.objects AS O ON I.object_id = O.object_id
       LEFT JOIN sys.dm_db_index_usage_stats AS S ON S.object_id = I.object_id
             AND I.index_id = S.index_id
             AND DATABASE_ID = DB_ID()
WHERE OBJECTPROPERTY(O.object_id,''IsMsShipped'') = 0
  AND I.name IS NOT NULL
  AND S.object_id IS NULL;'

SELECT *
  FROM #TempNeverUsedIndexes
 ORDER BY DatbaseName, SchemaName, TableName, IndexName;

-- Listing 3.9 What is the state of your statistics?
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT ss.name AS SchemaName,
       st.name AS TableName,
       s.name AS IndexName,
       STATS_DATE(s.id,s.indid) AS 'Statistics Last Updated',
       s.rowcnt AS 'Row Count',
       s.rowmodctr AS 'Number Of Changes',
       CAST((CAST(s.rowmodctr AS DECIMAL(28,8))/CAST(s.rowcnt AS DECIMAL(28,2)) * 100.0) AS DECIMAL(28,2)) AS '% Rows Changed'
  FROM sys.sysindexes AS s
       INNER JOIN sys.tables AS st ON st.[object_id] = s.[id]
       INNER JOIN sys.schemas AS ss ON ss.[schema_id] = st.[schema_id]
 WHERE s.id > 100
   AND s.indid > 0
   AND s.rowcnt >= 500
 ORDER BY SchemaName, TableName, IndexName;

-- Listing 4.1 How to find a cached plan
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
	  st.text AS [SQL],
	  cp.cacheobjtype,
	  cp.objtype,
	  COALESCE(DB_NAME(st.dbid), DB_NAME(CAST(pa.value AS INT)) + '*', 'Resource') AS [DatabaseName],
	  cp.usecounts AS [Plan usage],
	  qp.query_plan
  FROM sys.dm_exec_cached_plans AS cp
       CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
       CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
       OUTER APPLY sys.dm_exec_plan_attributes(cp.plan_handle) AS pa
 WHERE pa.attribute = 'dbid'
   AND st.text LIKE '%PartyType%';

-- Listing 4.2 Finding where a query is used
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
	  CA.Individual_Query,
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName,
       qp.query_plan
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
       CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
	  CROSS APPLY (SELECT SUBSTRING (qt.text,
                                      (qs.statement_start_offset/2) + 1,
                                      (
                                       (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2
							   ) + 1
                                     ) AS Individual_Query) AS CA
 WHERE CA.Individual_Query LIKE '%insert into dbo.deal%';

-- Listing 4.3 The queries that take the longest time to run
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
       CAST(qs.total_elapsed_time / 1000000.0 AS DECIMAL(28, 2)) AS [Total Duration (s)],
       CAST(qs.total_worker_time * 100.0 / qs.total_elapsed_time AS DECIMAL(28, 2)) AS [% CPU],
       CAST((qs.total_elapsed_time - qs.total_worker_time)* 100.0 / qs.total_elapsed_time AS DECIMAL(28, 2)) AS [% Waiting],
       qs.execution_count,
       CAST(qs.total_elapsed_time / 1000000.0 / qs.execution_count AS DECIMAL(28, 2)) AS [Average Duration (s)],
       SUBSTRING (qt.text,
	             (qs.statement_start_offset/2) + 1,
	             (
			    (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName,
       qp.query_plan
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
       CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
 WHERE qs.total_elapsed_time > 0
 ORDER BY qs.total_elapsed_time DESC;

-- Listing 4.4 The queries spend the longest time being blocked
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
       CAST((qs.total_elapsed_time - qs.total_worker_time)/1000000.0 AS DECIMAL(28,2)) AS [Total time blocked (s)],
       CAST(qs.total_worker_time * 100.0 / qs.total_elapsed_time AS DECIMAL(28,2)) AS [% CPU],
       CAST((qs.total_elapsed_time - qs.total_worker_time)* 100.0/qs.total_elapsed_time AS DECIMAL(28, 2)) AS [% Waiting],
       qs.execution_count,
       CAST((qs.total_elapsed_time - qs.total_worker_time)/1000000.0/qs.execution_count AS DECIMAL(28, 2)) AS [Blocking average (s)],
       SUBSTRING (qt.text,
	             (qs.statement_start_offset/2) + 1,
	             (
			    (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName,
       qp.query_plan
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
       CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
 WHERE qs.total_elapsed_time > 0
 ORDER BY [Total time blocked (s)] DESC;

-- Listing 4.5 The queries that use the most CPU
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
       CAST((qs.total_worker_time) / 1000000.0 AS DECIMAL(28,2)) AS [Total CPU time (s)],
       CAST(qs.total_worker_time * 100.0 / qs.total_elapsed_time AS DECIMAL(28,2)) AS [% CPU],
       CAST((qs.total_elapsed_time - qs.total_worker_time)* 100.0 / qs.total_elapsed_time AS DECIMAL(28, 2)) AS [% Waiting],
       qs.execution_count,
       CAST((qs.total_worker_time) / 1000000.0 / qs.execution_count AS DECIMAL(28, 2)) AS [CPU time average (s)],
       SUBSTRING (qt.text,
	             (qs.statement_start_offset/2) + 1,
                  (
			    (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName,
       qp.query_plan
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
       CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
 WHERE qs.total_elapsed_time > 0
 ORDER BY [Total CPU time (s)] DESC;

-- Listing 4.6 The queries that use the most I/O
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
       [Total IO] = (qs.total_logical_reads + qs.total_logical_writes),
       [Average IO] = (qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count,
       qs.execution_count,
       SUBSTRING (qt.text,
	             (qs.statement_start_offset/2) + 1,
       	        (
			    (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName,
       qp.query_plan
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
       CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
 ORDER BY [Total IO] DESC;

-- Listing 4.7 The queries that have been executed the most often
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
	  qs.execution_count,
       SUBSTRING (qt.text,
	             (qs.statement_start_offset/2) + 1,
                  (
			    (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName,
       qp.query_plan
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
       CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
 ORDER BY qs.execution_count DESC;

-- Listing 4.8 Finding when a query was last run
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT DISTINCT TOP 20
	  qs.last_execution_time,
	  qt.text AS [Parent Query],
	  DB_NAME(qt.dbid) AS DatabaseName
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
 WHERE qt.text LIKE '%CREATE PROCEDURE%List%PickList%'
 ORDER BY qs.last_execution_time DESC;

-- Listing 4.9 Finding when a table was last inserted
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
       qs.last_execution_time,
       CA.[Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
	  CROSS APPLY (SELECT SUBSTRING (qt.text,
                                      (qs.statement_start_offset/2) + 1,
                                      (
                                       (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2
                                      ) + 1
                                     ) AS [Individual Query]
                   ) AS CA
 WHERE CA.[Individual Query] LIKE '%INSERT INTO dbo.Underlying%'
 ORDER BY qs.last_execution_time DESC;

-- Listing 5.1 Finding queries with missing statistics
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
       st.text AS [Parent Query],
       DB_NAME(st.dbid)AS [DatabaseName],
       cp.usecounts AS [Usage Count],
       qp.query_plan
  FROM sys.dm_exec_cached_plans AS cp
       CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
       CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
 WHERE CAST(qp.query_plan AS NVARCHAR(MAX)) LIKE '%<ColumnsWithNoStatistics>%'
 ORDER BY cp.usecounts DESC;

-- Listing 5.2 Finding your default statistics options
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT name AS DatabaseName,
       is_auto_create_stats_on AS AutoCreateStatistics,
       is_auto_update_stats_on AS AutoUpdateStatistics,
       is_auto_update_stats_async_on AS AutoUpdateStatisticsAsync
  FROM sys.databases
 ORDER BY DatabaseName;

-- Listing 5.3 Finding disparate columns with different data types
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#Prevalence', 'U') IS NOT NULL DROP TABLE #Prevalence;
SELECT COLUMN_NAME,
       [%] = CONVERT(DECIMAL(12,2),COUNT(COLUMN_NAME)* 100.0 / COUNT(*) OVER())
  INTO #Prevalence
  FROM INFORMATION_SCHEMA.COLUMNS
 GROUP BY COLUMN_NAME;

SELECT DISTINCT
       C1.COLUMN_NAME,
       C1.TABLE_SCHEMA,
       C1.TABLE_NAME,
       C1.DATA_TYPE,
       C1.CHARACTER_MAXIMUM_LENGTH,
       C1.NUMERIC_PRECISION,
       C1.NUMERIC_SCALE,
       [%]
  FROM INFORMATION_SCHEMA.COLUMNS AS C1
       INNER JOIN INFORMATION_SCHEMA.COLUMNS AS C2 ON C1.COLUMN_NAME = C2.COLUMN_NAME
       INNER JOIN #Prevalence AS p ON p.COLUMN_NAME = C1.COLUMN_NAME
 WHERE ((C1.DATA_TYPE != C2.DATA_TYPE)
    OR  (C1.CHARACTER_MAXIMUM_LENGTH != C2.CHARACTER_MAXIMUM_LENGTH)
    OR  (C1.NUMERIC_PRECISION != C2.NUMERIC_PRECISION)
    OR  (C1.NUMERIC_SCALE != C2.NUMERIC_SCALE)
       )
 ORDER BY [%] DESC, C1.COLUMN_NAME, C1.TABLE_SCHEMA, C1.TABLE_NAME;

-- Listing 5.4 Finding queries that are running slower than normal
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#SlowQueries', 'U') IS NOT NULL DROP TABLE #SlowQueries;
IF OBJECT_ID('tempdb..#SlowQueriesByIO', 'U') IS NOT NULL DROP TABLE #SlowQueriesByIO;
SELECT TOP 100
       qs.execution_count AS [Runs],
       (qs.total_worker_time - qs.last_worker_time) / (qs.execution_count - 1) AS [Avg time],
       qs.last_worker_time AS [Last time],
       (qs.last_worker_time - ((qs.total_worker_time - qs.last_worker_time) / (qs.execution_count - 1))) AS [Time Deviation],
       IIF(qs.last_worker_time = 0, 100, (qs.last_worker_time - ((qs.total_worker_time - qs.last_worker_time) / (qs.execution_count - 1))) * 100)
       /(((qs.total_worker_time - qs.last_worker_time) / (qs.execution_count - 1.0))) AS [% Time Deviation],
       qs.last_logical_reads + qs.last_logical_writes + qs.last_physical_reads AS [Last IO],
       ((qs.total_logical_reads + qs.total_logical_writes + qs.total_physical_reads) - (qs.last_logical_reads + last_logical_writes + qs.last_physical_reads)) / (qs.execution_count - 1) AS [Avg IO],
       SUBSTRING (qt.text,
	             (qs.statement_start_offset/2) + 1,
                  (
			    (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS [DatabaseName]
  INTO #SlowQueries
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) AS qt
 WHERE qs.execution_count > 1
   AND qs.total_worker_time != qs.last_worker_time
 ORDER BY [% Time Deviation] DESC;

SELECT TOP 100 
       [Runs],
       [Avg time],
       [Last time],
       [Time Deviation],
       [% Time Deviation],
       [Last IO],
       [Avg IO],
       [Last IO] - [Avg IO] AS [IO Deviation],
       IIF([Avg IO] = 0, 0, ([Last IO] - [Avg IO]) * 100 / [Avg IO]) AS [% IO Deviation],
       [Individual Query],
       [Parent Query],
       [DatabaseName]
  INTO #SlowQueriesByIO
  FROM #SlowQueries
 ORDER BY [% Time Deviation] DESC;

SELECT TOP 100
       [Runs],
       [Avg time],
       [Last time],
       [Time Deviation],
       [% Time Deviation],
       [Last IO],
       [Avg IO],
       [IO Deviation],
       [% IO Deviation],
       [Impedance] = [% Time Deviation] - [% IO Deviation],
       [Individual Query],
       [Parent Query],
       [DatabaseName]
  FROM #SlowQueriesByIO
 WHERE [% Time Deviation] - [% IO Deviation] > 20
 ORDER BY [Impedance] DESC;

-- Listing 5.5 Finding unused stored procedures
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT s.name,
       s.type_desc
  FROM sys.procedures AS s
       LEFT JOIN sys.dm_exec_procedure_stats AS d ON s.object_id = d.object_id
 WHERE d.object_id IS NULL
 ORDER BY s.name;

-- Listing 5.6 Which queries run over a given time period
--ThisRoutineIdentifier99
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PreWorkSnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkSnapShot;
IF OBJECT_ID('tempdb..#PostWorkSnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkSnapShot;
SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PreWorkSnapShot
  FROM sys.dm_exec_query_stats;

WAITFOR DELAY '00:05:00';

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PostWorkSnapShot
  FROM sys.dm_exec_query_stats;

SELECT p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0) AS [Duration],
       p2.total_worker_time - ISNULL(p1.total_worker_time, 0) AS [Time on CPU],
       (p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) - (p2.total_worker_time - ISNULL(p1.total_worker_time, 0)) AS [Time blocked],
       p2.total_logical_reads - ISNULL(p1.total_logical_reads, 0) AS [Reads],
       p2.total_logical_writes - ISNULL(p1.total_logical_writes, 0) AS [Writes],
       p2.total_clr_time - ISNULL(p1.total_clr_time, 0) AS [CLR time],
       p2.execution_count - ISNULL(p1.execution_count, 0) AS [Executions],
       SUBSTRING (qt.text,
	             (p2.statement_start_offset/2 + 1),
		        (
			    (CASE WHEN p2.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE p2.statement_end_offset END - p2.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName,
       qp.query_plan
  FROM #PreWorkSnapShot AS p1
       RIGHT JOIN #PostWorkSnapShot AS p2 ON p2.sql_handle = ISNULL(p1.sql_handle, p2.sql_handle)
              AND p2.plan_handle = ISNULL(p1.plan_handle, p2.plan_handle)
              AND p2.statement_start_offset = ISNULL(p1.statement_start_offset, p2.statement_start_offset)
              AND p2.statement_end_offset = ISNULL(p1.statement_end_offset, p2.statement_end_offset)
       CROSS APPLY sys.dm_exec_sql_text(p2.sql_handle) AS qt
       CROSS APPLY sys.dm_exec_query_plan(p2.plan_handle) AS qp
 WHERE p2.execution_count != ISNULL(p1.execution_count, 0)
   AND qt.text NOT LIKE '--ThisRoutineIdentifier99%'
 ORDER BY [Duration] DESC;

-- Listing 5.7 Amalgamated DMV snapshots
--ThisRoutineIdentifier
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PreWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkQuerySnapShot;
IF OBJECT_ID('tempdb..#PostWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkQuerySnapShot;
IF OBJECT_ID('tempdb..#PostWorkWaitStats', 'U') IS NOT NULL DROP TABLE #PostWorkWaitStats;
IF OBJECT_ID('tempdb..#PreWorkWaitStats', 'U') IS NOT NULL DROP TABLE #PreWorkWaitStats;
IF OBJECT_ID('tempdb..#PreWorkOSSnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkOSSnapShot;
IF OBJECT_ID('tempdb..#PostWorkOSSnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkOSSnapShot;
IF OBJECT_ID('tempdb..#PreWorkMissingIndexes', 'U') IS NOT NULL DROP TABLE #PreWorkMissingIndexes;
IF OBJECT_ID('tempdb..#PostWorkMissingIndexes', 'U') IS NOT NULL DROP TABLE #PostWorkMissingIndexes;
SELECT index_group_handle,
       index_handle,
	  avg_total_user_cost,
	  avg_user_impact,
	  user_seeks,
	  user_scans
  INTO #PreWorkMissingIndexes
  FROM sys.dm_db_missing_index_groups AS g
       INNER JOIN sys.dm_db_missing_index_group_stats AS s ON s.group_handle = g.index_group_handle;

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PreWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

SELECT [object_name],
       [counter_name],
       [instance_name],
	  [cntr_value],
       [cntr_type]
  INTO #PreWorkOSSnapShot
  FROM sys.dm_os_performance_counters;

SELECT wait_type,
       waiting_tasks_count,
	  wait_time_ms,
       max_wait_time_ms,
       signal_wait_time_ms
  INTO #PreWorkWaitStats
  FROM sys.dm_os_wait_stats;

WAITFOR DELAY '00:05:00';

SELECT wait_type,
       waiting_tasks_count,
       wait_time_ms,
	  max_wait_time_ms,
       signal_wait_time_ms
  INTO #PostWorkWaitStats
  FROM sys.dm_os_wait_stats;

SELECT [object_name],
       [counter_name],
       [instance_name],
       [cntr_value],
       [cntr_type]
  INTO #PostWorkOSSnapShot
  FROM sys.dm_os_performance_counters;

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PostWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

SELECT index_group_handle,
       index_handle,
       avg_total_user_cost,
       avg_user_impact,
       user_seeks,
       user_scans
  INTO #PostWorkMissingIndexes
  FROM sys.dm_db_missing_index_groups AS g
       INNER JOIN sys.dm_db_missing_index_group_stats AS s ON s.group_handle = g.index_group_handle;

SELECT p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0) AS [Duration],
	  p2.total_worker_time - ISNULL(p1.total_worker_time, 0) AS [Time on CPU],
	  (p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) - (p2.total_worker_time - ISNULL(p1.total_worker_time, 0))	AS [Time blocked],
	  p2.total_logical_reads - ISNULL(p1.total_logical_reads, 0) AS [Reads],
	  p2.total_logical_writes - ISNULL(p1.total_logical_writes, 0) AS [Writes],
	  p2.total_clr_time - ISNULL(p1.total_clr_time, 0) AS [CLR time],
	  p2.execution_count - ISNULL(p1.execution_count, 0) AS [Executions],
	  SUBSTRING (qt.text,
	             (p2.statement_start_offset/2 + 1),
	             (
			    (CASE WHEN p2.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE p2.statement_end_offset END - p2.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
	  qt.text AS [Parent Query],
	  DB_NAME(qt.dbid) AS DatabaseName
  FROM #PreWorkQuerySnapShot AS p1
       RIGHT JOIN #PostWorkQuerySnapShot AS p2 ON p2.sql_handle = ISNULL(p1.sql_handle, p2.sql_handle)
              AND p2.plan_handle = ISNULL(p1.plan_handle, p2.plan_handle)
              AND p2.statement_start_offset = ISNULL(p1.statement_start_offset, p2.statement_start_offset)
              AND p2.statement_end_offset = ISNULL(p1.statement_end_offset, p2.statement_end_offset)
       CROSS APPLY sys.dm_exec_sql_text(p2.sql_handle) AS qt
 WHERE p2.execution_count != ISNULL(p1.execution_count, 0)
   AND qt.text NOT LIKE '--ThisRoutineIdentifier%'
 ORDER BY [Duration] DESC;

SELECT p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0) AS wait_time_ms,
	  p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms, 0) AS signal_wait_time_ms,
	  ((p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0)) - (p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms, 0))) AS RealWait,
	  p2.wait_type
  FROM #PreWorkWaitStats AS p1
       RIGHT JOIN #PostWorkWaitStats AS p2 ON p2.wait_type = ISNULL(p1.wait_type, p2.wait_type)
 WHERE p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0) > 0
   AND p2.wait_type NOT LIKE '%SLEEP%'
   AND p2.wait_type != 'WAITFOR'
 ORDER BY RealWait DESC;

SELECT ROUND(
             (p2.avg_total_user_cost - ISNULL(p1.avg_total_user_cost, 0))
	        * (p2.avg_user_impact - ISNULL(p1.avg_user_impact, 0))
	        * ((p2.user_seeks - ISNULL(p1.user_seeks, 0)) + (p2.user_scans - ISNULL(p1.user_scans, 0))), 0
		  ) AS [Total Cost],
	  p2.avg_total_user_cost - ISNULL(p1.avg_total_user_cost, 0) AS avg_total_user_cost,
	  p2.avg_user_impact - ISNULL(p1.avg_user_impact, 0) AS avg_user_impact,
	  p2.user_seeks - ISNULL(p1.user_seeks, 0) AS user_seeks,
	  p2.user_scans - ISNULL(p1.user_scans, 0) AS user_scans,
	  d.statement AS TableName,
	  d.equality_columns,
	  d.inequality_columns,
	  d.included_columns
  FROM #PreWorkMissingIndexes AS p1
       RIGHT JOIN #PostWorkMissingIndexes AS p2 ON p2.index_group_handle = ISNULL(p1.index_group_handle, p2.index_group_handle)
              AND p2.index_handle = ISNULL(p1.index_handle, p2.index_handle)
       INNER JOIN sys.dm_db_missing_index_details AS d ON p2.index_handle = d.index_handle
 WHERE p2.avg_total_user_cost - ISNULL(p1.avg_total_user_cost, 0) > 0
    OR p2.avg_user_impact - ISNULL(p1.avg_user_impact, 0) > 0
    OR p2.user_seeks - ISNULL(p1.user_seeks, 0) > 0
    OR p2.user_scans - ISNULL(p1.user_scans, 0) > 0
 ORDER BY [Total Cost] DESC;

SELECT p2.object_name,
       p2.counter_name,
       p2.instance_name,
       ISNULL(p1.cntr_value, 0) AS InitialValue,
       p2.cntr_value AS FinalValue,
       p2.cntr_value - ISNULL(p1.cntr_value, 0) AS Change,
       (p2.cntr_value - ISNULL(p1.cntr_value, 0)) * 100 / p1.cntr_value AS [% Change]
  FROM #PreWorkOSSnapShot AS p1
       RIGHT JOIN #PostWorkOSSnapShot AS p2 ON p2.object_name = ISNULL(p1.object_name, p2.object_name)
              AND p2.counter_name = ISNULL(p1.counter_name, p2.counter_name)
              AND p2.instance_name = ISNULL(p1.instance_name, p2.instance_name)
 WHERE p2.cntr_value - ISNULL(p1.cntr_value, 0) > 0
   AND ISNULL(p1.cntr_value, 0) != 0
 ORDER BY [% Change] DESC, Change DESC;

-- Listing 5.8 What queries are running now
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT es.session_id,
       es.host_name,
       es.login_name,
       er.status,
       DB_NAME(DB_ID()) AS DatabaseName,
       SUBSTRING (qt.text,
	             (er.statement_start_offset/2) + 1,
                  (
			    (CASE WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE er.statement_end_offset END - er.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       es.program_name,
       er.start_time,
       qp.query_plan,
       er.wait_type,
       er.total_elapsed_time,
       er.cpu_time,
       er.logical_reads,
       er.blocking_session_id,
       er.open_transaction_count,
       er.last_wait_type,
       er.percent_complete
  FROM sys.dm_exec_requests AS er
       INNER JOIN sys.dm_exec_sessions AS es ON es.session_id = er.session_id
       CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
       CROSS APPLY sys.dm_exec_query_plan(er.plan_handle) AS qp
 WHERE es.is_user_process = 1
   AND es.session_Id NOT IN (@@SPID)
 ORDER BY es.session_id;

-- Listing 5.9 Determining your most-recompiled queries
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
       qs.plan_generation_num,
       qs.total_elapsed_time,
       qs.execution_count,
       SUBSTRING (qt.text,
	             (qs.statement_start_offset/2) + 1,
	             (
			    (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE qs.statement_end_offset
	END - qs.statement_start_offset)/2) + 1) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid),
       qs.creation_time,
       qs.last_execution_time
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
 ORDER BY plan_generation_num DESC;

-- Listing 6.1 Why are you waiting?
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
	  wait_type, wait_time_ms,
	  signal_wait_time_ms,
	  wait_time_ms - signal_wait_time_ms AS RealWait,
	  CONVERT(DECIMAL(12,2), wait_time_ms * 100.0 / SUM(wait_time_ms) OVER()) AS [% Waiting],
	  CONVERT(DECIMAL(12,2), (wait_time_ms - signal_wait_time_ms) * 100.0 / SUM(wait_time_ms) OVER()) AS [% RealWait]
  FROM sys.dm_os_wait_stats
 WHERE wait_type NOT LIKE '%SLEEP%'
   AND wait_type != 'WAITFOR'
 ORDER BY wait_time_ms DESC;

-- Listing 6.2 Why are you waiting? (snapshot version)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PreWorkWaitStats', 'U') IS NOT NULL DROP TABLE #PreWorkWaitStats;
IF OBJECT_ID('tempdb..#PostWorkWaitStats', 'U') IS NOT NULL DROP TABLE #PostWorkWaitStats;
SELECT wait_type,
       waiting_tasks_count,
	  wait_time_ms,
	  max_wait_time_ms,
	  signal_wait_time_ms
  INTO #PreWorkWaitStats
  FROM sys.dm_os_wait_stats;

WAITFOR DELAY '00:10:00';

SELECT wait_type,
       waiting_tasks_count,
	  wait_time_ms,
	  max_wait_time_ms,
	  signal_wait_time_ms
  INTO #PostWorkWaitStats
  FROM sys.dm_os_wait_stats;

SELECT p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0) AS wait_time_ms,
       p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms, 0) AS signal_wait_time_ms,
       ((p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0)) - (p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms, 0))) AS RealWait,
       p2.wait_type
  FROM #PreWorkWaitStats AS p1
       RIGHT JOIN #PostWorkWaitStats AS p2 ON p2.wait_type = ISNULL(p1.wait_type, p2.wait_type)
 WHERE p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0) > 0
   AND p2.wait_type NOT LIKE '%SLEEP%'
   AND p2.wait_type != 'WAITFOR'
 ORDER BY RealWait DESC;

-- Listing 6.3 Why your queries are waiting
--ThisRoutineIdentifier
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PreWorkWaitStats', 'U') IS NOT NULL DROP TABLE #PreWorkWaitStats;
IF OBJECT_ID('tempdb..#PostWorkWaitStats', 'U') IS NOT NULL DROP TABLE #PostWorkWaitStats;
IF OBJECT_ID('tempdb..#PreWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkQuerySnapShot;
IF OBJECT_ID('tempdb..#PostWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkQuerySnapShot;
SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PreWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

SELECT wait_type,
       waiting_tasks_count,
	  wait_time_ms,
	  max_wait_time_ms,
	  signal_wait_time_ms
  INTO #PreWorkWaitStats
  FROM sys.dm_os_wait_stats;

WAITFOR DELAY '00:05:00';

SELECT wait_type,
       waiting_tasks_count,
	  wait_time_ms,
	  max_wait_time_ms,
	  signal_wait_time_ms
  INTO #PostWorkWaitStats
  FROM sys.dm_os_wait_stats;

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PostWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

SELECT p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0) AS wait_time_ms,
	  p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms, 0) AS signal_wait_time_ms,
	  ((p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0)) - (p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms, 0))) AS RealWait,
	  p2.wait_type
  FROM #PreWorkWaitStats AS p1
       RIGHT JOIN #PostWorkWaitStats AS p2 ON p2.wait_type = ISNULL(p1.wait_type, p2.wait_type)
 WHERE p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0) > 0
   AND p2.wait_type NOT LIKE '%SLEEP%'
   AND p2.wait_type != 'WAITFOR'
 ORDER BY RealWait DESC;

SELECT p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0) AS [Duration],
	  p2.total_worker_time - ISNULL(p1.total_worker_time, 0) AS [Time on CPU],
	  (p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) - (p2.total_worker_time - ISNULL(p1.total_worker_time, 0))	AS [Time blocked],
	  p2.total_logical_reads - ISNULL(p1.total_logical_reads, 0) AS [Reads],
	  p2.total_logical_writes - ISNULL(p1.total_logical_writes, 0)	AS [Writes],
	  p2.total_clr_time - ISNULL(p1.total_clr_time, 0) AS [CLR time],
	  p2.execution_count - ISNULL(p1.execution_count, 0) AS [Executions],
	  SUBSTRING (qt.text,
	             (p2.statement_start_offset/2 + 1),
	             (
			    (CASE WHEN p2.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE p2.statement_end_offset END - p2.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
	  qt.text AS [Parent Query],
	  DB_NAME(qt.dbid) AS DatabaseName
  FROM #PreWorkQuerySnapShot AS p1
       RIGHT JOIN #PostWorkQuerySnapShot AS p2 ON p2.sql_handle = ISNULL(p1.sql_handle, p2.sql_handle)
              AND p2.plan_handle = ISNULL(p1.plan_handle, p2.plan_handle)
              AND p2.statement_start_offset = ISNULL(p1.statement_start_offset, p2.statement_start_offset)
              AND p2.statement_end_offset = ISNULL(p1.statement_end_offset, p2.statement_end_offset)
       CROSS APPLY sys.dm_exec_sql_text(p2.sql_handle) AS qt
 WHERE p2.execution_count != ISNULL(p1.execution_count, 0)
   AND qt.text NOT LIKE '--ThisRoutineIdentifier%'
 ORDER BY [Time blocked] DESC;

-- Listing 6.4 What is blocked?
SET NOCOUNT ON;

SELECT Blocking.session_id AS BlockingSessionId,
       Sess.login_name AS BlockingUser,
       BlockingSQL.text AS BlockingSQL,
       Waits.wait_type WhyBlocked,
       Blocked.session_id AS BlockedSessionId,
       USER_NAME(Blocked.user_id) AS BlockedUser,
       BlockedSQL.text AS BlockedSQL,
       DB_NAME(Blocked.database_id) AS DatabaseName
  FROM sys.dm_exec_connections AS Blocking
       INNER JOIN sys.dm_exec_requests AS Blocked ON Blocking.session_id = Blocked.blocking_session_id
       INNER JOIN sys.dm_os_waiting_tasks AS Waits ON Blocked.session_id = Waits.session_id
       RIGHT JOIN sys.dm_exec_sessions AS Sess ON Blocking.session_id = sess.session_id
       CROSS APPLY sys.dm_exec_sql_text(Blocking.most_recent_sql_handle) AS BlockingSQL
       CROSS APPLY sys.dm_exec_sql_text(Blocked.sql_handle) AS BlockedSQL
 ORDER BY BlockingSessionId, BlockedSessionId;

-- Listing 6.5 Effect of queries on performance counters
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PreWorkOSSnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkOSSnapShot;
IF OBJECT_ID('tempdb..#PostWorkOSSnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkOSSnapShot;
SELECT [object_name],
       [counter_name],
       [instance_name],
	  [cntr_value],
       [cntr_type]
  INTO #PreWorkOSSnapShot
  FROM sys.dm_os_performance_counters;

WAITFOR DELAY '00:05:00';

SELECT [object_name],
       [counter_name],
       [instance_name],
	  [cntr_value],
       [cntr_type]
  INTO #PostWorkOSSnapShot
  FROM sys.dm_os_performance_counters;

SELECT p2.object_name,
       p2.counter_name,
	  p2.instance_name,
	  ISNULL(p1.cntr_value, 0) AS InitialValue,
	  p2.cntr_value AS FinalValue,
	  p2.cntr_value - ISNULL(p1.cntr_value, 0) AS Change,
	  (p2.cntr_value - ISNULL(p1.cntr_value, 0)) * 100 / p1.cntr_value AS [% Change]
  FROM #PreWorkOSSnapShot AS p1
       RIGHT JOIN #PostWorkOSSnapShot AS p2 ON p2.object_name = ISNULL(p1.object_name, p2.object_name)
              AND p2.counter_name = ISNULL(p1.counter_name, p2.counter_name)
              AND p2.instance_name = ISNULL(p1.instance_name, p2.instance_name)
 WHERE p2.cntr_value - ISNULL(p1.cntr_value, 0) > 0
   AND ISNULL(p1.cntr_value, 0) != 0
 ORDER BY [% Change] DESC, Change DESC;

-- Listing 6.6 Changes in performance counters and wait states
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PreWorkWaitStats', 'U') IS NOT NULL DROP TABLE #PreWorkWaitStats;
IF OBJECT_ID('tempdb..#PostWorkWaitStats', 'U') IS NOT NULL DROP TABLE #PostWorkWaitStats;
IF OBJECT_ID('tempdb..#PreWorkOSSnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkOSSnapShot;
IF OBJECT_ID('tempdb..#PostWorkOSSnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkOSSnapShot;

SELECT [object_name],
       [counter_name],
       [instance_name],
	  [cntr_value],
	  [cntr_type]
  INTO #PreWorkOSSnapShot
  FROM sys.dm_os_performance_counters;

SELECT wait_type,
       waiting_tasks_count,
	  wait_time_ms,
	  max_wait_time_ms,
	  signal_wait_time_ms
  INTO #PreWorkWaitStats
  FROM sys.dm_os_wait_stats;

WAITFOR DELAY '00:05:00';

SELECT wait_type,
       waiting_tasks_count,
	  wait_time_ms,
	  max_wait_time_ms,
	  signal_wait_time_ms
  INTO #PostWorkWaitStats
  FROM sys.dm_os_wait_stats;

SELECT [object_name],
       [counter_name],
	  [instance_name],
	  [cntr_value],
	  [cntr_type]
  INTO #PostWorkOSSnapShot
  FROM sys.dm_os_performance_counters;

SELECT p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0) AS wait_time_ms,
       p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms, 0) AS signal_wait_time_ms,
       ((p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0)) - (p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms, 0))) AS RealWait,
       p2.wait_type
  FROM #PreWorkWaitStats AS p1
       RIGHT JOIN #PostWorkWaitStats AS p2 ON p2.wait_type = ISNULL(p1.wait_type, p2.wait_type)
 WHERE p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0) > 0
   AND p2.wait_type NOT LIKE '%SLEEP%'
   AND p2.wait_type != 'WAITFOR'
 ORDER BY RealWait DESC;

SELECT p2.object_name,
       p2.counter_name,
       p2.instance_name,
	  ISNULL(p1.cntr_value, 0) AS InitialValue,
	  p2.cntr_value AS FinalValue,
	  p2.cntr_value - ISNULL(p1.cntr_value, 0) AS Change,
	  (p2.cntr_value - ISNULL(p1.cntr_value, 0)) * 100 / p1.cntr_value AS [% Change]
  FROM #PreWorkOSSnapShot AS p1
       RIGHT JOIN #PostWorkOSSnapShot AS p2 ON p2.object_name = ISNULL(p1.object_name, p2.object_name)
              AND p2.counter_name = ISNULL(p1.counter_name, p2.counter_name)
              AND p2.instance_name = ISNULL(p1.instance_name, p2.instance_name)
 WHERE p2.cntr_value - ISNULL(p1.cntr_value, 0) > 0
   AND ISNULL(p1.cntr_value, 0) != 0
 ORDER BY [% Change] DESC, Change DESC;

-- Listing 6.7 Queries that change performance counters and wait states
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PreWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkQuerySnapShot;
IF OBJECT_ID('tempdb..#PostWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkQuerySnapShot;
IF OBJECT_ID('tempdb..#PostWorkWaitStats', 'U') IS NOT NULL DROP TABLE #PostWorkWaitStats;
IF OBJECT_ID('tempdb..#PreWorkWaitStats', 'U') IS NOT NULL DROP TABLE #PreWorkWaitStats;
IF OBJECT_ID('tempdb..#PreWorkOSSnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkOSSnapShot;
IF OBJECT_ID('tempdb..#PostWorkOSSnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkOSSnapShot;

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PreWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

SELECT [object_name],
       [counter_name],
       [instance_name],
       [cntr_value],
       [cntr_type]
  INTO #PreWorkOSSnapShot
  FROM sys.dm_os_performance_counters;

SELECT wait_type,
       waiting_tasks_count,
       wait_time_ms,
       max_wait_time_ms,
       signal_wait_time_ms
  INTO #PreWorkWaitStats
  FROM sys.dm_os_wait_stats;

WAITFOR DELAY '00:05:00';

SELECT wait_type,
       waiting_tasks_count,
       wait_time_ms,
       max_wait_time_ms,
       signal_wait_time_ms
  INTO #PostWorkWaitStats
  FROM sys.dm_os_wait_stats;

SELECT [object_name],
       [counter_name],
       [instance_name],
       [cntr_value],
       [cntr_type]
  INTO #PostWorkOSSnapShot
  FROM sys.dm_os_performance_counters;

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PostWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

SELECT p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0) AS [Duration],
	  p2.total_worker_time - ISNULL(p1.total_worker_time, 0) AS [Time on CPU],
	  (p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) - (p2.total_worker_time - ISNULL(p1.total_worker_time, 0)) AS [Time blocked],
	  p2.total_logical_reads - ISNULL(p1.total_logical_reads, 0) AS [Reads],
	  p2.total_logical_writes - ISNULL(p1.total_logical_writes, 0) AS [Writes],
	  p2.total_clr_time - ISNULL(p1.total_clr_time, 0) AS [CLR time],
	  p2.execution_count - ISNULL(p1.execution_count, 0) AS [Executions],
	  SUBSTRING (qt.text,
	             p2.statement_start_offset/2 + 1,
	             (
			    (CASE WHEN p2.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE p2.statement_end_offset END - p2.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
	  qt.text AS [Parent Query],
	  DB_NAME(qt.dbid) AS DatabaseName
  FROM #PreWorkQuerySnapShot AS p1
       RIGHT JOIN #PostWorkQuerySnapShot AS p2 ON p2.sql_handle = ISNULL(p1.sql_handle, p2.sql_handle)
              AND p2.plan_handle = ISNULL(p1.plan_handle, p2.plan_handle)
              AND p2.statement_start_offset =ISNULL(p1.statement_start_offset, p2.statement_start_offset)
              AND p2.statement_end_offset =ISNULL(p1.statement_end_offset, p2.statement_end_offset)
       CROSS APPLY sys.dm_exec_sql_text(p2.sql_handle) AS qt
 WHERE p2.execution_count != ISNULL(p1.execution_count, 0)
   AND qt.text NOT LIKE '--ThisRoutineIdentifier%'
 ORDER BY [Duration] DESC;

SELECT p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0) AS wait_time_ms,
	  p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms, 0) AS signal_wait_time_ms,
	  ((p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0)) - (p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms, 0))) AS RealWait,
	  p2.wait_type
  FROM #PreWorkWaitStats AS p1
       RIGHT JOIN #PostWorkWaitStats AS p2 ON p2.wait_type = ISNULL(p1.wait_type, p2.wait_type)
 WHERE p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0) > 0
   AND p2.wait_type NOT LIKE '%SLEEP%'
   AND p2.wait_type != 'WAITFOR'
 ORDER BY RealWait DESC;

SELECT p2.object_name,
       p2.counter_name,
	  p2.instance_name,
	  ISNULL(p1.cntr_value, 0) AS InitialValue,
	  p2.cntr_value AS FinalValue,
	  p2.cntr_value - ISNULL(p1.cntr_value, 0) AS Change,
	  (p2.cntr_value - ISNULL(p1.cntr_value, 0)) * 100 / p1.cntr_value AS [% Change]
  FROM #PreWorkOSSnapShot AS p1
       RIGHT JOIN #PostWorkOSSnapShot AS p2 ON p2.object_name = ISNULL(p1.object_name, p2.object_name)
	         AND p2.counter_name = ISNULL(p1.counter_name, p2.counter_name)
	         AND p2.instance_name = ISNULL(p1.instance_name, p2.instance_name)
 WHERE p2.cntr_value - ISNULL(p1.cntr_value, 0) > 0
   AND ISNULL(p1.cntr_value, 0) != 0
 ORDER BY [% Change] DESC, Change DESC;

-- Listing 6.8 Recording DMV snapshots periodically
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PerfCounters', 'U') IS NOT NULL DROP TABLE #PerfCounters;
CREATE TABLE #PerfCounters
(	
 RunDateTime DATETIME NOT NULL,
 object_name NCHAR(128) NOT NULL,
 counter_name NCHAR(128) NOT NULL,
 instance_name NCHAR(128) NULL,
 cntr_value BIGINT NOT NULL,
 cntr_type INT NOT NULL
);

ALTER TABLE #PerfCounters
ADD CONSTRAINT DF_PerFCounters_RunDateTime DEFAULT (GETDATE()) FOR RunDateTime;
GO

INSERT INTO #PerfCounters
(object_name, counter_name, instance_name, cntr_value, cntr_type)
SELECT object_name,
       counter_name,
       instance_name,
       cntr_value,
       cntr_type
  FROM sys.dm_os_performance_counters;

WAITFOR DELAY '00:00:01';
GO 20

SELECT *
  FROM #PerfCounters
 ORDER BY RunDateTime, object_name, counter_name, instance_name;

--Listing 7.1 C# code to create regex functionality for use within SQL Server
/*
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;
using System.Text.RegularExpressions;
namespace CLRRegEx
{
    public partial class CLRRegEx
    {
        private const string sDigitsOnly = @"^\d+$";
        private const string sEmailRegEx =  @"^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$";
        private const string sWebAddressRegEx =  @"^http(s)?://([\w-*]+\.)+[\w-*]+(/[\w- ./?%&=*]*)?$";
        [SqlFunction(IsDeterministic = true, DataAccess = DataAccessKind.None)]
        public static SqlBoolean RegExEmailIsValid(SqlString sSource)
        {
            if (sSource.IsNull)
                return SqlBoolean.Null;
            else
                return (SqlBoolean)Regex.IsMatch(sSource.Value, sEmailRegEx
                , RegexOptions.IgnoreCase);
        }
        [SqlFunction(IsDeterministic = true, DataAccess = DataAccessKind.None)]
        public static SqlBoolean RegExDigitsOnly(SqlString sSource)
        {
            if (sSource.IsNull)
                return SqlBoolean.Null;
            else
                return (SqlBoolean)Regex.IsMatch(sSource.Value, sDigitsOnly
                , RegexOptions.CultureInvariant);
        }
        [SqlFunction(IsDeterministic = true, DataAccess = DataAccessKind.None)]
        public static SqlBoolean WebAddressIsValid(SqlString sSource)
        {
            if (sSource.IsNull)
                return SqlBoolean.Null;
            else
                return (SqlBoolean)Regex.IsMatch(sSource.Value, sWebAddressRegEx
                , RegexOptions.IgnoreCase);
        }
        [SqlFunction(IsDeterministic = true, DataAccess = DataAccessKind.None)]
        public static SqlString RegExReplace(SqlString sSource, SqlString sPattern
        , SqlString sReplacement)
        {
            if (sSource.IsNull || sPattern.IsNull || sReplacement.IsNull)
                return SqlString.Null;
            else
                return (SqlString)Regex.Replace(sSource.Value, sPattern.Value
                , sReplacement.Value);
        }
        [SqlFunction(IsDeterministic = true, DataAccess = DataAccessKind.None)]
        public static SqlBoolean RegExMatch(SqlString sSource, SqlString sRegEx)
        {
            if (sSource.IsNull || sRegEx.IsNull)
                return SqlBoolean.Null;
            else
                return (SqlBoolean)Regex.IsMatch(sSource.Value, sRegEx.Value
                , RegexOptions.CultureInvariant);
        }
    };
}
--*/

-- Listing 7.2 Enabling CLR integration within SQL Server
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE

EXEC sp_configure 'clr_enabled', 1;
RECONFIGURE

-- Listing 7.3 Using the CLR regular expression functionality
/*
SELECT dbo.RegExDigitsOnly('123456');
SELECT dbo.RegExDigitsOnly('123456789abc');

SELECT dbo.RegExEmailIsValid('ian_stirk@yahoo.com');
SELECT dbo.RegExEmailIsValid('ian_stirk@yahoo');

SELECT dbo.WebAddressIsValid('http://www.manning.com/stirk');
SELECT dbo.WebAddressIsValid('http://wwwmanningcom');


SELECT dbo.RegExReplace('Q123AS456WE789', '[^0-9]', 'a');

SELECT dbo.RegExMatch('123456789', '^[0-9]+$');

SELECT dbo.RegExMatch('12345678abc9', '^[0-9]+$');
--*/

-- Listing 7.4 The queries that spend the most time in the CLR
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
       qs.total_clr_time,
       qs.total_elapsed_time AS [Duration],
       qs.total_worker_time AS [Time on CPU],
       qs.total_elapsed_time - qs.total_worker_time AS [Time waiting],
       qs.total_logical_reads,
       qs.total_logical_writes,
       qs.execution_count,
       SUBSTRING (qt.text,
	             qs.statement_start_offset/2 + 1,
                  (
			    (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS qt
 WHERE qs.total_clr_time > 0
 ORDER BY qs.total_clr_time DESC;

-- Listing 7.5 The queries that spend the most time in the CLR (snapshot version)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PreWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkQuerySnapShot;
IF OBJECT_ID('tempdb..#PostWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkQuerySnapShot;

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PreWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

WAITFOR DELAY '00:10:00';

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PostWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

SELECT p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0) AS [Duration],
	  p2.total_worker_time - ISNULL(p1.total_worker_time, 0) AS [Time on CPU],
	  (p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) - (p2.total_worker_time - ISNULL(p1.total_worker_time, 0)) AS [Time blocked],
	  p2.total_logical_reads - ISNULL(p1.total_logical_reads, 0) AS [Reads],
	  p2.total_logical_writes - ISNULL(p1.total_logical_writes, 0) AS [Writes],
	  p2.total_clr_time - ISNULL(p1.total_clr_time, 0) AS [CLR time],
	  p2.execution_count - ISNULL(p1.execution_count, 0) AS [Executions],
	  SUBSTRING (qt.text,
	             p2.statement_start_offset/2 + 1,
	             (
			    (CASE WHEN p2.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE p2.statement_end_offset END - p2.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
	  qt.text AS [Parent Query],
	  DB_NAME(qt.dbid) AS DatabaseName
  FROM #PreWorkQuerySnapShot AS p1
       RIGHT JOIN #PostWorkQuerySnapShot AS p2 ON p2.sql_handle =ISNULL(p1.sql_handle, p2.sql_handle)
              AND p2.plan_handle = ISNULL(p1.plan_handle, p2.plan_handle)
              AND p2.statement_start_offset = ISNULL(p1.statement_start_offset, p2.statement_start_offset)
              AND p2.statement_end_offset = ISNULL(p1.statement_end_offset, p2.statement_end_offset)
       CROSS APPLY sys.dm_exec_sql_text(p2.sql_handle) AS qt
 WHERE p2.execution_count != ISNULL(p1.execution_count, 0)
   AND p2.total_clr_time - ISNULL(p1.total_clr_time, 0) <> 0
 ORDER BY [CLR time] DESC;

-- Listing 7.6 Relationships between DMVs and CLR queries
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PreWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkQuerySnapShot;
IF OBJECT_ID('tempdb..#PostWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkQuerySnapShot;
IF OBJECT_ID('tempdb..#PostWorkWaitStats', 'U') IS NOT NULL DROP TABLE #PostWorkWaitStats;
IF OBJECT_ID('tempdb..#PreWorkWaitStats', 'U') IS NOT NULL DROP TABLE #PreWorkWaitStats;
IF OBJECT_ID('tempdb..#PreWorkOSSnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkOSSnapShot;
IF OBJECT_ID('tempdb..#PostWorkOSSnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkOSSnapShot;
IF OBJECT_ID('tempdb..#PreWorkMissingIndexes', 'U') IS NOT NULL DROP TABLE #PreWorkMissingIndexes;
IF OBJECT_ID('tempdb..#PostWorkMissingIndexes', 'U') IS NOT NULL DROP TABLE #PostWorkMissingIndexes;

SELECT g.index_group_handle,
       g.index_handle,
       s.avg_total_user_cost,
       s.avg_user_impact,
       s.user_seeks,
       s.user_scans
  INTO #PreWorkMissingIndexes
  FROM sys.dm_db_missing_index_groups AS g
       INNER JOIN sys.dm_db_missing_index_group_stats AS s ON s.group_handle = g.index_group_handle;

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PreWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

SELECT [object_name],
       [counter_name],
       [instance_name],
       [cntr_value],
       [cntr_type]
  INTO #PreWorkOSSnapShot
  FROM sys.dm_os_performance_counters;

SELECT wait_type,
       waiting_tasks_count,
       wait_time_ms,
       max_wait_time_ms,
       signal_wait_time_ms
  INTO #PreWorkWaitStats
  FROM sys.dm_os_wait_stats;

WAITFOR DELAY '00:10:00';

SELECT wait_type,
       waiting_tasks_count,
       wait_time_ms,
       max_wait_time_ms,
       signal_wait_time_ms
  INTO #PostWorkWaitStats
  FROM sys.dm_os_wait_stats;

SELECT [object_name],
       [counter_name],
       [instance_name],
       [cntr_value],
       [cntr_type]
  INTO #PostWorkOSSnapShot
  FROM sys.dm_os_performance_counters;

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PostWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

SELECT g.index_group_handle,
       g.index_handle,
       s.avg_total_user_cost,
       s.avg_user_impact,
       s.user_seeks,
       s.user_scans
  INTO #PostWorkMissingIndexes
  FROM sys.dm_db_missing_index_groups AS g
       INNER JOIN sys.dm_db_missing_index_group_stats AS s ON s.group_handle = g.index_group_handle;

SELECT p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0) AS [Duration],
	  p2.total_worker_time - ISNULL(p1.total_worker_time, 0) AS [Time on CPU],
	  (p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) - (p2.total_worker_time - ISNULL(p1.total_worker_time, 0)) AS [Time blocked],
	  p2.total_logical_reads - ISNULL(p1.total_logical_reads, 0) AS [Reads],
	  p2.total_logical_writes - ISNULL(p1.total_logical_writes, 0) AS [Writes],
	  p2.total_clr_time - ISNULL(p1.total_clr_time, 0) AS [CLR time],
	  p2.execution_count - ISNULL(p1.execution_count, 0) AS [Executions],
	  SUBSTRING (qt.text,
	             p2.statement_start_offset/2 + 1,
	             (
			    (CASE WHEN p2.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE p2.statement_end_offset END - p2.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
	  qt.text AS [Parent Query],
	  DB_NAME(qt.dbid) AS DatabaseName
  FROM #PreWorkQuerySnapShot AS p1
       RIGHT JOIN #PostWorkQuerySnapShot AS p2 ON p2.sql_handle = ISNULL(p1.sql_handle, p2.sql_handle)
              AND p2.plan_handle = ISNULL(p1.plan_handle, p2.plan_handle)
              AND p2.statement_start_offset = ISNULL(p1.statement_start_offset, p2.statement_start_offset)
              AND p2.statement_end_offset = ISNULL(p1.statement_end_offset, p2.statement_end_offset)
       CROSS APPLY sys.dm_exec_sql_text(p2.sql_handle) AS qt
 WHERE p2.execution_count != ISNULL(p1.execution_count, 0)
   AND p2.total_clr_time - ISNULL(p1.total_clr_time, 0) <>0
 ORDER BY [CLR time] DESC;

SELECT p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0) AS wait_time_ms,
	  p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms, 0) AS signal_wait_time_ms,
	  ((p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0)) - (p2.signal_wait_time_ms - ISNULL(p1.signal_wait_time_ms, 0))) AS RealWait,
	  p2.wait_type
  FROM #PreWorkWaitStats AS p1
       RIGHT JOIN #PostWorkWaitStats AS p2 ON p2.wait_type = ISNULL(p1.wait_type, p2.wait_type)
 WHERE p2.wait_time_ms - ISNULL(p1.wait_time_ms, 0) > 0
   AND p2.wait_type NOT LIKE '%SLEEP%'
   AND p2.wait_type != 'WAITFOR'
 ORDER BY RealWait DESC;

SELECT ROUND((p2.avg_total_user_cost - ISNULL(p1.avg_total_user_cost, 0))
	  * (p2.avg_user_impact - ISNULL(p1.avg_user_impact, 0))
	  * ((p2.user_seeks - ISNULL(p1.user_seeks, 0)) + (p2.user_scans - ISNULL(p1.user_scans, 0))),0) AS [Total Cost],
	  p2.avg_total_user_cost - ISNULL(p1.avg_total_user_cost, 0) AS avg_total_user_cost,
	  p2.avg_user_impact - ISNULL(p1.avg_user_impact, 0) AS avg_user_impact,
	  p2.user_seeks - ISNULL(p1.user_seeks, 0) AS user_seeks,
	  p2.user_scans - ISNULL(p1.user_scans, 0) AS user_scans,
	  d.statement AS TableName,
	  d.equality_columns,
	  d.inequality_columns,
	  d.included_columns
  FROM #PreWorkMissingIndexes AS p1
       RIGHT JOIN #PostWorkMissingIndexes AS p2 ON p2.index_group_handle =ISNULL(p1.index_group_handle, p2.index_group_handle)
	         AND p2.index_handle = ISNULL(p1.index_handle, p2.index_handle)
       INNER JOIN sys.dm_db_missing_index_details AS d	ON p2.index_handle = d.index_handle
 WHERE p2.avg_total_user_cost - ISNULL(p1.avg_total_user_cost, 0) > 0
    OR p2.avg_user_impact - ISNULL(p1.avg_user_impact, 0) > 0
    OR p2.user_seeks - ISNULL(p1.user_seeks, 0) > 0
    OR p2.user_scans - ISNULL(p1.user_scans, 0) > 0
 ORDER BY [Total Cost] DESC;

SELECT p2.object_name,
       p2.counter_name,
       p2.instance_name,
       ISNULL(p1.cntr_value, 0) AS InitialValue,
       p2.cntr_value AS FinalValue,
       p2.cntr_value - ISNULL(p1.cntr_value, 0) AS Change,
       (p2.cntr_value - ISNULL(p1.cntr_value, 0)) * 100 / p1.cntr_value AS [% Change]
  FROM #PreWorkOSSnapShot AS p1
       RIGHT JOIN #PostWorkOSSnapShot AS p2 ON p2.object_name =ISNULL(p1.object_name, p2.object_name)
	         AND p2.counter_name = ISNULL(p1.counter_name, p2.counter_name)
	         AND p2.instance_name = ISNULL(p1.instance_name, p2.instance_name)
 WHERE p2.cntr_value - ISNULL(p1.cntr_value, 0) > 0
   AND ISNULL(p1.cntr_value, 0) != 0
 ORDER BY [% Change] DESC, Change DESC;

-- Listing 7.7 Obtaining information about SQL CLR assemblies
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT DB_NAME(d.db_id) AS DatabaseName,
	  USER_NAME(d.user_id) UserName,
	  a.name AS AssemblyName,
	  f.name AS AssemblyFileName,
	  a.create_date AS AssemblyCreateDate,
	  l.load_time AS AssemblyLoadDate,
	  d.appdomain_name,
	  d.creation_time AS AppDomainCreateTime,
	  a.permission_set_desc,
	  d.state,
	  a.clr_name,
	  a.is_visible
  FROM sys.dm_clr_loaded_assemblies AS l
       INNER JOIN sys.dm_clr_appdomains AS d ON l.appdomain_address = d.appdomain_address
       INNER JOIN sys.assemblies AS a ON l.assembly_id = a.assembly_id
       INNER JOIN sys.assembly_files AS f ON a.assembly_id = f.assembly_id
 ORDER BY DatabaseName, UserName, AssemblyName;

-- Listing 8.1 Transaction processing pattern
BEGIN TRY
	BEGIN TRAN
		SELECT 1/0;
		PRINT 'Success';
	COMMIT
END TRY
BEGIN CATCH
	ROLLBACK
	PRINT 'An error has occurred';
END CATCH

-- Listing 8.2 Creating the sample database and table
CREATE DATABASE IWS_Temp
GO

USE IWS_Temp
GO

CREATE TABLE [dbo].[tblCountry]
(
  CountryId     INT IDENTITY(1,1) NOT NULL,
  Code          CHAR(3) NOT NULL,
  [Description] VARCHAR(50) NOT NULL
);

-- Listing 8.3 Starting an open transaction
USE IWS_TEMP
GO
SET NOCOUNT ON;

BEGIN TRAN
INSERT INTO [dbo].[tblCountry] 
(Code, [Description])
SELECT 'ENG', 'ENGLAND';

-- Listing 8.4 Selecting data from a table that has an open transaction against it
USE IWS_TEMP
GO
SET NOCOUNT ON;

SELECT *
  FROM dbo.tblCountry;

-- Listing 8.5 Observing the current locks
SET NOCOUNT ON;

SELECT DB_NAME(resource_database_id) AS DatabaseName,
       request_session_id,
       resource_type,
	  request_status,
	  request_mode
  FROM sys.dm_tran_locks
 WHERE request_session_id !=@@spid
 ORDER BY request_session_id;

-- Listing 8.6 Template for handling deadlock retries
SET NOCOUNT ON;

DECLARE @CurrentTry INT = 1,
        @MaxRetries INT = 3,
        @Complete BIT = 0;

WHILE (@Complete = 0)
BEGIN
	BEGIN TRY
		EXEC dbo.SomeRoutine;
		SET @Complete = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorNum INT = ERROR_NUMBER(),
		        @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE(),
		        @ErrorState INT = ERROR_STATE(),
		        @ErrorSeverity INT = ERROR_SEVERITY();
		
		IF (@ErrorNum = 1205) AND (@CurrentTry < @MaxRetries)
		BEGIN
			IF @@TRANCOUNT > 0
				ROLLBACK TRAN
			SET @CurrentTry += 1;
			WAITFOR DELAY '00:00:10';
		END
		ELSE
		BEGIN
			IF @@TRANCOUNT > 0
				ROLLBACK TRAN
			SET @Complete = 1;
			RAISERROR ('An error has occurred',
					 @ErrorSeverity,
					 @ErrorState
					)
		END
	END CATCH
END

-- Listing 8.7 Information contained in sessions, connections, and requests
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT *
  FROM sys.dm_exec_sessions AS s
       LEFT JOIN sys.dm_exec_connections AS c ON s.session_id = c.session_id
       LEFT JOIN sys.dm_exec_requests AS r ON c.connection_id = r.connection_id
 WHERE s.session_id > 50;

-- Listing 8.8 How to discover which locks are currently held
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT DB_NAME(resource_database_id) AS DatabaseName,
	  request_session_id,
	  resource_type,
	  CASE WHEN resource_type = 'OBJECT' THEN OBJECT_NAME(resource_associated_entity_id)
            WHEN resource_type IN ('KEY', 'PAGE', 'RID') THEN (SELECT OBJECT_NAME(OBJECT_ID) FROM sys.partitions AS p WHERE p.hobt_id = l.resource_associated_entity_id)
	  END AS resource_type_name,
	  request_status,
	  request_mode
  FROM sys.dm_tran_locks AS l
 WHERE request_session_id != @@spid
 ORDER BY request_session_id;

-- Listing 8.9 How to identify contended resources
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT tl1.resource_type,
	  DB_NAME(tl1.resource_database_id) AS DatabaseName,
	  tl1.resource_associated_entity_id,
	  tl1.request_session_id,
	  tl1.request_mode,
	  tl1.request_status,
       CASE WHEN tl1.resource_type = 'OBJECT' THEN OBJECT_NAME(tl1.resource_associated_entity_id)
            WHEN tl1.resource_type IN ('KEY', 'PAGE', 'RID') THEN (SELECT OBJECT_NAME(OBJECT_ID) FROM sys.partitions AS s WHERE s.hobt_id = tl1.resource_associated_entity_id)
	  END AS resource_type_name
  FROM sys.dm_tran_locks AS tl1
       INNER JOIN sys.dm_tran_locks AS tl2 ON tl1.resource_associated_entity_id = tl2.resource_associated_entity_id
		    AND tl1.request_status <> tl2.request_status
		    AND (tl1.resource_description = tl2.resource_description 
		         OR (tl1.resource_description IS NULL AND tl2.resource_description IS NULL)
			   )
 ORDER BY tl1.resource_associated_entity_id, tl1.request_status;

-- Listing 8.10 How to identify contended resources, including SQL query details
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT tl1.resource_type,
       DB_NAME(tl1.resource_database_id) AS DatabaseName,
       tl1.resource_associated_entity_id,
       tl1.request_session_id,
       tl1.request_mode,
       tl1.request_status,
       CASE WHEN tl1.resource_type = 'OBJECT' THEN OBJECT_NAME(tl1.resource_associated_entity_id)
            WHEN tl1.resource_type IN ('KEY', 'PAGE', 'RID') THEN (SELECT OBJECT_NAME(OBJECT_ID) FROM sys.partitions AS s WHERE s.hobt_id = tl1.resource_associated_entity_id)
        END AS resource_type_name,
       t.text AS [Parent Query],
       SUBSTRING (t.text,
	             r.statement_start_offset/2 + 1,
		        (
			    (CASE WHEN r.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), t.text)) * 2 ELSE r.statement_end_offset END - r.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query]
  FROM sys.dm_tran_locks AS tl1
       INNER JOIN sys.dm_tran_locks AS tl2 ON tl1.resource_associated_entity_id = tl2.resource_associated_entity_id
              AND tl1.request_status <> tl2.request_status
              AND (tl1.resource_description = tl2.resource_description
                   OR (tl1.resource_description IS NULL AND tl2.resource_description IS NULL)
                  )
       INNER JOIN sys.dm_exec_connections AS c ON tl1.request_session_id = c.most_recent_session_id
       CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) AS t
       LEFT JOIN sys.dm_exec_requests r ON c.connection_id = r.connection_id
 ORDER BY tl1.resource_associated_entity_id, tl1.request_status;

-- Listing 8.11 How to find an idle session with an open transaction
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT es.session_id,
       es.login_name,
       es.host_name,
       est.text,
       cn.last_read,
       cn.last_write,
	  es.program_name
  FROM sys.dm_exec_sessions AS es
       INNER JOIN sys.dm_tran_session_transactions AS st ON es.session_id = st.session_id
       INNER JOIN sys.dm_exec_connections AS cn ON es.session_id = cn.session_id
       CROSS APPLY sys.dm_exec_sql_text(cn.most_recent_sql_handle) AS est
       LEFT JOIN sys.dm_exec_requests AS er ON st.session_id = er.session_id
             AND er.session_id IS NULL;

-- Listing 8.12 What’s being blocked by idle sessions with open transactions
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT Waits.wait_duration_ms / 1000 AS WaitInSeconds,
       Blocking.session_id as BlockingSessionId,
       DB_NAME(Blocked.database_id) AS DatabaseName,
       Sess.login_name AS BlockingUser,
       Sess.host_name AS BlockingLocation,
       BlockingSQL.text AS BlockingSQL,
       Blocked.session_id AS BlockedSessionId,
       BlockedSess.login_name AS BlockedUser,
       BlockedSess.host_name AS BlockedLocation,
       BlockedSQL.text AS BlockedSQL,
       SUBSTRING (BlockedSQL.text,
	             BlockedReq.statement_start_offset/2 + 1,
	             (
			    (CASE WHEN BlockedReq.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), BlockedSQL.text)) * 2 ELSE BlockedReq.statement_end_offset END - BlockedReq.statement_start_offset)/2
			   ) + 1
			  ) AS [Blocked Individual Query],
       Waits.wait_type
  FROM sys.dm_exec_connections AS Blocking
       INNER JOIN sys.dm_exec_requests AS Blocked ON Blocking.session_id = Blocked.blocking_session_id
       INNER JOIN sys.dm_exec_sessions AS Sess ON Blocking.session_id = sess.session_id
       INNER JOIN sys.dm_tran_session_transactions AS st ON Blocking.session_id = st.session_id
       LEFT JOIN sys.dm_exec_requests AS er ON st.session_id = er.session_id
             AND er.session_id IS NULL
       INNER JOIN sys.dm_os_waiting_tasks AS Waits ON Blocked.session_id = Waits.session_id
       CROSS APPLY sys.dm_exec_sql_text(Blocking.most_recent_sql_handle) AS BlockingSQL
       INNER JOIN sys.dm_exec_requests AS BlockedReq ON Waits.session_id = BlockedReq.session_id
       INNER JOIN sys.dm_exec_sessions AS BlockedSess ON Waits.session_id = BlockedSess.session_id
       CROSS APPLY sys.dm_exec_sql_text(Blocked.sql_handle) AS BlockedSQL
 ORDER BY WaitInSeconds;

-- Listing 8.13 What’s blocked by active sessions with open transactions
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT Waits.wait_duration_ms / 1000 AS WaitInSeconds,
       Blocking.session_id as BlockingSessionId,
       DB_NAME(Blocked.database_id) AS DatabaseName,
       Sess.login_name AS BlockingUser,
       Sess.host_name AS BlockingLocation,
       BlockingSQL.text AS BlockingSQL,
       Blocked.session_id AS BlockedSessionId,
       BlockedSess.login_name AS BlockedUser,
       BlockedSess.host_name AS BlockedLocation,
       BlockedSQL.text AS BlockedSQL,
       SUBSTRING (BlockedSQL.text,
	             BlockedReq.statement_start_offset/2 + 1,
                  (
			    (CASE WHEN BlockedReq.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), BlockedSQL.text)) * 2 ELSE BlockedReq.statement_end_offset END - BlockedReq.statement_start_offset)/2
		        ) + 1
			  ) AS [Blocked Individual Query],
       Waits.wait_type
  FROM sys.dm_exec_connections AS Blocking
       INNER JOIN sys.dm_exec_requests AS Blocked ON Blocking.session_id = Blocked.blocking_session_id
       INNER JOIN sys.dm_exec_sessions AS Sess ON Blocking.session_id = sess.session_id
       INNER JOIN sys.dm_tran_session_transactions AS st ON Blocking.session_id = st.session_id
       INNER JOIN sys.dm_exec_requests AS er ON st.session_id = er.session_id
       INNER JOIN sys.dm_os_waiting_tasks AS Waits ON Blocked.session_id = Waits.session_id
       CROSS APPLY sys.dm_exec_sql_text(Blocking.most_recent_sql_handle) AS BlockingSQL
       INNER JOIN sys.dm_exec_requests AS BlockedReq ON Waits.session_id = BlockedReq.session_id
       INNER JOIN sys.dm_exec_sessions AS BlockedSess ON Waits.session_id = BlockedSess.session_id
       CROSS APPLY sys.dm_exec_sql_text(Blocked.sql_handle) AS BlockedSQL
 ORDER BY WaitInSeconds;

-- Listing 8.14 What’s blocked—active and idle sessions with open transactions
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT Waits.wait_duration_ms / 1000 AS WaitInSeconds,
       Blocking.session_id as BlockingSessionId,
       DB_NAME(Blocked.database_id) AS DatabaseName,
       Sess.login_name AS BlockingUser,
       Sess.host_name AS BlockingLocation,
       BlockingSQL.text AS BlockingSQL,
       Blocked.session_id AS BlockedSessionId,
       BlockedSess.login_name AS BlockedUser,
       BlockedSess.host_name AS BlockedLocation,
       BlockedSQL.text AS BlockedSQL,
       SUBSTRING (BlockedSQL.text,
	             BlockedReq.statement_start_offset/2 + 1,
			   (
			    (CASE WHEN BlockedReq.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), BlockedSQL.text)) * 2 ELSE BlockedReq.statement_end_offset END - BlockedReq.statement_start_offset)/2
			   ) + 1
			  ) AS [Blocked Individual Query],
       Waits.wait_type
  FROM sys.dm_exec_connections AS Blocking
       INNER JOIN sys.dm_exec_requests AS Blocked ON Blocking.session_id = Blocked.blocking_session_id
       INNER JOIN sys.dm_exec_sessions AS Sess ON Blocking.session_id = sess.session_id
       INNER JOIN sys.dm_tran_session_transactions AS st ON Blocking.session_id = st.session_id
       LEFT JOIN sys.dm_exec_requests AS er ON st.session_id = er.session_id
       INNER JOIN sys.dm_os_waiting_tasks AS Waits ON Blocked.session_id = Waits.session_id
       CROSS APPLY sys.dm_exec_sql_text(Blocking.most_recent_sql_handle) AS BlockingSQL
       INNER JOIN sys.dm_exec_requests AS BlockedReq ON Waits.session_id = BlockedReq.session_id
       INNER JOIN sys.dm_exec_sessions AS BlockedSess ON Waits.session_id = BlockedSess.session_id
       CROSS APPLY sys.dm_exec_sql_text(Blocked.sql_handle) AS BlockedSQL
 ORDER BY WaitInSeconds;

-- Listing 8.15 What has been blocked for more than 30 seconds
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT Waits.wait_duration_ms / 1000 AS WaitInSeconds,
       Blocking.session_id as BlockingSessionId,
       Sess.login_name AS BlockingUser,
       Sess.host_name AS BlockingLocation,
       BlockingSQL.text AS BlockingSQL,
       Blocked.session_id AS BlockedSessionId,
       BlockedSess.login_name AS BlockedUser,
       BlockedSess.host_name AS BlockedLocation,
       BlockedSQL.text AS BlockedSQL,
       DB_NAME(Blocked.database_id) AS DatabaseName
  FROM sys.dm_exec_connections AS Blocking
       INNER JOIN sys.dm_exec_requests AS Blocked ON Blocking.session_id = Blocked.blocking_session_id
       INNER JOIN sys.dm_exec_sessions AS Sess ON Blocking.session_id = sess.session_id
       INNER JOIN sys.dm_tran_session_transactions AS st ON Blocking.session_id = st.session_id
       LEFT JOIN sys.dm_exec_requests AS er ON st.session_id = er.session_id
             AND er.session_id IS NULL
       INNER JOIN sys.dm_os_waiting_tasks AS Waits ON Blocked.session_id = Waits.session_id
       CROSS APPLY sys.dm_exec_sql_text(Blocking.most_recent_sql_handle) AS BlockingSQL
       INNER JOIN sys.dm_exec_requests AS BlockedReq ON Waits.session_id = BlockedReq.session_id
       INNER JOIN sys.dm_exec_sessions AS BlockedSess ON Waits.session_id = BlockedSess.session_id
       CROSS APPLY sys.dm_exec_sql_text(Blocked.sql_handle) AS BlockedSQL
 WHERE Waits.wait_duration_ms > 30000
 ORDER BY WaitInSeconds;

-- Listing 9.1 Amount of space (total, used, and free) in tempdb
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT SUM( user_object_reserved_page_count
          + internal_object_reserved_page_count
          + version_store_reserved_page_count
          + mixed_extent_page_count
          + unallocated_extent_page_count
          ) * (8.0/1024.0) AS [TotalSizeOfTempDB(MB)],
	  SUM( user_object_reserved_page_count
          + internal_object_reserved_page_count
          + version_store_reserved_page_count
          + mixed_extent_page_count
          ) * (8.0/1024.0) AS [UsedSpace (MB)],
	  SUM(unallocated_extent_page_count * (8.0/1024.0)) AS [FreeSpace (MB)]
  FROM sys.dm_db_file_space_usage;

-- Listing 9.2 Total amount of space (data, log, and log used) by database
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT instance_name,
       counter_name,
       cntr_value / 1024.0 AS [Size(MB)]
  FROM sys.dm_os_performance_counters
 WHERE object_name = 'SQLServer:Databases'
   AND counter_name IN ('Data File(s) Size (KB)', 'Log File(s) Size (KB)', 'Log File(s) Used Size (KB)')
 ORDER BY instance_name, counter_name;

-- Listing 9.3 Tempdb total space usage by object type
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT SUM (user_object_reserved_page_count) * (8.0/1024.0) AS [User Objects (MB)],
	  SUM (internal_object_reserved_page_count) * (8.0/1024.0) AS [Internal Objects (MB)],
	  SUM (version_store_reserved_page_count) * (8.0/1024.0) AS [Version Store (MB)],
	  SUM (mixed_extent_page_count)* (8.0/1024.0) AS [Mixed Extent (MB)],
	  SUM (unallocated_extent_page_count)* (8.0/1024.0) AS [Unallocated (MB)]
 FROM sys.dm_db_file_space_usage;

-- Listing 9.4 Space usage by session
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT es.session_id,
       ec.connection_id,
       es.login_name,
       es.host_name,
       st.text,
       su.user_objects_alloc_page_count,
       su.user_objects_dealloc_page_count,
       su.internal_objects_alloc_page_count,
       su.internal_objects_dealloc_page_count,
       ec.last_read,
       ec.last_write,
       es.program_name
  FROM sys.dm_db_session_space_usage su
       INNER JOIN sys.dm_exec_sessions AS es ON su.session_id = es.session_id
       LEFT JOIN sys.dm_exec_connections AS ec ON su.session_id = ec.most_recent_session_id
       OUTER APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle) AS st
 WHERE su.session_id > 50;

-- Listing 9.5 Space used and reclaimed in tempdb for completed batches
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT CAST(SUM(su.user_objects_alloc_page_count + su.internal_objects_alloc_page_count) * (8.0/1024.0) AS DECIMAL(20,3)) AS [SpaceUsed(MB)],
       CAST(SUM(su.user_objects_alloc_page_count
		      - su.user_objects_dealloc_page_count
		      + su.internal_objects_alloc_page_count
		      - su.internal_objects_dealloc_page_count
               ) * (8.0/1024.0) AS DECIMAL(20,3)
		 ) AS [SpaceStillUsed(MB)],
       su.session_id,
       ec.connection_id,
       es.login_name,
       es.host_name,
       st.text AS [LastQuery],
       ec.last_read,
       ec.last_write,
       es.program_name
  FROM sys.dm_db_session_space_usage AS su
       INNER JOIN sys.dm_exec_sessions AS es ON su.session_id = es.session_id
       LEFT JOIN sys.dm_exec_connections AS ec ON su.session_id = ec.most_recent_session_id
       OUTER APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle) st
 WHERE su.session_id > 50
 GROUP BY su.session_id, ec.connection_id, es.login_name, es.host_name, st.text, ec.last_read, ec.last_write, es.program_name
 ORDER BY [SpaceStillUsed(MB)] DESC;

-- Listing 9.6 Space usage by task
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT es.session_id,
       ec.connection_id,
       es.login_name,
       es.host_name,
       st.text,
       tu.user_objects_alloc_page_count,
       tu.user_objects_dealloc_page_count,
       tu.internal_objects_alloc_page_count,
       tu.internal_objects_dealloc_page_count,
       ec.last_read,
       ec.last_write,
       es.program_name
  FROM sys.dm_db_task_space_usage AS tu
       INNER JOIN sys.dm_exec_sessions AS es ON tu.session_id = es.session_id
       LEFT JOIN sys.dm_exec_connections AS ec ON tu.session_id = ec.most_recent_session_id
       OUTER APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle) AS st
 WHERE tu.session_id > 50;

-- Listing 9.7 Space used and not reclaimed in tempdb for active batches
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT SUM(ts.user_objects_alloc_page_count + ts.internal_objects_alloc_page_count) * (8.0/1024.0) AS [SpaceUsed(MB)],
	  SUM(ts.user_objects_alloc_page_count - ts.user_objects_dealloc_page_count + ts.internal_objects_alloc_page_count - ts.internal_objects_dealloc_page_count) * (8.0/1024.0) AS [SpaceStillUsed(MB)],
	  ts.session_id,
	  ec.connection_id,
	  es.login_name,
	  es.host_name,
	  st.text AS [Parent Query],
	  SUBSTRING (st.text,
	             er.statement_start_offset/2 + 1,
                  (
                   (CASE WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), st.text)) * 2 ELSE er.statement_end_offset END - er.statement_start_offset)/2
                  ) + 1
                 ) AS [Current Query],
       ec.last_read,
       ec.last_write,
       es.program_name
  FROM sys.dm_db_task_space_usage AS ts
       INNER JOIN sys.dm_exec_sessions AS es ON ts.session_id = es.session_id
       LEFT JOIN sys.dm_exec_connections AS ec ON ts.session_id = ec.most_recent_session_id
       OUTER APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle) AS st
       LEFT JOIN sys.dm_exec_requests AS er ON ts.session_id = er.session_id
 WHERE ts.session_id > 50
 GROUP BY ts.session_id, ec.connection_id, es.login_name, es.host_name,
	     st.text, ec.last_read, ec.last_write, es.program_name,
	     SUBSTRING (st.text,
	                er.statement_start_offset/2 + 1,
                     (
                      (CASE WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), st.text)) * 2 ELSE er.statement_end_offset END - er.statement_start_offset)/2
                     ) + 1
                    )
 ORDER BY [SpaceStillUsed(MB)] DESC;

-- Listing 9.8 Indexes under the most row-locking pressure
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
	  x.name AS SchemaName,
       OBJECT_NAME(s.object_id) AS TableName,
       i.name AS IndexName,
       s.row_lock_wait_in_ms,
       s.row_lock_wait_count
  FROM sys.dm_db_index_operational_stats(db_ID(), NULL, NULL, NULL) AS s
       INNER JOIN sys.objects AS o ON s.object_id = o.object_id
       INNER JOIN sys.indexes AS i ON s.index_id = i.index_id
              AND i.object_id = o.object_id
       INNER JOIN sys.schemas AS x ON x.schema_id = o.schema_id
 WHERE s.row_lock_wait_in_ms > 0
   AND o.is_ms_shipped = 0
 ORDER BY s.row_lock_wait_in_ms DESC;

-- Listing 9.9 Indexes with the most lock escalations
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
	  x.name AS SchemaName,
       OBJECT_NAME (s.object_id) AS TableName,
       i.name AS IndexName,
       s.index_lock_promotion_count
  FROM sys.dm_db_index_operational_stats(db_ID(), NULL, NULL, NULL) s
       INNER JOIN sys.objects o ON s.object_id = o.object_id
       INNER JOIN sys.indexes i ON s.index_id = i.index_id
              AND i.object_id = o.object_id
       INNER JOIN sys.schemas x ON x.schema_id = o.schema_id
 WHERE s.index_lock_promotion_count > 0
   AND o.is_ms_shipped = 0
 ORDER BY s.index_lock_promotion_count DESC;

-- Listing 9.10 Indexes with the most unsuccessful lock escalations
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
       x.name AS SchemaName,
       OBJECT_NAME (s.object_id) AS TableName,
       i.name AS IndexName,
       s.index_lock_promotion_attempt_count - s.index_lock_promotion_count AS UnsuccessfulIndexLockPromotions
  FROM sys.dm_db_index_operational_stats(db_ID(), NULL, NULL, NULL) AS s
       INNER JOIN sys.objects AS o ON s.object_id = o.object_id
       INNER JOIN sys.indexes AS i ON s.index_id = i.index_id
              AND i.object_id = o.object_id
       INNER JOIN sys.schemas x ON x.schema_id = o.schema_id
 WHERE (s.index_lock_promotion_attempt_count - index_lock_promotion_count) > 0
   AND o.is_ms_shipped = 0
 ORDER BY UnsuccessfulIndexLockPromotions DESC;

-- Listing 9.11 Indexes with the most page splits
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
       x.name AS SchemaName,
       object_name(s.object_id) AS TableName,
       i.name AS IndexName,
       s.leaf_allocation_count,
       s.nonleaf_allocation_count
  FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) AS s
       INNER JOIN sys.objects AS o ON s.object_id = o.object_id
       INNER JOIN sys.indexes AS i ON s.index_id = i.index_id
              AND i.object_id = o.object_id
       INNER JOIN sys.schemas AS x ON x.schema_id = o.schema_id
 WHERE s.leaf_allocation_count > 0
   AND o.is_ms_shipped = 0
 ORDER BY s.leaf_allocation_count DESC;

-- Listing 9.12 Indexes with the most latch contention
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
	  x.name AS SchemaName,
       OBJECT_NAME(s.object_id) AS TableName,
       i.name AS IndexName,
       s.page_latch_wait_in_ms,
       s.page_latch_wait_count
  FROM sys.dm_db_index_operational_stats(db_ID(), NULL, NULL, NULL) AS s
       INNER JOIN sys.objects AS o ON s.object_id = o.object_id
       INNER JOIN sys.indexes AS i ON s.index_id = i.index_id
              AND i.object_id = o.object_id
       INNER JOIN sys.schemas AS x ON x.schema_id = o.schema_id
 WHERE s.page_latch_wait_in_ms > 0
   AND o.is_ms_shipped = 0
 ORDER BY s.page_latch_wait_in_ms DESC;

-- Listing 9.13 Indexes with the most page I/O-latch contention
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT TOP 20
	  x.name AS SchemaName,
       OBJECT_NAME(s.object_id) AS TableName,
       i.name AS IndexName,
       s.page_io_latch_wait_count,
       s.page_io_latch_wait_in_ms
  FROM sys.dm_db_index_operational_stats(db_ID(), NULL, NULL, NULL) AS s
       INNER JOIN sys.objects o ON s.object_id = o.object_id
       INNER JOIN sys.indexes i ON s.index_id = i.index_id
              AND i.object_id = o.object_id
       INNER JOIN sys.schemas x ON x.schema_id = o.schema_id
 WHERE s.page_io_latch_wait_in_ms > 0
   AND o.is_ms_shipped = 0
 ORDER BY s.page_io_latch_wait_in_ms DESC;

-- Listing 9.14 Indexes under the most row-locking pressure—snapshot version
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PreWorkIndexCount', 'U') IS NOT NULL DROP TABLE #PreWorkIndexCount;
IF OBJECT_ID('tempdb..#PostWorkIndexCount', 'U') IS NOT NULL DROP TABLE #PostWorkIndexCount;
IF OBJECT_ID('tempdb..#PreWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkQuerySnapShot;
IF OBJECT_ID('tempdb..#PostWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkQuerySnapShot;

SELECT x.name AS SchemaName,
	  OBJECT_NAME (s.object_id) AS TableName,
	  i.name AS IndexName,
	  s.row_lock_wait_in_ms
  INTO #PreWorkIndexCount
  FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) AS s
       INNER JOIN sys.objects AS o ON s.object_id = o.object_id
       INNER JOIN sys.indexes AS i ON s.index_id = i.index_id
              AND i.object_id = o.object_id
       INNER JOIN sys.schemas AS x ON x.schema_id = o.schema_id
 WHERE s.row_lock_wait_in_ms > 0
   AND o.is_ms_shipped = 0;

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PreWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

WAITFOR DELAY '01:00:00';

SELECT x.name AS SchemaName,
       OBJECT_NAME (s.object_id) AS TableName,
       i.name AS IndexName,
       s.row_lock_wait_in_ms
  INTO #PostWorkIndexCount
  FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) AS s
       INNER JOIN sys.objects o ON s.object_id = o.object_id
       INNER JOIN sys.indexes i ON s.index_id = i.index_id
              AND i.object_id = o.object_id
       INNER JOIN sys.schemas x ON x.schema_id = o.schema_id
 WHERE s.row_lock_wait_in_ms > 0
   AND o.is_ms_shipped = 0;
	
SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PostWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

SELECT p2.SchemaName,
       p2.TableName,
       p2.IndexName,
       p2.row_lock_wait_in_ms - ISNULL(p1.row_lock_wait_in_ms, 0) AS RowLockWaitTimeDelta_ms
  FROM #PreWorkIndexCount AS p1
       RIGHT JOIN #PostWorkIndexCount AS p2 ON p2.SchemaName = ISNULL(p1.SchemaName, p2.SchemaName)
              AND p2.TableName = ISNULL(p1.TableName, p2.TableName)
              AND p2.IndexName = ISNULL(p1.IndexName, p2.IndexName)
 WHERE p2.row_lock_wait_in_ms - ISNULL(p1.row_lock_wait_in_ms, 0) > 0
 ORDER BY RowLockWaitTimeDelta_ms DESC;

SELECT p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0) AS [Duration],
       p2.total_worker_time - ISNULL(p1.total_worker_time, 0) AS [Time on CPU],
       (p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) - (p2.total_worker_time - ISNULL(p1.total_worker_time, 0)) AS [Time blocked],
       p2.total_logical_reads - ISNULL(p1.total_logical_reads, 0) AS [Reads],
       p2.total_logical_writes - ISNULL(p1.total_logical_writes, 0) AS [Writes],
       p2.total_clr_time - ISNULL(p1.total_clr_time, 0) AS [CLR time],
       p2.execution_count - ISNULL(p1.execution_count, 0) AS [Executions],
       SUBSTRING (qt.text,
                  p2.statement_start_offset/2 + 1,
                  (
			    (CASE WHEN p2.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE p2.statement_end_offset END - p2.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName
  FROM #PreWorkQuerySnapShot AS p1
       RIGHT JOIN #PostWorkQuerySnapShot AS p2 ON p2.sql_handle = ISNULL(p1.sql_handle, p2.sql_handle)
              AND p2.plan_handle = ISNULL(p1.plan_handle, p2.plan_handle)
              AND p2.statement_start_offset =ISNULL(p1.statement_start_offset, p2.statement_start_offset)
              AND p2.statement_end_offset =ISNULL(p1.statement_end_offset, p2.statement_end_offset)
       CROSS APPLY sys.dm_exec_sql_text(p2.sql_handle) AS qt
 WHERE p2.execution_count != ISNULL(p1.execution_count, 0)
   AND qt.text NOT LIKE '--ThisRoutineIdentifier%'
 ORDER BY [Duration] DESC;

-- Listing 9.15 Determining how many rows are inserted/deleted/updated/selected
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PreWorkIndexCount', 'U') IS NOT NULL DROP TABLE #PreWorkIndexCount;
IF OBJECT_ID('tempdb..#PostWorkIndexCount', 'U') IS NOT NULL DROP TABLE #PostWorkIndexCount;
IF OBJECT_ID('tempdb..#PreWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkQuerySnapShot;
IF OBJECT_ID('tempdb..#PostWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkQuerySnapShot;

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PreWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

SELECT x.name AS SchemaName,
       OBJECT_NAME (s.object_id) AS TableName,
       i.name AS IndexName,
       s.leaf_delete_count,
       s.leaf_ghost_count,
       s.leaf_insert_count,
       s.leaf_update_count,
       s.range_scan_count,
       s.singleton_lookup_count
  INTO #PreWorkIndexCount
  FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) AS s
       INNER JOIN sys.objects AS o ON s.object_id = o.object_id
       INNER JOIN sys.indexes AS i ON s.index_id = i.index_id
              AND i.object_id = o.object_id
       INNER JOIN sys.schemas AS x ON x.schema_id = o.schema_id
 WHERE o.is_ms_shipped = 0;

WAITFOR DELAY '01:00:00';

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PostWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

SELECT x.name AS SchemaName,
       OBJECT_NAME (s.object_id) AS TableName,
       i.name AS IndexName,
       s.leaf_delete_count,
       s.leaf_ghost_count,
       s.leaf_insert_count,
       s.leaf_update_count,
       s.range_scan_count,
       s.singleton_lookup_count
  INTO #PostWorkIndexCount
  FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) AS s
       INNER JOIN sys.objects AS o ON s.object_id = o.object_id
       INNER JOIN sys.indexes AS i ON s.index_id = i.index_id
              AND i.object_id = o.object_id
       INNER JOIN sys.schemas x ON x.schema_id = o.schema_id
 WHERE o.is_ms_shipped = 0;

SELECT p2.SchemaName,
       p2.TableName,
       p2.IndexName,
       p2.leaf_delete_count - ISNULL(p1.leaf_delete_count, 0) AS leaf_delete_countDelta,
       p2.leaf_ghost_count - ISNULL(p1.leaf_ghost_count, 0) AS leaf_ghost_countDelta,
       p2.leaf_insert_count - ISNULL(p1.leaf_insert_count, 0) AS leaf_insert_countDelta,
       p2.leaf_update_count - ISNULL(p1.leaf_update_count, 0) AS leaf_update_countDelta,
       p2.range_scan_count - ISNULL(p1.range_scan_count, 0) AS range_scan_countDelta,
       p2.singleton_lookup_count - ISNULL(p1.singleton_lookup_count, 0) AS singleton_lookup_countDelta
  FROM #PreWorkIndexCount AS p1
       RIGHT JOIN #PostWorkIndexCount p2 ON p2.SchemaName =ISNULL(p1.SchemaName, p2.SchemaName)
              AND p2.TableName = ISNULL(p1.TableName, p2.TableName)
              AND p2.IndexName = ISNULL(p1.IndexName, p2.IndexName)
 WHERE p2.leaf_delete_count - ISNULL(p1.leaf_delete_count, 0) > 0
    OR p2.leaf_ghost_count - ISNULL(p1.leaf_ghost_count, 0) > 0
    OR p2.leaf_insert_count - ISNULL(p1.leaf_insert_count, 0) > 0
    OR p2.leaf_update_count - ISNULL(p1.leaf_update_count, 0) > 0
    OR p2.range_scan_count - ISNULL(p1.range_scan_count, 0) > 0
    OR p2.singleton_lookup_count - ISNULL(p1.singleton_lookup_count, 0) > 0
 ORDER BY leaf_delete_countDelta DESC;

SELECT p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0) AS [Duration],
       p2.total_worker_time - ISNULL(p1.total_worker_time, 0) AS [Time on CPU],
       (p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) - (p2.total_worker_time - ISNULL(p1.total_worker_time, 0)) AS [Time blocked],
       p2.total_logical_reads - ISNULL(p1.total_logical_reads, 0) AS [Reads],
       p2.total_logical_writes - ISNULL(p1.total_logical_writes, 0) AS [Writes],
       p2.total_clr_time - ISNULL(p1.total_clr_time, 0) AS [CLR time],
       p2.execution_count - ISNULL(p1.execution_count, 0) AS [Executions],
       SUBSTRING (qt.text,
                  p2.statement_start_offset/2 + 1,
                  (
                   (CASE WHEN p2.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE p2.statement_end_offset END - p2.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName
  FROM #PreWorkQuerySnapShot AS p1
       RIGHT JOIN #PostWorkQuerySnapShot AS p2 ON p2.sql_handle =ISNULL(p1.sql_handle, p2.sql_handle)
              AND p2.plan_handle = ISNULL(p1.plan_handle, p2.plan_handle)
              AND p2.statement_start_offset =ISNULL(p1.statement_start_offset, p2.statement_start_offset)
              AND p2.statement_end_offset =ISNULL(p1.statement_end_offset, p2.statement_end_offset)
       CROSS APPLY sys.dm_exec_sql_text(p2.sql_handle) AS qt
 WHERE p2.execution_count != ISNULL(p1.execution_count, 0)
 ORDER BY [Duration] DESC;

--Listing 10.1 CLR function to extract the routine name
/*
using System;
using Microsoft.SqlServer.Server;
public partial class UserDefinedFunctions
{
    [SqlFunction(IsDeterministic = true, DataAccess = DataAccessKind.None)]
    public static String ExtractSQLRoutineName(String sSource)
    {
        int _routineStartOffset;
        int _firstSpaceOffset;
        int _endOfRoutineNameOffset;
        if (String.IsNullOrEmpty(sSource) == true)
        {
            return null;
        }
        _routineStartOffset = sSource.IndexOf("CREATE PROC", StringComparison.CurrentCultureIgnoreCase);
        if (_routineStartOffset == -1)
        {
            _routineStartOffset = sSource.IndexOf("CREATE FUNC", StringComparison.CurrentCultureIgnoreCase);
        }
        if (_routineStartOffset == -1)
        {
            return null;
        }
        _routineStartOffset = _routineStartOffset + "CREATE FUNC".Length;
        _firstSpaceOffset = sSource.IndexOf(" ", _routineStartOffset);
        for (int i = _firstSpaceOffset; i < (sSource.Length - 1); i++)
        {
            if (sSource.Substring(i, 1) != " ")
            {
                _firstSpaceOffset = i;
                break;
            }
        }
        _endOfRoutineNameOffset = sSource.IndexOfAny(new char[] { ' ','(', '\t', '\r', '\n' }, _firstSpaceOffset + 1);
        if (_endOfRoutineNameOffset > _routineStartOffset)
        {
            return sSource.Substring(_firstSpaceOffset,
            (_endOfRoutineNameOffset - _firstSpaceOffset));
        }
        else
            return null;
    }
};
--*/

-- Listing 10.2 Recompile routines that are running slower than normal
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

DECLARE @Length INT = 4000,
        @StartOffset INT = 0,
        @RecompilationSQL NVARCHAR(MAX) = '';

IF OBJECT_ID('tempdb..#SlowQueries', 'U') IS NOT NULL DROP TABLE #SlowQueries;
IF OBJECT_ID('tempdb..#RecompileQuery', 'U') IS NOT NULL DROP TABLE #RecompileQuery;
IF OBJECT_ID('tempdb..#SlowQueriesByIO', 'U') IS NOT NULL DROP TABLE #SlowQueriesByIO;
IF OBJECT_ID('tempdb..#QueriesRunningSlowerThanNormal', 'U') IS NOT NULL DROP TABLE #QueriesRunningSlowerThanNormal;

SELECT TOP 100
	  qs.execution_count AS [Runs],
	  (qs.total_worker_time - qs.last_worker_time) / (qs.execution_count - 1) AS [Avg time],
       qs.last_worker_time AS [Last time],
       (qs.last_worker_time - ((qs.total_worker_time - qs.last_worker_time) / (qs.execution_count - 1))) AS [Time Deviation],
       CASE WHEN qs.last_worker_time = 0 THEN 100 ELSE (qs.last_worker_time - ((qs.total_worker_time - qs.last_worker_time) / (qs.execution_count - 1))) * 100 END
       / (((qs.total_worker_time - qs.last_worker_time)
       / (qs.execution_count - 1))) AS [% Time Deviation],
	  qs.last_logical_reads + qs.last_logical_writes + qs.last_physical_reads AS [Last IO],
	  ((qs.total_logical_reads + qs.total_logical_writes + qs.total_physical_reads) - (qs.last_logical_reads + qs.last_logical_writes + qs.last_physical_reads))
       / (qs.execution_count - 1) AS [Avg IO],
       SUBSTRING (qt.text,
	             qs.statement_start_offset/2 + 1,
		        (
			    (CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE qs.statement_end_offset END - qs.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
	  qt.text AS [Parent Query],
	  DB_NAME(qt.dbid) AS [DatabaseName]
  INTO #SlowQueries
  FROM sys.dm_exec_query_stats AS qs
       CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) AS qt
 WHERE qs.execution_count > 1
   AND qs.total_worker_time != qs.last_worker_time
 ORDER BY [% Time Deviation] DESC;

SELECT TOP 100
       [Runs],
	  [Avg time],
	  [Last time],
	  [Time Deviation],
	  [% Time Deviation],
	  [Last IO],
	  [Avg IO],
	  [Last IO] - [Avg IO] AS [IO Deviation],
	  IIF([Avg IO] = 0, 0, ([Last IO]- [Avg IO]) * 100 / [Avg IO]) AS [% IO Deviation],
	  [Individual Query],
	  [Parent Query],
	  [DatabaseName]
  INTO #SlowQueriesByIO
  FROM #SlowQueries
 ORDER BY [% Time Deviation] DESC;

SELECT TOP 100
	  [Runs],
       [Avg time],
       [Last time],
       [Time Deviation],
       [% Time Deviation],
       [Last IO],
       [Avg IO],
       [IO Deviation],
       [% IO Deviation],
       [Impedance] = [% Time Deviation] - [% IO Deviation],
       [Individual Query],
       [Parent Query],
       [DatabaseName]
  INTO #QueriesRunningSlowerThanNormal
  FROM #SlowQueriesByIO
 WHERE [% Time Deviation] - [% IO Deviation] > 20
 ORDER BY [Impedance] DESC;

SELECT DISTINCT
	  ' EXEC sp_recompile ' + '''' + '[' + [DatabaseName] + '].' + dbo.ExtractSQLRoutineName([Parent Query]) + '''' AS recompileRoutineSQL
  INTO #RecompileQuery
  FROM #QueriesRunningSlowerThanNormal
 WHERE [DatabaseName] NOT IN ('master', 'msdb', '');

SELECT @RecompilationSQL += recompileRoutineSQL + CHAR(10)
  FROM #RecompileQuery
 WHERE recompileRoutineSQL IS NOT NULL;

WHILE (@StartOffset < LEN(@RecompilationSQL))
BEGIN
	PRINT SUBSTRING(@RecompilationSQL, @StartOffset, @Length);
	SET @StartOffset += @Length;
END

PRINT SUBSTRING(@RecompilationSQL, @StartOffset, @Length);

EXECUTE sp_executesql @RecompilationSQL;
GO

-- Listing 10.3 Rebuild/reorganize for a given database
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

DECLARE @Length INT = 4000,
        @StartOffset INT = 0,
        @RebuildIndexesSQL NVARCHAR(MAX) = '';

IF OBJECT_ID('tempdb..#FragmentedIndexes', 'U') IS NOT NULL DROP TABLE #FragmentedIndexes;
CREATE TABLE #FragmentedIndexes
(
 DatabaseName SYSNAME,
 SchemaName SYSNAME,
 TableName SYSNAME,
 IndexName SYSNAME,
 [Fragmentation%] FLOAT
);

INSERT INTO #FragmentedIndexes
SELECT DB_NAME(DB_ID()) AS DatabaseName,
       ss.name AS SchemaName,
       OBJECT_NAME (s.object_id) AS TableName,
       i.name AS IndexName,
       s.avg_fragmentation_in_percent AS [Fragmentation%]
  FROM sys.dm_db_index_physical_stats(db_id(),NULL, NULL, NULL, 'SAMPLED') AS s
       INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
              AND s.index_id = i.index_id
       INNER JOIN sys.objects AS o ON s.object_id = o.object_id
       INNER JOIN sys.schemas AS ss ON ss.[schema_id] = o.[schema_id]
 WHERE s.database_id = DB_ID()
   AND i.index_id != 0
   AND s.record_count > 0
   AND o.is_ms_shipped = 0;

SELECT @RebuildIndexesSQL += 
       CASE WHEN [Fragmentation%] > 30
            THEN CHAR(10) + 'ALTER INDEX ' + QUOTENAME(IndexName) + ' ON '
                 + QUOTENAME(SchemaName) + '.'
                 + QUOTENAME(TableName) + ' REBUILD;'
	       WHEN [Fragmentation%] > 10
            THEN CHAR(10) + 'ALTER INDEX ' + QUOTENAME(IndexName) + ' ON '
                 + QUOTENAME(SchemaName) + '.'
                 + QUOTENAME(TableName) + ' REORGANIZE;'
	  END
  FROM #FragmentedIndexes
 WHERE [Fragmentation%] > 10;

WHILE (@StartOffset < LEN(@RebuildIndexesSQL))
BEGIN
	PRINT SUBSTRING(@RebuildIndexesSQL, @StartOffset, @Length);
	SET @StartOffset += @Length;
END

PRINT SUBSTRING(@RebuildIndexesSQL, @StartOffset, @Length);

EXECUTE sp_executesql @RebuildIndexesSQL;
GO

-- Listing 10.4 Rebuild/reorganize for all databases on a given server
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

DECLARE @Length INT = 4000,
        @StartOffset INT = 0,
        @RebuildIndexesSQL NVARCHAR(MAX) = '';

IF OBJECT_ID('tempdb..#FragmentedIndexes', 'U') IS NOT NULL DROP TABLE #FragmentedIndexes;
CREATE TABLE #FragmentedIndexes
(
 DatabaseName SYSNAME,
 SchemaName SYSNAME,
 TableName SYSNAME,
 IndexName SYSNAME,
 [Fragmentation%] FLOAT
);

EXEC sp_MSForEachDB 
'USE [?];
INSERT INTO #FragmentedIndexes
SELECT DB_NAME(DB_ID()) AS DatabaseName,
       ss.name AS SchemaName,
       OBJECT_NAME (s.object_id) AS TableName,
       i.name AS IndexName,
       s.avg_fragmentation_in_percent AS [Fragmentation%]
  FROM sys.dm_db_index_physical_stats(db_id(),NULL, NULL, NULL, ''SAMPLED'') AS s
       INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
              AND s.index_id = i.index_id
       INNER JOIN sys.objects AS o ON s.object_id = o.object_id
       INNER JOIN sys.schemas AS ss ON ss.[schema_id] = o.[schema_id]
 WHERE s.database_id = DB_ID()
   AND i.index_id != 0
   AND s.record_count > 0
   AND o.is_ms_shipped = 0;'

SELECT @RebuildIndexesSQL += 
       CASE WHEN [Fragmentation%] > 30
            THEN CHAR(10) + 'ALTER INDEX ' + QUOTENAME(IndexName) + ' ON '
                 + QUOTENAME(SchemaName) + '.'
                 + QUOTENAME(TableName) + ' REBUILD;'
	       WHEN [Fragmentation%] > 10
            THEN CHAR(10) + 'ALTER INDEX ' + QUOTENAME(IndexName) + ' ON '
                 + QUOTENAME(SchemaName) + '.'
                 + QUOTENAME(TableName) + ' REORGANIZE;'
	  END
  FROM #FragmentedIndexes
 WHERE [Fragmentation%] > 10;

WHILE (@StartOffset < LEN(@RebuildIndexesSQL))
BEGIN
	PRINT SUBSTRING(@RebuildIndexesSQL, @StartOffset, @Length);
	SET @StartOffset += @Length;
END

PRINT SUBSTRING(@RebuildIndexesSQL, @StartOffset, @Length);

EXECUTE sp_executesql @RebuildIndexesSQL;
GO

-- Listing 10.5 Intelligently update statistics—simple version
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

DECLARE @Length INT = 4000,
        @StartOffset INT = 0,
        @UpdateStatisticsSQL NVARCHAR(MAX) = '';

IF OBJECT_ID('tempdb..#IndexUsage', 'U') IS NOT NULL DROP TABLE #IndexUsage;

SELECT ss.name AS SchemaName,
       st.name AS TableName,
       si.name AS IndexName,
       si.type_desc AS IndexType,
       STATS_DATE(si.object_id,si.index_id) AS StatsLastTaken,
       ssi.rowcnt,
       ssi.rowmodctr
  INTO #IndexUsage
  FROM sys.indexes AS si
       INNER JOIN sys.sysindexes AS ssi ON si.object_id = ssi.id
              AND si.name = ssi.name
       INNER JOIN sys.tables AS st ON st.[object_id] = si.[object_id]
       INNER JOIN sys.schemas AS ss ON ss.[schema_id] = st.[schema_id]
 WHERE st.is_ms_shipped = 0
   AND si.index_id != 0
   AND ssi.rowcnt > 100
   AND ssi.rowmodctr > 0;

SELECT @UpdateStatisticsSQL +=
	  + CHAR(10) + 'UPDATE STATISTICS '
	  + QUOTENAME(SchemaName) + '.' + QUOTENAME(TableName)
	  + ' ' + QUOTENAME(IndexName) + ' WITH SAMPLE '
	  + CASE WHEN rowcnt < 500000 THEN '100 PERCENT'
              WHEN rowcnt < 1000000 THEN '50 PERCENT'
              WHEN rowcnt < 5000000 THEN '25 PERCENT'
              WHEN rowcnt < 10000000 THEN '10 PERCENT'
              WHEN rowcnt < 50000000 THEN '2 PERCENT'
              WHEN rowcnt < 100000000 THEN '1 PERCENT'
              ELSE '3000000 ROWS '
	    END
       + '-- '
	  + CAST(rowcnt AS VARCHAR(22))
	  + ' rows'
  FROM #IndexUsage;

WHILE (@StartOffset < LEN(@UpdateStatisticsSQL))
BEGIN
	PRINT SUBSTRING(@UpdateStatisticsSQL, @StartOffset, @Length);
	SET @StartOffset += @Length;
END

PRINT SUBSTRING(@UpdateStatisticsSQL, @StartOffset, @Length);

EXECUTE sp_executesql @UpdateStatisticsSQL;
GO

-- Listing 10.6 Intelligently update statistics—time-based version
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

DECLARE @StatsMarker NVARCHAR(2000),
        @SamplingComplete BIT = 0,
        @RowsToSample BIGINT = 0,
        @RowsToBenchMark BIGINT = 500,
        @TotalStatsTime BIGINT,
        @StartTime DATETIME,
        @TimePerRow FLOAT,
	   @ErrorMsg VARCHAR(200),
        @MaxSamplingTimeInSeconds INT = 600, -- 10 mins
        @WorkIsWithinTimeLimit BIT = 0,
        @TotalTimeForAllStats INT,
        @ReduceFraction FLOAT = 1.0,
        @ReduceFractionSmall FLOAT = 1.0,
        @UpdateStatisticsSQL NVARCHAR(MAX) = '',
        @StartOffset INT = 0,
        @Length INT = 4000;

IF OBJECT_ID('tempdb..#IndexUsage', 'U') IS NOT NULL DROP TABLE #IndexUsage;

IF EXISTS
(
SELECT 1
  FROM sys.indexes AS si
       INNER JOIN sys.sysindexes AS ssi ON si.object_id = ssi.id
              AND si.name = ssi.name
       INNER JOIN sys.tables AS st ON st.[object_id] = si.[object_id]
       INNER JOIN sys.schemas AS ss ON ss.[schema_id] = st.[schema_id]
 WHERE st.is_ms_shipped = 0
   AND si.index_id != 0
   AND ssi.rowcnt > 100
   AND ssi.rowmodctr > 0
)
BEGIN
     WHILE (@SamplingComplete = 0)
     BEGIN
	     SELECT TOP 1 @StatsMarker
                 = 'UPDATE STATISTICS '
                 + QUOTENAME(ss.name) + '.' + QUOTENAME(st.name)
                 + ' ' + QUOTENAME(si.name) + ' WITH SAMPLE '
                 + CAST(@RowsToBenchMark AS VARCHAR(22)) + ' ROWS'
	       FROM sys.indexes AS si
                 INNER JOIN sys.sysindexes AS ssi ON si.object_id = ssi.id
                        AND si.name = ssi.name
                 INNER JOIN sys.tables AS st ON st.[object_id] = si.[object_id]
                 INNER JOIN sys.schemas AS ss ON ss.[schema_id] = st.[schema_id]
           WHERE st.is_ms_shipped = 0 -- User tables only
             AND si.index_id != 0 -- ignore heaps
             AND ssi.rowcnt > @RowsToBenchMark
	      ORDER BY ssi.rowcnt;
	
	     IF @@ROWCOUNT > 0
	     BEGIN
	     	PRINT 'Testing sampling time with: ' + @StatsMarker;
	     	
	     	SET @StartTime = GETDATE();
	     	
	     	EXECUTE sp_executesql @StatsMarker;
	     	
	     	SET @TotalStatsTime = DATEDIFF(SECOND, @StartTime, GETDATE());
	     	PRINT '@TotalStatsTime: ' + CAST(@TotalStatsTime AS VARCHAR(22));
	     	
	     	IF (@TotalStatsTime > 5)
	     	BEGIN
	     		SET @TimePerRow = @TotalStatsTime / (@RowsToBenchMark * 1.0);
	     		PRINT @TimePerRow;
	     		SET @SamplingComplete = 1;
	     	END
	     	ELSE
	     		SET @RowsToBenchMark = @RowsToBenchMark * 10;
	     END
	     ELSE
	     BEGIN
	     	SET @ErrorMsg = 'No indexes found with @RowsToBenchMark > ' + CAST(@RowsToBenchMark AS VARCHAR(22));
	     	RAISERROR(@ErrorMsg, 16, 1);
	     	RETURN;
	     END
     END -- End of Whileloop#1

     SELECT ss.name AS SchemaName,
            st.name AS TableName,
            si.name AS IndexName,
            si.type_desc AS IndexType,
            STATS_DATE(si.object_id,si.index_id) AS StatsLastTaken,
            ssi.rowcnt,
            ssi.rowmodctr,
            @RowsToSample AS RowsToSample
       INTO #IndexUsage
       FROM sys.indexes AS si
            INNER JOIN sys.sysindexes AS ssi ON si.object_id = ssi.id
                   AND si.name = ssi.name
            INNER JOIN sys.tables AS st ON st.[object_id] = si.[object_id]
            INNER JOIN sys.schemas AS ss ON ss.[schema_id] = st.[schema_id]
      WHERE st.is_ms_shipped = 0
        AND si.index_id != 0
        AND ssi.rowcnt > 100
        AND ssi.rowmodctr > 0;
     
     UPDATE #IndexUsage
        SET RowsToSample = IIF(rowcnt < 100000000, rowcnt, 3000000);

     WHILE (@WorkIsWithinTimeLimit = 0)
     BEGIN
     	UPDATE #IndexUsage
     	   SET RowsToSample = CASE
     		                 	  WHEN rowcnt < 500000 THEN rowcnt * @ReduceFractionSmall
     		                 	  WHEN rowcnt < 1000000 THEN rowcnt / 2 * @ReduceFractionSmall
     		                 	  WHEN rowcnt < 5000000 THEN rowcnt / 4 * @ReduceFractionSmall
     		                 	  WHEN rowcnt < 10000000 THEN rowcnt / 10 * @ReduceFraction
     		                 	  WHEN rowcnt < 50000000 THEN rowcnt / 50 * @ReduceFraction
     		                 	  WHEN rowcnt < 100000000 THEN rowcnt / 100 * @ReduceFraction
     		                 	  ELSE 3000000 * @ReduceFraction
     		                 END;
     		
     	SELECT @TotalTimeForAllStats = SUM(RowsToSample) * @TimePerRow
     	  FROM #IndexUsage;
     	
     	PRINT '@TotalTimeForAllStats: ' + CAST(@TotalTimeForAllStats AS VARCHAR(22));
     	
     	IF (@TotalTimeForAllStats < @MaxSamplingTimeInSeconds)
     		SET @WorkIsWithinTimeLimit = 1;
     	ELSE
     	BEGIN
     		SET @ReduceFraction -= 0.01;
     		SET @ReduceFractionSmall -= 0.001;
     	END
     END -- End of Whileloop#2

     SELECT @UpdateStatisticsSQL = @UpdateStatisticsSQL
     	                       + CHAR(10) + 'UPDATE STATISTICS ' + QUOTENAME(SchemaName)
     	                       + '.' + QUOTENAME(TableName)
     	                       + ' ' + QUOTENAME(IndexName) + ' WITH SAMPLE '
     	                       + CAST(RowsToSample AS VARCHAR(22)) + ' ROWS '
       FROM #IndexUsage;
     
     WHILE (@StartOffset < LEN(@UpdateStatisticsSQL))
     BEGIN
     	PRINT SUBSTRING(@UpdateStatisticsSQL, @StartOffset, @Length);
     	SET @StartOffset += @Length;
     END -- End of Whileloop#3
     
     PRINT SUBSTRING(@UpdateStatisticsSQL, @StartOffset, @Length);
     
     EXECUTE sp_executesql @UpdateStatisticsSQL;
END
GO

-- Listing 10.7 Update statistics used by a SQL routine or a time interval
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

DECLARE @StartOffset INT = 0,
        @Length INT = 4000,
        @UpdateStatisticsSQL NVARCHAR(MAX) = '';

IF OBJECT_ID('tempdb..#IndexUsage', 'U') IS NOT NULL DROP TABLE #IndexUsage;
IF OBJECT_ID('tempdb..#IndexStatsPre', 'U') IS NOT NULL DROP TABLE #IndexStatsPre;
IF OBJECT_ID('tempdb..#IndexStatsPost', 'U') IS NOT NULL DROP TABLE #IndexStatsPost;

SELECT SchemaName = ss.name,
       TableName = st.name,
       IndexName = si.name,
       si.type_desc AS IndexType,
       user_updates = ISNULL(ius.user_updates, 0),
       user_seeks = ISNULL(ius.user_seeks, 0),
       user_scans = ISNULL(ius.user_scans, 0),
       user_lookups = ISNULL(ius.user_lookups, 0),
       ssi.rowcnt,
       ssi.rowmodctr
  INTO #IndexStatsPre
  FROM sys.dm_db_index_usage_stats AS ius
       RIGHT JOIN sys.indexes AS si ON ius.[object_id] = si.[object_id]
              AND ius.index_id = si.index_id
       INNER JOIN sys.sysindexes AS ssi ON si.object_id = ssi.id
              AND si.name = ssi.name
       INNER JOIN sys.tables AS st ON st.[object_id] = si.[object_id]
       INNER JOIN sys.schemas AS ss ON ss.[schema_id] = st.[schema_id]
 WHERE ius.database_id = DB_ID()
   AND st.is_ms_shipped = 0;
	
WAITFOR DELAY '00:10:00';

SELECT SchemaName = ss.name,
       TableName = st.name,
       IndexName = si.name,
       si.type_desc AS IndexType,
       user_updates = ISNULL(ius.user_updates, 0),
       user_seeks = ISNULL(ius.user_seeks, 0),
       user_scans = ISNULL(ius.user_scans, 0),
       user_lookups = ISNULL(ius.user_lookups, 0),
       ssi.rowcnt,
       ssi.rowmodctr
  INTO #IndexStatsPost
  FROM sys.dm_db_index_usage_stats AS ius
       RIGHT JOIN sys.indexes AS si ON ius.[object_id] = si.[object_id]
              AND ius.index_id = si.index_id
       INNER JOIN sys.sysindexes AS ssi ON si.object_id = ssi.id
              AND si.name = ssi.name
       INNER JOIN sys.tables AS st ON st.[object_id] = si.[object_id]
       INNER JOIN sys.schemas AS ss ON ss.[schema_id] = st.[schema_id]
 WHERE ius.database_id = DB_ID()
   AND st.is_ms_shipped = 0;
	
SELECT po.[SchemaName],
       po.[TableName],
       po.[IndexName],
       po.rowcnt,
       po.[IndexType],
       [User Updates] = po.user_updates - ISNULL(pr.user_updates, 0),
       [User Seeks] = po.user_seeks - ISNULL(pr.user_seeks, 0),
       [User Scans] = po.user_scans - ISNULL(pr.user_scans, 0),
       [User Lookups] = po.user_lookups - ISNULL(pr.user_lookups, 0),
       [Rows Inserted] = po.rowcnt - ISNULL(pr.rowcnt, 0),
       [Updates I/U/D] = po.rowmodctr - ISNULL(pr.rowmodctr, 0)
  INTO #IndexUsage
  FROM #IndexStatsPost po
       LEFT JOIN #IndexStatsPre pr ON pr.SchemaName = po.SchemaName
             AND pr.TableName = po.TableName
             AND pr.IndexName = po.IndexName
             AND pr.IndexType = po.IndexType
 WHERE ISNULL(pr.user_updates, 0) != po.user_updates
    OR ISNULL(pr.user_seeks, 0) != po.user_seeks
    OR ISNULL(pr.user_scans, 0) != po.user_scans
    OR ISNULL(pr.user_lookups, 0) != po.user_lookups;

SELECT @UpdateStatisticsSQL +=
	                       + CHAR(10) + 'UPDATE STATISTICS ' + QUOTENAME(SchemaName)
	                       + '.' + QUOTENAME(TableName)
	                       + ' ' + QUOTENAME(IndexName) + ' WITH SAMPLE '
	                       + CASE
                                   WHEN rowcnt < 500000 THEN '100 PERCENT'
                                   WHEN rowcnt < 1000000 THEN '50 PERCENT'
                                   WHEN rowcnt < 5000000 THEN '25 PERCENT'
                                   WHEN rowcnt < 10000000 THEN '10 PERCENT'
                                   WHEN rowcnt < 50000000 THEN '2 PERCENT'
                                   WHEN rowcnt < 100000000 THEN '1 PERCENT'
                                   ELSE '3000000 ROWS '
	                         END
  FROM #IndexUsage
 WHERE [User Seeks] != 0
    OR [User Scans] != 0
    OR [User Lookups] != 0;

WHILE (@StartOffset < LEN(@UpdateStatisticsSQL))
BEGIN
	PRINT SUBSTRING(@UpdateStatisticsSQL, @StartOffset, @Length);
	SET @StartOffset += @Length;
END

PRINT SUBSTRING(@UpdateStatisticsSQL, @StartOffset, @Length);

EXECUTE sp_executesql @UpdateStatisticsSQL;
GO

-- Listing 10.8 Automatically create any missing indexes
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

DECLARE @Length INT = 4000,
        @StartOffset INT = 0,
        @MissingIndexesSQL NVARCHAR(MAX) = '';

IF OBJECT_ID('tempdb..#MissingIndexes', 'U') IS NOT NULL DROP TABLE #MissingIndexes;

SELECT TOP 20
       'CREATE NONCLUSTERED INDEX '
       + QUOTENAME('IX_AutoGenerated_'
       + REPLACE(REPLACE(CONVERT(VARCHAR(25), GETDATE(), 113), ' ', '_'), ':', '_')
       + '_' + CAST(d.index_handle AS VARCHAR(22))
       )
       + ' ON ' + d.[statement]
       + '('
       + CASE
             WHEN d.equality_columns IS NULL THEN d.inequality_columns
             WHEN d.inequality_columns IS NULL THEN d.equality_columns
             ELSE d.equality_columns + ',' + d.inequality_columns
         END
       + ')'
       + IIF(d.included_columns IS NOT NULL, ' INCLUDE (' + d.included_columns + ')', '') AS MissingIndexSQL,
       ROUND(s.avg_total_user_cost * s.avg_user_impact * (s.user_seeks + s.user_scans),0) AS [Total Cost],
       d.[statement] AS [Table Name],
       d.equality_columns,
       d.inequality_columns,
       d.included_columns
  INTO #MissingIndexes
  FROM sys.dm_db_missing_index_groups AS g
       INNER JOIN sys.dm_db_missing_index_group_stats AS s ON s.group_handle = g.index_group_handle
       INNER JOIN sys.dm_db_missing_index_details AS d ON d.index_handle = g.index_handle
 ORDER BY [Total Cost] DESC;

SELECT @MissingIndexesSQL += MissingIndexSQL + CHAR(10)
  FROM #MissingIndexes;

WHILE (@StartOffset < LEN(@MissingIndexesSQL))
BEGIN
	PRINT SUBSTRING(@MissingIndexesSQL, @StartOffset, @Length);
	SET @StartOffset += @Length;
END

PRINT SUBSTRING(@MissingIndexesSQL, @StartOffset, @Length);

EXECUTE sp_executesql @MissingIndexesSQL;
GO

-- Listing 10.9 Automatically disable or drop unused indexes
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

DECLARE @Length INT = 4000,
        @StartOffset INT = 0,
	   @DisableOrDrop INT = 1,
        @DisableIndexesSQL NVARCHAR(MAX) = '';

IF OBJECT_ID('tempdb..#TempUnusedIndexes', 'U') IS NOT NULL DROP TABLE #TempUnusedIndexes;

SELECT DB_NAME() AS DatabaseName,
       SCHEMA_NAME(o.Schema_ID) AS SchemaName,
       OBJECT_NAME(s.[object_id]) AS TableName,
       i.name AS IndexName,
       s.user_updates,
       s.system_seeks + s.system_scans + s.system_lookups AS [System usage]
  INTO #TempUnusedIndexes
  FROM sys.dm_db_index_usage_stats AS s
       INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
              AND s.index_id = i.index_id
       INNER JOIN sys.objects AS o ON i.object_id = O.object_id
WHERE 1 = 2;

EXEC sp_MSForEachDB '
USE [?];
INSERT INTO #TempUnusedIndexes
SELECT TOP 20
       DB_NAME() AS DatabaseName,
       SCHEMA_NAME(o.Schema_ID) AS SchemaName,
       OBJECT_NAME(s.[object_id]) AS TableName,
       i.name AS IndexName,
       s.user_updates,
       s.system_seeks + s.system_scans + s.system_lookups AS [System usage]
  FROM sys.dm_db_index_usage_stats AS s
       INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
              AND s.index_id = i.index_id
       INNER JOIN sys.objects AS o ON i.object_id = O.object_id
 WHERE s.database_id = DB_ID()
   AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
   AND user_seeks = 0
   AND user_scans = 0
   AND user_lookups = 0
   AND i.name IS NOT NULL
 ORDER BY user_updates DESC;'

SELECT @DisableIndexesSQL +=
                             CASE
                                  WHEN @DisableOrDrop = 1
                                  THEN CHAR(10) + 'ALTER INDEX ' + QUOTENAME(IndexName) + ' ON '
                                     + QUOTENAME(DatabaseName) + '.'+ QUOTENAME(SchemaName) + '.'
                                     + QUOTENAME(TableName) + ' DISABLE;'
                                  ELSE CHAR(10) + 'DROP INDEX ' + QUOTENAME(IndexName) + ' ON '
                                     + QUOTENAME(DatabaseName) + '.'+ QUOTENAME(SchemaName) + '.'
                                     + QUOTENAME(TableName)
                             END
  FROM #TempUnusedIndexes;

WHILE (@StartOffset < LEN(@DisableIndexesSQL))
BEGIN
	PRINT SUBSTRING(@DisableIndexesSQL, @StartOffset, @Length);
	SET @StartOffset += @Length;
END

PRINT SUBSTRING(@DisableIndexesSQL, @StartOffset, @Length);

EXECUTE sp_executesql @DisableIndexesSQL;
GO

-- Listing 11.1 Finding everyone’s last-run query
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT c.session_id,
       s.host_name,
       s.login_name,
       s.status,
       st.text,
       s.login_time,
       s.program_name,
       *
  FROM sys.dm_exec_connections AS c
       INNER JOIN sys.dm_exec_sessions AS s ON c.session_id = s.session_id
       CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle) AS st
 ORDER BY c.session_id;

-- Listing 11.2 Generic performance test harness
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PreWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkQuerySnapShot;
IF OBJECT_ID('tempdb..#PostWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkQuerySnapShot;

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PreWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

EXEC PutYourQueryHere

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PostWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

SELECT p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0) AS [Duration],
       p2.total_worker_time - ISNULL(p1.total_worker_time, 0) AS [Time on CPU],
       (p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) - (p2.total_worker_time - ISNULL(p1.total_worker_time, 0)) AS [Time blocked],
       p2.total_logical_reads - ISNULL(p1.total_logical_reads, 0) AS [Reads],
       p2.total_logical_writes - ISNULL(p1.total_logical_writes, 0) AS [Writes],
       p2.total_clr_time - ISNULL(p1.total_clr_time, 0) AS [CLR time],
       p2.execution_count - ISNULL(p1.execution_count, 0) AS [Executions],
       SUBSTRING (qt.text,
	             p2.statement_start_offset/2 + 1,
	             (
			    (CASE WHEN p2.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE p2.statement_end_offset END - p2.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName
  FROM #PreWorkQuerySnapShot AS p1
       RIGHT JOIN #PostWorkQuerySnapShot AS p2 ON p2.sql_handle =ISNULL(p1.sql_handle, p2.sql_handle)
              AND p2.plan_handle = ISNULL(p1.plan_handle, p2.plan_handle)
              AND p2.statement_start_offset =ISNULL(p1.statement_start_offset, p2.statement_start_offset)
              AND p2.statement_end_offset =ISNULL(p1.statement_end_offset, p2.statement_end_offset)
       CROSS APPLY sys.dm_exec_sql_text(p2.sql_handle) AS qt
 WHERE p2.execution_count != ISNULL(p1.execution_count, 0)
 ORDER BY qt.text, p2.statement_start_offset;

-- Listing 11.3 Determining the performance impact of a system upgrade
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PreWork', 'U') IS NOT NULL DROP TABLE #PreWork;
IF OBJECT_ID('tempdb..#PostWork', 'U') IS NOT NULL DROP TABLE #PostWork;

SELECT total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset,
       sql_handle,
       plan_handle
  INTO #prework
  FROM sys.dm_exec_query_stats;

EXEC PutYourWorkloadHere;

SELECT total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset,
       sql_handle,
       plan_handle
  INTO #postwork
  FROM sys.dm_exec_query_stats;

SELECT SUM(p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) AS [TotalDuration],
       SUM(p2.total_worker_time - ISNULL(p1.total_worker_time, 0)) AS [Total Time on CPU],
       SUM((p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) - (p2.total_worker_time - ISNULL(p1.total_worker_time, 0))) AS [Total Time Waiting],
       SUM(p2.total_logical_reads - ISNULL(p1.total_logical_reads, 0)) AS [TotalReads],
       SUM(p2.total_logical_writes - ISNULL(p1.total_logical_writes, 0)) AS [TotalWrites],
       SUM(p2.total_clr_time - ISNULL(p1.total_clr_time, 0)) AS [Total CLR time],
       SUM(p2.execution_count - ISNULL(p1.execution_count, 0)) AS [Total Executions],
       DB_NAME(qt.dbid) AS DatabaseName
  FROM #prework AS p1
       RIGHT JOIN #postwork AS p2 ON p2.sql_handle = ISNULL(p1.sql_handle, p2.sql_handle)
              AND p2.plan_handle = ISNULL(p1.plan_handle, p2.plan_handle)
              AND p2.statement_start_offset =ISNULL(p1.statement_start_offset, p2.statement_start_offset)
              AND p2.statement_end_offset =ISNULL(p1.statement_end_offset, p2.statement_end_offset)
       CROSS APPLY sys.dm_exec_sql_text(p2.sql_handle) AS qt
 WHERE p2.execution_count != ISNULL(p1.execution_count, 0)
 GROUP BY DB_NAME(qt.dbid);

SELECT SUM(p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) AS [TotalDuration],
       SUM(p2.total_worker_time - ISNULL(p1.total_worker_time, 0)) AS [Total Time on CPU],
       SUM((p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) - (p2.total_worker_time - ISNULL(p1.total_worker_time, 0))) AS [Total Time Waiting],
       SUM(p2.total_logical_reads - ISNULL(p1.total_logical_reads, 0)) AS [TotalReads],
       SUM(p2.total_logical_writes - ISNULL(p1.total_logical_writes, 0)) AS [TotalWrites],
       SUM(p2.total_clr_time - ISNULL(p1.total_clr_time, 0)) AS [Total CLR time],
       SUM(p2.execution_count - ISNULL(p1.execution_count, 0)) AS [Total Executions],
       DB_NAME(qt.dbid) AS DatabaseName,
       qt.text AS [Parent Query]
  FROM #prework AS p1
       RIGHT JOIN #postwork AS p2 ON p2.sql_handle = ISNULL(p1.sql_handle, p2.sql_handle)
              AND p2.plan_handle = ISNULL(p1.plan_handle, p2.plan_handle)
              AND p2.statement_start_offset =ISNULL(p1.statement_start_offset, p2.statement_start_offset)
              AND p2.statement_end_offset =ISNULL(p1.statement_end_offset, p2.statement_end_offset)
       CROSS APPLY sys.dm_exec_sql_text(p2.sql_handle) AS qt
 WHERE p2.execution_count != ISNULL(p1.execution_count, 0)
 GROUP BY DB_NAME(qt.dbid), qt.text
 ORDER BY [TotalDuration] DESC;

SELECT p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0) AS [TotalDuration],
       p2.total_worker_time - ISNULL(p1.total_worker_time, 0) AS [Total Time on CPU],
       (p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) - (p2.total_worker_time - ISNULL(p1.total_worker_time, 0)) AS [Total Time Waiting],
       p2.total_logical_reads - ISNULL(p1.total_logical_reads, 0) AS [TotalReads],
       p2.total_logical_writes - ISNULL(p1.total_logical_writes, 0) AS [TotalWrites],
       p2.total_clr_time - ISNULL(p1.total_clr_time, 0) AS [Total CLR time],
       p2.execution_count - ISNULL(p1.execution_count, 0) AS [Total Executions],
       SUBSTRING (qt.text,
	             p2.statement_start_offset/2 + 1,
	             (
			    (CASE WHEN p2.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE p2.statement_end_offset END - p2.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName
  FROM #prework AS p1
       RIGHT JOIN #postwork AS p2 ON p2.sql_handle = ISNULL(p1.sql_handle, p2.sql_handle)
              AND p2.plan_handle = ISNULL(p1.plan_handle, p2.plan_handle)
              AND p2.statement_start_offset = ISNULL(p1.statement_start_offset, p2.statement_start_offset)
              AND p2.statement_end_offset = ISNULL(p1.statement_end_offset, p2.statement_end_offset)
       CROSS APPLY sys.dm_exec_sql_text(p2.sql_handle) AS qt
 WHERE p2.execution_count != ISNULL(p1.execution_count, 0)
 ORDER BY [TotalDuration] DESC;

-- Listing 11.4 Estimating when a job will finish
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT r.percent_complete,
       DATEDIFF(MINUTE, start_time, GETDATE()) AS Age,
       DATEADD(MINUTE, DATEDIFF(MINUTE, start_time, GETDATE()) / percent_complete * 100, start_time) AS EstimatedEndTime,
       t.Text AS ParentQuery,
       SUBSTRING (t.text,
	             r.statement_start_offset/2 + 1,
                  (
			    (CASE WHEN r.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), t.text)) * 2 ELSE r.statement_end_offset END - r.statement_start_offset)/2
			   ) + 1
			  ) AS IndividualQuery,
       start_time,
       DB_NAME(Database_Id) AS DatabaseName,
       Status
  FROM sys.dm_exec_requests AS r
       CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS t
 WHERE session_id > 50
   AND percent_complete > 0
 ORDER BY percent_complete DESC;

-- Listing 11.5 Who’s doing what and when?
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('dbo.WhatsGoingOnHistory', 'U') IS NOT NULL DROP TABLE dbo.WhatsGoingOnHistory;
CREATE TABLE dbo.WhatsGoingOnHistory
(
 Runtime            DATETIME     NOT NULL,
 session_id         SMALLINT     NOT NULL,
 login_name         VARCHAR(128) NOT NULL,
 host_name          VARCHAR(128) NULL,
 DBName             VARCHAR(128) NULL,
 [Individual Query] VARCHAR(max) NULL,
 [Parent Query]     VARCHAR(200) NULL,
 status             VARCHAR(30)  NULL,
 start_time         DATETIME     NULL,
 wait_type          VARCHAR(60)  NULL,
 program_name       VARCHAR(128) NULL
);

CREATE UNIQUE NONCLUSTERED INDEX IX_NC_U_WhatsGoingOnHistory ON dbo.WhatsGoingOnHistory
([Runtime] ASC, [session_id] ASC);

INSERT INTO dbo.WhatsGoingOnHistory
SELECT GETDATE(),
       s.session_id,
       s.login_name,
       s.host_name,
       DB_NAME(r.database_id) AS DBName,
       SUBSTRING (t.text,
	             r.statement_start_offset/2 + 1,
                  (
			    (CASE WHEN r.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), t.text)) * 2 ELSE r.statement_end_offset END - r.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       SUBSTRING(text, 1, 200) AS [Parent Query],
       r.status,
       r.start_time,
       r.wait_type,
       s.program_name
  FROM sys.dm_exec_sessions AS s
       INNER JOIN sys.dm_exec_connections AS c ON s.session_id = c.session_id
       INNER JOIN sys.dm_exec_requests AS r ON c.connection_id = r.connection_id
       CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
 WHERE s.session_id > 50
   AND r.session_id != @@spid;
	
WAITFOR DELAY '00:01:00';
GO 1440; -- 60 * 24 (one day)

-- Listing 11.6 Determining where your query spends its time
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PreWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkQuerySnapShot;
IF OBJECT_ID('tempdb..#PostWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkQuerySnapShot;

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PreWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

EXEC PutYourQueryHere;

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset,
       last_execution_time
  INTO #PostWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

SELECT p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0) AS [Duration],
       p2.total_worker_time - ISNULL(p1.total_worker_time, 0) AS [Time on CPU],
       (p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) - (p2.total_worker_time - ISNULL(p1.total_worker_time, 0)) AS [Time waiting],
       p2.total_logical_reads - ISNULL(p1.total_logical_reads, 0) AS [Reads],
       p2.total_logical_writes - ISNULL(p1.total_logical_writes, 0) AS [Writes],
       p2.total_clr_time - ISNULL(p1.total_clr_time, 0) AS [CLR time],
       p2.execution_count - ISNULL(p1.execution_count, 0) AS [Executions],
       p2.last_execution_time,
       SUBSTRING (qt.text,
	             p2.statement_start_offset/2 + 1,
	             (
			    (CASE WHEN p2.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE p2.statement_end_offset END - p2.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName
  FROM #PreWorkQuerySnapShot AS p1
       RIGHT JOIN #PostWorkQuerySnapShot AS p2 ON p2.sql_handle = ISNULL(p1.sql_handle, p2.sql_handle)
              AND p2.plan_handle = ISNULL(p1.plan_handle, p2.plan_handle)
              AND p2.statement_start_offset = ISNULL(p1.statement_start_offset, p2.statement_start_offset)
              AND p2.statement_end_offset = ISNULL(p1.statement_end_offset, p2.statement_end_offset)
       CROSS APPLY sys.dm_exec_sql_text(p2.sql_handle) AS qt
 WHERE p2.execution_count != ISNULL(p1.execution_count, 0)
   AND qt.text LIKE '%PNLYearToDate_v01iws %'
 ORDER BY [Parent Query], p2.statement_start_offset;

-- Listing 11.7 Memory used per database
SET TRAN ISOLATION LEVEL READ UNCOMMITTED

SET NOCOUNT ON;

SELECT ISNULL(DB_NAME(database_id), 'ResourceDb') AS DatabaseName,
       CAST(COUNT(row_count) * 8.0 / (1024.0) AS DECIMAL(28,2)) AS [Size (MB)]
  FROM sys.dm_os_buffer_descriptors
 GROUP BY database_id
 ORDER BY DatabaseName;

-- Listing 11.8 Memory used by objects in the current database
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

SELECT OBJECT_NAME(p.[object_id]) AS [TableName],
       (COUNT(*) * 8) / 1024 AS [Buffer size(MB)],
       ISNULL(i.name, '-- HEAP --') AS ObjectName,
       COUNT(*) AS NumberOf8KPages
  FROM sys.allocation_units AS a
       INNER JOIN sys.dm_os_buffer_descriptors AS b ON a.allocation_unit_id = b.allocation_unit_id
       INNER JOIN sys.partitions AS p ON a.container_id = p.hobt_id
       INNER JOIN sys.indexes i ON p.index_id = i.index_id
              AND p.[object_id] = i.[object_id]
 WHERE b.database_id = DB_ID()
   AND p.[object_id] > 100
 GROUP BY p.[object_id], i.name;

-- Listing 11.9 I/O stalls at the database level
SET TRAN ISOLATION LEVEL READ UNCOMMITTED

SET NOCOUNT ON;

SELECT DB_NAME(database_id) AS [DatabaseName],
       SUM(CAST(io_stall / 1000.0 AS DECIMAL(20,2))) AS [IO stall (secs)],
       SUM(CAST(num_of_bytes_read / 1024.0 / 1024.0 AS DECIMAL(20,2))) AS [IO read (MB)],
       SUM(CAST(num_of_bytes_written / 1024.0 / 1024.0 AS DECIMAL(20,2))) AS [IO written (MB)],
       SUM(CAST((num_of_bytes_read + num_of_bytes_written) / 1024.0 / 1024.0 AS DECIMAL(20,2))) AS [TotalIO (MB)]
  FROM sys.dm_io_virtual_file_stats(NULL, NULL)
 GROUP BY database_id
 ORDER BY [IO stall (secs)] DESC;

-- Listing 11.10 I/O stalls at the file level
SET TRAN ISOLATION LEVEL READ UNCOMMITTED

SET NOCOUNT ON;

SELECT DB_NAME(database_id) AS [DatabaseName],
       file_id,
       SUM(CAST(io_stall / 1000.0 AS DECIMAL(20,2))) AS [IO stall (secs)],
       SUM(CAST(num_of_bytes_read / 1024.0 / 1024.0 AS DECIMAL(20,2))) AS [IO read (MB)],
       SUM(CAST(num_of_bytes_written / 1024.0 / 1024.0 AS DECIMAL(20,2))) AS [IO written (MB)],
       SUM(CAST((num_of_bytes_read + num_of_bytes_written) / 1024.0 / 1024.0 AS DECIMAL(20,2))) AS [TotalIO (MB)]
  FROM sys.dm_io_virtual_file_stats(NULL, NULL)
 GROUP BY database_id, file_id
 ORDER BY [IO stall (secs)] DESC;

-- Listing 11.11 Average read/write times per file, per database
SET TRAN ISOLATION LEVEL READ UNCOMMITTED

SET NOCOUNT ON;

SELECT DB_NAME(database_id) AS DatabaseName,
       file_id,
       io_stall_read_ms / num_of_reads AS 'Average read time',
       io_stall_write_ms / num_of_writes AS 'Average write time'
  FROM sys.dm_io_virtual_file_stats(NULL, NULL)
 WHERE num_of_reads > 0 and num_of_writes > 0
 ORDER BY DatabaseName;

-- Listing 11.12 Simple trace utility
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#PreWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PreWorkQuerySnapShot;
IF OBJECT_ID('tempdb..#PostWorkQuerySnapShot', 'U') IS NOT NULL DROP TABLE #PostWorkQuerySnapShot;

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset
  INTO #PreWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

WAITFOR DELAY '00:01:00';

SELECT sql_handle,
       plan_handle,
       total_elapsed_time,
       total_worker_time ,
       total_logical_reads,
       total_logical_writes,
       total_clr_time,
       execution_count,
       statement_start_offset,
       statement_end_offset,
       last_execution_time
  INTO #PostWorkQuerySnapShot
  FROM sys.dm_exec_query_stats;

SELECT p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0) AS [Duration],
       p2.total_worker_time - ISNULL(p1.total_worker_time, 0) AS [Time on CPU],
       (p2.total_elapsed_time - ISNULL(p1.total_elapsed_time, 0)) - (p2.total_worker_time - ISNULL(p1.total_worker_time, 0)) AS [Time waiting],
       p2.total_logical_reads - ISNULL(p1.total_logical_reads, 0) AS [Reads],
       p2.total_logical_writes - ISNULL(p1.total_logical_writes, 0) AS [Writes],
       p2.total_clr_time - ISNULL(p1.total_clr_time, 0) AS [CLR time],
       p2.execution_count - ISNULL(p1.execution_count, 0) AS [Executions],
       p2.last_execution_time,
       SUBSTRING (qt.text,
	             p2.statement_start_offset/2 + 1,
	             (
			    (CASE WHEN p2.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 ELSE p2.statement_end_offset END - p2.statement_start_offset)/2
			   ) + 1
			  ) AS [Individual Query],
       qt.text AS [Parent Query],
       DB_NAME(qt.dbid) AS DatabaseName
  FROM #PreWorkQuerySnapShot AS p1
       RIGHT JOIN #PostWorkQuerySnapShot AS p2 ON p2.sql_handle = ISNULL(p1.sql_handle, p2.sql_handle)
              AND p2.plan_handle = ISNULL(p1.plan_handle, p2.plan_handle)
              AND p2.statement_start_offset = ISNULL(p1.statement_start_offset, p2.statement_start_offset)
              AND p2.statement_end_offset = ISNULL(p1.statement_end_offset, p2.statement_end_offset)
       CROSS APPLY sys.dm_exec_sql_text(p2.sql_handle) AS qt
 WHERE p2.execution_count != ISNULL(p1.execution_count, 0)
 ORDER BY DatabaseName, [Parent Query], p2.statement_start_offset;