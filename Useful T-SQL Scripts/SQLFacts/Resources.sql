/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

DECLARE @A datetime = GETDATE() -- CONVERT(datetime, '2021/01/01 00:00:00' -- datetime to start monitoring

DECLARE @I int = 120 -- iterations

DECLARE @T int =  30 -- time between in seconds

DECLARE @Percent_memory decimal(05,02) = 5.00 -- threshold percentage of total amount (size) for memory

DECLARE @Percent_tempdb decimal(05,02) = 5.00 -- threshold percentage of total amount (size) for tempdb

DECLARE @GBs_memory decimal(19,05)

DECLARE @GBs_tempdb decimal(19,05)

DECLARE @O int = 0

DECLARE @E datetime

DECLARE @Z char(0008) = LEFT(CONVERT(varchar(20), DATEADD(second, @T, 0), 114), 8)

DECLARE @SQLService varchar(0128)

DECLARE @NamePrefix varchar(0128)

SET @SQLService  = @@SERVICENAME

SET @NamePrefix  = 'SQLServer'

IF  @SQLService != 'MSSQLSERVER' SET @NamePrefix = 'MSSQL$' + @SQLService

   SELECT @GBs_memory = I.cntr_value / 1024.0 / 1024.0
     FROM sys.dm_os_performance_counters AS I
    WHERE RTRIM(I.object_name  ) = @NamePrefix + ':Memory Manager'
      AND RTRIM(I.counter_name ) =               'Total Server Memory (KB)'
      AND RTRIM(I.instance_name) =               ''

   SELECT @GBs_tempdb = SUM(F.size) / 128.0 / 1024.0
     FROM tempdb.sys.database_files AS F
    WHERE F.type = 0

-- PRINT 'GBs_memory: ' + CONVERT(varchar(0040), @GBs_memory)
-- PRINT 'GBs_tempdb: ' + CONVERT(varchar(0040), @GBs_tempdb)

WHILE GETDATE() < @A BEGIN WAITFOR DELAY '00:00:01' END

SET NOCOUNT OFF

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SET NOCOUNT ON

   SELECT P.session_id
        , R.request_id
        , P.login_time
        , P.login_name
        , P.host_name
        , P.program_name
        , P.last_request_start_time
--      , DB_NAME(P.database_id) AS DB_session
        , DB_NAME(R.database_id) AS DB_request
        , R.total_elapsed_time
        , R.cpu_time
        , CONVERT(decimal(19,05),  R.granted_query_memory                                                       / 128.0 / 1024.0) AS GBs_memory
        , CONVERT(decimal(19,05), (Z.user_objects_alloc_page_count     - Z.user_objects_dealloc_page_count    ) / 128.0 / 1024.0)
        + CONVERT(decimal(19,05), (Z.internal_objects_alloc_page_count - Z.internal_objects_dealloc_page_count) / 128.0 / 1024.0) AS GBs_tempdb
        ,            DB_NAME(            T.dbid) AS DBName
        , OBJECT_SCHEMA_NAME(T.objectid, T.dbid) AS SchemaName
        ,        OBJECT_NAME(T.objectid, T.dbid) AS ObjectName
        , CASE WHEN R.statement_start_offset < 0 THEN     0                                                                                  ELSE R.statement_start_offset END / 2 + 1 AS I
        , CASE WHEN R.statement_end_offset   < 0 THEN LEN(T.text) * 2 WHEN R.statement_end_offset > LEN(T.text) * 2 - 4 THEN LEN(T.text) * 2 ELSE R.statement_end_offset   END / 2 + 1 AS O
        , T.text
     INTO #Action
     FROM sys.dm_exec_sessions AS P
     JOIN sys.dm_exec_requests AS R
       ON P.session_id
        = R.session_id
LEFT JOIN
  (SELECT U.session_id
        , SUM(U.user_objects_alloc_page_count      ) AS user_objects_alloc_page_count
        , SUM(U.user_objects_dealloc_page_count    ) AS user_objects_dealloc_page_count
        , SUM(U.internal_objects_alloc_page_count  ) AS internal_objects_alloc_page_count
        , SUM(U.internal_objects_dealloc_page_count) AS internal_objects_dealloc_page_count
     FROM sys.dm_db_task_space_usage AS U
 GROUP BY U.session_id) AS Z
       ON P.session_id
        = Z.session_id
    OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) AS T
    WHERE 0 = 1

WHILE @O < @I

    BEGIN

    IF @O > 0 WAITFOR DELAY @Z

    SET @E = GETDATE()

       INSERT #Action
       SELECT W.*
         FROM
      (SELECT P.session_id
            , R.request_id
            , P.login_time
            , P.login_name
            , P.host_name
            , P.program_name
            , P.last_request_start_time
--          , DB_NAME(P.database_id) AS DB_session
            , DB_NAME(R.database_id) AS DB_request
            , R.total_elapsed_time
            , R.cpu_time
            , CONVERT(decimal(19,05),  R.granted_query_memory                                                       / 128.0 / 1024.0) AS GBs_memory
            , CONVERT(decimal(19,05), (Z.user_objects_alloc_page_count     - Z.user_objects_dealloc_page_count    ) / 128.0 / 1024.0)
            + CONVERT(decimal(19,05), (Z.internal_objects_alloc_page_count - Z.internal_objects_dealloc_page_count) / 128.0 / 1024.0) AS GBs_tempdb
            ,            DB_NAME(            T.dbid) AS DBName
            , OBJECT_SCHEMA_NAME(T.objectid, T.dbid) AS SchemaName
            ,        OBJECT_NAME(T.objectid, T.dbid) AS ObjectName
            , CASE WHEN R.statement_start_offset < 0 THEN     0                                                                                  ELSE R.statement_start_offset END / 2 + 1 AS I
            , CASE WHEN R.statement_end_offset   < 0 THEN LEN(T.text) * 2 WHEN R.statement_end_offset > LEN(T.text) * 2 - 4 THEN LEN(T.text) * 2 ELSE R.statement_end_offset   END / 2 + 1 AS O
            , T.text
         FROM sys.dm_exec_sessions AS P
         JOIN sys.dm_exec_requests AS R
           ON P.session_id
            = R.session_id
    LEFT JOIN
      (SELECT U.session_id
            , SUM(U.user_objects_alloc_page_count      ) AS user_objects_alloc_page_count
            , SUM(U.user_objects_dealloc_page_count    ) AS user_objects_dealloc_page_count
            , SUM(U.internal_objects_alloc_page_count  ) AS internal_objects_alloc_page_count
            , SUM(U.internal_objects_dealloc_page_count) AS internal_objects_dealloc_page_count
         FROM sys.dm_db_task_space_usage AS U
     GROUP BY U.session_id) AS Z
           ON P.session_id
            = Z.session_id
        OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) AS T
        WHERE P.session_id != @@SPID
          AND P.is_user_process != 0) AS W
        WHERE CASE WHEN ISNULL(W.GBs_memory, 0.0) !< @GBs_memory * (@Percent_memory / 100.0) THEN 1
                   WHEN ISNULL(W.GBs_tempdb, 0.0) !< @GBs_tempdb * (@Percent_tempdb / 100.0) THEN 1 ELSE 0 END != 0

    SET @O = @O + 1

    END

SET NOCOUNT OFF

SET TRANSACTION ISOLATION LEVEL READ   COMMITTED

SET NOCOUNT ON

   SELECT CONVERT(varchar(40), E.login_time             , 120) AS login_time
        , E.login_name
        , E.host_name
        , E.program_name
        , CONVERT(varchar(40), E.last_request_start_time, 120) AS batch_time
--      , E.DB_session
        , E.DB_request
--      , CONVERT(varchar(0010), E.total_elapsed_time / 86400000) + ':' + CONVERT(varchar(0020), DATEADD(ms, E.total_elapsed_time % 86400000, 0), 114) AS run_time
--      , CONVERT(varchar(0010), E.cpu_time           / 86400000) + ':' + CONVERT(varchar(0020), DATEADD(ms, E.cpu_time           % 86400000, 0), 114) AS cpu_time
        , E.GBs_memory AS GBs_used_memory
        ,  @GBs_memory AS GBs_size_memory
        , CONVERT(decimal(05,02), E.GBs_memory * 100.0 / @GBs_memory) AS Percent_memory
        , E.DBName
        , E.SchemaName
        , E.ObjectName
--      , SUBSTRING(E.text, E.I, E.O - E.I) AS SQL_code
        ,           E.text                  AS SQL_code_all
     FROM
  (SELECT A.*
        , ROW_NUMBER() OVER (PARTITION BY A.session_id, A.last_request_start_time ORDER BY A.total_elapsed_time DESC) AS Most_Recent
     FROM #Action AS A) AS E
    WHERE CASE WHEN ISNULL(E.GBs_memory, 0.0) !< @GBs_memory * (@Percent_memory / 100.0) THEN 1 ELSE 0 END != 0
      AND E.Most_Recent = 1
 ORDER BY E.GBs_memory DESC
        , E.last_request_start_time
        , E.session_id

   SELECT CONVERT(varchar(40), E.login_time             , 120) AS login_time
        , E.login_name
        , E.host_name
        , E.program_name
        , CONVERT(varchar(40), E.last_request_start_time, 120) AS batch_time
--      , E.DB_session
        , E.DB_request
--      , CONVERT(varchar(0010), E.total_elapsed_time / 86400000) + ':' + CONVERT(varchar(0020), DATEADD(ms, E.total_elapsed_time % 86400000, 0), 114) AS run_time
--      , CONVERT(varchar(0010), E.cpu_time           / 86400000) + ':' + CONVERT(varchar(0020), DATEADD(ms, E.cpu_time           % 86400000, 0), 114) AS cpu_time
        , E.GBs_tempdb AS GBs_used_tempdb
        ,  @GBs_tempdb AS GBs_size_tempdb
        , CONVERT(decimal(05,02), E.GBs_tempdb * 100.0 / @GBs_tempdb) AS Percent_tempdb
        , E.DBName
        , E.SchemaName
        , E.ObjectName
--      , SUBSTRING(E.text, E.I, E.O - E.I) AS SQL_code
        ,           E.text                  AS SQL_code_all
     FROM
  (SELECT A.*
        , ROW_NUMBER() OVER (PARTITION BY A.session_id, A.last_request_start_time ORDER BY A.total_elapsed_time DESC) AS Most_Recent
     FROM #Action AS A) AS E
    WHERE CASE WHEN ISNULL(E.GBs_tempdb, 0.0) !< @GBs_tempdb * (@Percent_tempdb / 100.0) THEN 1 ELSE 0 END != 0
      AND E.Most_Recent = 1
 ORDER BY E.GBs_tempdb DESC
        , E.last_request_start_time
        , E.session_id

DROP TABLE #Action

SET NOCOUNT OFF

