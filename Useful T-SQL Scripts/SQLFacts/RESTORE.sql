/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

DECLARE @backup_set_id int = (0) -- enter BACKUP_ID on this line

DECLARE @PIT  varchar(0080) = SPACE(0) -- ', STOPAT = ' + CHAR(39) + '2021/01/01 00:00:00' + CHAR(39) -- for a point-in-time restore

DECLARE @Code varchar(8000)

DECLARE @Disk varchar(2000)

DECLARE @Line smallint

DECLARE @Base datetime = CONVERT(datetime,'1900/01/01')

CREATE TABLE #Pack
     ( LogicalName             nvarchar(0128)
     , PhysicalName            nvarchar(0260)
     , Type                        char(0001)
     , FileGroupName           nvarchar(0128)
     , Size                    numeric(20,00)
     , MaxSize                 numeric(20,00)
     , FileID                          bigint
     , CreateLSN               numeric(25,00)
     , DropLSN                 numeric(25,00)
     , UniqueID              uniqueidentifier
     , ReadOnlyLSN             numeric(25,00)
     , ReadWriteLSN            numeric(25,00)
     , BackupSizeInBytes               bigint
     , SourceBlockSize                    int
     , FileGroupID                        int
     , LogGroupGUID          uniqueidentifier
     , DifferentialBaseLSN     numeric(25,00)
     , DifferentialBaseGUID  uniqueidentifier
     , IsReadOnly                         bit
     , IsPresent                          bit )
--   , TDEThumbprint          varbinary(0032) )
--   , SnapshotURL             nvarchar(0360) )

IF (SELECT B.software_major_version FROM msdb.dbo.backupset AS B WHERE B.backup_set_id = @backup_set_id) !< 10 ALTER TABLE #Pack ADD TDEThumbprint          varbinary(0032)
IF (SELECT B.software_major_version FROM msdb.dbo.backupset AS B WHERE B.backup_set_id = @backup_set_id) !< 13 ALTER TABLE #Pack ADD SnapshotURL             nvarchar(0360)

   SELECT E.database_name
        , E.backup_start_date
        , MAX(CASE WHEN B.type = 'D' THEN B.backup_start_date ELSE @Base END) AS backup_start_date_full
        , MAX(CASE WHEN B.type = 'I' THEN B.backup_start_date ELSE @Base END) AS backup_start_date_diff
        , CONVERT(     int, 0) AS position_full
        , CONVERT(     int, 0) AS position_diff
        , CONVERT(smallint, 0) AS family_sequence_number_full_MIN
        , CONVERT(smallint, 0) AS family_sequence_number_full_MAX
        , CONVERT(smallint, 0) AS family_sequence_number_diff_MIN
        , CONVERT(smallint, 0) AS family_sequence_number_diff_MAX
     INTO #Back
     FROM msdb.dbo.backupset AS B
     JOIN
  (SELECT I.database_name
        , I.backup_start_date
     FROM msdb.dbo.backupset AS I
    WHERE I.backup_set_id
        =  @backup_set_id)   AS E
       ON B.database_name
        = E.database_name
      AND B.backup_start_date
       !> E.backup_start_date
    WHERE B.is_copy_only = 0
 GROUP BY E.database_name
        , E.backup_start_date

IF @@ROWCOUNT = 0 GOTO FINISH

   UPDATE #Back SET
          backup_start_date_diff = @Base
    WHERE backup_start_date_diff
        < backup_start_date_full

IF @@ROWCOUNT < 0 GOTO FINISH

   UPDATE #Back SET
            position_full
        = O.position_full
        ,   family_sequence_number_full_MIN
        = O.family_sequence_number_full_MIN
        ,   family_sequence_number_full_MAX
        = O.family_sequence_number_full_MAX
     FROM #Back AS U
     JOIN
  (SELECT B.position AS position_full
        , MIN(F.family_sequence_number) AS family_sequence_number_full_MIN
        , MAX(F.family_sequence_number) AS family_sequence_number_full_MAX
     FROM #Back AS T
     JOIN msdb.dbo.backupset         AS B
       ON T.database_name
        = B.database_name
      AND T.backup_start_date_full
        = B.backup_start_date
     JOIN msdb.dbo.backupmediafamily AS F
       ON B.media_set_id
        = F.media_set_id
    WHERE B.type = 'D'
 GROUP BY B.position)                AS O
       ON 0 = 0

IF @@ROWCOUNT = 0 GOTO FINISH

   UPDATE #Back SET
            position_diff
        = O.position_diff
        ,   family_sequence_number_diff_MIN
        = O.family_sequence_number_diff_MIN
        ,   family_sequence_number_diff_MAX
        = O.family_sequence_number_diff_MAX
     FROM #Back AS U
     JOIN
  (SELECT B.position AS position_diff
        , MIN(F.family_sequence_number) AS family_sequence_number_diff_MIN
        , MAX(F.family_sequence_number) AS family_sequence_number_diff_MAX
     FROM #Back AS T
     JOIN msdb.dbo.backupset         AS B
       ON T.database_name
        = B.database_name
      AND T.backup_start_date_diff
        = B.backup_start_date
     JOIN msdb.dbo.backupmediafamily AS F
       ON B.media_set_id
        = F.media_set_id
    WHERE B.type = 'I'
 GROUP BY B.position)                AS O
       ON 0 = 0

IF @@ROWCOUNT < 0 GOTO FINISH

SET @Code = 'RESTORE FILELISTONLY FROM' + CHAR(13) + CHAR(10)

  DECLARE Back CURSOR FAST_FORWARD FOR
   SELECT CASE WHEN F.family_sequence_number = T.family_sequence_number_full_MIN THEN CHAR(32) ELSE CHAR(44) END + ' DISK = ' + CHAR(39) + F.physical_device_name + CHAR(39)
     FROM #Back AS T
     JOIN msdb.dbo.backupset         AS B
       ON T.database_name
        = B.database_name
      AND T.backup_start_date_full
        = B.backup_start_date
     JOIN msdb.dbo.backupmediafamily AS F
       ON B.media_set_id
        = F.media_set_id
    WHERE T.backup_start_date_full
        = B.backup_start_date

OPEN Back

FETCH NEXT FROM Back INTO @Disk

WHILE @@FETCH_STATUS = 0

    BEGIN

    SET @Code = @Code + @Disk + CHAR(13) + CHAR(10)

    FETCH NEXT FROM Back INTO @Disk

    END

CLOSE Back DEALLOCATE Back

INSERT #Pack EXECUTE (@Code)

SELECT @Line = MAX(LEN(P.LogicalName)) FROM #Pack AS P

   SELECT CONVERT(tinyint, 0) AS SORT1
        , CONVERT(    int, 0) AS SORT2
        ,'RESTORE DATABASE ' + T.database_name + ' FROM' AS SQLCode
     FROM #Back AS T
    WHERE T.backup_start_date_full > @Base
    UNION
   SELECT CONVERT(tinyint, 1                       ) AS SORT1
        , CONVERT(    int, F.family_sequence_number) AS SORT2
        , CASE WHEN F.family_sequence_number = T.family_sequence_number_full_MIN THEN CHAR(32) ELSE CHAR(44) END + ' DISK = ' + CHAR(39) + F.physical_device_name + CHAR(39) AS SQLCode
     FROM #Back AS T
     JOIN msdb.dbo.backupset         AS B
       ON T.database_name
        = B.database_name
      AND T.backup_start_date_full
        = B.backup_start_date
     JOIN msdb.dbo.backupmediafamily AS F
       ON B.media_set_id
        = F.media_set_id
    WHERE T.backup_start_date_full > @Base
    UNION
   SELECT CONVERT(tinyint, 2) AS SORT1
        , CONVERT(    int, 0) AS SORT2
        , 'WITH ' + CASE WHEN T.backup_start_date_full < T.backup_start_date THEN 'NO' ELSE SPACE(2) END + 'RECOVERY' + CASE WHEN T.position_full > 1 THEN ', FILE = ' + CONVERT(varchar(10), T.position_full) ELSE SPACE(0) END        AS SQLCode
     FROM #Back AS T
    WHERE T.backup_start_date_full > @Base
    UNION
   SELECT CONVERT(tinyint, 3       ) AS SORT1
        , CONVERT(    int, T.FileID) AS SORT2
        , ', MOVE ' + CHAR(39) + T.LogicalName + CHAR(39) + SPACE(@Line - LEN(T.LogicalName)) + ' TO ' + CHAR(39) + T.PhysicalName + CHAR(39) AS SQLCode
     FROM #Pack AS T
    UNION
   SELECT CONVERT(tinyint, 4) AS SORT1
        , CONVERT(    int, 0) AS SORT2
        ,'RESTORE DATABASE ' + T.database_name + ' FROM' AS SQLCode
     FROM #Back AS T
    WHERE T.backup_start_date_diff > @Base
    UNION
   SELECT CONVERT(tinyint, 5                       ) AS SORT1
        , CONVERT(    int, F.family_sequence_number) AS SORT2
        , CASE WHEN F.family_sequence_number = T.family_sequence_number_diff_MIN THEN CHAR(32) ELSE CHAR(44) END + ' DISK = ' + CHAR(39) + F.physical_device_name + CHAR(39) AS SQLCode
     FROM #Back AS T
     JOIN msdb.dbo.backupset         AS B
       ON T.database_name
        = B.database_name
      AND T.backup_start_date_diff
        = B.backup_start_date
     JOIN msdb.dbo.backupmediafamily AS F
       ON B.media_set_id
        = F.media_set_id
    WHERE T.backup_start_date_diff > @Base
    UNION
   SELECT CONVERT(tinyint, 6) AS SORT1
        , CONVERT(    int, 0) AS SORT2
        , 'WITH ' + CASE WHEN T.backup_start_date_diff < T.backup_start_date THEN 'NO' ELSE SPACE(2) END + 'RECOVERY' + CASE WHEN T.position_diff > 1 THEN ', FILE = ' + CONVERT(varchar(10), T.position_diff) ELSE SPACE(0) END        AS SQLCode
     FROM #Back AS T
    WHERE T.backup_start_date_diff > @Base
    UNION
   SELECT CONVERT(tinyint, 7                                                              ) AS SORT1
        , CONVERT(    int, DATEDIFF(second, T.backup_start_date_full, B.backup_start_date)) AS SORT2
        , 'RESTORE LOG ' + T.database_name + ' FROM DISK = ' + CHAR(39) + F.physical_device_name + CHAR(39) + SPACE(1)
        + 'WITH ' + CASE WHEN B.backup_start_date      < T.backup_start_date THEN 'NO' ELSE SPACE(2) END + 'RECOVERY' + CASE WHEN B.position      > 1 THEN ', FILE = ' + CONVERT(varchar(10), B.position     ) ELSE SPACE(0) END + @PIT AS SQLCode
     FROM #Back AS T
     JOIN msdb.dbo.backupset         AS B
       ON T.database_name
        = B.database_name
      AND T.backup_start_date_full
        < B.backup_start_date
      AND T.backup_start_date_diff
        < B.backup_start_date
      AND T.backup_start_date
       !< B.backup_start_date
     JOIN msdb.dbo.backupmediafamily AS F
       ON B.media_set_id
        = F.media_set_id
    WHERE B.type = 'L'
 ORDER BY SORT1
        , SORT2

FINISH:

DROP TABLE #Back

DROP TABLE #Pack

SET NOCOUNT OFF

