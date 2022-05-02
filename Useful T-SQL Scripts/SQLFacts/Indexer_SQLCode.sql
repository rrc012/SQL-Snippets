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

DECLARE @GeneralID               int
DECLARE @GeneralObject varchar(0128)
DECLARE @GeneralSchema varchar(0128)
DECLARE @SQLServerName varchar(0128)
DECLARE @SQLServerFile varchar(0128)
DECLARE @RegularColumn varchar(2000)
DECLARE @IncludeColumn varchar(2000)
DECLARE @GeneralFilter varchar(2000)

DECLARE @table_type tinyint
DECLARE @index_type tinyint

DECLARE @is_unique bit

DECLARE @fill_factor tinyint

DECLARE @compression_type tinyint

DECLARE @SQLCode varchar(6000)

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

  DECLARE DBItems CURSOR FAST_FORWARD FOR
   SELECT T.GeneralSchema
        , T.GeneralObject
        , T.SQLServerName
        , T.SQLServerFile
        , T.table_type
        , T.index_type
        , T.is_unique
        , T.fill_factor
        , T.RegularColumn
        , T.IncludeColumn
        , T.GeneralFilter
        , Z.compression_type
     FROM #Hack AS T
     JOIN
  (SELECT P.object_id AS GeneralID
        , P.index_id
        , MIN(P.data_compression) AS compression_type
     FROM sys.partitions AS P
 GROUP BY P.object_id
        , P.index_id)    AS Z
       ON T.GeneralID
        = Z.GeneralID
      AND T.index_id
        = Z.index_id
    WHERE T.index_type IN (1, 2, 5, 6)
      AND CASE WHEN T.is_primary_key       != 0 THEN 1
               WHEN T.is_unique_constraint != 0 THEN 1 ELSE 0 END  = 0
 ORDER BY T.GeneralSchema
        , T.GeneralObject
        , T.SQLServerName

OPEN DBItems

FETCH NEXT FROM DBItems INTO @GeneralSchema, @GeneralObject, @SQLServerName, @SQLServerFile, @table_type, @index_type, @is_unique, @fill_factor, @RegularColumn, @IncludeColumn, @GeneralFilter, @compression_type

WHILE @@FETCH_STATUS = 0

    BEGIN

    SET @SQLCode = 'DROP   '
                 + CASE WHEN @index_type IN (1, 2      ) AND @is_unique != 0         THEN '       '                                                ELSE SPACE(07) END
                 + CASE WHEN @index_type IN (   2,    6)                             THEN '   '                                                    ELSE SPACE(03) END + '          '
                 + CASE WHEN @index_type IN (      5, 6)                             THEN '            '                                           ELSE SPACE(12) END + 'INDEX [' + @SQLServerName + '] ON [' + @GeneralSchema + '].[' + @GeneralObject + ']'

    PRINT @SQLCode

    SET @SQLCode = 'CREATE '
                 + CASE WHEN @index_type IN (1, 2      ) AND @is_unique != 0         THEN 'UNIQUE '                                                ELSE SPACE(07) END
                 + CASE WHEN @index_type IN (   2,    6)                             THEN 'NON'                                                    ELSE SPACE(03) END + 'CLUSTERED '
                 + CASE WHEN @index_type IN (      5, 6)                             THEN 'COLUMNSTORE '                                           ELSE SPACE(12) END + 'INDEX [' + @SQLServerName + '] ON [' + @GeneralSchema + '].[' + @GeneralObject + ']'
                 + CASE WHEN @index_type IN (1, 2      )                             THEN         ' (' + @RegularColumn + ')'                      ELSE SPACE(00) END
                 + CASE WHEN @index_type IN (         6)                             THEN         ' (' + @IncludeColumn + ')'                      ELSE SPACE(00) END
                 + CASE WHEN @index_type IN (   2      ) AND LEN(@IncludeColumn) > 0 THEN ' INCLUDE (' + @IncludeColumn + ')'                      ELSE SPACE(00) END
                 + CASE WHEN @index_type IN (   2,    6) AND LEN(@GeneralFilter) > 0 THEN ' WHERE '    + @GeneralFilter                            ELSE SPACE(00) END + CHAR(13) + CHAR(10) + 'WITH (DROP_EXISTING = OFF, ONLINE = OFF'
                 + CASE WHEN @index_type IN (1, 2      )                             THEN ', SORT_IN_TEMPDB = OFF'                                 ELSE SPACE(00) END
                 + CASE WHEN @index_type IN (1, 2      ) AND @fill_factor > 0        THEN ', FILLFACTOR = ' + CONVERT(varchar(0010), @fill_factor) ELSE SPACE(00) END + ', DATA_COMPRESSION = '
                 + CASE @compression_type WHEN 0 THEN 'NONE'
                                          WHEN 1 THEN 'ROW'
                                          WHEN 2 THEN 'PAGE'
                                          WHEN 3 THEN 'COLUMNSTORE'
                                          WHEN 4 THEN 'COLUMNSTORE_ARCHIVE' ELSE 'NONE' END + ') ON [' + @SQLServerFile + ']'

    PRINT @SQLCode

    PRINT CHAR(13) + CHAR(10)

    FETCH NEXT FROM DBItems INTO @GeneralSchema, @GeneralObject, @SQLServerName, @SQLServerFile, @table_type, @index_type, @is_unique, @fill_factor, @RegularColumn, @IncludeColumn, @GeneralFilter, @compression_type

    END

CLOSE DBItems DEALLOCATE DBItems

DROP TABLE #ZKey

DROP TABLE #Hack

SET NOCOUNT OFF

