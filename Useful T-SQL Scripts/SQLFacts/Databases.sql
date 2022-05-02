/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

SET ANSI_WARNINGS OFF

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
     ( database_id            int
     , file_id                int
     , DBName       varchar(0128)
     , DBFile       varchar(0128)
     , DBPath       varchar(0256)
     , type               tinyint
     , used                bigint
     , size                bigint
     , max_size               int
     , growth                 int
     , is_percent             bit
     , is_default             bit
     , FGName       varchar(0128) )

  DECLARE @database_id int
  DECLARE     @file_id int

  DECLARE @name   varchar(0128) = '%' -- database name LIKE

  DECLARE @DBName varchar(0128)
  DECLARE @DBFile varchar(0128)
  DECLARE @DBPath varchar(0256)
  DECLARE @DBType tinyint

  DECLARE @DBCode varchar(2000)

  DECLARE DBFiles CURSOR FAST_FORWARD FOR
   SELECT D.database_id
        , F.file_id
        , D.name
        , F.name
        , F.physical_name
        , F.type
     FROM sys.databases    AS D
     JOIN sys.master_files AS F
       ON D.database_id
        = F.database_id
    WHERE D.name LIKE @name
 ORDER BY D.name
        , F.name

OPEN DBFiles

FETCH NEXT FROM DBFiles INTO @database_id, @file_id, @DBName, @DBFile, @DBPath, @DBType

WHILE @@FETCH_STATUS = 0

    BEGIN

    SET @DBCode = 'USE [' + @DBName + ']; '
                + '   SELECT ' + CONVERT(varchar(0010), @database_id) + ' AS database_id, '
                               + CONVERT(varchar(0010),     @file_id) + ' AS     file_id, '
                               + CHAR(39) + @DBName + CHAR(39) + ' AS DBName, '
                               + CHAR(39) + @DBFile + CHAR(39) + ' AS DBFile, '
                               + CHAR(39) + @DBPath + CHAR(39) + ' AS DBPath, '
                               + STR(@DBType, 1) + ' AS type, '
                               + 'FILEPROPERTY(' + CHAR(39) + @DBFile + CHAR(39) + ', ' + CHAR(39) + 'SpaceUsed' + CHAR(39) + ') AS used, '
                               + 'F.size, '
                               + 'F.max_size, '
                               + 'F.growth, '
                               + 'F.is_percent_growth AS is_percent, '
                               + 'D.is_default, '
                               + 'D.name AS FGName '
                + '     FROM sys.database_files AS F '
                + 'LEFT JOIN sys.data_spaces    AS D '
                + '       ON F.data_space_id '
                + '        = D.data_space_id '
                + '    WHERE F.name = ' + CHAR(39) + @DBFile + CHAR(39)

    INSERT #Action EXECUTE (@DBCode)

    FETCH NEXT FROM DBFiles INTO @database_id, @file_id, @DBName, @DBFile, @DBPath, @DBType

    END

CLOSE DBFiles DEALLOCATE DBFiles

   SELECT B.database_name
        , B.type
        , MAX(B.backup_start_date) AS backup_start_date
     INTO #Action_BACKUPs
     FROM msdb.dbo.backupset AS B
    WHERE B.server_name = @@SERVERNAME
      AND B.backup_finish_date IS NOT NULL
      AND B.type IN ('D', 'I', 'L')
 GROUP BY B.database_name
        , B.type
 ORDER BY B.database_name
        , B.type

   SELECT D.name                AS [DBName]
        , P.name                AS [DBOwner]
        , D.state_desc          AS [DBState]
        , D.user_access_desc    AS [DBAccess]
        , D.recovery_model_desc AS [Recovery]
        , D.collation_name
        , CONVERT(varchar(0040),       D.create_date, 120) AS create_date
        , CONVERT(varchar(0040), B.backup_start_date, 120) AS Last_BACKUP_Full
        , CONVERT(varchar(0040), I.backup_start_date, 120) AS Last_BACKUP_Diff
        , CONVERT(varchar(0040), L.backup_start_date, 120) AS Last_BACKUP_TLog
     FROM sys.databases    AS D
     JOIN sys.server_principals AS P
       ON D.owner_sid
        =       P.sid
LEFT JOIN #Action_BACKUPs AS B ON D.name = B.database_name AND B.type = 'D'
LEFT JOIN #Action_BACKUPs AS I ON D.name = I.database_name AND I.type = 'I'
LEFT JOIN #Action_BACKUPs AS L ON D.name = L.database_name AND L.type = 'L'
    WHERE CASE WHEN D.database_id = 1 THEN 0
               WHEN D.database_id = 2 THEN 1
               WHEN D.database_id = 3 THEN 0
               WHEN D.database_id = 4 THEN 0 ELSE 1 END != 0
      AND D.name LIKE @name
 ORDER BY CASE WHEN D.database_id = 1 THEN 1
               WHEN D.database_id = 2 THEN 4
               WHEN D.database_id = 3 THEN 2
               WHEN D.database_id = 4 THEN 3 ELSE 5 END
        , D.name

   SELECT D.name                AS [DBName]
        , Z.Files_Data
        , CONVERT(decimal(19,05), (W.Pages_Size_SUM                   ) / 128.0 / 1024.0) AS GBs_Size_Data
        , CONVERT(decimal(19,05), (                   W.Pages_Used_SUM) / 128.0 / 1024.0) AS GBs_Used_Data
        , CONVERT(decimal(19,05), (W.Pages_Size_SUM - W.Pages_Used_SUM) / 128.0 / 1024.0) AS GBs_Free_Data
        , CONVERT(decimal(05,02), (                   W.Pages_Used_SUM) * 100.0 / W.Pages_Size_SUM) AS Percent_Used
        , CONVERT(decimal(05,02), (W.Pages_Size_SUM - W.Pages_Used_SUM) * 100.0 / W.Pages_Size_SUM) AS Percent_Free
--      , CONVERT(decimal(19,05), (W.Pages_Size_MIN                   ) / 128.0 / 1024.0) AS GBs_File_MIN
--      , CONVERT(decimal(19,05), (W.Pages_Size_MAX                   ) / 128.0 / 1024.0) AS GBs_File_MAX
     FROM sys.databases    AS D
     JOIN
  (SELECT F.database_id
        , MIN(CASE WHEN F.type = 0 THEN F.size ELSE NULL END) AS Pages_Size_MIN
        , MAX(CASE WHEN F.type = 0 THEN F.size ELSE NULL END) AS Pages_Size_MAX
        , SUM(CASE WHEN F.type = 0 THEN F.size ELSE 0    END) AS Pages_Size_SUM
        , SUM(CASE WHEN F.type = 1 THEN F.size ELSE 0    END) AS Pages_Size_Log
        , SUM(CASE WHEN F.type = 0 THEN 1      ELSE 0    END) AS Files_Data
        , SUM(CASE WHEN F.type = 1 THEN 1      ELSE 0    END) AS Files_Log
     FROM sys.master_files AS F
 GROUP BY F.database_id)   AS Z
       ON D.database_id
        = Z.database_id
     JOIN
  (SELECT S.database_id
        , MIN(CASE WHEN S.type = 0 THEN S.size ELSE NULL END) AS Pages_Size_MIN
        , MAX(CASE WHEN S.type = 0 THEN S.size ELSE NULL END) AS Pages_Size_MAX
        , SUM(CASE WHEN S.type = 0 THEN S.size ELSE 0    END) AS Pages_Size_SUM
        , SUM(CASE WHEN S.type = 1 THEN S.size ELSE 0    END) AS Pages_Size_Log
        , SUM(CASE WHEN S.type = 0 THEN S.used ELSE 0    END) AS Pages_Used_SUM
        , SUM(CASE WHEN S.type = 1 THEN S.used ELSE 0    END) AS Pages_Used_Log
     FROM #Action AS S
 GROUP BY S.database_id)   AS W
       ON D.database_id
        = W.database_id
    WHERE CASE WHEN D.database_id = 1 THEN 0
               WHEN D.database_id = 2 THEN 1
               WHEN D.database_id = 3 THEN 0
               WHEN D.database_id = 4 THEN 0 ELSE 1 END != 0
      AND D.name LIKE @name
 ORDER BY CASE WHEN D.database_id = 1 THEN 1
               WHEN D.database_id = 2 THEN 4
               WHEN D.database_id = 3 THEN 2
               WHEN D.database_id = 4 THEN 3 ELSE 5 END
        , D.name

   SELECT D.name                AS [DBName]
        , Z.Files_Log
        , CONVERT(decimal(19,05), (W.Pages_Size_Log                   ) / 128.0 / 1024.0) AS GBs_Size_Log
        , CONVERT(decimal(19,05), (                   W.Pages_Used_Log) / 128.0 / 1024.0) AS GBs_Used_Log
        , CONVERT(decimal(19,05), (W.Pages_Size_Log - W.Pages_Used_Log) / 128.0 / 1024.0) AS GBs_Free_Log
        , CONVERT(decimal(05,02), (                   W.Pages_Used_Log) * 100.0 / W.Pages_Size_Log) AS Percent_Used
        , CONVERT(decimal(05,02), (W.Pages_Size_Log - W.Pages_Used_Log) * 100.0 / W.Pages_Size_Log) AS Percent_Free
     FROM sys.databases    AS D
     JOIN
  (SELECT F.database_id
        , MIN(CASE WHEN F.type = 0 THEN F.size ELSE NULL END) AS Pages_Size_MIN
        , MAX(CASE WHEN F.type = 0 THEN F.size ELSE NULL END) AS Pages_Size_MAX
        , SUM(CASE WHEN F.type = 0 THEN F.size ELSE 0    END) AS Pages_Size_SUM
        , SUM(CASE WHEN F.type = 1 THEN F.size ELSE 0    END) AS Pages_Size_Log
        , SUM(CASE WHEN F.type = 0 THEN 1      ELSE 0    END) AS Files_Data
        , SUM(CASE WHEN F.type = 1 THEN 1      ELSE 0    END) AS Files_Log
     FROM sys.master_files AS F
 GROUP BY F.database_id)   AS Z
       ON D.database_id
        = Z.database_id
     JOIN
  (SELECT S.database_id
        , MIN(CASE WHEN S.type = 0 THEN S.size ELSE NULL END) AS Pages_Size_MIN
        , MAX(CASE WHEN S.type = 0 THEN S.size ELSE NULL END) AS Pages_Size_MAX
        , SUM(CASE WHEN S.type = 0 THEN S.size ELSE 0    END) AS Pages_Size_SUM
        , SUM(CASE WHEN S.type = 1 THEN S.size ELSE 0    END) AS Pages_Size_Log
        , SUM(CASE WHEN S.type = 0 THEN S.used ELSE 0    END) AS Pages_Used_SUM
        , SUM(CASE WHEN S.type = 1 THEN S.used ELSE 0    END) AS Pages_Used_Log
     FROM #Action AS S
 GROUP BY S.database_id)   AS W
       ON D.database_id
        = W.database_id
    WHERE CASE WHEN D.database_id = 1 THEN 0
               WHEN D.database_id = 2 THEN 1
               WHEN D.database_id = 3 THEN 0
               WHEN D.database_id = 4 THEN 0 ELSE 1 END != 0
      AND D.name LIKE @name
 ORDER BY CASE WHEN D.database_id = 1 THEN 1
               WHEN D.database_id = 2 THEN 4
               WHEN D.database_id = 3 THEN 2
               WHEN D.database_id = 4 THEN 3 ELSE 5 END
        , D.name

   SELECT S.DBName
        , S.FGName
        , S.is_default
        , COUNT(*)                                                                   AS Files_Data
        , CONVERT(decimal(19,05), (SUM(S.size)              ) / 128.0 / 1024.0)      AS GBs_Size_Data
        , CONVERT(decimal(19,05), (              SUM(S.used)) / 128.0 / 1024.0)      AS GBs_Used_Data
        , CONVERT(decimal(19,05), (SUM(S.size) - SUM(S.used)) / 128.0 / 1024.0)      AS GBs_Free_Data
        , CONVERT(decimal(05,02), (              SUM(S.used)) * 100.0 / SUM(S.size)) AS Percent_Used
        , CONVERT(decimal(05,02), (SUM(S.size) - SUM(S.used)) * 100.0 / SUM(S.size)) AS Percent_Free
        , CONVERT(decimal(19,05), (MIN(S.size)              ) / 128.0 / 1024.0)      AS GBs_File_MIN
        , CONVERT(decimal(19,05), (MAX(S.size)              ) / 128.0 / 1024.0)      AS GBs_File_MAX
     FROM #Action AS S
    WHERE CASE WHEN S.database_id = 1 THEN 0
               WHEN S.database_id = 2 THEN 1
               WHEN S.database_id = 3 THEN 0
               WHEN S.database_id = 4 THEN 0 ELSE 1 END != 0
      AND S.type = 0
 GROUP BY S.database_id
        , S.DBName
        , S.FGName
        , S.is_default
 ORDER BY CASE WHEN S.database_id = 1 THEN 1
               WHEN S.database_id = 2 THEN 4
               WHEN S.database_id = 3 THEN 2
               WHEN S.database_id = 4 THEN 3 ELSE 5 END
        , S.DBName
        , S.FGName

   SELECT S.DBName
        , S.FGName
        , S.DBFile
        , S.DBPath
--      , V.volume_mount_point AS FSPath
        , CASE WHEN S.is_percent  = 0 THEN  0       ELSE CONVERT(decimal(09,00), S.growth                   ) END AS [Percent_File]
        , CASE WHEN S.is_percent != 0 THEN  0.00000 ELSE CONVERT(decimal(19,05), S.growth   / 128.0 / 1024.0) END AS [GBs_ADD_File]
        , CASE WHEN S.max_size    < 0 THEN -1.00000 ELSE CONVERT(decimal(19,05), S.max_size / 128.0 / 1024.0) END AS [GBs_MAX_File]
        , CONVERT(decimal(19,05), (S.size         ) / 128.0 / 1024.0) AS GBs_Size_File
        , CONVERT(decimal(19,05), (         S.used) / 128.0 / 1024.0) AS GBs_Used_File
        , CONVERT(decimal(19,05), (S.size - S.used) / 128.0 / 1024.0) AS GBs_Free_File
--      , CONVERT(decimal(05,02), (         S.used) * 100.0 / S.size) AS Percent_Used_File
--      , CONVERT(decimal(05,02), (S.size - S.used) * 100.0 / S.size) AS Percent_Free_File
        , CONVERT(decimal(19,05), (V.total_bytes                    ) / 1024.0 / 1024.0 / 1024.0) AS GBs_Size_Disk
        , CONVERT(decimal(19,05), (V.total_bytes - V.available_bytes) / 1024.0 / 1024.0 / 1024.0) AS GBs_Used_Disk
        , CONVERT(decimal(19,05), (                V.available_bytes) / 1024.0 / 1024.0 / 1024.0) AS GBs_Free_Disk
--      , CONVERT(decimal(05,02), (V.total_bytes - V.available_bytes) * 100.0 / V.total_bytes) AS Percent_Used_Disk
--      , CONVERT(decimal(05,02), (                V.available_bytes) * 100.0 / V.total_bytes) AS Percent_Free_Disk
     FROM #Action AS S CROSS APPLY sys.dm_os_volume_stats(S.database_id, S.file_id) AS V
    WHERE CASE WHEN S.database_id = 1 THEN 0
               WHEN S.database_id = 2 THEN 1
               WHEN S.database_id = 3 THEN 0
               WHEN S.database_id = 4 THEN 0 ELSE 1 END != 0
      AND S.type = 0
 ORDER BY CASE WHEN S.database_id = 1 THEN 1
               WHEN S.database_id = 2 THEN 4
               WHEN S.database_id = 3 THEN 2
               WHEN S.database_id = 4 THEN 3 ELSE 5 END
        , S.DBName
        , S.FGName
        , S.DBFile

DROP TABLE #Action

DROP TABLE #Action_BACKUPs

SET ANSI_WARNINGS ON

SET NOCOUNT OFF

