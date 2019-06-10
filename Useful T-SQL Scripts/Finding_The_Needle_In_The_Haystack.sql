/*
 ===============================================================================
 Author:	     Matan Yungman
 Source:       http://www.madeiradata.com/finding-the-needle-in-the-haystack/
 Article Name: Finding The Needle In The Haystack
 Create Date:  27-AUG-2012
 Description:  The following script receives the database name, schema name and
               the procedure name, and returns a table with all of its "child"
			procedures (and functions).
 Revision History:
 11-JUL-2017 - RAGHUNANDAN CUMBAKONAM
			Formatted the code.
			Added the history.
 Usage:		N/A			   
 ===============================================================================
*/

USE master
GO

SET NOCOUNT ON;

DECLARE @lvl INT = 0,
        @collation SYSNAME,
	   @cmd NVARCHAR(4000),
        @DatabaseName VARCHAR(100) = 'HPG_EDV',
        @SchemaName VARCHAR(100) = 'api_v1',
        @SPName VARCHAR(100) = 'USP_CONTRACTED_ITEM';

IF OBJECT_ID('tempdb..#dependencies') IS NOT NULL DROP TABLE #dependencies;
IF OBJECT_ID('tempdb..#allProcedures') IS NOT NULL DROP TABLE #allProcedures;

CREATE TABLE #dependencies
(
 CallingProcedureDB       VARCHAR(1000),
 CallingProcedureSchema   VARCHAR(1000),
 CallingProcedure         VARCHAR(1000),
 CallingProcedureObjectId INT,
 CalledProcedureDB        VARCHAR(1000),
 CalledProcedureSchema    VARCHAR(1000),
 CalledProcedure          VARCHAR(1000),
 CalledProcedureObjectId  INT,
 Lvl                      INT,
 Handled                  BIT
);

CREATE TABLE #allProcedures
(
 DBName     VARCHAR(1000),
 SchemaName VARCHAR(1000),
 SPName     VARCHAR(1000),
 ObjectId   INT
);

SELECT @collation = collation_name
  FROM sys.databases
 WHERE name = 'master';

--Populate the procedures table
EXEC sp_MSforeachdb '
INSERT INTO #allProcedures
SELECT ''?'',
       s.name,
       p.name,
       p.object_id
  FROM ?.sys.procedures AS p
       INNER JOIN ?.sys.schemas AS s ON p.schema_id = s.schema_id';

--Start the "recursive" process
INSERT INTO #dependencies
(
 CalledProcedureDB,
 CalledProcedureSchema,
 CalledProcedure,
 CalledProcedureObjectId,
 Lvl,
 Handled
)
SELECT @DatabaseName,
       @SchemaName,
       @SPName,
       OBJECT_ID(@SchemaName + '.' + @SPName),
       @lvl,
       0;

WHILE EXISTS
(
SELECT *
  FROM #dependencies
 WHERE Lvl = @lvl
   AND Handled = 0
)
BEGIN
    SET @cmd = 'INSERT INTO #dependencies
                SELECT d.CalledProcedureDB,
                       d.CalledProcedureSchema,
                       d.CalledProcedure,
                       d.CalledProcedureObjectId,
                       p.dbName,
                       p.SchemaName,
                       e.referenced_entity_name,
                       p.ObjectId,
                       ' + CAST(@lvl + 1 AS NVARCHAR(50)) + ',0
                  FROM #dependencies AS d
                       CROSS APPLY ?.sys.dm_sql_referenced_entities (CalledProcedureSchema + ''.'' + CalledProcedure, ''OBJECT'') AS e
                       INNER JOIN #allProcedures AS p ON e.referenced_entity_name collate ' + @collation + ' = p.SPName
                              AND ISNULL(e.referenced_database_name collate ' + @collation + ' ,CalledProcedureDB) = p.DBName
                 WHERE Lvl = ' + CAST(@lvl AS NVARCHAR(50));
    EXEC sp_MSForEachDB @cmd;

    UPDATE #dependencies
       SET Handled = 1
     WHERE Lvl = @lvl;

    SET @lvl += 1;
END;

;WITH CTE
AS
(
SELECT OBJECT_NAME(objectid) AS ProcedureName,
       objectid,
       dbid,
       AVG(total_elapsed_time / execution_count) / 1000 AS AvgElapsedTimeMS
  FROM sys.dm_exec_procedure_stats
       CROSS APPLY sys.dm_exec_sql_text(sql_handle)
 GROUP BY OBJECT_NAME(objectid),
          objectid,
          dbid
)
SELECT d.*,
       t.AvgElapsedTimeMS
  FROM #dependencies AS d
       LEFT JOIN CTE AS t ON d.CalledProcedureObjectId = t.objectid
             AND d.CalledProcedureDB = DB_NAME(t.dbid)
 ORDER BY d.lvl,
          d.CallingProcedure,
          d.CalledProcedure;