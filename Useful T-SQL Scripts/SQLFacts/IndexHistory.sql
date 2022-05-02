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

   SELECT O.object_id AS GeneralID
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        ,        H.name          AS SQLServerFile
        , ISNULL(I.name, O.name) AS SQLServerName
        , I.index_id
        , I.type      AS table_type
        , I.type      AS index_type
        , I.fill_factor
        , I.is_primary_key
        , I.is_unique_constraint
        , I.is_unique
        , I.is_disabled
        , M.is_included_column
        , M.is_descending_key
        , M.partition_ordinal
        , ISNULL(M.index_column_id, 0) AS index_column_id
        , CASE WHEN M.is_included_column  = 0 THEN ROW_NUMBER() OVER (PARTITION BY M.object_id, M.index_id, M.is_included_column ORDER BY M.index_column_id) ELSE 0 END AS regular_column_id
        , CASE WHEN M.is_included_column != 0 THEN ROW_NUMBER() OVER (PARTITION BY M.object_id, M.index_id, M.is_included_column ORDER BY M.index_column_id) ELSE 0 END AS include_column_id
        , ISNULL(I.filter_definition, SPACE(0)) AS GeneralFilter
        , C.name      AS GeneralColumn
        , T.name
        , CASE WHEN T.name LIKE 'n%char' AND C.max_length > 0 THEN C.max_length / 2 ELSE C.max_length END AS min_length
        , C.max_length
        , C.precision
        , C.scale
     INTO #ZKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.indexes AS I
       ON O.object_id
        = I.object_id
LEFT JOIN sys.index_columns AS M
       ON I.object_id
        = M.object_id
      AND I.index_id
        = M.index_id
LEFT JOIN sys.columns AS C
       ON M.object_id
        = C.object_id
      AND M.column_id
        = C.column_id
LEFT JOIN sys.types   AS T
       ON C.user_type_id
        = T.user_type_id
     JOIN sys.data_spaces AS H
       ON I.data_space_id
        = H.data_space_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY   GeneralSchema
        ,   GeneralObject
        ,   SQLServerName
        ,   index_column_id

   UPDATE Z SET
            table_type
        = W.index_type
     FROM #ZKey AS Z
     JOIN #ZKey AS W
       ON Z.GeneralID
        = W.GeneralID
      AND W.index_type      IN (0, 1, 5)
      AND W.index_column_id IN (0, 1)

   SELECT Z.GeneralID
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerFile
        , Z.SQLServerName
        , Z.index_id
        , Z.table_type
        , Z.index_type
        , Z.fill_factor
        , Z.is_primary_key
        , Z.is_unique_constraint
        , Z.is_unique
        , Z.is_disabled
        , Z.GeneralFilter
        , COUNT(*) AS KeyColumns
        , MAX(CASE WHEN Z.regular_column_id =  1 THEN   '[' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  2 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  3 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  4 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  5 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  6 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  7 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  8 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  9 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 10 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 11 THEN   '[' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 12 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 13 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 14 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 15 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 16 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 17 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 18 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 19 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id > 19 THEN ', [...]'                                                                                         ELSE SPACE(0) END) AS RegularColumn
        , MAX(CASE WHEN Z.include_column_id =  1 THEN   '[' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  2 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  3 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  4 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  5 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  6 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  7 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  8 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  9 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 10 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 11 THEN   '[' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 12 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 13 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 14 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 15 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 16 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 17 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 18 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 19 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id > 19 THEN ', [...]'                                                                                         ELSE SPACE(0) END) AS IncludeColumn
     INTO #Hack
     FROM #ZKey AS Z
 GROUP BY Z.GeneralID
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerFile
        , Z.SQLServerName
        , Z.index_id
        , Z.table_type
        , Z.index_type
        , Z.fill_factor
        , Z.is_primary_key
        , Z.is_unique_constraint
        , Z.is_unique
        , Z.is_disabled
        , Z.GeneralFilter
 ORDER BY Z.GeneralSchema
        , Z.GeneralObject
        , Z.index_id

   SELECT I.GeneralSchema
        , I.GeneralObject
        , I.SQLServerName
--      , I.SQLServerFile
        , CASE WHEN I.index_type            = 0 THEN 'S '
               WHEN I.index_type            = 5 THEN 'S '
               WHEN I.index_type            = 6 THEN 'S '
               WHEN I.is_primary_key       != 0 THEN 'PK'
               WHEN I.is_unique_constraint != 0 THEN 'AK'
               WHEN I.is_unique            != 0 AND LEN(I.GeneralFilter) = 0 THEN 'U '
               WHEN I.is_unique            != 0 AND LEN(I.GeneralFilter) > 0 THEN 'UF'
               WHEN I.is_unique             = 0 AND LEN(I.GeneralFilter) = 0 THEN 'S '
               WHEN I.is_unique             = 0 AND LEN(I.GeneralFilter) > 0 THEN 'SF' END AS Nature
--      , I.fill_factor AS Factor
--      , I.is_primary_key
--      , I.is_unique_constraint
--      , I.is_unique
--      , I.is_disabled
--      , STR(I.table_type, 1) + ' / ' + STR(I.index_type, 1) AS types
        , I.table_type
        , I.index_type
        , E.index_rows
        , CONVERT(decimal(19,05), T.pages_total / 128.0 / 1024.0) AS GBs_total_size
        , I.RegularColumn
        , I.IncludeColumn
--      , I.GeneralFilter
        , CASE WHEN EXISTS
  (SELECT *
     FROM #Hack AS O
    WHERE O.GeneralSchema
        = I.GeneralSchema
      AND O.GeneralObject
        = I.GeneralObject
      AND O.GeneralFilter
        = I.GeneralFilter
      AND O.SQLServerName
       != I.SQLServerName
      AND O.index_type IN (1, 2)
      AND I.index_type IN (1, 2)
      AND REPLACE(REPLACE(O.RegularColumn, '[', '<'), ']', '>')
     LIKE REPLACE(REPLACE(I.RegularColumn, '[', '<'), ']', '>') + '%'
      AND CASE WHEN O.RegularColumn > I.RegularColumn THEN 1
               WHEN O.RegularColumn = I.RegularColumn
                AND O.IncludeColumn > I.IncludeColumn THEN 1
               WHEN O.RegularColumn = I.RegularColumn
                AND O.IncludeColumn = I.IncludeColumn
                AND O.SQLServerName > I.SQLServerName THEN 1 ELSE 0 END != 0) THEN 'see next row' ELSE SPACE(0) END AS Redundancy
        , U.user_seeks
        , U.user_scans
        , U.user_lookups
        , U.user_updates
        , U.system_seeks
        , U.system_scans
        , U.system_lookups
        , U.system_updates
--      , CONVERT(varchar(0040), U.last_user_seek    , 120) AS last_user_seek
--      , CONVERT(varchar(0040), U.last_user_scan    , 120) AS last_user_scan
--      , CONVERT(varchar(0040), U.last_user_lookup  , 120) AS last_user_lookup
--      , CONVERT(varchar(0040), U.last_user_update  , 120) AS last_user_update
--      , CONVERT(varchar(0040), U.last_system_seek  , 120) AS last_system_seek
--      , CONVERT(varchar(0040), U.last_system_scan  , 120) AS last_system_scan
--      , CONVERT(varchar(0040), U.last_system_lookup, 120) AS last_system_lookup
--      , CONVERT(varchar(0040), U.last_system_update, 120) AS last_system_update
     FROM #Hack AS I
     JOIN
  (SELECT P.object_id
        , P.index_id
        , SUM(P.rows) AS index_rows
     FROM sys.partitions AS P
 GROUP BY P.object_id
        , P.index_id)    AS E
       ON I.GeneralID
        = E.object_id
      AND I.index_id
        = E.index_id
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
       ON I.GeneralID
        = T.object_id
      AND I.index_id
        = T.index_id
LEFT JOIN sys.dm_db_index_usage_stats AS U
       ON I.GeneralID
        = U.object_id
      AND I.index_id
        = U.index_id
      AND U.database_id = DB_ID()
 ORDER BY I.GeneralSchema
        , I.GeneralObject
        , I.RegularColumn
        , I.IncludeColumn
        , I.SQLServerName

DROP TABLE #ZKey

DROP TABLE #Hack

SET NOCOUNT OFF

