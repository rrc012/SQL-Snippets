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

DECLARE @Brackets bit = 0 -- use brackets on object/column names

DECLARE @X varchar(0010) = CASE WHEN @Brackets = 0 THEN SPACE(0) ELSE '[' END
DECLARE @Y varchar(0010) = CASE WHEN @Brackets = 0 THEN SPACE(0) ELSE ']' END

DECLARE @PrimaryID               int
DECLARE @PrimaryType      char(0002)
DECLARE @PrimaryObject varchar(0128)
DECLARE @PrimarySchema varchar(0128)
DECLARE @PrimaryColumn varchar(0128)

DECLARE @ForeignID               int
DECLARE @ForeignType      char(0002)
DECLARE @ForeignObject varchar(0128)
DECLARE @ForeignSchema varchar(0128)
DECLARE @ForeignColumn varchar(0128)

DECLARE @GeneralID               int
DECLARE @GeneralType      char(0002)
DECLARE @GeneralObject varchar(0128)
DECLARE @GeneralSchema varchar(0128)
DECLARE @GeneralColumn varchar(0128)

DECLARE @VirtualID               int
DECLARE @SQLServerCode varchar(0020)
DECLARE @SQLServerName varchar(0010)
DECLARE @SQLServerMore varchar(0010)

DECLARE @Parameters    varchar(2000)
DECLARE @Parameterz    varchar(2000)

DECLARE @A smallint = 0
DECLARE @I smallint
DECLARE @O smallint
DECLARE @W smallint
DECLARE @Z smallint
DECLARE @T smallint = 2
DECLARE @U smallint
DECLARE @V smallint

-- base objects

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
--      , CONVERT(varchar(0040), O.create_date, 120) AS create_date
--      , CONVERT(varchar(0040), O.modify_date, 120) AS modify_date
        , CASE O.type
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END AS SQLServerCode
        , '----'                      AS SQLServerName
        , LEN(S.name)
        + LEN(O.name) AS I
        , LEN(O.name) AS O
        , CONVERT(smallint, 0) AS X
        , CONVERT(smallint, 0) AS Y
        , CONVERT(varchar(2000),
          CASE WHEN O.type = 'IF' THEN '(DEFAULT' + REPLICATE(', DEFAULT', (SELECT COUNT(*) - 1 FROM sys.parameters AS M WHERE M.object_id = O.object_id)) + ')'
               WHEN O.type = 'TF' THEN '(DEFAULT' + REPLICATE(', DEFAULT', (SELECT COUNT(*) - 1 FROM sys.parameters AS M WHERE M.object_id = O.object_id)) + ')' ELSE SPACE(0) END) AS Parameters
     INTO #Base
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ', 'V ',             'IF', 'TF')
 ORDER BY O.type
        , S.name
        , O.name

   SELECT @I = MAX(E.I) FROM #Base AS E
   SELECT @O = MAX(E.O) FROM #Base AS E

WHILE @A < @O

    BEGIN

    SET @A = @A + 1

       UPDATE #Base SET X = @A
         FROM #Base AS E
        WHERE ASCII(SUBSTRING(E.GeneralObject, @A, 1)) BETWEEN 65 AND 90
          AND E.X = 0

       UPDATE #Base SET Y = @A
         FROM #Base AS E
        WHERE ASCII(SUBSTRING(E.GeneralObject, @A, 1)) BETWEEN 65 AND 90
          AND E.Y = 0
          AND E.X > 0
          AND E.X < @A

    END

   UPDATE #Base SET X = 1
     FROM #Base AS E
    WHERE E.X = 0

   UPDATE #Base SET Y = E.X + 1
     FROM #Base AS E
    WHERE E.Y = 0

   UPDATE #Base SET SQLServerName
        = UPPER(SUBSTRING(E.GeneralObject, E.X, 1))
        + UPPER(SUBSTRING(E.GeneralObject, E.Y, 1)) + '--'
     FROM #Base AS E

   UPDATE #Base SET SQLServerName
        = LEFT(E.SQLServerName, 2) + RIGHT(STR(Z.U + 100, 3), 2)
     FROM #Base AS E
     JOIN
  (SELECT W.GeneralID
        , ROW_NUMBER() OVER (PARTITION BY LEFT(W.SQLServerName, 2) ORDER BY W.SQLServerCode, W.GeneralObject) AS U
     FROM #Base AS W
 GROUP BY W.GeneralID
        , W.GeneralType
        , W.GeneralObject
        , W.GeneralSchema
        , W.SQLServerCode
        , W.SQLServerName) AS Z
       ON E.GeneralID
        = Z.GeneralID

-- primary keys

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
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
        , M.is_descending_key
        , M.partition_ordinal
        , M.key_ordinal
        , C.name      AS GeneralColumn
     INTO #PKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.indexes AS I
       ON O.object_id
        = I.object_id
      AND CASE WHEN I.is_primary_key       != 0 THEN 1
               WHEN I.is_unique_constraint != 0 THEN 1 ELSE 0 END != 0
     JOIN sys.index_columns AS M
       ON I.object_id
        = M.object_id
      AND I.index_id
        = M.index_id
     JOIN sys.columns AS C
       ON M.object_id
        = C.object_id
      AND M.column_id
        = C.column_id
     JOIN sys.data_spaces AS H
       ON I.data_space_id
        = H.data_space_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY   GeneralSchema
        ,   GeneralObject
        ,   SQLServerName
        ,   key_ordinal

   SELECT P.GeneralID
        , P.GeneralType
        , P.GeneralObject
        , P.GeneralSchema
        , P.SQLServerName
        , P.is_primary_key
        , P.is_unique_constraint
        , COUNT(*) AS Columns
     INTO #PKeys
     FROM #PKey AS P
 GROUP BY P.GeneralID
        , P.GeneralType
        , P.GeneralObject
        , P.GeneralSchema
        , P.SQLServerName
        , P.is_primary_key
        , P.is_unique_constraint
 ORDER BY P.GeneralSchema
        , P.GeneralObject
        , P.is_primary_key
        , P.is_unique_constraint

-- foreign keys

   SELECT O.object_id AS ForeignID
        , W.object_id AS PrimaryID
        , O.type      AS ForeignType
        , W.type      AS PrimaryType
        , O.name      AS ForeignObject
        , W.name      AS PrimaryObject
        , S.name      AS ForeignSchema
        , Z.name      AS PrimarySchema
        , F.name      AS SQLServerName
--      , CONVERT(varchar(0040), F.create_date, 120) AS create_date
--      , CONVERT(varchar(0040), F.modify_date, 120) AS modify_date
        , CONVERT(bit, 0) AS is_bogus
        , F.is_disabled
        , F.is_not_trusted
        , M.constraint_column_id
        , C.name      AS ForeignColumn
        , K.name      AS PrimaryColumn
     INTO #FKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.foreign_keys AS F
       ON        O.object_id
        = F.parent_object_id
     JOIN sys.foreign_key_columns AS M
       ON            F.object_id
        = M.constraint_object_id
     JOIN sys.columns AS C
       ON M.parent_object_id
        =        C.object_id
      AND M.parent_column_id
        =        C.column_id
     JOIN sys.columns AS K
       ON M.referenced_object_id
        =            K.object_id
      AND M.referenced_column_id
        =            K.column_id
     JOIN sys.objects AS W
       ON F.referenced_object_id
        =            W.object_id
--    AND            O.object_id
--     !=            W.object_id
     JOIN sys.schemas AS Z
       ON W.schema_id
        = Z.schema_id
      AND Z.name IN (SELECT [Schema] FROM @Match)
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY   PrimarySchema
        ,   PrimaryObject
        ,   ForeignSchema
        ,   ForeignObject
        ,   constraint_column_id

   SELECT F.PrimaryID
        , F.ForeignID
        , F.PrimaryType
        , F.ForeignType
        , F.PrimaryObject
        , F.ForeignObject
        , F.PrimarySchema
        , F.ForeignSchema
        , F.SQLServerName
        , F.is_bogus
        , COUNT(*) AS Columns
     INTO #FKeys
     FROM #FKey AS F
    WHERE F.PrimaryID
       != F.ForeignID
 GROUP BY F.PrimaryID
        , F.ForeignID
        , F.PrimaryType
        , F.ForeignType
        , F.PrimaryObject
        , F.ForeignObject
        , F.PrimarySchema
        , F.ForeignSchema
        , F.SQLServerName
        , F.is_bogus
 ORDER BY F.PrimarySchema
        , F.PrimaryObject
        , F.ForeignSchema
        , F.ForeignObject

-- indexes

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
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

-- columns

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        , C.column_id
        , ISNULL(M.index_column_id, 0) AS index_column_id
        , C.is_nullable
        , C.is_computed
        , C.is_identity
        , CASE WHEN C.is_identity != 0 THEN CONVERT(decimal(38,00), IDENT_SEED   (S.name + '.' + O.name)) ELSE 0 END AS [From]
        , CASE WHEN C.is_identity != 0 THEN CONVERT(decimal(38,00), IDENT_INCR   (S.name + '.' + O.name)) ELSE 0 END AS [Plus]
        , CASE WHEN C.is_identity != 0 THEN CONVERT(decimal(38,00), IDENT_CURRENT(S.name + '.' + O.name)) ELSE 0 END AS [Used]
        , C.name      AS GeneralColumn
        , T.name
        , CASE WHEN T.name LIKE 'n%char' AND C.max_length > 0 THEN C.max_length / 2 ELSE C.max_length END AS min_length
        , C.max_length
        , C.precision
        , C.scale
        , ISNULL(                   C.collation_name , '') AS collation_name
        , ISNULL(CONVERT(varchar(4000), W.definition), '') AS FormulaCode
        , ISNULL(CONVERT(varchar(4000), Z.definition), '') AS DefaultCode
        , ISNULL(                             Z.name , '') AS DefaultName
     INTO #TKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.columns AS C
       ON O.object_id
        = C.object_id
     JOIN sys.types   AS T
       ON C.user_type_id
        = T.user_type_id
LEFT JOIN sys.indexes AS I
       ON O.object_id
        = I.object_id
      AND I.is_primary_key != 0
LEFT JOIN sys.index_columns AS M
       ON I.object_id
        = M.object_id
      AND I.index_id
        = M.index_id
      AND C.column_id
        = M.column_id
LEFT JOIN sys.computed_columns AS W
       ON C.object_id
        = W.object_id
      AND C.column_id
        = W.column_id
LEFT JOIN sys.default_constraints AS Z
       ON        C.object_id
        = Z.parent_object_id
      AND        C.column_id
        = Z.parent_column_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ', 'V ',             'IF', 'TF')
 ORDER BY   GeneralType
        ,   GeneralSchema
        ,   GeneralObject
        ,   column_id

   SELECT T.*
        , CASE WHEN T.name = 'time'           THEN T.name + '(' +                                                   STR(T.scale,       1)     + ')'
               WHEN T.name = 'datetime2'      THEN T.name + '(' +                                                   STR(T.scale,       1)     + ')'
               WHEN T.name = 'datetimeoffset' THEN T.name + '(' +                                                   STR(T.scale,       1)     + ')'
               WHEN T.name = 'float'          THEN T.name + '(' + RIGHT(STR(T.precision + 100, 3), 2)                                         + ')'
               WHEN T.name = 'numeric'        THEN T.name + '(' + RIGHT(STR(T.precision + 100, 3), 2) + ',' + RIGHT(STR(T.scale + 100, 3), 2) + ')'
               WHEN T.name = 'decimal'        THEN T.name + '(' + RIGHT(STR(T.precision + 100, 3), 2) + ',' + RIGHT(STR(T.scale + 100, 3), 2) + ')'
               WHEN T.name = 'vardecimal'     THEN T.name + '(' + RIGHT(STR(T.precision + 100, 3), 2) + ',' + RIGHT(STR(T.scale + 100, 3), 2) + ')'
               WHEN T.name = 'binary'         THEN T.name + '(' +                                 RIGHT(STR(T.max_length + 10000, 5), 4)                 + ')'
               WHEN T.name = 'varbinary'      THEN T.name + '(' + CASE WHEN T.max_length > 0 THEN RIGHT(STR(T.max_length + 10000, 5), 4) ELSE 'max ' END + ')'
               WHEN T.name = 'nchar'          THEN T.name + '(' +                                 RIGHT(STR(T.min_length + 10000, 5), 4)                 + ')'
               WHEN T.name = 'nvarchar'       THEN T.name + '(' + CASE WHEN T.min_length > 0 THEN RIGHT(STR(T.min_length + 10000, 5), 4) ELSE 'max ' END + ')'
               WHEN T.name = 'char'           THEN T.name + '(' +                                 RIGHT(STR(T.max_length + 10000, 5), 4)                 + ')'
               WHEN T.name = 'varchar'        THEN T.name + '(' + CASE WHEN T.max_length > 0 THEN RIGHT(STR(T.max_length + 10000, 5), 4) ELSE 'max ' END + ')'
                                              ELSE T.name END AS SQLServerType
     INTO #TKeys
     FROM #TKey AS T
--  WHERE T.GeneralType IN ('U ', 'V ',             'IF', 'TF')
 ORDER BY T.GeneralType
        , T.GeneralSchema
        , T.GeneralObject
        , T.column_id

-- references

   INSERT #PKey
   SELECT Z.GeneralID
        , Z.GeneralType
        , Z.GeneralObject
        , Z.GeneralSchema
        , Z.SQLServerFile
        , Z.SQLServerName
        , Z.index_id
        , Z.table_type
        , Z.index_type
        , Z.fill_factor
        , Z.is_primary_key
        , Z.is_unique_constraint
        , Z.is_descending_key
        , Z.partition_ordinal
        , Z.index_column_id
        , Z.GeneralColumn
     FROM #ZKey AS Z
    WHERE CASE WHEN Z.is_primary_key       != 0 THEN 1
               WHEN Z.is_unique_constraint != 0 THEN 1 ELSE 0 END  = 0
      AND Z.is_unique != 0
 ORDER BY   GeneralSchema
        ,   GeneralObject
        ,   SQLServerName
        ,   index_column_id

   INSERT #PKeys
   SELECT P.GeneralID
        , P.GeneralType
        , P.GeneralObject
        , P.GeneralSchema
        , P.SQLServerName
        , P.is_primary_key
        , P.is_unique_constraint
        , COUNT(*) AS Columns
     FROM #PKey AS P
    WHERE CASE WHEN P.is_primary_key       != 0 THEN 1
               WHEN P.is_unique_constraint != 0 THEN 1 ELSE 0 END  = 0
 GROUP BY P.GeneralID
        , P.GeneralType
        , P.GeneralObject
        , P.GeneralSchema
        , P.SQLServerName
        , P.is_primary_key
        , P.is_unique_constraint
 ORDER BY P.GeneralSchema
        , P.GeneralObject
        , P.is_primary_key
        , P.is_unique_constraint

   INSERT #FKeys
   SELECT T.GeneralID     AS PrimaryID
        , Z.GeneralID     AS ForeignID
        , T.GeneralType   AS PrimaryType
        , Z.GeneralType   AS ForeignType
        , T.GeneralObject AS PrimaryObject
        , Z.GeneralObject AS ForeignObject
        , T.GeneralSchema AS PrimarySchema
        , Z.GeneralSchema AS ForeignSchema
        , W.SQLServerName
        , 1
        , W.Columns
     FROM #PKey  AS P
     JOIN #PKeys AS W
       ON P.GeneralID
        = W.GeneralID
      AND P.is_primary_key
        = W.is_primary_key
      AND P.is_unique_constraint
        = W.is_unique_constraint
     JOIN #TKeys AS T
       ON P.GeneralID
        = T.GeneralID
      AND P.GeneralColumn
        = T.GeneralColumn
     JOIN #TKeys AS Z
       ON T.GeneralID
       != Z.GeneralID
      AND T.GeneralColumn
        = Z.GeneralColumn
      AND T.SQLServerType
        = Z.SQLServerType
LEFT JOIN #FKeys AS F
       ON T.GeneralSchema
        = F.PrimarySchema
      AND T.GeneralObject
        = F.PrimaryObject
      AND Z.GeneralSchema
        = F.ForeignSchema
      AND Z.GeneralObject
        = F.ForeignObject
    WHERE F.Columns IS NULL
      AND T.GeneralSchema IN (SELECT [Schema] FROM @Match)
      AND Z.GeneralSchema IN (SELECT [Schema] FROM @Match)
 GROUP BY W.Columns
        , W.is_primary_key
        , W.is_unique_constraint
        , W.SQLServerName
        , Z.GeneralID
        , Z.GeneralType
        , Z.GeneralObject
        , Z.GeneralSchema
        , T.GeneralID
        , T.GeneralType
        , T.GeneralObject
        , T.GeneralSchema
   HAVING W.Columns = COUNT(*)
 ORDER BY T.GeneralSchema
        , T.GeneralObject
        , Z.GeneralSchema
        , Z.GeneralObject

   INSERT #FKey
   SELECT F.ForeignID
        , F.PrimaryID
        , F.ForeignType
        , F.PrimaryType
        , F.ForeignObject
        , F.PrimaryObject
        , F.ForeignSchema
        , F.PrimarySchema
        , F.SQLServerName
        , F.is_bogus
        , 1
        , 1
        , P.key_ordinal
        , P.GeneralColumn
        , P.GeneralColumn
     FROM #FKeys AS F
     JOIN #PKey  AS P
       ON F.PrimaryID
        = P.GeneralID
      AND F.SQLServerName
        = P.SQLServerName
      AND F.is_bogus != 0

   SELECT W.PrimaryID
        , W.ForeignID
        , W.SQLServerName
     INTO #Work
     FROM
  (SELECT F.PrimaryID
        , F.ForeignID
        , F.SQLServerName
        , ROW_NUMBER() OVER (PARTITION BY F.PrimaryID, F.ForeignID ORDER BY CASE WHEN F.is_bogus = 0 THEN 1 ELSE 2 END, F.Columns, F.SQLServerName) AS RowID
     FROM #FKeys AS F) AS W
    WHERE W.RowID > 1
 ORDER BY W.PrimaryID
        , W.ForeignID

   DELETE #FKeys
     FROM #FKeys AS F
     JOIN #Work  AS W
       ON F.PrimaryID
        = W.PrimaryID
      AND F.ForeignID
        = W.ForeignID
      AND F.SQLServerName
        = W.SQLServerName

   DELETE #FKey
     FROM #FKey  AS F
     JOIN #Work  AS W
       ON F.PrimaryID
        = W.PrimaryID
      AND F.ForeignID
        = W.ForeignID
      AND F.SQLServerName
        = W.SQLServerName

-- generate SQL

   SELECT P.GeneralType
        , P.GeneralSchema
        , P.GeneralObject
        , E.SQLServerName AS GeneralAlias
        , MAX(CASE WHEN P.key_ordinal = 1 THEN        @X + P.GeneralColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 2 THEN ', ' + @X + P.GeneralColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 3 THEN ', ' + @X + P.GeneralColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 4 THEN ', ' + @X + P.GeneralColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 5 THEN ', ' + @X + P.GeneralColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 6 THEN ', ' + @X + P.GeneralColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 7 THEN ', ' + @X + P.GeneralColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 8 THEN ', ' + @X + P.GeneralColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 9 THEN ', ' + @X + P.GeneralColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal > 9 THEN ', ' + @X + '...'           + @Y ELSE SPACE(0) END) AS GeneralColumn
        , P.is_primary_key
        , P.is_unique_constraint
     FROM #PKey AS P
     JOIN #Base AS E
       ON P.GeneralID
        = E.GeneralID
 GROUP BY P.GeneralType
        , P.GeneralSchema
        , P.GeneralObject
        , E.SQLServerName
        , P.is_primary_key
        , P.is_unique_constraint
 ORDER BY P.GeneralSchema
        , P.GeneralObject
        , CASE WHEN P.is_primary_key       != 0 THEN 1
               WHEN P.is_unique_constraint != 0 THEN 2 ELSE 3 END

   SELECT F.PrimaryType
        , F.PrimarySchema
        , F.PrimaryObject
        , E.SQLServerName AS PrimaryAlias
        , MAX(CASE WHEN F.constraint_column_id = 1 THEN        @X + F.PrimaryColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 2 THEN ', ' + @X + F.PrimaryColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 3 THEN ', ' + @X + F.PrimaryColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 4 THEN ', ' + @X + F.PrimaryColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 5 THEN ', ' + @X + F.PrimaryColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 6 THEN ', ' + @X + F.PrimaryColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 7 THEN ', ' + @X + F.PrimaryColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 8 THEN ', ' + @X + F.PrimaryColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 9 THEN ', ' + @X + F.PrimaryColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id > 9 THEN ', ' + @X + '...'           + @Y ELSE SPACE(0) END) AS PrimaryColumn
        , F.ForeignType
        , F.ForeignSchema
        , F.ForeignObject
        , Z.SQLServerName AS ForeignAlias
        , MAX(CASE WHEN F.constraint_column_id = 1 THEN        @X + F.ForeignColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 2 THEN ', ' + @X + F.ForeignColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 3 THEN ', ' + @X + F.ForeignColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 4 THEN ', ' + @X + F.ForeignColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 5 THEN ', ' + @X + F.ForeignColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 6 THEN ', ' + @X + F.ForeignColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 7 THEN ', ' + @X + F.ForeignColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 8 THEN ', ' + @X + F.ForeignColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 9 THEN ', ' + @X + F.ForeignColumn + @Y ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id > 9 THEN ', ' + @X + '...'           + @Y ELSE SPACE(0) END) AS ForeignColumn
        , F.is_bogus AS is_not_FK
     FROM #FKey AS F
     JOIN #Base AS E
       ON F.PrimaryID
        = E.GeneralID
     JOIN #Base AS Z
       ON F.ForeignID
        = Z.GeneralID
 GROUP BY F.PrimaryType
        , F.PrimarySchema
        , F.PrimaryObject
        , E.SQLServerName
        , F.ForeignType
        , F.ForeignSchema
        , F.ForeignObject
        , Z.SQLServerName
        , F.is_bogus
 ORDER BY F.PrimarySchema
        , F.PrimaryObject
        , F.ForeignSchema
        , F.ForeignObject

  DECLARE Objects CURSOR FAST_FORWARD FOR
   SELECT E.GeneralID
        , E.GeneralSchema
        , E.GeneralObject
        , E.SQLServerName
        , E.Parameters
        , E.I
     FROM #Base AS E
 ORDER BY CASE WHEN E.GeneralType = 'U ' THEN 0 ELSE 1 END
        , E.GeneralSchema
        , E.GeneralObject

OPEN Objects

FETCH NEXT FROM Objects INTO @GeneralID, @GeneralSchema, @GeneralObject, @SQLServerName, @Parameters, @W

WHILE @@FETCH_STATUS = 0

    BEGIN

    SET @SQLServerCode = '   SELECT '

      DECLARE Columns CURSOR FAST_FORWARD FOR
       SELECT T.GeneralColumn
         FROM #Base AS E
         JOIN #TKey AS T
           ON E.GeneralID
            = T.GeneralID
        WHERE E.GeneralID
            =  @GeneralID
     ORDER BY T.column_id

    OPEN Columns

    FETCH NEXT FROM Columns INTO @GeneralColumn

    WHILE @@FETCH_STATUS = 0

        BEGIN

        PRINT @SQLServerCode + @SQLServerName + '.' + @X + @GeneralColumn + @Y

        SET @SQLServerCode = '        , '

        FETCH NEXT FROM Columns INTO @GeneralColumn

        END

    CLOSE Columns DEALLOCATE Columns

    PRINT '     FROM ' + @GeneralSchema + '.' + @X + @GeneralObject + @Y + @Parameters + SPACE(@I - @W) + ' AS ' + @SQLServerName

      DECLARE DBItems CURSOR FAST_FORWARD FOR
       SELECT F.PrimaryID
            , F.PrimarySchema
            , F.PrimaryObject
            , A.SQLServerName
            , A.Parameters
            , A.I
         FROM #Base  AS E
         JOIN #FKeys AS F
           ON E.GeneralID
            = F.ForeignID
         JOIN #Base  AS A
           ON F.PrimaryID
            = A.GeneralID
        WHERE E.GeneralID
            =  @GeneralID
     ORDER BY F.PrimarySchema
            , F.PrimaryObject

    OPEN DBItems

    FETCH NEXT FROM DBItems INTO @PrimaryID, @PrimarySchema, @PrimaryObject, @SQLServerMore, @Parameterz, @Z

    WHILE @@FETCH_STATUS = 0

        BEGIN

        PRINT '     JOIN ' + @PrimarySchema + '.' + @X + @PrimaryObject + @Y + @Parameterz + SPACE(@I - @Z) + ' AS ' + @SQLServerMore

    SET @SQLServerCode = '       ON '

          DECLARE Columns CURSOR FAST_FORWARD FOR
           SELECT F.PrimaryColumn
                , F.ForeignColumn
             FROM #Base AS E
             JOIN #FKey AS F
               ON E.GeneralID
                = F.ForeignID
            WHERE E.GeneralID
                =  @GeneralID
              AND F.PrimaryID
                =  @PrimaryID
         ORDER BY F.constraint_column_id

        OPEN Columns

        FETCH NEXT FROM Columns INTO @PrimaryColumn, @ForeignColumn

        WHILE @@FETCH_STATUS = 0

            BEGIN

            PRINT @SQLServerCode + @SQLServerName + '.' + @X + @ForeignColumn + @Y + CHAR(13) + CHAR(10) + '        = ' + @SQLServerMore + '.' + @X + @PrimaryColumn + @Y

            SET @SQLServerCode = '      AND '

            FETCH NEXT FROM Columns INTO @PrimaryColumn, @ForeignColumn

            END

        CLOSE Columns DEALLOCATE Columns

        FETCH NEXT FROM DBItems INTO @PrimaryID, @PrimarySchema, @PrimaryObject, @SQLServerMore, @Parameterz, @Z

        END

    CLOSE DBItems DEALLOCATE DBItems

      DECLARE DBItems CURSOR FAST_FORWARD FOR
       SELECT F.ForeignID
            , F.ForeignSchema
            , F.ForeignObject
            , A.SQLServerName
            , A.Parameters
            , A.I
         FROM #Base  AS E
         JOIN #FKeys AS F
           ON E.GeneralID
            = F.PrimaryID
         JOIN #Base  AS A
           ON F.ForeignID
            = A.GeneralID
        WHERE E.GeneralID
            =  @GeneralID
     ORDER BY F.ForeignSchema
            , F.ForeignObject

    OPEN DBItems

    FETCH NEXT FROM DBItems INTO @ForeignID, @ForeignSchema, @ForeignObject, @SQLServerMore, @Parameterz, @Z

    WHILE @@FETCH_STATUS = 0

        BEGIN

        PRINT '     JOIN ' + @ForeignSchema + '.' + @X + @ForeignObject + @Y + @Parameterz + SPACE(@I - @Z) + ' AS ' + @SQLServerMore

    SET @SQLServerCode = '       ON '

          DECLARE Columns CURSOR FAST_FORWARD FOR
           SELECT F.PrimaryColumn
                , F.ForeignColumn
             FROM #Base AS E
             JOIN #FKey AS F
               ON E.GeneralID
                = F.PrimaryID
            WHERE E.GeneralID
                =  @GeneralID
              AND F.ForeignID
                =  @ForeignID
         ORDER BY F.constraint_column_id

        OPEN Columns

        FETCH NEXT FROM Columns INTO @PrimaryColumn, @ForeignColumn

        WHILE @@FETCH_STATUS = 0

            BEGIN

            PRINT @SQLServerCode + @SQLServerName + '.' + @X + @ForeignColumn + @Y + CHAR(13) + CHAR(10) + '        = ' + @SQLServerMore + '.' + @X + @PrimaryColumn + @Y

            SET @SQLServerCode = '      AND '

            FETCH NEXT FROM Columns INTO @PrimaryColumn, @ForeignColumn

            END

        CLOSE Columns DEALLOCATE Columns

        FETCH NEXT FROM DBItems INTO @ForeignID, @ForeignSchema, @ForeignObject, @SQLServerMore, @Parameterz, @Z

        END

    CLOSE DBItems DEALLOCATE DBItems

    PRINT CHAR(13) + CHAR(10)

    FETCH NEXT FROM Objects INTO @GeneralID, @GeneralSchema, @GeneralObject, @SQLServerName, @Parameters, @W

    END

CLOSE Objects DEALLOCATE Objects

DROP TABLE #Base

DROP TABLE #PKey
DROP TABLE #PKeys

DROP TABLE #FKey
DROP TABLE #FKeys

DROP TABLE #ZKey
DROP TABLE #ZKeys

DROP TABLE #TKey
DROP TABLE #TKeys

DROP TABLE #Work

SET NOCOUNT OFF

