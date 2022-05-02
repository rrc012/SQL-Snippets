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

PRINT 'index_type_1 means a table as clustered index'
PRINT 'index_type_5 means a table as clustered index (columnstore)'
PRINT 'index_type_2 means a       nonclustered index'
PRINT 'index_type_6 means a       nonclustered index (columnstore)'

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
        , C.is_identity
        , C.is_nullable
        , C.is_computed
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

   SELECT Z.*
        , CASE WHEN Z.name = 'time'           THEN Z.name + '(' +                                                   STR(Z.scale,       1)     + ')'
               WHEN Z.name = 'datetime2'      THEN Z.name + '(' +                                                   STR(Z.scale,       1)     + ')'
               WHEN Z.name = 'datetimeoffset' THEN Z.name + '(' +                                                   STR(Z.scale,       1)     + ')'
               WHEN Z.name = 'float'          THEN Z.name + '(' + RIGHT(STR(Z.precision + 100, 3), 2)                                         + ')'
               WHEN Z.name = 'numeric'        THEN Z.name + '(' + RIGHT(STR(Z.precision + 100, 3), 2) + ',' + RIGHT(STR(Z.scale + 100, 3), 2) + ')'
               WHEN Z.name = 'decimal'        THEN Z.name + '(' + RIGHT(STR(Z.precision + 100, 3), 2) + ',' + RIGHT(STR(Z.scale + 100, 3), 2) + ')'
               WHEN Z.name = 'vardecimal'     THEN Z.name + '(' + RIGHT(STR(Z.precision + 100, 3), 2) + ',' + RIGHT(STR(Z.scale + 100, 3), 2) + ')'
               WHEN Z.name = 'binary'         THEN Z.name + '(' +                                 RIGHT(STR(Z.max_length + 10000, 5), 4)                 + ')'
               WHEN Z.name = 'varbinary'      THEN Z.name + '(' + CASE WHEN Z.max_length > 0 THEN RIGHT(STR(Z.max_length + 10000, 5), 4) ELSE 'max ' END + ')'
               WHEN Z.name = 'nchar'          THEN Z.name + '(' +                                 RIGHT(STR(Z.min_length + 10000, 5), 4)                 + ')'
               WHEN Z.name = 'nvarchar'       THEN Z.name + '(' + CASE WHEN Z.min_length > 0 THEN RIGHT(STR(Z.min_length + 10000, 5), 4) ELSE 'max ' END + ')'
               WHEN Z.name = 'char'           THEN Z.name + '(' +                                 RIGHT(STR(Z.max_length + 10000, 5), 4)                 + ')'
               WHEN Z.name = 'varchar'        THEN Z.name + '(' + CASE WHEN Z.max_length > 0 THEN RIGHT(STR(Z.max_length + 10000, 5), 4) ELSE 'max ' END + ')'
                                              ELSE Z.name END AS SQLServerType
     INTO #ZKeys
     FROM #ZKey AS Z
 ORDER BY Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerName
        , Z.index_column_id

   SELECT Z.GeneralSchema
        , Z.GeneralObject
        , Z.GeneralColumn
        , Z.SQLServerType
        , Z.is_identity
        , Z.is_nullable
        , Z.is_computed
        , SUM(CASE WHEN Z.index_type          = 1 THEN 1 ELSE 0 END) AS [index_type_1]
        , SUM(CASE WHEN Z.index_type          = 5 THEN 1 ELSE 0 END) AS [index_type_5]
        , SUM(CASE WHEN Z.index_type          = 2 THEN 1 ELSE 0 END) AS [index_type_2]
        , SUM(CASE WHEN Z.index_type          = 6 THEN 1 ELSE 0 END) AS [index_type_6]
        , SUM(CASE WHEN Z.regular_column_id   = 1 THEN 1 ELSE 0 END) AS [Position_First]
        , SUM(CASE WHEN Z.regular_column_id   > 1 THEN 1 ELSE 0 END) AS [Position_Other]
        , SUM(CASE WHEN Z.include_column_id   > 0 THEN 1 ELSE 0 END) AS [Include_Column]
        ,  SUM(CASE WHEN Z.is_descending_key != 0 THEN 1 ELSE 0 END) AS [Descending_Key]
     FROM #ZKeys AS Z
    WHERE Z.index_type IN (1, 2, 5, 6)
 GROUP BY Z.GeneralSchema
        , Z.GeneralObject
        , Z.GeneralColumn
        , Z.SQLServerType
        , Z.is_identity
        , Z.is_nullable
        , Z.is_computed
 ORDER BY Z.GeneralSchema
        , Z.GeneralObject
        , Z.GeneralColumn

DROP TABLE #ZKey

DROP TABLE #ZKeys

SET NOCOUNT OFF

