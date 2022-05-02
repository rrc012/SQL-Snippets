/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

   SELECT L.request_session_id   AS session_id
        , L.request_request_id   AS request_id
        , L.request_mode
        , L.request_status
        , L.resource_database_id AS database_id
        , CASE WHEN L.resource_type IN ('OBJECT'                    ) THEN CONVERT(int, L.resource_associated_entity_id) ELSE 0 END AS object_id
        , CASE WHEN L.resource_type IN ('HOBT', 'PAGE', 'RID', 'KEY') THEN              L.resource_associated_entity_id  ELSE 0 END AS partition_id
        , CONVERT(varchar(0128), NULL) AS index_name
        , CONVERT(tinyint      , NULL) AS index_type
        , L.resource_type
        , COUNT(*) AS locks
     INTO #Locks
     FROM sys.dm_tran_locks AS L
--  WHERE L.request_status LIKE 'GRANT%'
 GROUP BY L.request_session_id
        , L.request_request_id
        , L.request_mode
        , L.request_status
        , L.resource_database_id
        , L.resource_associated_entity_id
        , L.resource_type

  DECLARE @database_id int

  DECLARE @name   varchar(0128) = '%' -- database name LIKE

  DECLARE @DBName varchar(0128)

  DECLARE @DBCode varchar(2000)

  DECLARE DBNames CURSOR FAST_FORWARD FOR
   SELECT D.database_id
        , DB_NAME(D.database_id)
     FROM #Locks AS D
    WHERE DB_NAME(D.database_id) LIKE @name
      AND D.object_id     = 0
      AND D.partition_id != 0
 GROUP BY D.database_id
        , DB_NAME(D.database_id)
 ORDER BY DB_NAME(D.database_id)

OPEN DBNames

FETCH NEXT FROM DBNames INTO @database_id, @DBName

WHILE @@FETCH_STATUS = 0

    BEGIN

    SET @DBCode = 'USE [' + @DBName + ']; '
                + '    UPDATE #Locks SET'
                + '             object_id'
                + '         = P.object_id'
                + '         ,   index_name'
                + '         =       I.name'
                + '         ,   index_type'
                + '         =       I.type'
                + '      FROM #Locks AS L'
                + '      JOIN sys.partitions AS P'
                + '        ON L.partition_id'
                + '         = P.partition_id'
                + ' LEFT JOIN sys.indexes AS I'
                + '        ON P.object_id'
                + '         = I.object_id'
                + '       AND P.index_id'
                + '         = I.index_id'
                + '     WHERE L.database_id = ' + CONVERT(varchar(0010), @database_id)
                + '       AND L.object_id     = 0'
                + '       AND L.partition_id != 0'

    EXECUTE (@DBCode)

    FETCH NEXT FROM DBNames INTO @database_id, @DBName

    END

CLOSE DBNames DEALLOCATE DBNames

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
        , CONVERT(decimal(19,05), R.granted_query_memory / 128.0 / 1024.0) AS GBs_RAM
        , R.blocking_session_id AS blocking_id
        , Z.transaction_state   AS trans_state
        ,            DB_NAME(             L.database_id) AS DBName
        , OBJECT_SCHEMA_NAME(L.object_id, L.database_id) AS SchemaName
        ,        OBJECT_NAME(L.object_id, L.database_id) AS ObjectName
        ,                                       SPACE(2) AS ObjectType
        , L.index_name
        , L.index_type
        , L.resource_type
        , L.request_mode   AS lock_mode
        , L.request_status AS lock_status
        , L.locks
     INTO #Action
     FROM sys.dm_exec_sessions AS P
LEFT JOIN sys.dm_exec_requests AS R
       ON P.session_id
        = R.session_id
LEFT JOIN sys.dm_tran_session_transactions AS W
       ON R.session_id
        = W.session_id
      AND R.transaction_id
        = W.transaction_id
LEFT JOIN sys.dm_tran_active_transactions AS Z
       ON W.transaction_id
        = Z.transaction_id
LEFT JOIN #Locks AS L
       ON P.session_id
        = L.session_id
      AND ISNULL(R.request_id, 0)
        = ISNULL(L.request_id, 0)
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
--      , E.run_time
--      , E.cpu_time
--      , E.GBs_RAM
--      , E.blocking_id
--      , E.trans_state
        , E.locks
        , E.lock_mode
        , E.lock_status
        , E.resource_type
        , E.DBName
        , E.SchemaName
        , E.ObjectName
--      , E.ObjectType
        , E.index_name
        , E.index_type
     FROM #Action AS E
    WHERE CASE WHEN ISNULL(E.blocking_id, -1) !> 0 AND E.session_id IN (SELECT blocking_id FROM #Action) THEN 1 -- session involved in block as lead blocker
               WHEN ISNULL(E.blocking_id, -1)  > 0 AND E.session_id IN (SELECT blocking_id FROM #Action) THEN 2 -- session involved in block as      blocker
               WHEN ISNULL(E.blocking_id, -1)  > 0                                                       THEN 3 -- session involved in block as      blocked
               WHEN E.is_user_process          = 0                                                       THEN 0
               WHEN E.program_name LIKE 'SQLAgent%'                                                      THEN 0
               WHEN ISNULL(E.blocking_id, -1) !< 0                                                       THEN 4
               WHEN ISNULL(E.trans_state, -1) !< 0                                                       THEN 4 ELSE 5 END IN (1, 2, 3, 4) -- add 5 to include idle sessions
      AND E.lock_mode IS NOT NULL
 ORDER BY E.session_id
        , E.request_id
        , CASE E.resource_type
          WHEN 'DATABASE'        THEN 1
          WHEN 'FILE'            THEN 2
          WHEN 'HOBT'            THEN 3
          WHEN 'OBJECT'          THEN 4
          WHEN 'ALLOCATION_UNIT' THEN 5
          WHEN 'EXTENT'          THEN 6
          WHEN 'PAGE'            THEN 7
          WHEN 'RID'             THEN 8
          WHEN 'KEY'             THEN 9 ELSE 10 END
        , E.lock_status
        , E.lock_mode
        , E.index_type DESC
        , E.index_name

DROP TABLE #Locks

DROP TABLE #Action

SET NOCOUNT OFF

