/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

IF OBJECT_ID('tempdb..#Monitor', 'U ') IS NOT NULL DROP TABLE #Monitor

CREATE TABLE #Monitor (name varchar(0128)) -- databases to monitor file IO

INSERT #Monitor SELECT 'tempdb'
INSERT #Monitor SELECT 'AdventureWorks'

DECLARE @I int =  6 -- iterations

DECLARE @T int = 20 -- time between in seconds

DECLARE @Intervals int = 1 -- do not change, use the variables above instead

DECLARE @O int = 0

DECLARE @E datetime

DECLARE @Z char(0008) = LEFT(CONVERT(varchar(20), DATEADD(second, @T, 0), 114), 8)

DECLARE @SQLService varchar(0128)

DECLARE @NamePrefix varchar(0128)

SET @SQLService  = @@SERVICENAME

SET @NamePrefix  = 'SQLServer'

IF  @SQLService != 'MSSQLSERVER' SET @NamePrefix = 'MSSQL$' + @SQLService

IF OBJECT_ID('tempdb..#FileHistory', 'U ') IS NOT NULL DROP TABLE #FileHistory

CREATE TABLE #FileHistory
     ( KeyID                      int NOT NULL IDENTITY(0,1)
     , KeyDT                 datetime NOT NULL
     , database_id           smallint NOT NULL
     , num_of_files          smallint NOT NULL
     , size_on_disk_bytes      bigint NOT NULL
     , num_of_reads            bigint NOT NULL
     , num_of_writes           bigint NOT NULL
     , num_of_bytes_read       bigint NOT NULL
     , num_of_bytes_written    bigint NOT NULL
     , io_stall_read_ms        bigint NOT NULL
     , io_stall_write_ms       bigint NOT NULL )

-- CREATE UNIQUE CLUSTERED INDEX idx_KeyDT ON #FileHistory (KeyDT, database_id)

-- CREATE UNIQUE CLUSTERED INDEX idx_KeyID ON #FileHistory (KeyID, database_id)

IF OBJECT_ID('tempdb..#WaitHistory', 'U ') IS NOT NULL DROP TABLE #WaitHistory

CREATE TABLE #WaitHistory
     ( KeyID        int NOT NULL IDENTITY(0,1)
     , KeyDT   datetime NOT NULL
     , NIO_WC    bigint NOT NULL
     , NIO_WS    bigint NOT NULL
     , NIO_WT    bigint NOT NULL
     , DIO_WC    bigint NOT NULL
     , DIO_WS    bigint NOT NULL
     , DIO_WT    bigint NOT NULL
     , SIO_WC    bigint NOT NULL
     , SIO_WS    bigint NOT NULL
     , SIO_WT    bigint NOT NULL
     , PIO_WC    bigint NOT NULL
     , PIO_WS    bigint NOT NULL
     , PIO_WT    bigint NOT NULL
     , LOG_WC    bigint NOT NULL
     , LOG_WS    bigint NOT NULL
     , LOG_WT    bigint NOT NULL
     , RAM_WC    bigint NOT NULL
     , RAM_WS    bigint NOT NULL
     , RAM_WT    bigint NOT NULL
     , CPU_WC    bigint NOT NULL
     , CPU_WS    bigint NOT NULL
     , CPU_WT    bigint NOT NULL
     , DOP_WC    bigint NOT NULL
     , DOP_WS    bigint NOT NULL
     , DOP_WT    bigint NOT NULL
     , DBM_WC    bigint NOT NULL
     , DBM_WS    bigint NOT NULL
     , DBM_WT    bigint NOT NULL
     , DBS_WC    bigint NOT NULL
     , DBS_WS    bigint NOT NULL
     , DBS_WT    bigint NOT NULL
     , X___WC    bigint NOT NULL
     , X___WS    bigint NOT NULL
     , X___WT    bigint NOT NULL
     , U___WC    bigint NOT NULL
     , U___WS    bigint NOT NULL
     , U___WT    bigint NOT NULL
     , S___WC    bigint NOT NULL
     , S___WS    bigint NOT NULL
     , S___WT    bigint NOT NULL
     , IX__WC    bigint NOT NULL
     , IX__WS    bigint NOT NULL
     , IX__WT    bigint NOT NULL
     , IU__WC    bigint NOT NULL
     , IU__WS    bigint NOT NULL
     , IU__WT    bigint NOT NULL
     , IS__WC    bigint NOT NULL
     , IS__WS    bigint NOT NULL
     , IS__WT    bigint NOT NULL
     , SIX_WC    bigint NOT NULL
     , SIX_WS    bigint NOT NULL
     , SIX_WT    bigint NOT NULL
     , SIU_WC    bigint NOT NULL
     , SIU_WS    bigint NOT NULL
     , SIU_WT    bigint NOT NULL
     , UIX_WC    bigint NOT NULL
     , UIX_WS    bigint NOT NULL
     , UIX_WT    bigint NOT NULL )

-- CREATE UNIQUE CLUSTERED INDEX idx_KeyDT ON #WaitHistory (KeyDT)

-- CREATE UNIQUE CLUSTERED INDEX idx_KeyID ON #WaitHistory (KeyID)

IF OBJECT_ID('tempdb..#wait_type', 'U ') IS NOT NULL DROP TABLE #wait_type

CREATE TABLE #wait_type
     ( wait_ID           smallint NOT NULL IDENTITY(1,1)
     , wait_type   nvarchar(0060) NOT NULL )

IF OBJECT_ID('tempdb..#wait_count', 'U ') IS NOT NULL DROP TABLE #wait_count

CREATE TABLE #wait_count
     ( KeyID                  int NOT NULL IDENTITY(1,1)
     , KeyDT             datetime NOT NULL
     , wait_ID           smallint NOT NULL
     , wait_count        smallint NOT NULL )

-- CREATE UNIQUE CLUSTERED INDEX idx_KeyDT ON #wait_count (KeyDT, wait_ID)

-- CREATE UNIQUE CLUSTERED INDEX idx_KeyID ON #wait_count (KeyID)

IF OBJECT_ID('tempdb..#CounterHistory', 'U ') IS NOT NULL DROP TABLE #CounterHistory

CREATE TABLE #CounterHistory
     ( KeyID        int NOT NULL IDENTITY(0,1)
     , KeyDT   datetime NOT NULL
     , C101      bigint NOT NULL
     , C102      bigint NOT NULL
     , C103      bigint NOT NULL
     , C104      bigint NOT NULL
     , C105      bigint NOT NULL
     , C106      bigint NOT NULL
     , C107      bigint NOT NULL
     , C108      bigint NOT NULL
     , C109      bigint NOT NULL
     , C201      bigint NOT NULL
     , C202      bigint NOT NULL
     , C203      bigint NOT NULL
     , C204      bigint NOT NULL
     , C205      bigint NOT NULL
     , C206      bigint NOT NULL
     , C207      bigint NOT NULL
     , C208      bigint NOT NULL
     , C209      bigint NOT NULL
     , C301      bigint NOT NULL
     , C302      bigint NOT NULL
     , C303      bigint NOT NULL
     , C304      bigint NOT NULL
     , C305      bigint NOT NULL
     , C306      bigint NOT NULL
     , C307      bigint NOT NULL
     , C308      bigint NOT NULL
     , C309      bigint NOT NULL
     , C401      bigint NOT NULL
     , C402      bigint NOT NULL
     , C403      bigint NOT NULL
     , C404      bigint NOT NULL
     , C405      bigint NOT NULL
     , C406      bigint NOT NULL
     , C407      bigint NOT NULL
     , C408      bigint NOT NULL
     , C409      bigint NOT NULL
     , C501      bigint NOT NULL
     , C502      bigint NOT NULL
     , C503      bigint NOT NULL
     , C504      bigint NOT NULL
     , C505      bigint NOT NULL
     , C506      bigint NOT NULL
     , C507      bigint NOT NULL
     , C508      bigint NOT NULL
     , C509      bigint NOT NULL
     , C601      bigint NOT NULL
     , C602      bigint NOT NULL
     , C603      bigint NOT NULL
     , C604      bigint NOT NULL
     , C605      bigint NOT NULL
     , C606      bigint NOT NULL
     , C607      bigint NOT NULL
     , C608      bigint NOT NULL
     , C609      bigint NOT NULL
     , C701      bigint NOT NULL
     , C702      bigint NOT NULL
     , C703      bigint NOT NULL
     , C704      bigint NOT NULL
     , C705      bigint NOT NULL
     , C706      bigint NOT NULL
     , C707      bigint NOT NULL
     , C708      bigint NOT NULL
     , C709      bigint NOT NULL )

-- CREATE UNIQUE CLUSTERED INDEX idx_KeyDT ON #CounterHistory (KeyDT)

-- CREATE UNIQUE CLUSTERED INDEX idx_KeyID ON #CounterHistory (KeyID)

IF OBJECT_ID('tempdb..#Counter', 'U ') IS NOT NULL DROP TABLE #Counter

CREATE TABLE #Counter
     ( KeyID               smallint NOT NULL
     , object_name    varchar(0128) NOT NULL
     , counter_name   varchar(0128) NOT NULL
     , instance_name  varchar(0128) NOT NULL )

INSERT #Counter SELECT 101, ':Buffer Manager'        , 'Buffer cache hit ratio'       , ''
INSERT #Counter SELECT 201, ':Buffer Manager'        , 'Buffer cache hit ratio base'  , ''
INSERT #Counter SELECT 102, ':Plan Cache'            , 'Cache Hit Ratio'              , 'Object Plans'
INSERT #Counter SELECT 202, ':Plan Cache'            , 'Cache Hit Ratio Base'         , 'Object Plans'
INSERT #Counter SELECT 103, ':Plan Cache'            , 'Cache Hit Ratio'              , 'SQL Plans'
INSERT #Counter SELECT 203, ':Plan Cache'            , 'Cache Hit Ratio Base'         , 'SQL Plans'
INSERT #Counter SELECT 104, ':Plan Cache'            , 'Cache Pages'                  , 'Object Plans'
INSERT #Counter SELECT 204, ':Plan Cache'            , 'Cache Object Counts'          , 'Object Plans'
INSERT #Counter SELECT 105, ':Plan Cache'            , 'Cache Pages'                  , 'SQL Plans'
INSERT #Counter SELECT 205, ':Plan Cache'            , 'Cache Object Counts'          , 'SQL Plans'

INSERT #Counter SELECT 301, ':Buffer Manager'        , 'Page life expectancy'         , ''
INSERT #Counter SELECT 302, ':Buffer Manager'        , 'Database pages'               , ''
INSERT #Counter SELECT 303, ':Memory Manager'        , 'Database Cache Memory (KB)'   , ''
INSERT #Counter SELECT 304, ':Memory Manager'        , 'Total Server Memory (KB)'     , ''
INSERT #Counter SELECT 305, ':Memory Manager'        , 'Target Server Memory (KB)'    , ''
INSERT #Counter SELECT 306, ':Memory Manager'        , 'Lock Memory (KB)'             , ''
INSERT #Counter SELECT 307, ':Memory Manager'        , 'Granted Workspace Memory (KB)', ''
INSERT #Counter SELECT 308, ':Memory Manager'        , 'Memory Grants Outstanding'    , ''
INSERT #Counter SELECT 309, ':Memory Manager'        , 'Memory Grants Pending'        , ''

INSERT #Counter SELECT 401, ':Databases'             , 'Active Transactions'          , '_Total'
INSERT #Counter SELECT 402, ':Databases'             , 'Active Transactions'          , 'tempdb'
INSERT #Counter SELECT 403, ':Cursor Manager by Type', 'Active cursors'               , '_Total'
INSERT #Counter SELECT 404, ':Cursor Manager by Type', 'Active cursors'               , 'API Cursor'
INSERT #Counter SELECT 405, ':Cursor Manager by Type', 'Cursor memory usage'          , '_Total'
INSERT #Counter SELECT 406, ':Cursor Manager by Type', 'Cursor memory usage'          , 'API Cursor'
INSERT #Counter SELECT 407, ':General Statistics'    , 'Active Temp Tables'           , ''
INSERT #Counter SELECT 408, ':General Statistics'    , 'Processes blocked'            , ''
INSERT #Counter SELECT 409, ':General Statistics'    , 'User Connections'             , ''

INSERT #Counter SELECT 601, ':Access Methods'        , 'Full Scans/sec'               , ''
INSERT #Counter SELECT 602, ':Access Methods'        , 'Page Splits/sec'              , ''
INSERT #Counter SELECT 603, ':Buffer Manager'        , 'Page reads/sec'               , ''
INSERT #Counter SELECT 604, ':Buffer Manager'        , 'Page writes/sec'              , ''
INSERT #Counter SELECT 605, ':Buffer Manager'        , 'Page lookups/sec'             , ''
INSERT #Counter SELECT 606, ':General Statistics'    , 'Temp Tables Creation Rate'    , ''
INSERT #Counter SELECT 607, ':General Statistics'    , 'Connection resets/sec'        , ''
INSERT #Counter SELECT 608, ':General Statistics'    , 'Logins/sec'                   , ''
INSERT #Counter SELECT 609, ':General Statistics'    , 'Logouts/sec'                  , ''

INSERT #Counter SELECT 701, ':SQL Statistics'        , 'SQL Compilations/sec'         , ''
INSERT #Counter SELECT 702, ':SQL Statistics'        , 'Batch Requests/sec'           , ''
INSERT #Counter SELECT 703, ':Databases'             , 'Transactions/sec'             , '_Total'
INSERT #Counter SELECT 704, ':Databases'             , 'Transactions/sec'             , 'tempdb'
INSERT #Counter SELECT 705, ':Cursor Manager by Type', 'Cursor Requests/sec'          , '_Total'
INSERT #Counter SELECT 706, ':Cursor Manager by Type', 'Cursor Requests/sec'          , 'API Cursor'
INSERT #Counter SELECT 707, ':SQL Errors'            , 'Errors/sec'                   , 'User Errors'
INSERT #Counter SELECT 708, ':SQL Errors'            , 'Errors/sec'                   , 'Kill Connection Errors'
INSERT #Counter SELECT 709, ':Locks'                 , 'Number of Deadlocks/sec'      , '_Total'

SET NOCOUNT OFF

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SET NOCOUNT ON

WHILE @O < @I

    BEGIN

    IF @O > 0 WAITFOR DELAY @Z

    SET @E = GETDATE()

       INSERT #FileHistory
       SELECT @E AS KeyDT
            , F.database_id
            , COUNT(*)
            , SUM(F.size_on_disk_bytes)
            , SUM(F.num_of_reads)
            , SUM(F.num_of_writes)
            , SUM(F.num_of_bytes_read)
            , SUM(F.num_of_bytes_written)
            , SUM(F.io_stall_read_ms)
            , SUM(F.io_stall_write_ms)
         FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS F
         JOIN sys.master_files AS M
           ON F.database_id
            = M.database_id
          AND F.file_id
            = M.file_id
         JOIN sys.databases AS W
           ON F.database_id
            = W.database_id
         JOIN #Monitor AS Z
           ON W.name
            = Z.name
        WHERE M.type = 0
     GROUP BY F.database_id
     ORDER BY F.database_id

       INSERT #WaitHistory
       SELECT @E AS KeyDT
            , NIO.waiting_tasks_count AS NIO_WC
            , NIO.signal_wait_time_ms AS NIO_WS
            , NIO.wait_time_ms        AS NIO_WT
            , DIO.waiting_tasks_count AS DIO_WC
            , DIO.signal_wait_time_ms AS DIO_WS
            , DIO.wait_time_ms        AS DIO_WT
            , SIO.waiting_tasks_count AS SIO_WC
            , SIO.signal_wait_time_ms AS SIO_WS
            , SIO.wait_time_ms        AS SIO_WT
            , PLX.waiting_tasks_count
            + PLU.waiting_tasks_count
            + PLS.waiting_tasks_count AS PIO_WC
            , PLX.signal_wait_time_ms
            + PLU.signal_wait_time_ms
            + PLS.signal_wait_time_ms AS PIO_WS
            , PLX.wait_time_ms
            + PLU.wait_time_ms
            + PLS.wait_time_ms        AS PIO_WT
            , LUG.waiting_tasks_count AS LOG_WC
            , LUG.signal_wait_time_ms AS LOG_WS
            , LUG.wait_time_ms        AS LOG_WT
            , RAM.waiting_tasks_count AS RAM_WC
            , RAM.signal_wait_time_ms AS RAM_WS
            , RAM.wait_time_ms        AS RAM_WT
            , CPU.waiting_tasks_count AS CPU_WC
            , CPU.signal_wait_time_ms AS CPU_WS
            , CPU.wait_time_ms        AS CPU_WT
            , DOP.waiting_tasks_count AS DOP_WC
            , DOP.signal_wait_time_ms AS DOP_WS
            , DOP.wait_time_ms        AS DOP_WT
            , DBM.waiting_tasks_count AS DBM_WC
            , DBM.signal_wait_time_ms AS DBM_WS
            , DBM.wait_time_ms        AS DBM_WT
            , DBS.waiting_tasks_count AS DBS_WC
            , DBS.signal_wait_time_ms AS DBS_WS
            , DBS.wait_time_ms        AS DBS_WT
            , X__.waiting_tasks_count AS X___WC
            , X__.signal_wait_time_ms AS X___WS
            , X__.wait_time_ms        AS X___WT
            , U__.waiting_tasks_count AS U___WC
            , U__.signal_wait_time_ms AS U___WS
            , U__.wait_time_ms        AS U___WT
            , S__.waiting_tasks_count AS S___WC
            , S__.signal_wait_time_ms AS S___WS
            , S__.wait_time_ms        AS S___WT
            , IX_.waiting_tasks_count AS IX__WC
            , IX_.signal_wait_time_ms AS IX__WS
            , IX_.wait_time_ms        AS IX__WT
            , IU_.waiting_tasks_count AS IU__WC
            , IU_.signal_wait_time_ms AS IU__WS
            , IU_.wait_time_ms        AS IU__WT
            , IS_.waiting_tasks_count AS IS__WC
            , IS_.signal_wait_time_ms AS IS__WS
            , IS_.wait_time_ms        AS IS__WT
            , SIX.waiting_tasks_count AS SIX_WC
            , SIX.signal_wait_time_ms AS SIX_WS
            , SIX.wait_time_ms        AS SIX_WT
            , SIU.waiting_tasks_count AS SIU_WC
            , SIU.signal_wait_time_ms AS SIU_WS
            , SIU.wait_time_ms        AS SIU_WT
            , UIX.waiting_tasks_count AS UIX_WC
            , UIX.signal_wait_time_ms AS UIX_WS
            , UIX.wait_time_ms        AS UIX_WT
         FROM
      (SELECT 0 AS KeyID) AS KID
         JOIN sys.dm_os_wait_stats AS NIO ON NIO.wait_type = 'ASYNC_NETWORK_IO'
         JOIN sys.dm_os_wait_stats AS DIO ON DIO.wait_type = 'ASYNC_IO_COMPLETION'
         JOIN sys.dm_os_wait_stats AS SIO ON SIO.wait_type =       'IO_COMPLETION'
         JOIN sys.dm_os_wait_stats AS PLX ON PLX.wait_type = 'PAGEIOLATCH_EX'
         JOIN sys.dm_os_wait_stats AS PLU ON PLU.wait_type = 'PAGEIOLATCH_UP'
         JOIN sys.dm_os_wait_stats AS PLS ON PLS.wait_type = 'PAGEIOLATCH_SH'
         JOIN sys.dm_os_wait_stats AS LUG ON LUG.wait_type = 'LOGBUFFER'
         JOIN sys.dm_os_wait_stats AS RAM ON RAM.wait_type = 'RESOURCE_SEMAPHORE'
         JOIN sys.dm_os_wait_stats AS CPU ON CPU.wait_type = 'SOS_SCHEDULER_YIELD'
         JOIN sys.dm_os_wait_stats AS DOP ON DOP.wait_type = 'CXPACKET'
         JOIN sys.dm_os_wait_stats AS DBM ON DBM.wait_type = 'LCK_M_SCH_M'
         JOIN sys.dm_os_wait_stats AS DBS ON DBS.wait_type = 'LCK_M_SCH_S'
         JOIN sys.dm_os_wait_stats AS X__ ON X__.wait_type = 'LCK_M_X'
         JOIN sys.dm_os_wait_stats AS U__ ON U__.wait_type = 'LCK_M_U'
         JOIN sys.dm_os_wait_stats AS S__ ON S__.wait_type = 'LCK_M_S'
         JOIN sys.dm_os_wait_stats AS IX_ ON IX_.wait_type = 'LCK_M_IX'
         JOIN sys.dm_os_wait_stats AS IU_ ON IU_.wait_type = 'LCK_M_IU'
         JOIN sys.dm_os_wait_stats AS IS_ ON IS_.wait_type = 'LCK_M_IS'
         JOIN sys.dm_os_wait_stats AS SIX ON SIX.wait_type = 'LCK_M_SIX'
         JOIN sys.dm_os_wait_stats AS SIU ON SIU.wait_type = 'LCK_M_SIU'
         JOIN sys.dm_os_wait_stats AS UIX ON UIX.wait_type = 'LCK_M_UIX'

       SELECT CASE WHEN R.wait_resource LIKE '2:%' THEN R.wait_type + '_tempdb' ELSE R.wait_type END AS wait_type
         INTO #Action
         FROM sys.dm_exec_sessions AS P
         JOIN sys.dm_exec_requests AS R
           ON P.session_id
            = R.session_id
        WHERE P.is_user_process != 0
          AND R.wait_type IS NOT NULL

       INSERT #wait_type
            ( wait_type )
       SELECT R.wait_type
         FROM #Action AS R
    LEFT JOIN #wait_type AS T
           ON R.wait_type
            = T.wait_type
        WHERE T.wait_ID IS NULL
     GROUP BY R.wait_type

       INSERT #wait_count
            ( KeyDT
            , wait_ID
            , wait_count )
       SELECT GETDATE() AS KeyDT
            , T.wait_ID
            , COUNT(*)  AS wait_count
         FROM #Action AS R
         JOIN #wait_type AS T
           ON R.wait_type
            = T.wait_type
     GROUP BY T.wait_ID

    DROP TABLE #Action

       INSERT #CounterHistory
       SELECT W.KeyDT
            , W.C101
            , W.C102
            , W.C103
            , W.C104
            , W.C105
            , (SELECT CONVERT(bigint, value_in_use) FROM sys.configurations WHERE name LIKE 'ma% parallelism') AS C106
            , (SELECT CONVERT(bigint, value_in_use) FROM sys.configurations WHERE name LIKE 'co% parallelism') AS C107
            , (SELECT CONVERT(bigint, value_in_use) FROM sys.configurations WHERE name LIKE 'min%memory (MB)') AS C108
            , (SELECT CONVERT(bigint, value_in_use) FROM sys.configurations WHERE name LIKE 'max%memory (MB)') AS C109
            , W.C201
            , W.C202
            , W.C203
            , W.C204
            , W.C205
            , (SELECT CONVERT(bigint, value_in_use) FROM sys.configurations WHERE name LIKE 'nested triggers') AS C206
            , (SELECT CONVERT(bigint, value_in_use) FROM sys.configurations WHERE name LIKE 'opt%for ad hoc%') AS C207
            , (SELECT CONVERT(bigint, value_in_use) FROM sys.configurations WHERE name LIKE 'Agent XPs'      ) AS C208
            , (SELECT CONVERT(bigint, value_in_use) FROM sys.configurations WHERE name LIKE '%Mail XPs'      ) AS C209
            , W.C301
            , W.C302
            , W.C303
            , W.C304
            , W.C305
            , W.C306
            , W.C307
            , W.C308
            , W.C309
            , W.C401
            , W.C402
            , W.C403
            , W.C404
            , W.C405
            , W.C406
            , W.C407
            , W.C408
            , W.C409
            , O.physical_memory_kb                AS C501 -- SQL Server 2012 and newer
--          , O.physical_memory_in_bytes / 1024.0 AS C501 -- less than SQL Server 2012
            , O.cpu_count AS C502
            , Z.C503
            , Z.C504
            , Z.C505
            , Z.C506
            , Z.C507
            , Z.C508
            , Z.C509
            , W.C601
            , W.C602
            , W.C603
            , W.C604
            , W.C605
            , W.C606
            , W.C607
            , W.C608
            , W.C609
            , W.C701
            , W.C702
            , W.C703
            , W.C704
            , W.C705
            , W.C706
            , W.C707
            , W.C708
            , W.C709
         FROM
      (SELECT @E AS KeyDT
            , MAX(CASE WHEN T.KeyID = 101 THEN I.cntr_value ELSE 0 END) AS C101
            , MAX(CASE WHEN T.KeyID = 102 THEN I.cntr_value ELSE 0 END) AS C102
            , MAX(CASE WHEN T.KeyID = 103 THEN I.cntr_value ELSE 0 END) AS C103
            , MAX(CASE WHEN T.KeyID = 104 THEN I.cntr_value ELSE 0 END) AS C104
            , MAX(CASE WHEN T.KeyID = 105 THEN I.cntr_value ELSE 0 END) AS C105
            , MAX(CASE WHEN T.KeyID = 201 THEN I.cntr_value ELSE 0 END) AS C201
            , MAX(CASE WHEN T.KeyID = 202 THEN I.cntr_value ELSE 0 END) AS C202
            , MAX(CASE WHEN T.KeyID = 203 THEN I.cntr_value ELSE 0 END) AS C203
            , MAX(CASE WHEN T.KeyID = 204 THEN I.cntr_value ELSE 0 END) AS C204
            , MAX(CASE WHEN T.KeyID = 205 THEN I.cntr_value ELSE 0 END) AS C205
            , MAX(CASE WHEN T.KeyID = 301 THEN I.cntr_value ELSE 0 END) AS C301
            , MAX(CASE WHEN T.KeyID = 302 THEN I.cntr_value ELSE 0 END) AS C302
            , MAX(CASE WHEN T.KeyID = 303 THEN I.cntr_value ELSE 0 END) AS C303
            , MAX(CASE WHEN T.KeyID = 304 THEN I.cntr_value ELSE 0 END) AS C304
            , MAX(CASE WHEN T.KeyID = 305 THEN I.cntr_value ELSE 0 END) AS C305
            , MAX(CASE WHEN T.KeyID = 306 THEN I.cntr_value ELSE 0 END) AS C306
            , MAX(CASE WHEN T.KeyID = 307 THEN I.cntr_value ELSE 0 END) AS C307
            , MAX(CASE WHEN T.KeyID = 308 THEN I.cntr_value ELSE 0 END) AS C308
            , MAX(CASE WHEN T.KeyID = 309 THEN I.cntr_value ELSE 0 END) AS C309
            , MAX(CASE WHEN T.KeyID = 401 THEN I.cntr_value ELSE 0 END) AS C401
            , MAX(CASE WHEN T.KeyID = 402 THEN I.cntr_value ELSE 0 END) AS C402
            , MAX(CASE WHEN T.KeyID = 403 THEN I.cntr_value ELSE 0 END) AS C403
            , MAX(CASE WHEN T.KeyID = 404 THEN I.cntr_value ELSE 0 END) AS C404
            , MAX(CASE WHEN T.KeyID = 405 THEN I.cntr_value ELSE 0 END) AS C405
            , MAX(CASE WHEN T.KeyID = 406 THEN I.cntr_value ELSE 0 END) AS C406
            , MAX(CASE WHEN T.KeyID = 407 THEN I.cntr_value ELSE 0 END) AS C407
            , MAX(CASE WHEN T.KeyID = 408 THEN I.cntr_value ELSE 0 END) AS C408
            , MAX(CASE WHEN T.KeyID = 409 THEN I.cntr_value ELSE 0 END) AS C409
            , MAX(CASE WHEN T.KeyID = 601 THEN I.cntr_value ELSE 0 END) AS C601
            , MAX(CASE WHEN T.KeyID = 602 THEN I.cntr_value ELSE 0 END) AS C602
            , MAX(CASE WHEN T.KeyID = 603 THEN I.cntr_value ELSE 0 END) AS C603
            , MAX(CASE WHEN T.KeyID = 604 THEN I.cntr_value ELSE 0 END) AS C604
            , MAX(CASE WHEN T.KeyID = 605 THEN I.cntr_value ELSE 0 END) AS C605
            , MAX(CASE WHEN T.KeyID = 606 THEN I.cntr_value ELSE 0 END) AS C606
            , MAX(CASE WHEN T.KeyID = 607 THEN I.cntr_value ELSE 0 END) AS C607
            , MAX(CASE WHEN T.KeyID = 608 THEN I.cntr_value ELSE 0 END) AS C608
            , MAX(CASE WHEN T.KeyID = 609 THEN I.cntr_value ELSE 0 END) AS C609
            , MAX(CASE WHEN T.KeyID = 701 THEN I.cntr_value ELSE 0 END) AS C701
            , MAX(CASE WHEN T.KeyID = 702 THEN I.cntr_value ELSE 0 END) AS C702
            , MAX(CASE WHEN T.KeyID = 703 THEN I.cntr_value ELSE 0 END) AS C703
            , MAX(CASE WHEN T.KeyID = 704 THEN I.cntr_value ELSE 0 END) AS C704
            , MAX(CASE WHEN T.KeyID = 705 THEN I.cntr_value ELSE 0 END) AS C705
            , MAX(CASE WHEN T.KeyID = 706 THEN I.cntr_value ELSE 0 END) AS C706
            , MAX(CASE WHEN T.KeyID = 707 THEN I.cntr_value ELSE 0 END) AS C707
            , MAX(CASE WHEN T.KeyID = 708 THEN I.cntr_value ELSE 0 END) AS C708
            , MAX(CASE WHEN T.KeyID = 709 THEN I.cntr_value ELSE 0 END) AS C709
         FROM sys.dm_os_performance_counters AS I
         JOIN #Counter AS T
           ON RTRIM(I.object_name  ) = @NamePrefix + T.object_name
          AND RTRIM(I.counter_name ) =               T.counter_name
          AND RTRIM(I.instance_name) =               T.instance_name) AS W,
      (SELECT SUM(                              1           ) AS C503
            , SUM(CASE WHEN S.is_idle != 0 THEN 1 ELSE 0 END) AS C504
            , SUM(S.current_workers_count                   ) AS C505
            , SUM(S.runnable_tasks_count                    ) AS C506
            , SUM(S.current_tasks_count                     )
            + SUM(S.work_queue_count                        ) AS C507
            , SUM(S.work_queue_count                        ) AS C508
            , SUM(S.pending_disk_io_count                   ) AS C509
         FROM sys.dm_os_schedulers AS S
        WHERE S.scheduler_id < 255
          AND S.is_online != 0) AS Z, sys.dm_os_sys_info AS O

    SET @O = @O + 1

    END

SET NOCOUNT OFF

SET TRANSACTION ISOLATION LEVEL READ   COMMITTED

SET NOCOUNT ON

   SELECT CONVERT(varchar(20), T.KeyDT, 120) AS KeyDT
        , CONVERT(decimal(09,02), CASE WHEN T.C201 = 0 THEN 0.0 ELSE (T.C101 * 100.0) / T.C201 END) AS BCHR
        , T.C301 AS Page_Life
        , T.C309 AS RAM_stalls
        , T.C308 AS RAM_grants
        , CONVERT(decimal(19,05), T.C307 / 1024.0 / 1024.0) AS GBs_RAM_task
        , CONVERT(decimal(19,05), T.C306 / 1024.0 / 1024.0) AS GBs_RAM_lock
        , CONVERT(decimal(19,05), T.C303 / 1024.0 / 1024.0) AS GBs_RAM_disk -- SQL Server 2012 and newer
--      , CONVERT(decimal(19,05), T.C302 /  128.0 / 1024.0) AS GBs_RAM_disk -- less than SQL Server 2012
        , CONVERT(decimal(19,05), T.C304 / 1024.0 / 1024.0) AS GBs_RAM_total
        , CONVERT(decimal(19,05), T.C305 / 1024.0 / 1024.0) AS GBs_RAM_ideal
        , CONVERT(decimal(19,05), T.C501 / 1024.0 / 1024.0) AS GBs_RAM_final
        , CONVERT(decimal(19,05), T.C108          / 1024.0) AS GBs_Server_Min
        , CONVERT(decimal(19,05), T.C109          / 1024.0) AS GBs_Server_Max
     FROM #CounterHistory AS I
     JOIN #CounterHistory AS T
       ON I.KeyID + @Intervals
        = T.KeyID
    WHERE I.KeyID % @Intervals = 0
 ORDER BY T.KeyID

   SELECT CONVERT(varchar(20), T.KeyDT, 120) AS KeyDT
        , CONVERT(decimal(09,02), CASE WHEN T.C202 = 0 THEN 0.0 ELSE (T.C102 * 100.0) / T.C202 END) AS PCHR_object
        , CONVERT(decimal(09,02), CASE WHEN T.C203 = 0 THEN 0.0 ELSE (T.C103 * 100.0) / T.C203 END) AS PCHR_ad_hoc
        , T.C204 AS Tally_PC_object
        , T.C205 AS Tally_PC_ad_hoc
        , CONVERT(decimal(19,05), T.C104 /  128.0 / 1024.0) AS GBs_PC_object
        , CONVERT(decimal(19,05), T.C105 /  128.0 / 1024.0) AS GBs_PC_ad_hoc
        , CONVERT(decimal(19,02), CASE WHEN T.C204 = 0 THEN 0.0 ELSE T.C104 * 8.0 / T.C204 END) AS KBs_Each_object
        , CONVERT(decimal(19,02), CASE WHEN T.C205 = 0 THEN 0.0 ELSE T.C105 * 8.0 / T.C205 END) AS KBs_Each_ad_hoc
        , CASE WHEN T.C206 = 0 THEN 'False' ELSE 'True' END AS Trigger_Nest
        , CASE WHEN T.C207 = 0 THEN 'False' ELSE 'True' END AS Favor_ad_hoc
        , T.C106 AS DOP_Max
        , T.C107 AS DOP_Cost
     FROM #CounterHistory AS I
     JOIN #CounterHistory AS T
       ON I.KeyID + @Intervals
        = T.KeyID
    WHERE I.KeyID % @Intervals = 0
 ORDER BY T.KeyID

   SELECT CONVERT(varchar(20), T.KeyDT, 120) AS KeyDT
        , T.C401          AS Transactions
        , T.C402          AS XAs_tempdb
        , T.C403          AS Cursors_All
        , T.C404          AS Cursors_API
--      , T.C405          AS Cursor_KB_All
--      , T.C406          AS Cursor_KB_API
        , T.C407          AS Temp_Tables
        , T.C408          AS SPID_Blocks
        , T.C409          AS Connections
        , T.C502          AS CPUs_All
        , T.C503          AS CPUs_SQL
        , T.C504          AS CPUs_Idle
        , T.C505          AS Workers_All
        , T.C506          AS Workers_Wait
        , T.C507          AS Tasks_All
        , T.C508          AS Tasks_Wait
        , T.C509          AS Pending_IOs
     FROM #CounterHistory AS I
     JOIN #CounterHistory AS T
       ON I.KeyID + @Intervals
        = T.KeyID
    WHERE I.KeyID % @Intervals = 0
 ORDER BY T.KeyID

   SELECT CONVERT(varchar(20), T.KeyDT, 120) AS KeyDT
        , DATEDIFF(second, I.KeyDT, T.KeyDT) AS Seconds
        , T.C703 - I.C703 AS Transactions
        , T.C704 - I.C704 AS XAs_tempdb
        , T.C705 - I.C705 AS Cursors_All
        , T.C706 - I.C706 AS Cursors_API
        , T.C606 - I.C606 AS Temp_Tables
        , T.C601 - I.C601 AS Table_Scans
        , T.C602 - I.C602 AS Page_Splits
        , T.C603 - I.C603 AS Page_Reads
        , T.C604 - I.C604 AS Page_Writes
--      , T.C605 - I.C605 AS Page_Lookups
--      , T.C607 - I.C607 AS Resets
--      , T.C608 - I.C608 AS Logins
--      , T.C609 - I.C609 AS Logouts
        , T.C701 - I.C701 AS SQL_Compiles
        , T.C702 - I.C702 AS SQL_Batches
        , T.C707 - I.C707 AS Errors_11_19
        , T.C708 - I.C708 AS Errors_20_25
        , T.C709 - I.C709 AS Deadlocks
     FROM #CounterHistory AS I
     JOIN #CounterHistory AS T
       ON I.KeyID + @Intervals
        = T.KeyID
    WHERE I.KeyID % @Intervals = 0
 ORDER BY T.KeyID

   SELECT E.KeyDT
        , E.Seconds
        ,                                                                   E.SQL_WT
        , CASE WHEN E.SQL_WT = 0.000 THEN 0.00 ELSE CONVERT(decimal(09,02), E.SQL_WS * 100.0 / E.SQL_WT) END AS SQL_WP
        ,                                                                   E.NIO_WT
        , CASE WHEN E.SQL_WT = 0.000 THEN 0.00 ELSE CONVERT(decimal(09,02), E.NIO_WT * 100.0 / E.SQL_WT) END AS NIO_WP
        ,                                                                   E.DIO_WT
        , CASE WHEN E.SQL_WT = 0.000 THEN 0.00 ELSE CONVERT(decimal(09,02), E.DIO_WT * 100.0 / E.SQL_WT) END AS DIO_WP
        ,                                                                   E.SIO_WT
        , CASE WHEN E.SQL_WT = 0.000 THEN 0.00 ELSE CONVERT(decimal(09,02), E.SIO_WT * 100.0 / E.SQL_WT) END AS SIO_WP
        ,                                                                   E.PIO_WT
        , CASE WHEN E.SQL_WT = 0.000 THEN 0.00 ELSE CONVERT(decimal(09,02), E.PIO_WT * 100.0 / E.SQL_WT) END AS PIO_WP
        ,                                                                   E.LOG_WT
        , CASE WHEN E.SQL_WT = 0.000 THEN 0.00 ELSE CONVERT(decimal(09,02), E.LOG_WT * 100.0 / E.SQL_WT) END AS LOG_WP
        ,                                                                   E.RAM_WT
        , CASE WHEN E.SQL_WT = 0.000 THEN 0.00 ELSE CONVERT(decimal(09,02), E.RAM_WT * 100.0 / E.SQL_WT) END AS RAM_WP
        ,                                                                   E.CPU_WT
        , CASE WHEN E.SQL_WT = 0.000 THEN 0.00 ELSE CONVERT(decimal(09,02), E.CPU_WT * 100.0 / E.SQL_WT) END AS CPU_WP
        ,                                                                   E.DOP_WT
        , CASE WHEN E.SQL_WT = 0.000 THEN 0.00 ELSE CONVERT(decimal(09,02), E.DOP_WT * 100.0 / E.SQL_WT) END AS DOP_WP
        ,                                                                   E.LCK_WT
        , CASE WHEN E.SQL_WT = 0.000 THEN 0.00 ELSE CONVERT(decimal(09,02), E.LCK_WT * 100.0 / E.SQL_WT) END AS LCK_WP
     FROM
  (SELECT CONVERT(varchar(20), T.KeyDT, 120) AS KeyDT
        , DATEDIFF(second, I.KeyDT, T.KeyDT) AS Seconds
        , CONVERT(decimal(19,03), (T.NIO_WS - I.NIO_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.DIO_WS - I.DIO_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIO_WS - I.SIO_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.PIO_WS - I.PIO_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.LOG_WS - I.LOG_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.RAM_WS - I.RAM_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.CPU_WS - I.CPU_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.DOP_WS - I.DOP_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.DBM_WS - I.DBM_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.DBS_WS - I.DBS_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.X___WS - I.X___WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.U___WS - I.U___WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.S___WS - I.S___WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.IX__WS - I.IX__WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.IU__WS - I.IU__WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.IS__WS - I.IS__WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIX_WS - I.SIX_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIU_WS - I.SIU_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.UIX_WS - I.UIX_WS) / 1000.0) AS SQL_WS
        , CONVERT(decimal(19,03), (T.NIO_WT - I.NIO_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.DIO_WT - I.DIO_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIO_WT - I.SIO_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.PIO_WT - I.PIO_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.LOG_WT - I.LOG_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.RAM_WT - I.RAM_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.CPU_WT - I.CPU_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.DOP_WT - I.DOP_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.DBM_WT - I.DBM_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.DBS_WT - I.DBS_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.X___WT - I.X___WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.U___WT - I.U___WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.S___WT - I.S___WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.IX__WT - I.IX__WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.IU__WT - I.IU__WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.IS__WT - I.IS__WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIX_WT - I.SIX_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIU_WT - I.SIU_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.UIX_WT - I.UIX_WT) / 1000.0) AS SQL_WT
        , CONVERT(decimal(19,03), (T.NIO_WT - I.NIO_WT) / 1000.0) AS NIO_WT
        , CONVERT(decimal(19,03), (T.DIO_WT - I.DIO_WT) / 1000.0) AS DIO_WT
        , CONVERT(decimal(19,03), (T.SIO_WT - I.SIO_WT) / 1000.0) AS SIO_WT
        , CONVERT(decimal(19,03), (T.PIO_WT - I.PIO_WT) / 1000.0) AS PIO_WT
        , CONVERT(decimal(19,03), (T.LOG_WT - I.LOG_WT) / 1000.0) AS LOG_WT
        , CONVERT(decimal(19,03), (T.RAM_WT - I.RAM_WT) / 1000.0) AS RAM_WT
        , CONVERT(decimal(19,03), (T.CPU_WT - I.CPU_WT) / 1000.0) AS CPU_WT
        , CONVERT(decimal(19,03), (T.DOP_WT - I.DOP_WT) / 1000.0) AS DOP_WT
        , CONVERT(decimal(19,03), (T.DBM_WT - I.DBM_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.DBS_WT - I.DBS_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.X___WT - I.X___WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.U___WT - I.U___WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.S___WT - I.S___WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.IX__WT - I.IX__WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.IU__WT - I.IU__WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.IS__WT - I.IS__WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIX_WT - I.SIX_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIU_WT - I.SIU_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.UIX_WT - I.UIX_WT) / 1000.0) AS LCK_WT
        , I.KeyID
     FROM #WaitHistory AS I
     JOIN #WaitHistory AS T
       ON I.KeyID + @Intervals
        = T.KeyID
    WHERE I.KeyID % @Intervals = 0) AS E
 ORDER BY E.KeyID

/*

   SELECT CONVERT(varchar(20), T.KeyDT, 120) AS KeyDT
        , DATEDIFF(second, I.KeyDT, T.KeyDT) AS Seconds
        , CONVERT(decimal(19,03), (T.NIO_WS - I.NIO_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.DIO_WS - I.DIO_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIO_WS - I.SIO_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.PIO_WS - I.PIO_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.LOG_WS - I.LOG_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.RAM_WS - I.RAM_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.CPU_WS - I.CPU_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.DOP_WS - I.DOP_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.DBM_WS - I.DBM_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.DBS_WS - I.DBS_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.X___WS - I.X___WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.U___WS - I.U___WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.S___WS - I.S___WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.IX__WS - I.IX__WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.IU__WS - I.IU__WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.IS__WS - I.IS__WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIX_WS - I.SIX_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIU_WS - I.SIU_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.UIX_WS - I.UIX_WS) / 1000.0) AS SQL_WS
        , CONVERT(decimal(19,03), (T.NIO_WT - I.NIO_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.DIO_WT - I.DIO_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIO_WT - I.SIO_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.PIO_WT - I.PIO_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.LOG_WT - I.LOG_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.RAM_WT - I.RAM_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.CPU_WT - I.CPU_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.DOP_WT - I.DOP_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.DBM_WT - I.DBM_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.DBS_WT - I.DBS_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.X___WT - I.X___WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.U___WT - I.U___WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.S___WT - I.S___WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.IX__WT - I.IX__WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.IU__WT - I.IU__WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.IS__WT - I.IS__WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIX_WT - I.SIX_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIU_WT - I.SIU_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.UIX_WT - I.UIX_WT) / 1000.0) AS SQL_WT
        ,                         (T.NIO_WC - I.NIO_WC)           AS NIO_WC
        , CONVERT(decimal(19,03), (T.NIO_WT - I.NIO_WT) / 1000.0) AS NIO_WT
        ,                         (T.DIO_WC - I.DIO_WC)           AS DIO_WC
        , CONVERT(decimal(19,03), (T.DIO_WT - I.DIO_WT) / 1000.0) AS DIO_WT
        ,                         (T.SIO_WC - I.SIO_WC)           AS SIO_WC
        , CONVERT(decimal(19,03), (T.SIO_WT - I.SIO_WT) / 1000.0) AS SIO_WT
        ,                         (T.PIO_WC - I.PIO_WC)           AS PIO_WC
        , CONVERT(decimal(19,03), (T.PIO_WT - I.PIO_WT) / 1000.0) AS PIO_WT
        ,                         (T.LOG_WC - I.LOG_WC)           AS LOG_WC
        , CONVERT(decimal(19,03), (T.LOG_WT - I.LOG_WT) / 1000.0) AS LOG_WT
        ,                         (T.RAM_WC - I.RAM_WC)           AS RAM_WC
        , CONVERT(decimal(19,03), (T.RAM_WT - I.RAM_WT) / 1000.0) AS RAM_WT
        ,                         (T.CPU_WC - I.CPU_WC)           AS CPU_WC
        , CONVERT(decimal(19,03), (T.CPU_WT - I.CPU_WT) / 1000.0) AS CPU_WT
        ,                         (T.DOP_WC - I.DOP_WC)           AS DOP_WC
        , CONVERT(decimal(19,03), (T.DOP_WT - I.DOP_WT) / 1000.0) AS DOP_WT
        ,                         (T.DBM_WC - I.DBM_WC)
        +                         (T.DBS_WC - I.DBS_WC)
        +                         (T.X___WC - I.X___WC)
        +                         (T.U___WC - I.U___WC)
        +                         (T.S___WC - I.S___WC)
        +                         (T.IX__WC - I.IX__WC)
        +                         (T.IU__WC - I.IU__WC)
        +                         (T.IS__WC - I.IS__WC)
        +                         (T.SIX_WC - I.SIX_WC)
        +                         (T.SIU_WC - I.SIU_WC)
        +                         (T.UIX_WC - I.UIX_WC)           AS LCK_WC
        , CONVERT(decimal(19,03), (T.DBM_WT - I.DBM_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.DBS_WT - I.DBS_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.X___WT - I.X___WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.U___WT - I.U___WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.S___WT - I.S___WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.IX__WT - I.IX__WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.IU__WT - I.IU__WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.IS__WT - I.IS__WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIX_WT - I.SIX_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIU_WT - I.SIU_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.UIX_WT - I.UIX_WT) / 1000.0) AS LCK_WT
     FROM #WaitHistory AS I
     JOIN #WaitHistory AS T
       ON I.KeyID + @Intervals
        = T.KeyID
    WHERE I.KeyID % @Intervals = 0
 ORDER BY T.KeyID

*/

/*

   SELECT CONVERT(varchar(20), T.KeyDT, 120) AS KeyDT
        , DATEDIFF(second, I.KeyDT, T.KeyDT) AS Seconds
        , CONVERT(decimal(19,03), (T.NIO_WS - I.NIO_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.DIO_WS - I.DIO_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIO_WS - I.SIO_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.PIO_WS - I.PIO_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.LOG_WS - I.LOG_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.RAM_WS - I.RAM_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.CPU_WS - I.CPU_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.DOP_WS - I.DOP_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.DBM_WS - I.DBM_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.DBS_WS - I.DBS_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.X___WS - I.X___WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.U___WS - I.U___WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.S___WS - I.S___WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.IX__WS - I.IX__WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.IU__WS - I.IU__WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.IS__WS - I.IS__WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIX_WS - I.SIX_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIU_WS - I.SIU_WS) / 1000.0)
        + CONVERT(decimal(19,03), (T.UIX_WS - I.UIX_WS) / 1000.0) AS SQL_WS
        , CONVERT(decimal(19,03), (T.NIO_WT - I.NIO_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.DIO_WT - I.DIO_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIO_WT - I.SIO_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.PIO_WT - I.PIO_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.LOG_WT - I.LOG_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.RAM_WT - I.RAM_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.CPU_WT - I.CPU_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.DOP_WT - I.DOP_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.DBM_WT - I.DBM_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.DBS_WT - I.DBS_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.X___WT - I.X___WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.U___WT - I.U___WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.S___WT - I.S___WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.IX__WT - I.IX__WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.IU__WT - I.IU__WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.IS__WT - I.IS__WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIX_WT - I.SIX_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.SIU_WT - I.SIU_WT) / 1000.0)
        + CONVERT(decimal(19,03), (T.UIX_WT - I.UIX_WT) / 1000.0) AS SQL_WT
        ,                         (T.NIO_WC - I.NIO_WC)           AS NIO_WC
        , CONVERT(decimal(19,03), (T.NIO_WT - I.NIO_WT) / 1000.0) AS NIO_WT
        ,                         (T.DIO_WC - I.DIO_WC)           AS DIO_WC
        , CONVERT(decimal(19,03), (T.DIO_WT - I.DIO_WT) / 1000.0) AS DIO_WT
        ,                         (T.SIO_WC - I.SIO_WC)           AS SIO_WC
        , CONVERT(decimal(19,03), (T.SIO_WT - I.SIO_WT) / 1000.0) AS SIO_WT
        ,                         (T.PIO_WC - I.PIO_WC)           AS PIO_WC
        , CONVERT(decimal(19,03), (T.PIO_WT - I.PIO_WT) / 1000.0) AS PIO_WT
        ,                         (T.LOG_WC - I.LOG_WC)           AS LOG_WC
        , CONVERT(decimal(19,03), (T.LOG_WT - I.LOG_WT) / 1000.0) AS LOG_WT
        ,                         (T.RAM_WC - I.RAM_WC)           AS RAM_WC
        , CONVERT(decimal(19,03), (T.RAM_WT - I.RAM_WT) / 1000.0) AS RAM_WT
        ,                         (T.CPU_WC - I.CPU_WC)           AS CPU_WC
        , CONVERT(decimal(19,03), (T.CPU_WT - I.CPU_WT) / 1000.0) AS CPU_WT
        ,                         (T.DOP_WC - I.DOP_WC)           AS DOP_WC
        , CONVERT(decimal(19,03), (T.DOP_WT - I.DOP_WT) / 1000.0) AS DOP_WT
        ,                         (T.DBM_WC - I.DBM_WC)           AS DBM_WC
        , CONVERT(decimal(19,03), (T.DBM_WT - I.DBM_WT) / 1000.0) AS DBM_WT
        ,                         (T.DBS_WC - I.DBS_WC)           AS DBS_WC
        , CONVERT(decimal(19,03), (T.DBS_WT - I.DBS_WT) / 1000.0) AS DBS_WT
        ,                         (T.X___WC - I.X___WC)           AS X___WC
        , CONVERT(decimal(19,03), (T.X___WT - I.X___WT) / 1000.0) AS X___WT
        ,                         (T.U___WC - I.U___WC)           AS U___WC
        , CONVERT(decimal(19,03), (T.U___WT - I.U___WT) / 1000.0) AS U___WT
        ,                         (T.S___WC - I.S___WC)           AS S___WC
        , CONVERT(decimal(19,03), (T.S___WT - I.S___WT) / 1000.0) AS S___WT
        ,                         (T.IX__WC - I.IX__WC)           AS IX__WC
        , CONVERT(decimal(19,03), (T.IX__WT - I.IX__WT) / 1000.0) AS IX__WT
        ,                         (T.IU__WC - I.IU__WC)           AS IU__WC
        , CONVERT(decimal(19,03), (T.IU__WT - I.IU__WT) / 1000.0) AS IU__WT
        ,                         (T.IS__WC - I.IS__WC)           AS IS__WC
        , CONVERT(decimal(19,03), (T.IS__WT - I.IS__WT) / 1000.0) AS IS__WT
        ,                         (T.SIX_WC - I.SIX_WC)           AS SIX_WC
        , CONVERT(decimal(19,03), (T.SIX_WT - I.SIX_WT) / 1000.0) AS SIX_WT
        ,                         (T.SIU_WC - I.SIU_WC)           AS SIU_WC
        , CONVERT(decimal(19,03), (T.SIU_WT - I.SIU_WT) / 1000.0) AS SIU_WT
        ,                         (T.UIX_WC - I.UIX_WC)           AS UIX_WC
        , CONVERT(decimal(19,03), (T.UIX_WT - I.UIX_WT) / 1000.0) AS UIX_WT
     FROM #WaitHistory AS I
     JOIN #WaitHistory AS T
       ON I.KeyID + @Intervals
        = T.KeyID
    WHERE I.KeyID % @Intervals = 0
 ORDER BY T.KeyID

*/

-- 

   SELECT T.wait_type
        , CONVERT(varchar(20), MIN(C.KeyDT), 120) AS KeyDT_MIN
        , CONVERT(varchar(20), MAX(C.KeyDT), 120) AS KeyDT_MAX
        , SUM(C.wait_count) AS wait_count
        , COUNT(*)          AS Intervals
        , CONVERT(decimal(09,02), AVG(C.wait_count))                                                                       AS [Average]
        , CONVERT(decimal(05,02), SUM(C.wait_count) * 100.0 / CASE WHEN Z.wait_count > 0.0 THEN Z.wait_count ELSE 1.0 END) AS [Percent]
     FROM #wait_count AS C
     JOIN #wait_type  AS T
       ON C.wait_ID
        = T.wait_ID
     JOIN
  (SELECT SUM(W.wait_count) AS wait_count
     FROM #wait_count AS W) AS Z
       ON 0 = 0
 GROUP BY T.wait_type
        , Z.wait_count
 ORDER BY [Percent] DESC

   SELECT ROW_NUMBER() OVER (PARTITION BY I.database_id ORDER BY I.KeyID) - 1 AS KeyID
        , I.KeyDT
        , I.database_id
        , I.num_of_files
        , I.size_on_disk_bytes
        , I.num_of_reads
        , I.num_of_writes
        , I.num_of_bytes_read
        , I.num_of_bytes_written
        , I.io_stall_read_ms
        , I.io_stall_write_ms
     INTO #FileHistoryWork
     FROM #FileHistory AS I
 ORDER BY I.database_id
        , I.KeyID

-- CREATE UNIQUE CLUSTERED INDEX idx_KeyDT ON #FileHistoryWork (KeyDT, database_id)

-- CREATE UNIQUE CLUSTERED INDEX idx_KeyID ON #FileHistoryWork (KeyID, database_id)

   SELECT W.name         AS [Database]
        , T.num_of_files AS [Files]
        , CONVERT(varchar(20), T.KeyDT, 120) AS KeyDT
        , DATEDIFF(second, I.KeyDT, T.KeyDT) AS Seconds
        ,                                                                                                                                                    (T.num_of_reads  - I.num_of_reads )      AS Tally_Reads
        ,                                                                                                                                                    (T.num_of_writes - I.num_of_writes)      AS Tally_Writes
        , CONVERT(decimal(19,03), (T.io_stall_read_ms     - I.io_stall_read_ms    ) / 1000.0                                                                                                        ) AS Stall_Reads
        , CONVERT(decimal(19,03), (T.io_stall_write_ms    - I.io_stall_write_ms   ) / 1000.0                                                                                                        ) AS Stall_Writes
        , CONVERT(decimal(19,05), (T.io_stall_read_ms     - I.io_stall_read_ms    ) / 1000.0 / CASE WHEN (T.num_of_reads  - I.num_of_reads ) = 0 THEN 1 ELSE (T.num_of_reads  - I.num_of_reads ) END) AS Stall_Per_Read
        , CONVERT(decimal(19,05), (T.io_stall_write_ms    - I.io_stall_write_ms   ) / 1000.0 / CASE WHEN (T.num_of_writes - I.num_of_writes) = 0 THEN 1 ELSE (T.num_of_writes - I.num_of_writes) END) AS Stall_Per_Write
        , CONVERT(decimal(19,05), (T.num_of_bytes_read    - I.num_of_bytes_read   ) / 1024.0 / 1024.0 / 1024.0) AS GBs_File_Reads
        , CONVERT(decimal(19,05), (T.num_of_bytes_written - I.num_of_bytes_written) / 1024.0 / 1024.0 / 1024.0) AS GBs_File_Writes
        , CONVERT(decimal(19,05), (T.size_on_disk_bytes   - I.size_on_disk_bytes  ) / 1024.0 / 1024.0 / 1024.0) AS GBs_Size_Change
     FROM #FileHistoryWork AS I
     JOIN #FileHistoryWork AS T
       ON I.KeyID + @Intervals
        = T.KeyID
      AND I.database_id
        = T.database_id
     JOIN sys.databases AS W
       ON T.database_id
        = W.database_id
    WHERE I.KeyID % @Intervals = 0
 ORDER BY W.name
        , T.KeyID

DROP TABLE #Monitor

DROP TABLE #FileHistory

DROP TABLE #FileHistoryWork

DROP TABLE #wait_type

DROP TABLE #wait_count

DROP TABLE #WaitHistory

DROP TABLE #CounterHistory

DROP TABLE #Counter

SET NOCOUNT OFF

