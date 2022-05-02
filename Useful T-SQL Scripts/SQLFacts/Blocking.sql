/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

DECLARE @A datetime = GETDATE() -- CONVERT(datetime, '2021/01/01 00:00:00' -- datetime to start monitoring

DECLARE @I int = 120 -- iterations

DECLARE @T int =  30 -- time between in seconds

DECLARE @U int =  30 -- threshold number of seconds being blocked

DECLARE @O int = 0

DECLARE @Z char(0008) = LEFT(CONVERT(varchar(20), DATEADD(second, @T, 0), 114), 8)

WHILE GETDATE() < @A BEGIN WAITFOR DELAY '00:00:01' END

SET NOCOUNT OFF

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SET NOCOUNT ON

   SELECT GETDATE() AS KeyDT
        , P.session_id
        , R.request_id
        , P.login_time
        , P.login_name
        , P.host_name
        , P.program_name
        , P.last_request_start_time
--      , DB_NAME(P.database_id) AS DB_session
        , DB_NAME(R.database_id) AS DB_request
        , R.wait_resource
        , R.wait_type
        , R.wait_time / 1000.0 AS wait_seconds
        , R.total_elapsed_time
        , R.cpu_time
        , R.blocking_session_id
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
    OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) AS T
    WHERE 0 = 1

   SELECT A.*
     INTO #Action_Blocker
     FROM #Action AS A
    WHERE 0 = 1

   SELECT A.*
        , A.last_request_start_time AS blocking_last_request_start_time
     INTO #Action_Blocked
     FROM #Action AS A
    WHERE 0 = 1

WHILE @O < @I

    BEGIN

    IF @O > 0 WAITFOR DELAY @Z

    TRUNCATE TABLE #Action

       INSERT #Action
       SELECT W.*
         FROM
      (SELECT GETDATE() AS KeyDT
            , P.session_id
            , R.request_id
            , P.login_time
            , P.login_name
            , P.host_name
            , P.program_name
            , P.last_request_start_time
--          , DB_NAME(P.database_id) AS DB_session
            , DB_NAME(R.database_id) AS DB_request
            , R.wait_resource
            , R.wait_type
            , R.wait_time / 1000.0 AS wait_seconds
            , R.total_elapsed_time
            , R.cpu_time
            , R.blocking_session_id
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
        OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) AS T
        WHERE P.session_id != @@SPID
          AND P.is_user_process != 0) AS W

       INSERT #Action_Blocker
       SELECT A.*
         FROM #Action AS A
        WHERE A.session_id IN
      (SELECT E.blocking_session_id
         FROM #Action AS E
        WHERE E.wait_seconds !< @U)

       INSERT #Action_Blocked
       SELECT A.*
            , E.last_request_start_time
         FROM #Action AS A
         JOIN #Action AS E
           ON A.blocking_session_id
            =          E.session_id
        WHERE A.wait_seconds !< @U
          AND A.blocking_session_id IS NOT NULL
          AND A.blocking_session_id != 0

    SET @O = @O + 1

    END

WHILE @O > 0

    BEGIN

       UPDATE T SET
                blocking_session_id
            = W.blocking_session_id
            ,   blocking_last_request_start_time
            = W.blocking_last_request_start_time
         FROM #Action_Blocked AS T
         JOIN #Action_Blocked AS W
           ON T.blocking_session_id
            =          W.session_id
          AND T.KeyDT
            = W.KeyDT
          AND T.wait_resource
            = W.wait_resource
          AND T.wait_type
            = W.wait_type
         JOIN #Action_Blocker AS Z
           ON W.blocking_session_id
            =          Z.session_id
          AND W.KeyDT
            = Z.KeyDT

    SET @O = @@ROWCOUNT

    END

   DELETE #Action_Blocker
     FROM #Action_Blocker AS Z
    WHERE NOT EXISTS
  (SELECT *
     FROM #Action_Blocked AS W
    WHERE W.blocking_session_id
        =          Z.session_id)

/*

   SELECT E.*
     FROM #Action_Blocker AS E
 ORDER BY E.KeyDT
        , E.session_id
        , E.last_request_start_time

   SELECT E.*
     FROM #Action_Blocked AS E
 ORDER BY E.KeyDT
        , E.session_id
        , E.last_request_start_time

*/

SET NOCOUNT OFF

SET TRANSACTION ISOLATION LEVEL READ   COMMITTED

SET NOCOUNT ON

   SELECT U.*
     INTO #Action_Blocker_Final
     FROM
  (SELECT E.*
        , ROW_NUMBER() OVER (PARTITION BY E.session_id, E.last_request_start_time                                                                                          ORDER BY E.KeyDT DESC) AS Most_Recent
     FROM #Action_Blocker AS E) AS U
    WHERE U.Most_Recent = 1

   SELECT U.*
     INTO #Action_Blocked_Final
     FROM
  (SELECT E.*
        , ROW_NUMBER() OVER (PARTITION BY E.session_id, E.last_request_start_time, E.wait_resource, E.wait_type, E.blocking_session_id, E.blocking_last_request_start_time ORDER BY E.KeyDT DESC) AS Most_Recent
     FROM #Action_Blocked AS E) AS U
    WHERE U.Most_Recent = 1

/*

   SELECT E.*
     FROM #Action_Blocker_Final AS E
 ORDER BY E.KeyDT
        , E.session_id
        , E.last_request_start_time

   SELECT E.*
     FROM #Action_Blocked_Final AS E
 ORDER BY E.KeyDT
        , E.session_id
        , E.last_request_start_time

*/

   SELECT A.blocking_session_id
        , A.blocking_last_request_start_time
        , A.wait_resource
        , A.wait_type
        , CONVERT(decimal(19,03), MAX(A.wait_seconds)) AS wait_seconds_MAX
        , CONVERT(decimal(19,03), SUM(A.wait_seconds)) AS wait_seconds_SUM
        , COUNT(DISTINCT STR(A.session_id, 10) + CONVERT(varchar(0040), A.last_request_start_time, 114)) AS [Sessions]
     INTO #Action_Block
     FROM #Action_Blocked_Final AS A
 GROUP BY A.blocking_session_id
        , A.blocking_last_request_start_time
        , A.wait_resource
        , A.wait_type

   SELECT E.session_id
        , CONVERT(varchar(40), E.login_time             , 120) AS login_time
        , E.login_name
        , E.host_name
        , E.program_name
        , CONVERT(varchar(40), E.last_request_start_time, 120) AS batch_time
--      , E.DB_session
        , E.DB_request
--      , CONVERT(varchar(0010), E.total_elapsed_time / 86400000) + ':' + CONVERT(varchar(0020), DATEADD(ms, E.total_elapsed_time % 86400000, 0), 114) AS run_time
--      , CONVERT(varchar(0010), E.cpu_time           / 86400000) + ':' + CONVERT(varchar(0020), DATEADD(ms, E.cpu_time           % 86400000, 0), 114) AS cpu_time
        , E.DBName
        , E.SchemaName
        , E.ObjectName
        , SUBSTRING(E.text, E.I, E.O - E.I) AS SQL_code
        ,           E.text                  AS SQL_code_all
        , Z.wait_resource
        , Z.wait_type
        , Z.wait_seconds_MAX
        , Z.wait_seconds_SUM
        , Z.[Sessions]
     FROM #Action_Blocker_Final AS E
     JOIN #Action_Block         AS Z
       ON          E.session_id
        = Z.blocking_session_id
      AND          E.last_request_start_time
        = Z.blocking_last_request_start_time
     JOIN
  (SELECT A.blocking_session_id
        , A.blocking_last_request_start_time
        , SUM(A.wait_seconds_SUM) AS wait_seconds_SUM
     FROM #Action_Block         AS A
 GROUP BY A.blocking_session_id
        , A.blocking_last_request_start_time) AS W
       ON          E.session_id
        = W.blocking_session_id
      AND          E.last_request_start_time
        = W.blocking_last_request_start_time
 ORDER BY W.wait_seconds_SUM DESC
        , W.blocking_session_id
        , W.blocking_last_request_start_time
        , Z.wait_seconds_SUM DESC
        , E.wait_resource
        , E.wait_type

DROP TABLE #Action

DROP TABLE #Action_Blocker

DROP TABLE #Action_Blocked

DROP TABLE #Action_Blocker_Final

DROP TABLE #Action_Blocked_Final

DROP TABLE #Action_Block

SET NOCOUNT OFF

