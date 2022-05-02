/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

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

   SELECT P.is_user_process
        , P.session_id
        , R.request_id
        , CONVERT(varchar(40), P.login_time             , 120) AS login_time
        , P.login_name
        , P.host_name
        , P.program_name
        , CONVERT(varchar(40), P.last_request_start_time, 120) AS batch_time
--      , DB_NAME(P.database_id) AS DB_session
        , DB_NAME(R.database_id) AS DB_request
        , R.status                                             AS batch_state
        , R.wait_resource
        , R.wait_type
        , R.wait_time / 1000.0 AS wait_seconds
        , CONVERT(varchar(0010), R.total_elapsed_time / 86400000) + ':' + CONVERT(varchar(0020), DATEADD(ms, R.total_elapsed_time % 86400000, 0), 114) AS run_time
        , CONVERT(varchar(0010), R.cpu_time           / 86400000) + ':' + CONVERT(varchar(0020), DATEADD(ms, R.cpu_time           % 86400000, 0), 114) AS cpu_time
        , S.CPUs
        , S.tasks
        , R.reads
        , R.writes
        , R.row_count
        , CONVERT(decimal(19,05), R.granted_query_memory / 128.0 / 1024.0) AS GBs_RAM
        , R.blocking_session_id AS blocking_id
        , Z.transaction_state   AS trans_state
        ,            DB_NAME(            T.dbid) AS DBName
        , OBJECT_SCHEMA_NAME(T.objectid, T.dbid) AS SchemaName
        ,        OBJECT_NAME(T.objectid, T.dbid) AS ObjectName
        ,                               SPACE(2) AS ObjectType
        , R.command
        , CASE WHEN R.statement_start_offset < 0 THEN     0                                                                                  ELSE R.statement_start_offset END / 2 + 1 AS I
        , CASE WHEN R.statement_end_offset   < 0 THEN LEN(T.text) * 2 WHEN R.statement_end_offset > LEN(T.text) * 2 - 4 THEN LEN(T.text) * 2 ELSE R.statement_end_offset   END / 2 + 1 AS O
        , T.text
        , V.query_plan
     INTO #Action
     FROM sys.dm_exec_sessions AS P
LEFT JOIN sys.dm_exec_requests AS R
       ON P.session_id
        = R.session_id
LEFT JOIN
  (SELECT Q.session_id
        , Q.request_id
        , SUM(CASE WHEN Q.task_state = 'RUNNING' THEN 1 ELSE 0 END) AS CPUs
        , SUM(                                        1           ) AS tasks
     FROM sys.dm_os_tasks AS Q
    WHERE Q.session_id IS NOT NULL
 GROUP BY Q.session_id
        , Q.request_id)   AS S
       ON R.session_id
        = S.session_id
      AND R.request_id
        = S.request_id
LEFT JOIN sys.dm_tran_session_transactions AS W
       ON R.session_id
        = W.session_id
      AND R.transaction_id
        = W.transaction_id
LEFT JOIN sys.dm_tran_active_transactions AS Z
       ON W.transaction_id
        = Z.transaction_id
    OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) AS T OUTER APPLY sys.dm_exec_query_plan(R.plan_handle) AS V
    WHERE P.session_id != @@SPID

   SELECT E.session_id
--      , E.request_id
        , E.login_time
        , E.login_name
        , E.host_name
        , E.program_name
        , E.batch_time
--      , E.DB_session
        , E.DB_request
--      , E.batch_state
--      , E.wait_resource
--      , E.wait_type
--      , E.wait_seconds
        , E.run_time
        , E.cpu_time
--      , E.CPUs
--      , E.tasks
--      , E.reads
--      , E.writes
--      , E.row_count
        , E.GBs_RAM
        , E.blocking_id
        , E.trans_state
--      , E.DBName
--      , E.SchemaName
--      , E.ObjectName
--      , E.ObjectType
--      , E.command
        , SUBSTRING(E.text, E.I, E.O - E.I) AS SQL_code
        ,           E.text                  AS SQL_code_all
        , E.query_plan
     FROM #Action AS E
    WHERE CASE WHEN ISNULL(E.blocking_id, -1) !> 0 AND E.session_id IN (SELECT blocking_id FROM #Action) THEN 1 -- session involved in block as lead blocker
               WHEN ISNULL(E.blocking_id, -1)  > 0 AND E.session_id IN (SELECT blocking_id FROM #Action) THEN 2 -- session involved in block as      blocker
               WHEN ISNULL(E.blocking_id, -1)  > 0                                                       THEN 3 -- session involved in block as      blocked
               WHEN E.is_user_process          = 0                                                       THEN 0
               WHEN E.program_name LIKE 'SQLAgent%'                                                      THEN 0
               WHEN ISNULL(E.blocking_id, -1) !< 0                                                       THEN 4
               WHEN ISNULL(E.trans_state, -1) !< 0                                                       THEN 4 ELSE 5 END IN (1, 2, 3, 4) -- add 5 to include idle sessions
 ORDER BY E.session_id
        , E.request_id

/*

-- wait summary

   SELECT A.wait_type
        , COUNT(*) AS wait_count
        , CONVERT(decimal(19,03), SUM(A.wait_seconds)) AS wait_seconds
        , CONVERT(decimal(05,02), 
          CONVERT(decimal(19,03), SUM(A.wait_seconds)) * 100.0 / CASE WHEN U.wait_seconds > 0.0 THEN U.wait_seconds ELSE 1.0 END) AS [Percent]
     FROM
  (SELECT E.wait_type
        , E.wait_seconds
     FROM #Action AS E
    WHERE E.is_user_process != 0
      AND E.wait_type IS NOT NULL) AS A,
  (SELECT CONVERT(decimal(19,03), SUM(E.wait_seconds)) AS wait_seconds
     FROM #Action AS E
    WHERE E.is_user_process != 0
      AND E.wait_type IS NOT NULL) AS U
 GROUP BY A.wait_type
        , U.wait_seconds
 ORDER BY [Percent] DESC

*/

/*

-- wait summary by database

   SELECT A.wait_type
        , COUNT(*) AS wait_count
        , CONVERT(decimal(19,03), SUM(A.wait_seconds)) AS wait_seconds
        , A.wait_database
     FROM
  (SELECT E.wait_type
        , E.wait_seconds
        , CASE WHEN E.wait_resource LIKE '[1-9]%:[1-9]%:[1-9]%' THEN DB_NAME(CONVERT(smallint, SUBSTRING(E.wait_resource, 1, CHARINDEX(':', E.wait_resource, 1) - 1)))
               WHEN LEFT(E.wait_resource, 4) =           'KEY:' THEN DB_NAME(CONVERT(smallint, SUBSTRING(E.wait_resource, 6, CHARINDEX(':', E.wait_resource, 6) - 6)))
               WHEN LEFT(E.wait_resource, 5) =          'PAGE:' THEN DB_NAME(CONVERT(smallint, SUBSTRING(E.wait_resource, 7, CHARINDEX(':', E.wait_resource, 7) - 7)))
               WHEN LEFT(E.wait_resource, 7) =        'OBJECT:' THEN DB_NAME(CONVERT(smallint, SUBSTRING(E.wait_resource, 9, CHARINDEX(':', E.wait_resource, 9) - 9))) ELSE SPACE(0) END AS wait_database
     FROM #Action AS E
    WHERE E.is_user_process != 0
      AND E.wait_type IS NOT NULL) AS A
 GROUP BY A.wait_type
        , A.wait_database
 ORDER BY A.wait_type
        , A.wait_database

*/

-- session/request usage of tempdb

   SELECT P.session_id
        , CONVERT(varchar(40), P.login_time             , 120) AS login_time
        , P.login_name
        , P.host_name
        , P.program_name
        , CONVERT(varchar(40), P.last_request_start_time, 120) AS batch_time
--      , DB_NAME(P.database_id) AS DB_session
        , DB_NAME(R.database_id) AS DB_request
        , CONVERT(varchar(0010), R.total_elapsed_time / 86400000) + ':' + CONVERT(varchar(0020), DATEADD(ms, R.total_elapsed_time % 86400000, 0), 114) AS run_time
        , CONVERT(varchar(0010), R.cpu_time           / 86400000) + ':' + CONVERT(varchar(0020), DATEADD(ms, R.cpu_time           % 86400000, 0), 114) AS cpu_time
        , CONVERT(decimal(19,05), R.granted_query_memory / 128.0 / 1024.0) AS GBs_RAM
        , DB_NAME(W.database_id) AS DB_affected
--      , CONVERT(decimal(19,05), (W.user_objects_alloc_page_count                                            ) / 128.0 / 1024.0) AS GBs_session_user_all
        , CONVERT(decimal(19,05), (W.user_objects_alloc_page_count     - W.user_objects_dealloc_page_count    ) / 128.0 / 1024.0) AS GBs_session_user
--      , CONVERT(decimal(19,05), (W.internal_objects_alloc_page_count                                        ) / 128.0 / 1024.0) AS GBs_session_auto_all
        , CONVERT(decimal(19,05), (W.internal_objects_alloc_page_count - W.internal_objects_dealloc_page_count) / 128.0 / 1024.0) AS GBs_session_auto
--      , CONVERT(decimal(19,05), (Z.user_objects_alloc_page_count                                            ) / 128.0 / 1024.0) AS GBs_request_user_all
        , CONVERT(decimal(19,05), (Z.user_objects_alloc_page_count     - Z.user_objects_dealloc_page_count    ) / 128.0 / 1024.0) AS GBs_request_user
--      , CONVERT(decimal(19,05), (Z.internal_objects_alloc_page_count                                        ) / 128.0 / 1024.0) AS GBs_request_auto_all
        , CONVERT(decimal(19,05), (Z.internal_objects_alloc_page_count - Z.internal_objects_dealloc_page_count) / 128.0 / 1024.0) AS GBs_request_auto
     FROM sys.dm_exec_sessions AS P
     JOIN sys.dm_exec_requests AS R
       ON P.session_id
        = R.session_id
     JOIN
  (SELECT U.session_id
        , U.database_id
        , U.user_objects_alloc_page_count
        , U.user_objects_dealloc_page_count
        , U.internal_objects_alloc_page_count
        , U.internal_objects_dealloc_page_count
     FROM sys.dm_db_session_space_usage AS U) AS W
       ON P.session_id
        = W.session_id
     JOIN
  (SELECT U.session_id
        , SUM(U.user_objects_alloc_page_count      ) AS user_objects_alloc_page_count
        , SUM(U.user_objects_dealloc_page_count    ) AS user_objects_dealloc_page_count
        , SUM(U.internal_objects_alloc_page_count  ) AS internal_objects_alloc_page_count
        , SUM(U.internal_objects_dealloc_page_count) AS internal_objects_dealloc_page_count
     FROM sys.dm_db_task_space_usage AS U
 GROUP BY U.session_id) AS Z
       ON P.session_id
        = Z.session_id
    WHERE P.session_id != @@SPID
      AND P.is_user_process != 0
      AND W.user_objects_alloc_page_count
        + W.internal_objects_alloc_page_count
        + Z.user_objects_alloc_page_count
        + Z.internal_objects_alloc_page_count > 0
 ORDER BY P.session_id

-- session/request usage of transaction log

   SELECT P.session_id
        , CONVERT(varchar(40), P.login_time             , 120) AS login_time
        , P.login_name
        , P.host_name
        , P.program_name
        , CONVERT(varchar(40), P.last_request_start_time, 120) AS batch_time
--      , DB_NAME(P.database_id) AS DB_session
        , DB_NAME(R.database_id) AS DB_request
        , CONVERT(varchar(0010), R.total_elapsed_time / 86400000) + ':' + CONVERT(varchar(0020), DATEADD(ms, R.total_elapsed_time % 86400000, 0), 114) AS run_time
        , CONVERT(varchar(0010), R.cpu_time           / 86400000) + ':' + CONVERT(varchar(0020), DATEADD(ms, R.cpu_time           % 86400000, 0), 114) AS cpu_time
        , CONVERT(decimal(19,05), R.granted_query_memory / 128.0 / 1024.0) AS GBs_RAM
        , DB_NAME(W.database_id) AS DB_affected
        , CONVERT(decimal(19,05), W.database_transaction_log_bytes_used            / 1024.0 / 1024.0 / 1024.0    ) AS GBs_tran_log_user
        , CONVERT(decimal(19,05), W.database_transaction_log_bytes_used_system     / 1024.0 / 1024.0 / 1024.0    ) AS GBs_tran_log_auto
        , CONVERT(decimal(19,05),                                           Z.size          /  128.0 / 1024.0    ) AS GBs_tran_log_size
        , CONVERT(decimal(19,05), CASE WHEN Z.max_size < 0 THEN -1 ELSE Z.max_size          /  128.0 / 1024.0 END) AS GBs_tran_log_size_MAX
     FROM sys.dm_exec_sessions AS P
     JOIN sys.dm_exec_requests AS R
       ON P.session_id
        = R.session_id
     JOIN sys.dm_tran_database_transactions AS W
       ON R.transaction_id
        = W.transaction_id
     JOIN
  (SELECT M.database_id
        ,                                            SUM(    M.size)     AS     size
        , CASE WHEN MIN(M.max_size) < 0 THEN -1 ELSE SUM(M.max_size) END AS max_size
     FROM sys.master_files AS M
    WHERE M.type = 1
 GROUP BY M.database_id) AS Z
       ON W.database_id
        = Z.database_id
    WHERE P.session_id != @@SPID
      AND P.is_user_process != 0
      AND W.database_transaction_state = 4
      AND W.database_id NOT IN (1, 2, 3, 4)
 ORDER BY P.session_id
        , DB_NAME(W.database_id)

DROP TABLE #Action

SET NOCOUNT OFF

