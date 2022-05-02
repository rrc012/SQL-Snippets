/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

DECLARE @Match TABLE ([Schema] varchar(0128))

/*

INSERT @Match ([Schema])
VALUES ('dbo')
     , ('dba')

*/

   INSERT @Match ([Schema])
   SELECT S.name
     FROM sys.schemas AS S
    WHERE CASE WHEN S.schema_id  =     1 THEN 1
               WHEN S.schema_id  =     2 THEN 0
               WHEN S.schema_id  =     3 THEN 0
               WHEN S.schema_id  =     4 THEN 0
               WHEN S.schema_id !< 16384 THEN 0 ELSE 1 END != 0
 ORDER BY S.schema_id

DECLARE @DaysTable smallint = 90 -- minimum number of days without read/write activity for table DROP statement eligibility, not actively used for this variant

DECLARE @DaysIndex smallint = 90 -- minimum number of days without read/write activity for index DROP statement eligibility

DECLARE @DT datetime = (SELECT I.sqlserver_start_time FROM sys.dm_os_sys_info AS I)

DECLARE @DZ datetime = GETDATE()

DECLARE @DaysRunning smallint = DATEDIFF(day, @DT, @DZ)

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

PRINT CHAR(13) + CHAR(10)

PRINT 'Nature PK means primary   key'
PRINT 'Nature AK means alternate key (unique constraint)'
PRINT 'Nature U  means unique'
PRINT 'Nature UF means unique filtered'
PRINT 'Nature S  means simple'
PRINT 'Nature SF means simple filtered'

PRINT CHAR(13) + CHAR(10)

PRINT 'table_type 0 means a table as heap'
PRINT 'table_type 1 means a table as clustered index'
PRINT 'table_type 5 means a table as clustered index (columnstore)'

PRINT CHAR(13) + CHAR(10)

PRINT 'index_type 0 means a table as heap'
PRINT 'index_type 1 means a table as clustered index'
PRINT 'index_type 5 means a table as clustered index (columnstore)'
PRINT 'index_type 2 means a       nonclustered index'
PRINT 'index_type 6 means a       nonclustered index (columnstore)'

PRINT CHAR(13) + CHAR(10)

PRINT 'SQL Server instance has been running for ' + CONVERT(varchar(0010), @DaysRunning) + ' days'

PRINT CHAR(13) + CHAR(10)

   SELECT O.object_id AS GeneralID
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        ,        H.name          AS SQLServerFile
        , ISNULL(I.name, O.name) AS SQLServerName
        , CONVERT(varchar(0040), O.create_date, 120) AS create_date
        , CONVERT(varchar(0040), O.modify_date, 120) AS modify_date
        , I.index_id
        , I.type      AS table_type
        , I.type      AS index_type
        , I.fill_factor
        , I.is_primary_key
        , I.is_unique_constraint
        , I.is_unique
        , I.is_disabled
        , ISNULL(I.filter_definition, SPACE(0)) AS GeneralFilter
     INTO #ZKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.indexes AS I
       ON O.object_id
        = I.object_id
     JOIN sys.data_spaces AS H
       ON I.data_space_id
        = H.data_space_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY   GeneralSchema
        ,   GeneralObject
        ,   SQLServerName

   UPDATE Z SET
            table_type
        = W.index_type
     FROM #ZKey AS Z
     JOIN #ZKey AS W
       ON Z.GeneralID
        = W.GeneralID
      AND W.index_type      IN (0, 1, 5)

   SELECT Z.GeneralID
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerFile
        , Z.SQLServerName
        , Z.create_date
        , Z.modify_date
        , CASE WHEN Z.index_type            = 0 THEN 'S '
               WHEN Z.index_type            = 5 THEN 'S '
               WHEN Z.index_type            = 6 THEN 'S '
               WHEN Z.is_primary_key       != 0 THEN 'PK'
               WHEN Z.is_unique_constraint != 0 THEN 'AK'
               WHEN Z.is_unique            != 0 AND LEN(Z.GeneralFilter) = 0 THEN 'U '
               WHEN Z.is_unique            != 0 AND LEN(Z.GeneralFilter) > 0 THEN 'UF'
               WHEN Z.is_unique             = 0 AND LEN(Z.GeneralFilter) = 0 THEN 'S '
               WHEN Z.is_unique             = 0 AND LEN(Z.GeneralFilter) > 0 THEN 'SF' END AS Nature
        , Z.index_id
        , STR(Z.table_type, 1) + ' / ' + STR(Z.index_type, 1) AS types
        , Z.table_type
        , Z.index_type
        , CONVERT(decimal(19,05), T.pages_total / 128.0 / 1024.0) AS GBs
        , Z.fill_factor
        , Z.is_primary_key
        , Z.is_unique_constraint
        , Z.is_unique
        , Z.is_disabled
--      , Z.GeneralFilter
        ,         CONVERT(varchar(0040), U.last_user_seek    , 120)       AS last_user_seek
        ,         CONVERT(varchar(0040), U.last_system_seek  , 120)       AS last_system_seek
        ,         CONVERT(varchar(0040), U.last_user_scan    , 120)       AS last_user_scan
        ,         CONVERT(varchar(0040), U.last_system_scan  , 120)       AS last_system_scan
        ,         CONVERT(varchar(0040), U.last_user_lookup  , 120)       AS last_user_lookup
        ,         CONVERT(varchar(0040), U.last_system_lookup, 120)       AS last_system_lookup
        ,         CONVERT(varchar(0040), U.last_user_update  , 120)       AS last_user_update
        ,         CONVERT(varchar(0040), U.last_system_update, 120)       AS last_system_update
        ,           DATEDIFF(day, ISNULL(U.last_user_seek    , @DT), @DZ) AS past_user_seek
        ,           DATEDIFF(day, ISNULL(U.last_system_seek  , @DT), @DZ) AS past_system_seek
        ,           DATEDIFF(day, ISNULL(U.last_user_scan    , @DT), @DZ) AS past_user_scan
        ,           DATEDIFF(day, ISNULL(U.last_system_scan  , @DT), @DZ) AS past_system_scan
        ,           DATEDIFF(day, ISNULL(U.last_user_lookup  , @DT), @DZ) AS past_user_lookup
        ,           DATEDIFF(day, ISNULL(U.last_system_lookup, @DT), @DZ) AS past_system_lookup
        ,           DATEDIFF(day, ISNULL(U.last_user_update  , @DT), @DZ) AS past_user_update
        ,           DATEDIFF(day, ISNULL(U.last_system_update, @DT), @DZ) AS past_system_update
        , CASE WHEN DATEDIFF(day, ISNULL(U.last_user_seek    , @DT), @DZ) < @DaysTable THEN 1 ELSE 0 END
        + CASE WHEN DATEDIFF(day, ISNULL(U.last_system_seek  , @DT), @DZ) < @DaysTable THEN 1 ELSE 0 END
        + CASE WHEN DATEDIFF(day, ISNULL(U.last_user_scan    , @DT), @DZ) < @DaysTable THEN 1 ELSE 0 END
        + CASE WHEN DATEDIFF(day, ISNULL(U.last_system_scan  , @DT), @DZ) < @DaysTable THEN 1 ELSE 0 END
        + CASE WHEN DATEDIFF(day, ISNULL(U.last_user_lookup  , @DT), @DZ) < @DaysTable THEN 1 ELSE 0 END
        + CASE WHEN DATEDIFF(day, ISNULL(U.last_system_lookup, @DT), @DZ) < @DaysTable THEN 1 ELSE 0 END AS SSL_Table
        , CASE WHEN DATEDIFF(day, ISNULL(U.last_user_update  , @DT), @DZ) < @DaysTable THEN 1 ELSE 0 END
        + CASE WHEN DATEDIFF(day, ISNULL(U.last_system_update, @DT), @DZ) < @DaysTable THEN 1 ELSE 0 END AS IUD_Table
        , CASE WHEN DATEDIFF(day, ISNULL(U.last_user_seek    , @DT), @DZ) < @DaysIndex THEN 1 ELSE 0 END
        + CASE WHEN DATEDIFF(day, ISNULL(U.last_system_seek  , @DT), @DZ) < @DaysIndex THEN 1 ELSE 0 END
        + CASE WHEN DATEDIFF(day, ISNULL(U.last_user_scan    , @DT), @DZ) < @DaysIndex THEN 1 ELSE 0 END
        + CASE WHEN DATEDIFF(day, ISNULL(U.last_system_scan  , @DT), @DZ) < @DaysIndex THEN 1 ELSE 0 END
        + CASE WHEN DATEDIFF(day, ISNULL(U.last_user_lookup  , @DT), @DZ) < @DaysIndex THEN 1 ELSE 0 END
        + CASE WHEN DATEDIFF(day, ISNULL(U.last_system_lookup, @DT), @DZ) < @DaysIndex THEN 1 ELSE 0 END AS SSL_Index
        , CASE WHEN DATEDIFF(day, ISNULL(U.last_user_update  , @DT), @DZ) < @DaysIndex THEN 1 ELSE 0 END
        + CASE WHEN DATEDIFF(day, ISNULL(U.last_system_update, @DT), @DZ) < @DaysIndex THEN 1 ELSE 0 END AS IUD_Index
     INTO #Hack
     FROM #ZKey AS Z
     JOIN
  (SELECT P.object_id
        , P.index_id
        , SUM(A.total_pages) AS pages_total
     FROM sys.partitions AS P
     JOIN sys.allocation_units AS A
       ON P.partition_id
        = A.container_id
      AND A.type != 0
 GROUP BY P.object_id
        , P.index_id)    AS T
       ON Z.GeneralID
        = T.object_id
      AND Z.index_id
        = T.index_id
LEFT JOIN sys.dm_db_index_usage_stats AS U
       ON Z.GeneralID
        = U.object_id
      AND Z.index_id
        = U.index_id
      AND U.database_id = DB_ID()
 ORDER BY Z.GeneralSchema
        , Z.GeneralObject
        , Z.index_id

   SELECT I.GeneralSchema
        , I.GeneralObject
        , I.SQLServerName
--      , I.SQLServerFile
        , I.Nature
--      , I.fill_factor AS Factor
--      , I.is_primary_key
--      , I.is_unique_constraint
--      , I.is_unique
--      , I.is_disabled
--      , I.types
        , I.table_type
        , I.index_type
        , I.past_user_seek
        , I.past_user_scan
        , I.past_user_lookup
        , I.past_user_update
        , I.past_system_seek
        , I.past_system_scan
        , I.past_system_lookup
        , I.past_system_update
--      , I.last_user_seek
--      , I.last_user_scan
--      , I.last_user_lookup
--      , I.last_user_update
--      , I.last_system_seek
--      , I.last_system_scan
--      , I.last_system_lookup
--      , I.last_system_update
        , I.GBs
--      , T.GeneralColumn
        , '-- DROP INDEX ' + I.SQLServerName + ' ON ' + I.GeneralSchema + '.' + I.GeneralObject AS SQLCode
     FROM #Hack AS I
     JOIN
  (SELECT M.object_id AS GeneralID
        , M.index_id
        , MAX(CASE WHEN M.index_column_id = 1 THEN   '[' + C.name + ']' + CASE WHEN M.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN M.index_column_id = 2 THEN ', [' + C.name + ']' + CASE WHEN M.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN M.index_column_id = 3 THEN ', [' + C.name + ']' + CASE WHEN M.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN M.index_column_id > 3 THEN ', [...]'                                                                                ELSE SPACE(0) END) AS GeneralColumn
     FROM sys.index_columns AS M
     JOIN sys.columns AS C
       ON M.object_id
        = C.object_id
      AND M.column_id
        = C.column_id
    WHERE M.is_included_column = 0
 GROUP BY M.object_id
        , M.index_id) AS T
       ON I.GeneralID
        = T.GeneralID
      AND I.index_id
        = T.index_id
    WHERE I.index_type NOT IN (0, 1, 5)
      AND I.SSL_Index = 0
      AND I.IUD_Index = 0
 ORDER BY I.GeneralSchema
        , I.GeneralObject
        , I.SQLServerName

   SELECT I.GeneralSchema
        , I.GeneralObject
        , I.SQLServerName
--      , I.SQLServerFile
        , I.Nature
--      , I.fill_factor AS Factor
--      , I.is_primary_key
--      , I.is_unique_constraint
--      , I.is_unique
--      , I.is_disabled
--      , I.types
        , I.table_type
        , I.index_type
        , I.past_user_seek
        , I.past_user_scan
        , I.past_user_lookup
        , I.past_user_update
        , I.past_system_seek
        , I.past_system_scan
        , I.past_system_lookup
        , I.past_system_update
--      , I.last_user_seek
--      , I.last_user_scan
--      , I.last_user_lookup
--      , I.last_user_update
--      , I.last_system_seek
--      , I.last_system_scan
--      , I.last_system_lookup
--      , I.last_system_update
        , I.GBs
--      , T.GeneralColumn
        , '   DROP INDEX ' + I.SQLServerName + ' ON ' + I.GeneralSchema + '.' + I.GeneralObject AS SQLCode
     FROM #Hack AS I
     JOIN
  (SELECT M.object_id AS GeneralID
        , M.index_id
        , MAX(CASE WHEN M.index_column_id = 1 THEN   '[' + C.name + ']' + CASE WHEN M.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN M.index_column_id = 2 THEN ', [' + C.name + ']' + CASE WHEN M.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN M.index_column_id = 3 THEN ', [' + C.name + ']' + CASE WHEN M.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN M.index_column_id > 3 THEN ', [...]'                                                                                ELSE SPACE(0) END) AS GeneralColumn
     FROM sys.index_columns AS M
     JOIN sys.columns AS C
       ON M.object_id
        = C.object_id
      AND M.column_id
        = C.column_id
    WHERE M.is_included_column = 0
 GROUP BY M.object_id
        , M.index_id) AS T
       ON I.GeneralID
        = T.GeneralID
      AND I.index_id
        = T.index_id
    WHERE I.index_type NOT IN (0, 1, 5)
      AND I.SSL_Index = 0
      AND I.IUD_Index > 0
 ORDER BY I.GeneralSchema
        , I.GeneralObject
        , I.SQLServerName

   SELECT I.GeneralSchema
        , I.GeneralObject
        , I.SQLServerName
--      , I.SQLServerFile
        , I.Nature
--      , I.fill_factor AS Factor
--      , I.is_primary_key
--      , I.is_unique_constraint
--      , I.is_unique
--      , I.is_disabled
--      , I.types
        , I.table_type
        , I.index_type
        , I.past_user_seek
        , I.past_user_scan
        , I.past_user_lookup
        , I.past_user_update
        , I.past_system_seek
        , I.past_system_scan
        , I.past_system_lookup
        , I.past_system_update
--      , I.last_user_seek
--      , I.last_user_scan
--      , I.last_user_lookup
--      , I.last_user_update
--      , I.last_system_seek
--      , I.last_system_scan
--      , I.last_system_lookup
--      , I.last_system_update
        , I.GBs
--      , T.GeneralColumn
     FROM #Hack AS I
     JOIN
  (SELECT M.object_id AS GeneralID
        , M.index_id
        , MAX(CASE WHEN M.index_column_id = 1 THEN   '[' + C.name + ']' + CASE WHEN M.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN M.index_column_id = 2 THEN ', [' + C.name + ']' + CASE WHEN M.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN M.index_column_id = 3 THEN ', [' + C.name + ']' + CASE WHEN M.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN M.index_column_id > 3 THEN ', [...]'                                                                                ELSE SPACE(0) END) AS GeneralColumn
     FROM sys.index_columns AS M
     JOIN sys.columns AS C
       ON M.object_id
        = C.object_id
      AND M.column_id
        = C.column_id
    WHERE M.is_included_column = 0
 GROUP BY M.object_id
        , M.index_id) AS T
       ON I.GeneralID
        = T.GeneralID
      AND I.index_id
        = T.index_id
    WHERE I.index_type NOT IN (0, 1, 5)
      AND I.SSL_Index > 0
 ORDER BY I.GeneralSchema
        , I.GeneralObject
        , I.SQLServerName

DROP TABLE #ZKey

DROP TABLE #Hack

SET NOCOUNT OFF

