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

CREATE TABLE #Action
     ( database_id     int
     , used         bigint
     , size         bigint )

  DECLARE @database_id int

  DECLARE @DBName varchar(0128)

  DECLARE @DBCode varchar(2000)

  DECLARE DBNames CURSOR FAST_FORWARD FOR
   SELECT D.database_id
        , D.name
     FROM sys.databases    AS D
 ORDER BY D.name

OPEN DBNames

FETCH NEXT FROM DBNames INTO @database_id, @DBName

WHILE @@FETCH_STATUS = 0

    BEGIN

    SET @DBCode = 'USE [' + @DBName + ']; '
                + '   SELECT ' + CONVERT(varchar(0010), @database_id) + ' AS database_id'
                +         ', ' + 'L.used_log_space_in_bytes'
                +         ', ' + 'L.total_log_size_in_bytes'
                + '     FROM sys.dm_db_log_space_usage AS L'

    INSERT #Action EXECUTE (@DBCode)

    FETCH NEXT FROM DBNames INTO @database_id, @DBName

    END

CLOSE DBNames DEALLOCATE DBNames

   SELECT G.name
        , R.replica_server_name
        , R.create_date
        , R.modify_date
        , R.availability_mode_desc
        , R.failover_mode_desc
        , A.operational_state_desc
        , A.role
        , A.role_desc
        , D.database_id
        , D.last_commit_time
     INTO #Action_AG
     FROM sys.availability_groups AS G
     JOIN sys.availability_replicas AS R
       ON G.group_id
        = R.group_id
     JOIN sys.dm_hadr_availability_replica_states AS A
       ON R.group_id
        = A.group_id
      AND R.replica_id
        = A.replica_id
     JOIN sys.dm_hadr_database_replica_states AS D
       ON R.group_id
        = D.group_id
      AND R.replica_id
        = D.replica_id
 ORDER BY D.database_id
        , R.replica_server_name

   SELECT DB_NAME(A.database_id)  AS database_name
        , A.replica_server_name   AS primary_name
        , CONVERT(decimal(19,05), T.used / 1024.0 / 1024.0 / 1024.0) AS GBs_log_used
        , CONVERT(decimal(19,05), T.size / 1024.0 / 1024.0 / 1024.0) AS GBs_log_size
        , CONVERT(decimal(05,02), T.used *  100.0 / T.size)          AS [Percent]
        , A.name                  AS group_name
        , A.availability_mode_desc
        , A.failover_mode_desc
        , A.operational_state_desc
        , CONVERT(varchar(0040), A.create_date, 120) AS create_date
        , CONVERT(varchar(0040), A.modify_date, 120) AS modify_date
     FROM #Action_AG AS A
LEFT JOIN #Action    AS T
       ON A.database_id
        = T.database_id
    WHERE A.role = 1
 ORDER BY DB_NAME(A.database_id)

   SELECT DB_NAME(P.database_id)  AS database_name
        , S.replica_server_name   AS secondary_name
        ,                         DATEDIFF(second, S.last_commit_time, P.last_commit_time)         AS Lag_Seconds
        , CONVERT(decimal(09,03), DATEDIFF(second, S.last_commit_time, P.last_commit_time) / 60.0) AS Lag_Minutes
     FROM
  (SELECT A.replica_server_name
        , A.database_id
        , A.last_commit_time
     FROM #Action_AG  AS A
    WHERE A.role = 1) AS P
     JOIN
  (SELECT A.replica_server_name
        , A.database_id
        , A.last_commit_time
     FROM #Action_AG  AS A
    WHERE A.role = 2) AS S
       ON P.database_id
        = S.database_id
 ORDER BY DB_NAME(P.database_id)
        , P.replica_server_name
        , S.replica_server_name

DROP TABLE #Action

DROP TABLE #Action_AG

SET NOCOUNT OFF

