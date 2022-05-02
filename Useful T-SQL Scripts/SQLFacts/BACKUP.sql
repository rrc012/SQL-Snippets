/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

DECLARE @name varchar(0128) = '%' -- database name LIKE

   SELECT B.database_name
        , B.type
        , MIN(B.backup_start_date) AS backup_start_date_MIN
        , MAX(B.backup_start_date) AS backup_start_date_MAX
     INTO #Action_BACKUPs
     FROM msdb.dbo.backupset         AS B
    WHERE B.server_name = @@SERVERNAME
      AND B.database_name LIKE @name
      AND B.backup_finish_date IS NOT NULL
      AND B.type IN ('D', 'I', 'L')
 GROUP BY B.database_name
        , B.type
 ORDER BY B.database_name
        , B.type

   SELECT D.name                AS [DBName]
        , D.recovery_model_desc AS [Recovery]
        , CONVERT(varchar(0040), B.backup_start_date_MIN, 120) AS Oldest_BACKUP_Full
        , CONVERT(varchar(0040), I.backup_start_date_MIN, 120) AS Oldest_BACKUP_Diff
        , CONVERT(varchar(0040), L.backup_start_date_MIN, 120) AS Oldest_BACKUP_TLog
        , CONVERT(varchar(0040), B.backup_start_date_MAX, 120) AS Newest_BACKUP_Full
        , CONVERT(varchar(0040), I.backup_start_date_MAX, 120) AS Newest_BACKUP_Diff
        , CONVERT(varchar(0040), L.backup_start_date_MAX, 120) AS Newest_BACKUP_TLog
     FROM sys.databases AS D
LEFT JOIN #Action_BACKUPs AS B ON D.name = B.database_name AND B.type = 'D'
LEFT JOIN #Action_BACKUPs AS I ON D.name = I.database_name AND I.type = 'I'
LEFT JOIN #Action_BACKUPs AS L ON D.name = L.database_name AND L.type = 'L'
    WHERE D.name LIKE @name
 ORDER BY CASE WHEN D.database_id = 1 THEN 1
               WHEN D.database_id = 2 THEN 4
               WHEN D.database_id = 3 THEN 2
               WHEN D.database_id = 4 THEN 3 ELSE 5 END
        , D.name

   SELECT B.backup_set_id          AS BACKUP_ID -- for use with RESTORE
        , B.database_name          AS BACKUP_Name
        , B.type                   AS BACKUP_Type
        , F.physical_device_name   AS BACKUP_Path
        , B.user_name              AS BACKUP_User
        , B.backup_start_date      AS BACKUP_From
        , B.backup_finish_date     AS BACKUP_Thru
        , CONVERT(decimal(19,03), DATEDIFF(minute, B.backup_start_date, B.backup_finish_date) / 60.0) AS [Minutes]
        , CONVERT(decimal(19,05), B.backup_size            / 1024.0 / 1024.0 / 1024.0) AS GBs_As_Created
        , CONVERT(decimal(19,05), B.compressed_backup_size / 1024.0 / 1024.0 / 1024.0) AS GBs_Compressed
        , B.is_copy_only
        , B.position
        , F.family_sequence_number
        , B.software_major_version
        , B.software_minor_version
     FROM msdb.dbo.backupset         AS B
     JOIN msdb.dbo.backupmediafamily AS F
       ON B.media_set_id
        = F.media_set_id
    WHERE B.server_name = @@SERVERNAME
      AND B.database_name LIKE @name
      AND B.backup_finish_date IS NOT NULL
      AND B.type IN ('D', 'I', 'L')
 ORDER BY B.database_name
        , B.backup_start_date
        , F.family_sequence_number

DROP TABLE #Action_BACKUPs

SET NOCOUNT OFF

