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

DECLARE @Percentage smallint = 90 -- percentage of threshold to generate live UPDATE STATISTICS statement

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
        , C.name      AS GeneralColumn
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
        , ISNULL(I.filter_definition, SPACE(0)) AS GeneralFilter
        , E.index_rows
        , E.index_rows                                     AS threshold
        , CONVERT(bigint,      E.index_rows * 0.20 ) + 500 AS Version14
        , CONVERT(bigint, SQRT(E.index_rows * 1000))       AS Version16
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
      AND M.index_column_id = 1
LEFT JOIN sys.columns AS C
       ON M.object_id
        = C.object_id
      AND M.column_id
        = C.column_id
     JOIN
  (SELECT P.object_id
        , P.index_id
        , SUM(P.rows) AS index_rows
     FROM sys.partitions AS P
 GROUP BY P.object_id
        , P.index_id)    AS E
       ON I.object_id
        = E.object_id
      AND I.index_id
        = E.index_id
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
      AND W.index_type IN (0, 1, 5)

   UPDATE #ZKey SET threshold = CASE WHEN index_rows !> 500 THEN 500 ELSE CASE WHEN Version16 < Version14 THEN Version16 ELSE Version14 END END

   SELECT I.GeneralSchema
        , I.GeneralObject
        , I.GeneralColumn
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
        , I.index_rows
        , E.rows                                      AS [stats_rows]
        , E.modification_counter                      AS [stats_mods]
        , CONVERT(varchar(0040), E.last_updated, 120) AS [stats_date]
        , T.name                                      AS [stats_name]
        , ISNULL(T.auto_created, 0) AS is_auto
        , ISNULL(T.user_created, 0) AS is_user
        , I.threshold
        , CONVERT(decimal(19,02), ISNULL(E.modification_counter, 0) * 100.0 / I.threshold) AS Percentage
        , CASE WHEN I.is_disabled = 0 AND E.modification_counter IS NOT NULL AND E.modification_counter !< I.threshold * 100.0 / @Percentage THEN '   ' ELSE '-- ' END + CASE WHEN T.name IS NOT NULL THEN 'UPDATE STATISTICS ' + I.GeneralSchema + '.' + I.GeneralObject + ' ' + T.name ELSE SPACE(0) END AS [statement]
     FROM #ZKey     AS I
LEFT JOIN sys.stats AS T
       ON I.GeneralID
        = T.object_id
      AND I.index_id
        = T.stats_id
    OUTER APPLY sys.dm_db_stats_properties (T.object_id, T.stats_id) AS E
 ORDER BY I.GeneralSchema
        , I.GeneralObject
        , I.SQLServerName

   SELECT I.GeneralSchema
        , I.GeneralObject
        , C.name AS GeneralColumn
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
        , I.index_rows
        , E.rows                                      AS [stats_rows]
        , E.modification_counter                      AS [stats_mods]
        , CONVERT(varchar(0040), E.last_updated, 120) AS [stats_date]
        , T.name                                      AS [stats_name]
        , ISNULL(T.auto_created, 0) AS is_auto
        , ISNULL(T.user_created, 0) AS is_user
        , I.threshold
        , CONVERT(decimal(19,02), ISNULL(E.modification_counter, 0) * 100.0 / I.threshold) AS Percentage
        , CASE WHEN I.is_disabled = 0 AND E.modification_counter IS NOT NULL AND E.modification_counter !< I.threshold * 100.0 / @Percentage THEN '   ' ELSE '-- ' END + CASE WHEN T.name IS NOT NULL THEN 'UPDATE STATISTICS ' + I.GeneralSchema + '.' + I.GeneralObject + ' ' + T.name ELSE SPACE(0) END AS [statement]
     FROM #ZKey       AS I
     JOIN sys.columns AS C
       ON I.GeneralID
        = C.object_id
     JOIN sys.stats   AS T
       ON T.name LIKE '[_]WA[_]Sys[_]%'
      AND C.object_id = CONVERT(int, CONVERT(binary(0004), SUBSTRING(T.name, 18, 8), 2))
      AND C.column_id = CONVERT(int, CONVERT(binary(0004), SUBSTRING(T.name, 09, 8), 2))
    OUTER APPLY sys.dm_db_stats_properties (T.object_id, T.stats_id) AS E
    WHERE I.index_type IN (0, 1, 5)
 ORDER BY I.GeneralSchema
        , I.GeneralObject
        , C.name

DROP TABLE #ZKey

SET NOCOUNT OFF

