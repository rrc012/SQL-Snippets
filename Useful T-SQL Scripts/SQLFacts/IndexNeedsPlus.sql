/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

DECLARE @Last_Run datetime = CONVERT(datetime, '1900/01/01 00:00:00') -- minimum datetime of last run

DECLARE @BaseVersion varchar(1000) = CONVERT(varchar(1000), SERVERPROPERTY('ProductVersion'))

DECLARE @Information varchar(4000) = 'SQL Server '
+ CASE WHEN @BaseVersion LIKE  '8.%'  THEN '2000 '
       WHEN @BaseVersion LIKE  '9.%'  THEN '2005 '
       WHEN @BaseVersion LIKE '10.0%' THEN '2008 '
       WHEN @BaseVersion LIKE '10.5%' THEN '2008 R2 '
       WHEN @BaseVersion LIKE '11.%'  THEN '2012 '
       WHEN @BaseVersion LIKE '12.%'  THEN '2014 '
       WHEN @BaseVersion LIKE '13.%'  THEN '2016 '
       WHEN @BaseVersion LIKE '14.%'  THEN '2017 '
       WHEN @BaseVersion LIKE '15.%'  THEN '2019 '
       WHEN @BaseVersion LIKE '16.%'  THEN '2022 ' ELSE '20XX ' END
+ CONVERT(varchar(1000), SERVERPROPERTY('Edition')) + ' has been running since '
+ CONVERT(varchar(1000), (SELECT I.sqlserver_start_time FROM sys.dm_os_sys_info AS I), 120)

PRINT @Information

   SELECT E.DBName
        , E.SchemaName
        , E.ObjectName
        , E.ObjectType
        , E.query_plan
        , E.Creation
        , E.Last_Run
        , ROW_NUMBER() OVER (ORDER BY E.DBName, E.SchemaName, E.ObjectName, E.Creation, E.Last_Run) AS PlanID
        , CONVERT(bit, 0) AS PlanType
        , SUBSTRING(E.text, E.I, E.O - E.I) AS SQL_code
        ,           E.text                  AS SQL_code_all
     INTO #PlanX
     FROM
  (SELECT CONVERT(varchar(0040),       S.creation_time, 120) AS Creation
        , CONVERT(varchar(0040), S.last_execution_time, 120) AS Last_Run
        ,            DB_NAME(            V.dbid) AS DBName
        , OBJECT_SCHEMA_NAME(V.objectid, V.dbid) AS SchemaName
        ,        OBJECT_NAME(V.objectid, V.dbid) AS ObjectName
        ,                               SPACE(2) AS ObjectType
        , CASE WHEN S.statement_start_offset < 0 THEN     0                                                                                  ELSE S.statement_start_offset END / 2 + 1 AS I
        , CASE WHEN S.statement_end_offset   < 0 THEN LEN(T.text) * 2 WHEN S.statement_end_offset > LEN(T.text) * 2 - 4 THEN LEN(T.text) * 2 ELSE S.statement_end_offset   END / 2 + 1 AS O
        , T.text
        , CONVERT(nvarchar(max), V.query_plan) AS query_plan
     FROM sys.dm_exec_query_stats AS S OUTER APPLY sys.dm_exec_sql_text(S.sql_handle) AS T OUTER APPLY sys.dm_exec_query_plan(S.plan_handle) AS V) AS E
    WHERE E.DBName NOT IN ('msdb', 'master')
      AND E.ObjectType IN ('P ', 'V ', 'FN', 'IF', 'TF', 'TR', SPACE(2))
      AND E.query_plan LIKE '%<MissingIndexes>%'
      AND E.Last_Run
       !<  @Last_Run
 ORDER BY E.DBName
        , E.SchemaName
        , E.ObjectName
        , E.Creation
        , E.Last_Run

   INSERT #PlanX
   SELECT E.DBName
        , E.SchemaName
        , E.ObjectName
        , E.ObjectType
        , E.query_plan
        , E.Creation
        , E.Last_Run
        , ROW_NUMBER() OVER (ORDER BY E.DBName, E.SchemaName, E.ObjectName, E.Creation, E.Last_Run) AS PlanID
        , CONVERT(bit, 1) AS PlanType
        , SPACE(0) AS SQL_code
        , SPACE(0) AS SQL_code_all
     FROM
  (SELECT CONVERT(varchar(0040),         S.cached_time, 120) AS Creation
        , CONVERT(varchar(0040), S.last_execution_time, 120) AS Last_Run
        ,            DB_NAME(             S.database_id) AS DBName
        , OBJECT_SCHEMA_NAME(S.object_id, S.database_id) AS SchemaName
        ,        OBJECT_NAME(S.object_id, S.database_id) AS ObjectName
        ,                       ISNULL(S.type, SPACE(2)) AS ObjectType
        , CONVERT(nvarchar(max), V.query_plan) AS query_plan
     FROM sys.dm_exec_procedure_stats AS S OUTER APPLY sys.dm_exec_query_plan(S.plan_handle) AS V) AS E
    WHERE E.DBName NOT IN ('msdb', 'master')
      AND E.ObjectType IN ('P ', 'V ', 'FN', 'IF', 'TF', 'TR', SPACE(2))
      AND E.query_plan LIKE '%<MissingIndexes>%'
      AND E.Last_Run
       !<  @Last_Run
 ORDER BY E.DBName
        , E.SchemaName
        , E.ObjectName
        , E.Creation
        , E.Last_Run

/*

   SELECT E.*
     FROM #PlanX AS E
    WHERE E.PlanType  = 0
 ORDER BY E.PlanID

   SELECT E.*
     FROM #PlanX AS E
    WHERE E.PlanType != 0
 ORDER BY E.PlanID

*/

DECLARE @T smallint

   SELECT U.*
        , CHARINDEX('</MissingIndexGroup>', U.query_plan, U.I     ) AS O
        , CHARINDEX('"'                   , U.query_plan, U.I + 27) AS Z
     INTO #PlanY
     FROM
  (SELECT E.*
        , CHARINDEX( '<MissingIndexGroup ', E.query_plan,   1) AS I
     FROM #PlanX AS E) AS U

SET @T = @@ROWCOUNT

WHILE @T > 0

    BEGIN

       INSERT #PlanY
       SELECT U.*
            , CHARINDEX('</MissingIndexGroup>', U.query_plan, U.I     ) AS O
            , CHARINDEX('"'                   , U.query_plan, U.I + 27) AS Z
         FROM
      (SELECT E.DBName
            , E.SchemaName
            , E.ObjectName
            , E.ObjectType
            , E.query_plan
            , E.Creation
            , E.Last_Run
            , E.PlanID
            , E.PlanType
            , E.SQL_code
            , E.SQL_code_all
            , CHARINDEX( '<MissingIndexGroup ', E.query_plan, Z.T) AS I
         FROM #PlanY AS E
         JOIN
      (SELECT W.PlanID
            , MAX(W.O)  AS T
         FROM #PlanY    AS W
     GROUP BY W.PlanID) AS Z
           ON E.PlanID
            = Z.PlanID
          AND E.O
            = Z.T)      AS U
        WHERE U.I > 0

    SET @T = @@ROWCOUNT

    END

   SELECT E.DBName
        , E.SchemaName
        , E.ObjectName
        , E.ObjectType
        , CONVERT(decimal(09,04), SUBSTRING(E.query_plan, E.I + 27, E.Z - E.I - 27)) AS index_value
        ,                         SUBSTRING(E.query_plan, E.Z +  2, E.O - E.Z -  2)  AS index_details_from_query_plan
        , CONVERT(XML, E.query_plan) AS query_plan
--      , E.I
--      , E.O
--      , E.PlanID
--      , E.PlanType
        , E.Creation
        , E.Last_Run
        , E.SQL_code
        , E.SQL_code_all
     FROM #PlanY AS E
    WHERE E.PlanType  = 0
 ORDER BY E.PlanID

   SELECT E.DBName
        , E.SchemaName
        , E.ObjectName
        , E.ObjectType
        , CONVERT(decimal(09,04), SUBSTRING(E.query_plan, E.I + 27, E.Z - E.I - 27)) AS index_value
        ,                         SUBSTRING(E.query_plan, E.Z +  2, E.O - E.Z -  2)  AS index_details_from_query_plan
        , CONVERT(XML, E.query_plan) AS query_plan
--      , E.I
--      , E.O
--      , E.PlanID
--      , E.PlanType
        , E.Creation
        , E.Last_Run
--      , E.SQL_code
--      , E.SQL_code_all
     FROM #PlanY AS E
    WHERE E.PlanType != 0
 ORDER BY E.PlanID

DROP TABLE #PlanX

DROP TABLE #PlanY

SET NOCOUNT OFF

