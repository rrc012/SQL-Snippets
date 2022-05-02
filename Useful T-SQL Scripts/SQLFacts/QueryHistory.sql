/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

DECLARE @Seconds_SUM decimal(19,03) = 60 -- minimum number for Seconds_SUM

DECLARE @CPU_time bit = 0
--      @CPU_time     = 0 means Seconds are run time
--      @CPU_time     = 1 means Seconds are CPU time

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

   SELECT E.Executions
        , E.Creation
        , E.Last_Run
        , E.Seconds_SUM -- total
        , E.Seconds_MIN -- minimum
        , E.Seconds_MAX -- maximum
        , E.Seconds_AVG -- average
--      , E.Seconds_LST -- last
        , E.Writes_SUM
        , E.Writes_MIN
        , E.Writes_MAX
        , E.Writes_AVG
--      , E.Writes_LST
        , E.LReads_SUM
        , E.LReads_MIN
        , E.LReads_MAX
        , E.LReads_AVG
--      , E.LReads_LST
--      , E.PReads_SUM
--      , E.PReads_MIN
--      , E.PReads_MAX
--      , E.PReads_AVG
--      , E.PReads_LST
--      , E.Rows_SUM
--      , E.Rows_MIN
--      , E.Rows_MAX
--      , E.Rows_AVG
--      , E.Rows_LST
        , E.DBName
        , E.SchemaName
        , E.ObjectName
        , E.ObjectType
        , E.query_plan
        , SUBSTRING(E.text, E.I, E.O - E.I) AS SQL_code
        ,           E.text                  AS SQL_code_all
     FROM
  (SELECT S.execution_count                                   AS Executions
        , CONVERT(varchar(0040) ,       S.creation_time, 120) AS Creation
        , CONVERT(varchar(0040) , S.last_execution_time, 120) AS Last_Run
        , CONVERT(decimal(19,03), CASE WHEN @CPU_time = 0 THEN S.total_elapsed_time ELSE S.total_worker_time END / 1000.0 / 1000.0 / S.execution_count) AS Seconds_AVG
        , CONVERT(decimal(19,03), CASE WHEN @CPU_time = 0 THEN S.total_elapsed_time ELSE S.total_worker_time END / 1000.0 / 1000.0                    ) AS Seconds_SUM
        , CONVERT(decimal(19,03), CASE WHEN @CPU_time = 0 THEN  S.last_elapsed_time ELSE  S.last_worker_time END / 1000.0 / 1000.0                    ) AS Seconds_LST
        , CONVERT(decimal(19,03), CASE WHEN @CPU_time = 0 THEN   S.min_elapsed_time ELSE   S.min_worker_time END / 1000.0 / 1000.0                    ) AS Seconds_MIN
        , CONVERT(decimal(19,03), CASE WHEN @CPU_time = 0 THEN   S.max_elapsed_time ELSE   S.max_worker_time END / 1000.0 / 1000.0                    ) AS Seconds_MAX
--      , CONVERT(decimal(19,03),                                  S.total_clr_time                              / 1000.0 / 1000.0 / S.execution_count) AS SQL_CLR_AVG
--      , CONVERT(decimal(19,03),                                  S.total_clr_time                              / 1000.0 / 1000.0                    ) AS SQL_CLR_SUM
--      , CONVERT(decimal(19,03),                                   S.last_clr_time                              / 1000.0 / 1000.0                    ) AS SQL_CLR_LST
--      , CONVERT(decimal(19,03),                                    S.min_clr_time                              / 1000.0 / 1000.0                    ) AS SQL_CLR_MIN
--      , CONVERT(decimal(19,03),                                    S.max_clr_time                              / 1000.0 / 1000.0                    ) AS SQL_CLR_MAX
        , S.total_logical_writes / S.execution_count AS Writes_AVG
        , S.total_logical_writes                     AS Writes_SUM
        ,  S.last_logical_writes                     AS Writes_LST
        ,   S.min_logical_writes                     AS Writes_MIN
        ,   S.max_logical_writes                     AS Writes_MAX
        ,  S.total_logical_reads / S.execution_count AS LReads_AVG
        ,  S.total_logical_reads                     AS LReads_SUM
        ,   S.last_logical_reads                     AS LReads_LST
        ,    S.min_logical_reads                     AS LReads_MIN
        ,    S.max_logical_reads                     AS LReads_MAX
        , S.total_physical_reads / S.execution_count AS PReads_AVG
        , S.total_physical_reads                     AS PReads_SUM
        ,  S.last_physical_reads                     AS PReads_LST
        ,   S.min_physical_reads                     AS PReads_MIN
        ,   S.max_physical_reads                     AS PReads_MAX
        ,           S.total_rows / S.execution_count AS Rows_AVG
        ,           S.total_rows                     AS Rows_SUM
        ,            S.last_rows                     AS Rows_LST
        ,             S.min_rows                     AS Rows_MIN
        ,             S.max_rows                     AS Rows_MAX
        ,            DB_NAME(            V.dbid) AS DBName
        , OBJECT_SCHEMA_NAME(V.objectid, V.dbid) AS SchemaName
        ,        OBJECT_NAME(V.objectid, V.dbid) AS ObjectName
        ,                               SPACE(2) AS ObjectType
        , CASE WHEN S.statement_start_offset < 0 THEN     0                                                                                  ELSE S.statement_start_offset END / 2 + 1 AS I
        , CASE WHEN S.statement_end_offset   < 0 THEN LEN(T.text) * 2 WHEN S.statement_end_offset > LEN(T.text) * 2 - 4 THEN LEN(T.text) * 2 ELSE S.statement_end_offset   END / 2 + 1 AS O
        , T.text
        , V.query_plan
     FROM sys.dm_exec_query_stats AS S OUTER APPLY sys.dm_exec_sql_text(S.sql_handle) AS T OUTER APPLY sys.dm_exec_query_plan(S.plan_handle) AS V) AS E
    WHERE E.DBName NOT IN ('msdb', 'master')
      AND E.ObjectType IN ('P ', 'V ', 'FN', 'IF', 'TF', 'TR', SPACE(2))
      AND E.Seconds_SUM
       !<  @Seconds_SUM
 ORDER BY E.Seconds_SUM DESC
        , E.Executions  DESC

   SELECT E.Executions
        , E.Creation
        , E.Last_Run
        , E.Seconds_SUM -- total
        , E.Seconds_MIN -- minimum
        , E.Seconds_MAX -- maximum
        , E.Seconds_AVG -- average
--      , E.Seconds_LST -- last
        , E.Writes_SUM
        , E.Writes_MIN
        , E.Writes_MAX
        , E.Writes_AVG
--      , E.Writes_LST
        , E.LReads_SUM
        , E.LReads_MIN
        , E.LReads_MAX
        , E.LReads_AVG
--      , E.LReads_LST
--      , E.PReads_SUM
--      , E.PReads_MIN
--      , E.PReads_MAX
--      , E.PReads_AVG
--      , E.PReads_LST
        , E.DBName
        , E.SchemaName
        , E.ObjectName
        , E.ObjectType
        , E.query_plan
     FROM
  (SELECT S.execution_count                                   AS Executions
        , CONVERT(varchar(0040) ,         S.cached_time, 120) AS Creation
        , CONVERT(varchar(0040) , S.last_execution_time, 120) AS Last_Run
        , CONVERT(decimal(19,03), CASE WHEN @CPU_time = 0 THEN S.total_elapsed_time ELSE S.total_worker_time END / 1000.0 / 1000.0 / S.execution_count) AS Seconds_AVG
        , CONVERT(decimal(19,03), CASE WHEN @CPU_time = 0 THEN S.total_elapsed_time ELSE S.total_worker_time END / 1000.0 / 1000.0                    ) AS Seconds_SUM
        , CONVERT(decimal(19,03), CASE WHEN @CPU_time = 0 THEN  S.last_elapsed_time ELSE  S.last_worker_time END / 1000.0 / 1000.0                    ) AS Seconds_LST
        , CONVERT(decimal(19,03), CASE WHEN @CPU_time = 0 THEN   S.min_elapsed_time ELSE   S.min_worker_time END / 1000.0 / 1000.0                    ) AS Seconds_MIN
        , CONVERT(decimal(19,03), CASE WHEN @CPU_time = 0 THEN   S.max_elapsed_time ELSE   S.max_worker_time END / 1000.0 / 1000.0                    ) AS Seconds_MAX
        , S.total_logical_writes / S.execution_count AS Writes_AVG
        , S.total_logical_writes                     AS Writes_SUM
        ,  S.last_logical_writes                     AS Writes_LST
        ,   S.min_logical_writes                     AS Writes_MIN
        ,   S.max_logical_writes                     AS Writes_MAX
        ,  S.total_logical_reads / S.execution_count AS LReads_AVG
        ,  S.total_logical_reads                     AS LReads_SUM
        ,   S.last_logical_reads                     AS LReads_LST
        ,    S.min_logical_reads                     AS LReads_MIN
        ,    S.max_logical_reads                     AS LReads_MAX
        , S.total_physical_reads / S.execution_count AS PReads_AVG
        , S.total_physical_reads                     AS PReads_SUM
        ,  S.last_physical_reads                     AS PReads_LST
        ,   S.min_physical_reads                     AS PReads_MIN
        ,   S.max_physical_reads                     AS PReads_MAX
        ,            DB_NAME(             S.database_id) AS DBName
        , OBJECT_SCHEMA_NAME(S.object_id, S.database_id) AS SchemaName
        ,        OBJECT_NAME(S.object_id, S.database_id) AS ObjectName
        ,                       ISNULL(S.type, SPACE(2)) AS ObjectType
        , V.query_plan
     FROM sys.dm_exec_procedure_stats AS S OUTER APPLY sys.dm_exec_query_plan(S.plan_handle) AS V) AS E
    WHERE E.DBName NOT IN ('msdb', 'master')
      AND E.ObjectType IN ('P ', 'V ', 'FN', 'IF', 'TF', 'TR', SPACE(2))
      AND E.Seconds_SUM
       !<  @Seconds_SUM
 ORDER BY E.Seconds_SUM DESC
        , E.Executions  DESC

SET NOCOUNT OFF

