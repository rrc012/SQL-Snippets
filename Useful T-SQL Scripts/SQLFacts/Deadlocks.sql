/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

DECLARE @Minutes int = 60 * 24 -- maximum number of minutes ago, 60 * 24 is one day

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

CREATE TABLE #Action (deadlock_id smallint, deadlock XML)

/*

DECLARE @EventPath varchar(0260) = (SELECT LEFT(F.physical_name, CHARINDEX('master', F.physical_name) - 1) FROM sys.master_files AS F WHERE F.name = 'master') + 'SQLFacts_Deadlocks.xel'

EXECUTE ('
CREATE EVENT SESSION SQLFacts_Deadlocks ON SERVER
  ADD EVENT sqlserver.xml_deadlock_report
    (ACTION ( sqlserver.username
            , sqlserver.client_hostname
            , sqlserver.client_app_name ))
  ADD TARGET package0.event_file (SET FILENAME = ''' + @EventPath + ''', MAX_FILE_SIZE = 1000, MAX_ROLLOVER_FILES = 4)
WITH (EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS, MAX_DISPATCH_LATENCY = 30 SECONDS, MAX_MEMORY = 1024MB, STARTUP_STATE = OFF)')

   ALTER EVENT SESSION SQLFacts_Deadlocks ON SERVER STATE = START

-- ALTER EVENT SESSION SQLFacts_Deadlocks ON SERVER STATE = STOP

--  DROP EVENT SESSION SQLFacts_Deadlocks ON SERVER

*/

-- DECLARE @XESession varchar(0128) = 'SQLFacts_Deadlocks'

   DECLARE @XESession varchar(0128) = 'system_health'

   DECLARE @EventPath varchar(0260)

   SELECT @EventPath = LEFT(U.EventPath, CHARINDEX(@XESession, U.EventPath) + LEN(@XESession) - 1) + '*.xel'
     FROM
  (SELECT CONVERT(XML, T.target_data).value('(EventFileTarget/File/@name)[1]', 'varchar(0260)') AS EventPath
     FROM sys.dm_xe_sessions        AS S
     JOIN sys.dm_xe_session_targets AS T
       ON               S.address
        = T.event_session_address
    WHERE S.name = @XESession
      AND T.target_name = 'event_file') AS U

   INSERT #Action
   SELECT ROW_NUMBER() OVER (ORDER BY V.event_datetime)
        , V.event_data
     FROM
  (SELECT Table0.deadlock.value('@timestamp', 'datetime') AS event_datetime
        , Z.event_data
     FROM
  (SELECT CONVERT(XML, W.event_data) AS event_data
     FROM sys.fn_xe_file_target_read_file(@EventPath, NULL, NULL, NULL) AS W
    WHERE W.object_name = 'xml_deadlock_report') AS Z
    CROSS APPLY Z.event_data.nodes('event') AS Table0(deadlock)) AS V
    WHERE DATEDIFF(minute, DATEADD(hour, DATEDIFF(hour, SYSUTCDATETIME(), SYSDATETIME()), V.event_datetime), GETDATE()) !> @Minutes

   SELECT E.deadlock
        , ROW_NUMBER() OVER (PARTITION BY E.deadlock ORDER BY E.process_id) AS process
        , E.process_id
        , E.login_name
        , E.host_name
        , E.program_name
        , E.batch_time
        , E.trans_time
        , E.wait_resource
        , E.victim
     INTO #Action_Base
     FROM
  (SELECT Z.deadlock_id AS deadlock
        , Table2.deadlock.value('@id'              , 'varchar(0200)') AS process_id
        , Table2.deadlock.value('@loginname'       , 'varchar(0200)') AS login_name
        , Table2.deadlock.value('@hostname'        , 'varchar(0200)') AS host_name
        , Table2.deadlock.value('@clientapp'       , 'varchar(0200)') AS program_name
        , Table2.deadlock.value('@lastbatchstarted', 'datetime'     ) AS batch_time
        , Table2.deadlock.value('@lasttranstarted' , 'datetime'     ) AS trans_time
        , Table2.deadlock.value('@waitresource'    , 'varchar(0200)') AS wait_resource
        , CASE WHEN Table2.deadlock.value('@id'    , 'varchar(0200)')
                  = Table3.deadlock.value('@id'    , 'varchar(0200)') THEN 'victim' ELSE SPACE(0) END AS victim
     FROM #Action AS Z
    CROSS APPLY      Z.deadlock.nodes('event/data/value/deadlock'   ) AS Table1(deadlock)
    CROSS APPLY Table1.deadlock.nodes('process-list/process'        ) AS Table2(deadlock)
    CROSS APPLY Table1.deadlock.nodes('victim-list/victimProcess '  ) AS Table3(deadlock)) AS E
 ORDER BY E.deadlock
        , E.process_id

   SELECT A.deadlock
        , ROW_NUMBER() OVER (PARTITION BY A.deadlock ORDER BY A.process_id) AS process
        , A.process_id
        , A.proc_name
        , A.line
        , MAX(CASE WHEN A.RowID = 1 THEN RTRIM(SUBSTRING(A.SQL_code    , PATINDEX('%[A-Z/-]%', A.SQL_code    ), 1000)) ELSE SPACE(0) END) AS SQL_line_planned
        , MAX(CASE WHEN A.RowID = 2 THEN RTRIM(SUBSTRING(A.SQL_code    , PATINDEX('%[A-Z/-]%', A.SQL_code    ), 1000)) ELSE SPACE(0) END) AS SQL_line_written
        , MAX(                           RTRIM(SUBSTRING(A.SQL_code_all, PATINDEX('%[A-Z/-]%', A.SQL_code_all), 4000))                  ) AS SQL_code_all
     INTO #Action_Code
     FROM
  (SELECT E.deadlock
        , E.process_id
        , E.proc_name
        , E.line
        , E.SQL_code
        , E.SQL_code_all
        , ROW_NUMBER() OVER (PARTITION BY E.deadlock, E.process_id ORDER BY E.line, E.start) AS RowID
     FROM
  (SELECT Z.deadlock_id AS deadlock
        , Table2.deadlock.value('@id'              , 'varchar(0200)') AS process_id
        , Table3.deadlock.value('@procname'        , 'varchar(0200)') AS proc_name
        , Table3.deadlock.value('@line'            , 'int'          ) AS line
        , Table3.deadlock.value('@stmtstart'       , 'int'          ) AS start
        , Table3.deadlock.value('.'                , 'varchar(1000)') AS SQL_code
        , Table4.deadlock.value('.'                , 'varchar(4000)') AS SQL_code_all
     FROM #Action AS Z
    CROSS APPLY      Z.deadlock.nodes('event/data/value/deadlock'   ) AS Table1(deadlock)
    CROSS APPLY Table1.deadlock.nodes('process-list/process'        ) AS Table2(deadlock)
    CROSS APPLY Table2.deadlock.nodes('executionStack/frame'        ) AS Table3(deadlock)
    CROSS APPLY Table2.deadlock.nodes('inputbuf'                    ) AS Table4(deadlock)) AS E) AS A
 GROUP BY A.deadlock
        , A.process_id
        , A.proc_name
        , A.line
 ORDER BY A.deadlock
        , A.process_id

   SELECT E.deadlock
        , ROW_NUMBER() OVER (PARTITION BY E.deadlock ORDER BY E.owner_id) AS process
        , E.owner_id                                                      AS process_id
        , E.waiter_id                                                     AS process_id_waiter
        , E.owner_mode                                                    AS lock_mode
        , E.waiter_mode                                                   AS lock_mode_waiter
        , E.lock_type
        , E.object_name
        , DB_NAME(E.database_id) AS database_name
        , E.database_id
        , E.file_id
        , E.page_id
     INTO #Action_More
     FROM
  (SELECT Z.deadlock_id AS deadlock
        , Table3.deadlock.value(    '(owner-list/owner/@id)[1]', 'varchar(0200)') AS owner_id
        , Table3.deadlock.value(  '(waiter-list/waiter/@id)[1]', 'varchar(0200)') AS waiter_id
        , Table3.deadlock.value(  '(owner-list/owner/@mode)[1]', 'varchar(0200)') AS owner_mode
        , Table3.deadlock.value('(waiter-list/waiter/@mode)[1]', 'varchar(0200)') AS waiter_mode
        , Table3.deadlock.value('local-name(.)'    , 'varchar(0200)') AS lock_type
        , Table3.deadlock.value('@objectname'      , 'varchar(0200)') AS object_name
        , Table3.deadlock.value('@dbid'            , 'int'          ) AS database_id
        , Table3.deadlock.value('@fileid'          , 'int'          ) AS file_id
        , Table3.deadlock.value('@pageid'          , 'int'          ) AS page_id
     FROM #Action AS Z
    CROSS APPLY      Z.deadlock.nodes('event/data/value/deadlock'   ) AS Table1(deadlock)
    CROSS APPLY Table1.deadlock.nodes('resource-list'               ) AS Table2(deadlock)
    CROSS APPLY Table2.deadlock.nodes('*'                           ) AS Table3(deadlock)) AS E
 ORDER BY E.deadlock
        , E.owner_id

   SELECT W.deadlock
        , W.process
        , W.process_id
        , W.login_name
        , W.host_name
        , W.program_name
        , W.batch_time
        , W.trans_time
        , W.wait_resource
        , W.victim
     FROM #Action_Base AS W
 ORDER BY W.deadlock
        , W.process

   SELECT X.deadlock
        , X.process
        , X.process_id
        , X.proc_name
        , X.line
        , X.SQL_line_planned
        , X.SQL_line_written
        , X.SQL_code_all
     FROM #Action_Code AS X
 ORDER BY X.deadlock
        , X.process

   SELECT Y.deadlock
        , Y.process
        , Y.process_id
        , Y.process_id_waiter
        , Y.lock_mode
        , Y.lock_mode_waiter
        , Y.lock_type
        , Y.object_name
        , Y.database_name
        , Y.database_id
        , Y.file_id
        , Y.page_id
     FROM #Action_More AS Y
 ORDER BY Y.deadlock
        , Y.process

/*

   SELECT W.deadlock
        , W.process
        , W.process_id
        , W.login_name
        , W.host_name
        , W.program_name
        , W.batch_time
        , W.trans_time
        , W.wait_resource
        , W.victim
        , X.proc_name
        , X.line
        , X.SQL_line_planned
        , X.SQL_line_written
        , X.SQL_code_all
        , Y.process_id_waiter
        , Y.lock_mode
        , Y.lock_mode_waiter
        , Y.lock_type
        , Y.object_name
        , Y.database_name
        , Y.database_id
        , Y.file_id
        , Y.page_id
     FROM #Action_Base AS W
     JOIN #Action_Code AS X
       ON W.deadlock
        = X.deadlock
      AND W.process
        = X.process
     JOIN #Action_More AS Y
       ON W.deadlock
        = Y.deadlock
      AND W.process
        = Y.process
 ORDER BY W.deadlock
        , W.process

*/

DROP TABLE #Action

DROP TABLE #Action_Base
DROP TABLE #Action_Code
DROP TABLE #Action_More

SET NOCOUNT OFF

