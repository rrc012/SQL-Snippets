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

DECLARE @GeneralID int

DECLARE @GeneralType char(0002)

DECLARE @GeneralSchema varchar(0128) = 'dbo' -- enter schema name here

DECLARE @GeneralObject varchar(0128) = 'dba' -- enter object name here

   SELECT @GeneralID   = O.object_id
        , @GeneralType = O.type
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
    WHERE S.name = @GeneralSchema
      AND O.name = @GeneralObject

IF OBJECT_ID('tempdb..#Base' , 'U ') IS NOT NULL DROP TABLE #Base

IF OBJECT_ID('tempdb..#More' , 'U ') IS NOT NULL DROP TABLE #More

IF OBJECT_ID('tempdb..#Task' , 'U ') IS NOT NULL DROP TABLE #Task

IF OBJECT_ID('tempdb..#PKey' , 'U ') IS NOT NULL DROP TABLE #PKey

IF OBJECT_ID('tempdb..#FKey' , 'U ') IS NOT NULL DROP TABLE #FKey
IF OBJECT_ID('tempdb..#FKeys', 'U ') IS NOT NULL DROP TABLE #FKeys

IF OBJECT_ID('tempdb..#ZKey' , 'U ') IS NOT NULL DROP TABLE #ZKey
IF OBJECT_ID('tempdb..#ZKeys', 'U ') IS NOT NULL DROP TABLE #ZKeys

IF OBJECT_ID('tempdb..#TKey' , 'U ') IS NOT NULL DROP TABLE #TKey
IF OBJECT_ID('tempdb..#TKeys', 'U ') IS NOT NULL DROP TABLE #TKeys

IF OBJECT_ID('tempdb..#UKey' , 'U ') IS NOT NULL DROP TABLE #UKey
IF OBJECT_ID('tempdb..#UKeys', 'U ') IS NOT NULL DROP TABLE #UKeys

IF OBJECT_ID('tempdb..#VKey' , 'U ') IS NOT NULL DROP TABLE #VKey

IF OBJECT_ID('tempdb..#WKey' , 'U ') IS NOT NULL DROP TABLE #WKey

-- base objects

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        , CONVERT(varchar(0040), O.create_date, 120) AS create_date
        , CONVERT(varchar(0040), O.modify_date, 120) AS modify_date
        , O.parent_object_id AS VariousID
        , CONVERT(varchar(max ), ISNULL(M.definition, SPACE(0))) AS SQLServerCode
     INTO #Base
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
LEFT JOIN sys.sql_modules AS M
       ON O.object_id
        = M.object_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ', 'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
 ORDER BY O.type
        , S.name
        , O.name

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        , CONVERT(varchar(0040), Z.create_date, 120) AS create_date
        , CONVERT(varchar(0040), Z.modify_date, 120) AS modify_date
        , Z.is_disabled
        , Z.is_not_trusted
        , ISNULL(C.name, SPACE(0))                               AS GeneralColumn
        , ISNULL(Z.name, SPACE(0))                               AS SQLServerName
        , CONVERT(varchar(max ), ISNULL(Z.definition, SPACE(0))) AS SQLServerCode
     INTO #More
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.check_constraints AS Z
       ON        O.object_id
        = Z.parent_object_id
LEFT JOIN sys.columns AS C
       ON Z.parent_object_id
        =        C.object_id
      AND Z.parent_column_id
        =        C.column_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY O.type
        , S.name
        , O.name
        , Z.name

   SELECT O.object_id AS ReferenceByID
        , O.type      AS ReferenceByType
        , O.name      AS ReferenceByObject
        , S.name      AS ReferenceBySchema
        , W.object_id AS ReferenceOfID
        , W.type      AS ReferenceOfType
        , W.name      AS ReferenceOfObject
        , Z.name      AS ReferenceOfSchema
     INTO #Task
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN
  (SELECT D.referencing_id AS ReferenceByID
        , D.referenced_id  AS ReferenceOfID
     FROM sys.sql_expression_dependencies AS D
    WHERE D.referencing_id
       != D.referenced_id
 GROUP BY D.referencing_id
        , D.referenced_id) AS K
       ON O.object_id
        = K.ReferenceByID
     JOIN sys.objects AS W
       ON K.ReferenceOfID
        = W.object_id
     JOIN sys.schemas AS Z
       ON W.schema_id
        = Z.schema_id
    WHERE O.type NOT IN ('C ')
 ORDER BY   ReferenceByID
        ,   ReferenceOfID

-- primary keys

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

-- foreign keys

   SELECT O.object_id AS ForeignID
        , W.object_id AS PrimaryID
        , O.name      AS ForeignObject
        , W.name      AS PrimaryObject
        , S.name      AS ForeignSchema
        , Z.name      AS PrimarySchema
        , F.name      AS SQLServerName
        , CONVERT(varchar(0040), F.create_date, 120) AS create_date
        , CONVERT(varchar(0040), F.modify_date, 120) AS modify_date
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
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY   PrimarySchema
        ,   PrimaryObject
        ,   ForeignSchema
        ,   ForeignObject
        ,   constraint_column_id

   SELECT F.PrimaryID
        , F.ForeignID
        , F.PrimaryObject
        , F.ForeignObject
        , F.PrimarySchema
        , F.ForeignSchema
        , F.SQLServerName
        , COUNT(*) AS Columns
     INTO #FKeys
     FROM #FKey AS F
    WHERE F.PrimaryID
       != F.ForeignID
 GROUP BY F.PrimaryID
        , F.ForeignID
        , F.PrimaryObject
        , F.ForeignObject
        , F.PrimarySchema
        , F.ForeignSchema
        , F.SQLServerName
 ORDER BY F.PrimarySchema
        , F.PrimaryObject
        , F.ForeignSchema
        , F.ForeignObject

-- indexes

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
      AND O.type IN ('U ', 'V ', 'P ', 'FN', 'IF', 'TF')
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
--  WHERE T.GeneralType IN ('U ', 'V ', 'P ', 'FN', 'IF', 'TF')
 ORDER BY T.GeneralType
        , T.GeneralSchema
        , T.GeneralObject
        , T.column_id

-- parameters

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        , W.parameter_id
        , CONVERT(bit, COLUMNPROPERTY(O.object_id, W.name, 'AllowsNull')) AS is_nullable
        , CONVERT(bit, COLUMNPROPERTY(O.object_id, W.name, 'IsOutParam')) AS is_output
        , W.name      AS GeneralColumn
        , T.name
        , CASE WHEN T.name LIKE 'n%char' AND W.max_length > 0 THEN W.max_length / 2 ELSE W.max_length END AS min_length
        , W.max_length
        , W.precision
        , W.scale
     INTO #UKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.parameters AS W
       ON O.object_id
        = W.object_id
      AND W.parameter_id != 0
     JOIN sys.types AS T
       ON W.user_type_id
        = T.user_type_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN (            'P ', 'FN', 'IF', 'TF')
 ORDER BY   GeneralType
        ,   GeneralSchema
        ,   GeneralObject
        ,   parameter_id

   SELECT U.*
        , CASE WHEN U.name = 'time'           THEN U.name + '(' +                                                   STR(U.scale,       1)     + ')'
               WHEN U.name = 'datetime2'      THEN U.name + '(' +                                                   STR(U.scale,       1)     + ')'
               WHEN U.name = 'datetimeoffset' THEN U.name + '(' +                                                   STR(U.scale,       1)     + ')'
               WHEN U.name = 'float'          THEN U.name + '(' + RIGHT(STR(U.precision + 100, 3), 2)                                         + ')'
               WHEN U.name = 'numeric'        THEN U.name + '(' + RIGHT(STR(U.precision + 100, 3), 2) + ',' + RIGHT(STR(U.scale + 100, 3), 2) + ')'
               WHEN U.name = 'decimal'        THEN U.name + '(' + RIGHT(STR(U.precision + 100, 3), 2) + ',' + RIGHT(STR(U.scale + 100, 3), 2) + ')'
               WHEN U.name = 'vardecimal'     THEN U.name + '(' + RIGHT(STR(U.precision + 100, 3), 2) + ',' + RIGHT(STR(U.scale + 100, 3), 2) + ')'
               WHEN U.name = 'binary'         THEN U.name + '(' +                                 RIGHT(STR(U.max_length + 10000, 5), 4)                 + ')'
               WHEN U.name = 'varbinary'      THEN U.name + '(' + CASE WHEN U.max_length > 0 THEN RIGHT(STR(U.max_length + 10000, 5), 4) ELSE 'max ' END + ')'
               WHEN U.name = 'nchar'          THEN U.name + '(' +                                 RIGHT(STR(U.min_length + 10000, 5), 4)                 + ')'
               WHEN U.name = 'nvarchar'       THEN U.name + '(' + CASE WHEN U.min_length > 0 THEN RIGHT(STR(U.min_length + 10000, 5), 4) ELSE 'max ' END + ')'
               WHEN U.name = 'char'           THEN U.name + '(' +                                 RIGHT(STR(U.max_length + 10000, 5), 4)                 + ')'
               WHEN U.name = 'varchar'        THEN U.name + '(' + CASE WHEN U.max_length > 0 THEN RIGHT(STR(U.max_length + 10000, 5), 4) ELSE 'max ' END + ')'
                                              ELSE U.name END AS SQLServerType
     INTO #UKeys
     FROM #UKey AS U
--  WHERE U.GeneralType IN (            'P ', 'FN', 'IF', 'TF')
 ORDER BY U.GeneralType
        , U.GeneralSchema
        , U.GeneralObject
        , U.parameter_id

-- partitions

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        ,        H.name          AS SQLServerFile
        , ISNULL(I.name, O.name) AS SQLServerName
        , X.name AS [PS_Name]
        , Y.name AS [PF_Name]
        , C.GeneralColumn
        , C.SQLServerType
        , CASE WHEN Y.boundary_value_on_right = 0 THEN 'THRU' ELSE 'FROM' END + ' - ' + ISNULL(CASE WHEN T.name LIKE '%datetime%' THEN LEFT(CONVERT(varchar(0400), CONVERT(datetime, W.value), 120), 16) ELSE CONVERT(varchar(0400), W.value) END, SPACE(0)) AS Boundary
        , P.partition_number AS [Partition]
        , P.rows             AS [Rows]
        , CASE WHEN P.data_compression = 1 THEN 'ROW'
               WHEN P.data_compression = 2 THEN 'PAGE'
               WHEN P.data_compression > 2 THEN 'COLUMNSTORE' ELSE SPACE(0) END AS [Compression]
        , I.type      AS table_type
        , I.type      AS index_type
        , I.fill_factor
     INTO #VKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.indexes AS I
       ON O.object_id
        = I.object_id
LEFT JOIN #ZKeys AS C
       ON I.object_id
        = C.GeneralID
      AND I.index_id
        = C.index_id
      AND C.partition_ordinal = 1
     JOIN sys.partitions AS P
       ON I.object_id
        = P.object_id
      AND I.index_id
        = P.index_id
     JOIN sys.partition_schemes AS X
       ON I.data_space_id
        = X.data_space_id
     JOIN sys.partition_functions AS Y
       ON X.function_id
        = Y.function_id
     JOIN sys.partition_parameters AS Z
       ON Y.function_id
        = Z.function_id
     JOIN sys.types AS T
       ON Z.user_type_id
        = T.user_type_id
LEFT JOIN sys.partition_range_values AS W
       ON Z.function_id
        = W.function_id
      AND Z.parameter_id = 1
      AND W.parameter_id = 1
      AND P.partition_number
        = W.boundary_id + CASE WHEN Y.boundary_value_on_right = 0 THEN 0 ELSE 1 END
     JOIN
  (SELECT E.partition_scheme_id AS data_space_id
        , E.destination_id      AS partition_number
        , K.name
     FROM sys.destination_data_spaces AS E
     JOIN sys.data_spaces AS K
       ON E.data_space_id
        = K.data_space_id) AS H
       ON X.data_space_id
        = H.data_space_id
      AND P.partition_number
        = H.partition_number
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY   GeneralSchema
        ,   GeneralObject
        ,   [Partition]

-- table_type

   UPDATE P SET table_type = E.index_type FROM #PKey  AS P JOIN #ZKey AS E ON P.GeneralID = E.GeneralID AND E.index_type IN (0, 1, 5) AND E.index_column_id IN (0, 1)

   UPDATE Z SET table_type = E.index_type FROM #ZKey  AS Z JOIN #ZKey AS E ON Z.GeneralID = E.GeneralID AND E.index_type IN (0, 1, 5) AND E.index_column_id IN (0, 1)
   UPDATE Z SET table_type = E.index_type FROM #ZKeys AS Z JOIN #ZKey AS E ON Z.GeneralID = E.GeneralID AND E.index_type IN (0, 1, 5) AND E.index_column_id IN (0, 1)

   UPDATE V SET table_type = E.index_type FROM #VKey  AS V JOIN #ZKey AS E ON V.GeneralID = E.GeneralID AND E.index_type IN (0, 1, 5) AND E.index_column_id IN (0, 1)

-- rows / GBs

   SELECT O.object_id AS GeneralID
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        ,        H.name          AS SQLServerFile
        , ISNULL(I.name, O.name) AS SQLServerName
        , ISNULL(CONVERT(decimal(38,00), IDENT_SEED   (S.name + '.' + O.name)), 0) AS [From]
        , ISNULL(CONVERT(decimal(38,00), IDENT_INCR   (S.name + '.' + O.name)), 0) AS [Plus]
        , ISNULL(CONVERT(decimal(38,00), IDENT_CURRENT(S.name + '.' + O.name)), 0) AS [Used]
        , T.index_id
        , I.type      AS table_type
        , I.type      AS index_type
        , CASE WHEN T.DC_MIN  = T.DC_MAX AND T.DC_MIN = 1 THEN 'ROW'
               WHEN T.DC_MIN  = T.DC_MAX AND T.DC_MIN = 2 THEN 'PAGE'
               WHEN T.DC_MIN  = T.DC_MAX AND T.DC_MIN > 2 THEN 'COLUMNSTORE'
               WHEN T.DC_MIN != T.DC_MAX                  THEN 'MIXED TYPES' ELSE SPACE(0) END AS [Compression]
        , T.[Partitions]
        , T.total_rows          AS [Rows]
        , ISNULL(Z.index_id, 0) AS [Indexes]
        , CONVERT(decimal(19,05), ISNULL(W.total_pages, 0) / 128.0 / 1024.0) AS GBs_Table
        , CONVERT(decimal(19,05), ISNULL(Z.total_pages, 0) / 128.0 / 1024.0) AS GBs_Indexes
     INTO #WKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.indexes AS I
       ON O.object_id
        = I.object_id
      AND I.type                     IN (0, 1, 5)
     JOIN sys.data_spaces AS H
       ON I.data_space_id
        = H.data_space_id
     JOIN
  (SELECT I.object_id
        , MIN(I.index_id)            AS index_id
        , SUM(P.rows)                AS total_rows
        , COUNT(*)                   AS Partitions
        , MIN(P.data_compression)    AS DC_MIN
        , MAX(P.data_compression)    AS DC_MAX
     FROM sys.indexes    AS I
     JOIN sys.partitions AS P
       ON I.object_id
        = P.object_id
      AND I.index_id
        = P.index_id
    WHERE I.type                     IN (0, 1, 5)
 GROUP BY I.object_id)               AS T
       ON O.object_id
        = T.object_id
     JOIN
  (SELECT I.object_id
        , MIN(I.index_id)            AS index_id
        , SUM(A.total_pages)         AS total_pages
     FROM sys.indexes    AS I
     JOIN sys.partitions AS P
       ON I.object_id
        = P.object_id
      AND I.index_id
        = P.index_id
     JOIN sys.allocation_units       AS A
       ON P.partition_id
        = A.container_id
      AND A.type != 0
    WHERE I.type                     IN (0, 1, 5)
 GROUP BY I.object_id)               AS W
       ON O.object_id
        = W.object_id
LEFT JOIN
  (SELECT I.object_id
        , COUNT(DISTINCT I.index_id) AS index_id
        , SUM(A.total_pages)         AS total_pages
     FROM sys.indexes    AS I
     JOIN sys.partitions AS P
       ON I.object_id
        = P.object_id
      AND I.index_id
        = P.index_id
     JOIN sys.allocation_units       AS A
       ON P.partition_id
        = A.container_id
      AND A.type != 0
    WHERE I.type                 NOT IN (0, 1, 5)
 GROUP BY I.object_id)               AS Z
       ON O.object_id
        = Z.object_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY   GeneralSchema
        ,   GeneralObject

-- <<< SQLFacts >>>

IF @GeneralType = 'U '

BEGIN

-- SQLFacts <> 06 Table Details, by name

PRINT '-- Fact 06 Table Details, by name'

   SELECT '06' AS Fact
        , E.GeneralSchema
        , E.GeneralObject
        , W.SQLServerFile
--      , W.SQLServerName
        , E.create_date
        , E.modify_date
        , (SELECT COUNT(*) FROM #PKey AS P WHERE P.GeneralID = E.GeneralID AND P.is_primary_key       != 0 AND P.key_ordinal          = 1) AS [PKs]
        , (SELECT COUNT(*) FROM #PKey AS P WHERE P.GeneralID = E.GeneralID AND P.is_unique_constraint != 0 AND P.key_ordinal          = 1) AS [AKs]
        , (SELECT COUNT(*) FROM #FKey AS F WHERE F.ForeignID = E.GeneralID                                 AND F.constraint_column_id = 1) AS [FKs_P]
        , (SELECT COUNT(*) FROM #FKey AS F WHERE F.PrimaryID = E.GeneralID                                 AND F.constraint_column_id = 1) AS [FKs_C]
        , (SELECT COUNT(*) FROM #TKey AS T WHERE T.GeneralID = E.GeneralID                                                               ) AS [Columns]
        , W.[From]
        , W.[Plus]
        , W.[Used]
        , W.[Compression]
        , W.[Partitions]
        , W.[Rows]
        , W.[table_type]
        , W.[Indexes]
        , W.GBs_Table
        , W.GBs_Indexes
--      , (SELECT COUNT(*) FROM #More AS M WHERE M.GeneralID     = E.GeneralID                                               ) AS [Checks]
--      , (SELECT COUNT(*) FROM #Base AS A WHERE A.GeneralID     = E.GeneralID AND A.GeneralType       IN ('TR')
--                                                                             AND A.GeneralObject     NOT LIKE 'uspG[SIUD]%'
--                                                                             AND A.GeneralObject     NOT LIKE 'trgG[SIUD]%') AS [Triggers]
--      , (SELECT COUNT(*) FROM #Task AS T WHERE T.ReferenceOfID = E.GeneralID AND T.ReferenceByType   IN (      'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
--                                                                             AND T.ReferenceByObject NOT LIKE 'uspG[SIUD]%'
--                                                                             AND T.ReferenceByObject NOT LIKE 'trgG[SIUD]%') AS [References]
--   INTO SQLFacts.dbo.Fact_06
     FROM #Base AS E
LEFT JOIN #WKey AS W
       ON E.GeneralID
        = W.GeneralID
    WHERE E.GeneralType IN ('U ')
      AND E.GeneralID
        =  @GeneralID
 ORDER BY E.GeneralSchema
        , E.GeneralObject

-- SQLFacts <> 10 Primary Keys

PRINT '-- Fact 10 Primary Keys'

   SELECT '10' AS Fact
        , P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerFile
        , P.SQLServerName
        , P.table_type
        , P.index_type
        , P.fill_factor AS Factor
        , 'PK' AS [Key]
        , MAX(CASE WHEN P.key_ordinal = 1 THEN   '[' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 2 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 3 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 4 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 5 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 6 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 7 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 8 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 9 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal > 9 THEN ', [...]'                                                                                         ELSE SPACE(0) END) AS GeneralColumn
--   INTO SQLFacts.dbo.Fact_10
     FROM #PKey AS P
    WHERE P.is_primary_key != 0
      AND P.GeneralID
        =  @GeneralID
 GROUP BY P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerFile
        , P.SQLServerName
        , P.table_type
        , P.index_type
        , P.fill_factor
 ORDER BY P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerName

-- SQLFacts <> 11 Alternate Keys

PRINT '-- Fact 11 Alternate Keys'

   SELECT '11' AS Fact
        , P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerFile
        , P.SQLServerName
        , P.table_type
        , P.index_type
        , P.fill_factor AS Factor
        , 'AK' AS [Key]
        , MAX(CASE WHEN P.key_ordinal = 1 THEN   '[' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 2 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 3 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 4 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 5 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 6 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 7 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 8 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 9 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal > 9 THEN ', [...]'                                                                                         ELSE SPACE(0) END) AS GeneralColumn
--   INTO SQLFacts.dbo.Fact_11
     FROM #PKey AS P
    WHERE P.is_unique_constraint != 0
      AND P.GeneralID
        =  @GeneralID
 GROUP BY P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerFile
        , P.SQLServerName
        , P.table_type
        , P.index_type
        , P.fill_factor
 ORDER BY P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerName

-- SQLFacts <> 13 Foreign Keys / Parents

PRINT '-- Fact 13 Foreign Keys / Parents'

   SELECT '13' AS Fact
        , F.PrimarySchema
        , F.PrimaryObject
        , MAX(CASE WHEN F.constraint_column_id = 1 THEN   '[' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 2 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 3 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 4 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 5 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 6 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 7 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 8 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 9 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id > 9 THEN ', [...]'                     ELSE SPACE(0) END) AS PrimaryColumn
        , F.SQLServerName
        , F.create_date
        , F.modify_date
        , F.is_disabled
        , F.is_not_trusted
        , F.ForeignSchema
        , F.ForeignObject
        , MAX(CASE WHEN F.constraint_column_id = 1 THEN   '[' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 2 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 3 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 4 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 5 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 6 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 7 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 8 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 9 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id > 9 THEN ', [...]'                     ELSE SPACE(0) END) AS ForeignColumn
--   INTO SQLFacts.dbo.Fact_13_P
     FROM #FKey AS F
    WHERE F.ForeignID
        =  @GeneralID
 GROUP BY F.PrimarySchema
        , F.PrimaryObject
        , F.SQLServerName
        , F.create_date
        , F.modify_date
        , F.is_disabled
        , F.is_not_trusted
        , F.ForeignSchema
        , F.ForeignObject
 ORDER BY F.PrimarySchema
        , F.PrimaryObject
--      , F.SQLServerName
        , F.ForeignSchema
        , F.ForeignObject

-- SQLFacts <> 13 Foreign Keys / Children

PRINT '-- Fact 13 Foreign Keys / Children'

   SELECT '13' AS Fact
        , F.PrimarySchema
        , F.PrimaryObject
        , MAX(CASE WHEN F.constraint_column_id = 1 THEN   '[' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 2 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 3 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 4 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 5 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 6 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 7 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 8 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 9 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id > 9 THEN ', [...]'                     ELSE SPACE(0) END) AS PrimaryColumn
        , F.SQLServerName
        , F.create_date
        , F.modify_date
        , F.is_disabled
        , F.is_not_trusted
        , F.ForeignSchema
        , F.ForeignObject
        , MAX(CASE WHEN F.constraint_column_id = 1 THEN   '[' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 2 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 3 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 4 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 5 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 6 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 7 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 8 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 9 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id > 9 THEN ', [...]'                     ELSE SPACE(0) END) AS ForeignColumn
--   INTO SQLFacts.dbo.Fact_13_C
     FROM #FKey AS F
    WHERE F.PrimaryID
        =  @GeneralID
 GROUP BY F.PrimarySchema
        , F.PrimaryObject
        , F.SQLServerName
        , F.create_date
        , F.modify_date
        , F.is_disabled
        , F.is_not_trusted
        , F.ForeignSchema
        , F.ForeignObject
 ORDER BY F.PrimarySchema
        , F.PrimaryObject
--      , F.SQLServerName
        , F.ForeignSchema
        , F.ForeignObject

-- SQLFacts <> 16 Table Columns

PRINT '-- Fact 16 Table Columns'

   SELECT '16' AS Fact
        , T.GeneralType
        , T.GeneralSchema
        , T.GeneralObject
        , T.column_id
        , T.GeneralColumn
        , T.SQLServerType
        , T.collation_name
        , T.is_nullable
        , T.is_identity
        , T.[From]
        , T.[Plus]
        , T.[Used]
        , T.index_column_id AS PK_column_id
        , T.DefaultName
        , T.DefaultCode
        , T.FormulaCode
--   INTO SQLFacts.dbo.Fact_16
     FROM #TKeys AS T
    WHERE T.GeneralType IN ('U ')
      AND T.GeneralID
        =  @GeneralID
 ORDER BY T.GeneralType
        , T.GeneralSchema
        , T.GeneralObject
        , T.column_id

-- SQLFacts <> 08 Partitions (Table)

PRINT '-- Fact 08 Partitions (Table)'

   SELECT '08' AS Fact
        , V.GeneralSchema
        , V.GeneralObject
        , V.SQLServerFile
        , V.SQLServerName
        , V.table_type
        , V.index_type
        , V.fill_factor AS Factor
        , V.[PS_Name]
        , V.[PF_Name]
        , V.GeneralColumn
        , V.SQLServerType
        , V.Boundary
        , V.[Partition]
        , V.[Rows]
        , V.[Compression]
--   INTO SQLFacts.dbo.Fact_08
     FROM #VKey AS V
    WHERE V.index_type     IN (0, 1, 5)
      AND V.GeneralID
        =  @GeneralID
 ORDER BY V.GeneralSchema
        , V.GeneralObject
        , V.index_type
        , V.SQLServerName
        , V.[Partition]

-- SQLFacts <> 09 Partitions (Index)

PRINT '-- Fact 09 Partitions (Index)
'

   SELECT '09' AS Fact
        , E.GeneralSchema
        , E.GeneralObject
        , E.SQLServerFile
        , E.SQLServerName
        , E.table_type
        , E.index_type
        , E.fill_factor AS Factor
        , E.[PS_Name]
        , E.[PF_Name]
        , E.GeneralColumn
        , E.SQLServerType
        , E.Boundary
        , E.[Partition]
        , E.[Rows]
        , E.[Compression]
--   INTO SQLFacts.dbo.Fact_09
     FROM #VKey AS E
LEFT JOIN #VKey AS V
       ON E.GeneralID
        = V.GeneralID
      AND E.[PS_Name]
        = V.[PS_Name]
      AND V.index_type     IN (0, 1, 5)
    WHERE E.index_type NOT IN (0, 1, 5)
      AND V.index_type     IS NULL
      AND E.GeneralID
        =  @GeneralID
    UNION
   SELECT '09' AS Fact
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerFile
        , Z.SQLServerName
        , Z.table_type
        , Z.index_type
        , Z.fill_factor AS Factor
        , NULL AS [PS_Name]
        , NULL AS [PF_Name]
        , NULL AS GeneralColumn
        , NULL AS SQLServerType
        , NULL AS Boundary
        , NULL AS [Partition]
        , NULL AS [Rows]
        , NULL AS [Compression]
     FROM #ZKey AS Z
     JOIN #VKey AS V
       ON Z.GeneralID
        = V.GeneralID
      AND Z.SQLServerFile
       != V.[PS_Name]
      AND V.index_type     IN (0, 1, 5)
    WHERE Z.index_type NOT IN (0, 1, 5)
      AND Z.index_column_id = 1
      AND Z.GeneralID
        =  @GeneralID
 ORDER BY   GeneralSchema
        ,   GeneralObject
        ,   index_type
        ,   SQLServerName
        ,   [Partition]

-- SQLFacts <> 12 Indexes

PRINT '-- Fact 12 Indexes'

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
    WHERE Z.GeneralID
        =  @GeneralID
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

   SELECT '12' AS Fact
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerFile
        , Z.SQLServerName
        , Z.table_type
        , Z.index_type
        , Z.fill_factor AS Factor
        , Z.is_unique
        , Z.is_disabled
        , Z.RegularColumn
        , Z.IncludeColumn
        , Z.GeneralFilter
        , (SELECT SUM(P.rows) FROM sys.partitions AS P WHERE P.object_id = Z.GeneralID AND P.index_id = Z.index_id) AS [Rows]
--   INTO SQLFacts.dbo.Fact_12
     FROM #Hack AS Z
    WHERE CASE WHEN Z.is_primary_key       != 0 THEN 1
               WHEN Z.is_unique_constraint != 0 THEN 1 ELSE 0 END  = 0
 ORDER BY Z.GeneralSchema
        , Z.GeneralObject
        , CASE Z.index_type
          WHEN 0 THEN 0
          WHEN 1 THEN 0
          WHEN 5 THEN 0
          WHEN 2 THEN 1
          WHEN 6 THEN 2 ELSE 3 END
        , Z.SQLServerName

-- SQLFacts <> 37 Foreign Key Indexes

PRINT '-- Fact 37 Foreign Key Indexes'

   SELECT '37' AS Fact
        , A.PrimarySchema
        , A.PrimaryObject
--      , A.SQLServerName
        , A.ForeignSchema
        , A.ForeignObject
        , A.ForeignColumn
        , U.SQLServerName
        , U.RegularColumn
     FROM
  (SELECT F.PrimaryID
        , F.PrimarySchema
        , F.PrimaryObject
        , F.SQLServerName
        , F.ForeignID
        , F.ForeignSchema
        , F.ForeignObject
        , MAX(CASE WHEN F.constraint_column_id = 1 THEN   '[' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 2 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 3 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 4 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 5 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 6 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 7 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 8 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 9 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id > 9 THEN ', [...]'                     ELSE SPACE(0) END) AS ForeignColumn
--   INTO SQLFacts.dbo.Fact_37
     FROM #FKey AS F
    WHERE F.ForeignID
        =  @GeneralID
 GROUP BY F.PrimaryID
        , F.PrimarySchema
        , F.PrimaryObject
        , F.SQLServerName
        , F.ForeignID
        , F.ForeignSchema
        , F.ForeignObject) AS A
LEFT JOIN
  (SELECT Z.GeneralID
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerName
        , MAX(CASE WHEN Z.regular_column_id = 1 THEN   '[' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 2 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 3 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 4 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 5 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 6 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 7 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 8 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 9 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id > 9 THEN ', [...]'                     ELSE SPACE(0) END) AS RegularColumn
     FROM #ZKey AS Z
    WHERE Z.GeneralFilter = SPACE(0)
 GROUP BY Z.GeneralID
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerName) AS U
       ON A.ForeignID
        = U.GeneralID
      AND REPLACE(REPLACE(U.RegularColumn, '[', '<'), ']', '>')
     LIKE REPLACE(REPLACE(A.ForeignColumn, '[', '<'), ']', '>') + '%'
 ORDER BY A.ForeignSchema
        , A.ForeignObject
        , A.ForeignColumn
        , U.RegularColumn DESC

-- SQLFacts <> 38 Index Redundancy

PRINT '-- Fact 38 Index Redundancy'

   SELECT '38' AS Fact
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerName
        , Z.table_type
        , Z.index_type
        , Z.RegularColumn
        , Z.IncludeColumn
--      , Z.GeneralFilter
--      , Z.SQLServerFile
--      , Z.fill_factor AS Factor
        , Z.is_primary_key
        , Z.is_unique_constraint
        , Z.is_unique
        , Z.is_disabled
        , ROW_NUMBER() OVER (ORDER BY Z.GeneralSchema, Z.GeneralObject, Z.index_type, W.index_type, Z.SQLServerName, W.SQLServerName) AS Redundancy
--   INTO SQLFacts.dbo.Fact_38
     FROM #Hack AS Z
     JOIN #Hack AS W
       ON Z.GeneralSchema
        = W.GeneralSchema
      AND Z.GeneralObject
        = W.GeneralObject
      AND Z.GeneralFilter
        = W.GeneralFilter
      AND Z.SQLServerName
       != W.SQLServerName
    WHERE W.index_type IN (1, 2)
      AND REPLACE(REPLACE(Z.RegularColumn, '[', '<'), ']', '>')
     LIKE REPLACE(REPLACE(W.RegularColumn, '[', '<'), ']', '>') + '%'
      AND CASE WHEN Z.RegularColumn > W.RegularColumn THEN 1
               WHEN Z.RegularColumn = W.RegularColumn
                AND Z.IncludeColumn > W.IncludeColumn THEN 1
               WHEN Z.RegularColumn = W.RegularColumn
                AND Z.IncludeColumn = W.IncludeColumn
                AND Z.SQLServerName < W.SQLServerName THEN 1 ELSE 0 END != 0
      AND Z.GeneralSchema
        =  @GeneralSchema
      AND Z.GeneralObject
        =  @GeneralObject
    UNION ALL
   SELECT '38' AS Fact
        , Z.GeneralSchema
        , Z.GeneralObject
        , W.SQLServerName
        , W.table_type
        , W.index_type
        , W.RegularColumn
        , W.IncludeColumn
--      , W.GeneralFilter
--      , W.SQLServerFile
--      , W.fill_factor AS Factor
        , W.is_primary_key
        , W.is_unique_constraint
        , W.is_unique
        , W.is_disabled
        , ROW_NUMBER() OVER (ORDER BY Z.GeneralSchema, Z.GeneralObject, Z.index_type, W.index_type, Z.SQLServerName, W.SQLServerName) AS Redundancy
     FROM #Hack AS Z
     JOIN #Hack AS W
       ON Z.GeneralSchema
        = W.GeneralSchema
      AND Z.GeneralObject
        = W.GeneralObject
      AND Z.GeneralFilter
        = W.GeneralFilter
      AND Z.SQLServerName
       != W.SQLServerName
    WHERE W.index_type IN (1, 2)
      AND REPLACE(REPLACE(Z.RegularColumn, '[', '<'), ']', '>')
     LIKE REPLACE(REPLACE(W.RegularColumn, '[', '<'), ']', '>') + '%'
      AND CASE WHEN Z.RegularColumn > W.RegularColumn THEN 1
               WHEN Z.RegularColumn = W.RegularColumn
                AND Z.IncludeColumn > W.IncludeColumn THEN 1
               WHEN Z.RegularColumn = W.RegularColumn
                AND Z.IncludeColumn = W.IncludeColumn
                AND Z.SQLServerName < W.SQLServerName THEN 1 ELSE 0 END != 0
      AND Z.GeneralSchema
        =  @GeneralSchema
      AND Z.GeneralObject
        =  @GeneralObject
 ORDER BY   Redundancy
        ,   RegularColumn DESC
        ,   IncludeColumn DESC
        ,   index_type
        ,   SQLServerName

-- SQLFacts <> 24 Internal References, by object called

PRINT '-- Fact 24 Internal References, by object called'

   SELECT '24' AS Fact
        , T.ReferenceByType
        , T.ReferenceBySchema
        , T.ReferenceByObject
        , T.ReferenceOfType
        , T.ReferenceOfSchema
        , T.ReferenceOfObject
--   INTO SQLFacts.dbo.Fact_24
     FROM #Task AS T
    WHERE T.ReferenceByType IN (      'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
      AND T.ReferenceByObject NOT LIKE 'uspG[SIUD]%'
      AND T.ReferenceByObject NOT LIKE 'trgG[SIUD]%'
      AND T.ReferenceOfID
        =  @GeneralID
 ORDER BY CASE T.ReferenceOfType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , T.ReferenceOfSchema
        , T.ReferenceOfObject
        , CASE T.ReferenceByType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , T.ReferenceBySchema
        , T.ReferenceByObject

-- create model SQL statements

DECLARE @GeneralColumn varchar(0128)

DECLARE @GeneralINSERT varchar(4000) = SPACE(0)
DECLARE @GeneralSELECT varchar(4000) = SPACE(0)
DECLARE @GeneralUPDATE varchar(8000) = SPACE(0)

DECLARE @W char(0001) = LEFT(@GeneralObject, 1)

DECLARE @Z char(0002) = CHAR(13) + CHAR(10)

  DECLARE Columns CURSOR FAST_FORWARD FOR
   SELECT T.GeneralColumn
     FROM #TKeys AS T
    WHERE T.GeneralType IN ('U ')
      AND T.GeneralID
        =  @GeneralID
 ORDER BY T.column_id

OPEN Columns

FETCH NEXT FROM Columns INTO @GeneralColumn

WHILE @@FETCH_STATUS = 0

    BEGIN

    SET @GeneralINSERT = @GeneralINSERT + CASE WHEN LEN(@GeneralINSERT) = 0 THEN                                @GeneralColumn
                                                                            ELSE @Z + '        , ' +            @GeneralColumn END

    SET @GeneralSELECT = @GeneralSELECT + CASE WHEN LEN(@GeneralSELECT) = 0 THEN                     @W + '.' + @GeneralColumn
                                                                            ELSE @Z + '        , ' + @W + '.' + @GeneralColumn END

    SET @GeneralUPDATE = @GeneralUPDATE + CASE WHEN LEN(@GeneralUPDATE) = 0 THEN                     SPACE(2) + @GeneralColumn
                                                                               + @Z + '        = ' + @W + '.' + @GeneralColumn
                                                                            ELSE @Z + '        , ' + SPACE(2) + @GeneralColumn
                                                                               + @Z + '        = ' + @W + '.' + @GeneralColumn END

    FETCH NEXT FROM Columns INTO @GeneralColumn

    END

CLOSE Columns DEALLOCATE Columns

PRINT @Z

PRINT      '   INSERT ' + @GeneralSchema + '.' + @GeneralObject
    + @Z + '        ( ' + @GeneralINSERT + ' )'
    + @Z + '   SELECT ' + @GeneralSELECT
    + @Z + '     FROM ' + @GeneralSchema + '.' + @GeneralObject + ' AS ' + @W
    + @Z + '    WHERE 0 = 1' + @Z + @Z

PRINT      '   UPDATE ' + @GeneralSchema + '.' + @GeneralObject + ' SET'
    + @Z + '          ' + @GeneralUPDATE
    + @Z + '     FROM ' + @GeneralSchema + '.' + @GeneralObject + ' AS ' + @W
    + @Z + '    WHERE 0 = 1' + @Z + @Z

DROP TABLE #Hack

END
ELSE
BEGIN

-- SQLFacts <> 23 Internal References, by object caller

PRINT '-- Fact 23 Internal References, by object caller'

   SELECT '23' AS Fact
        , T.ReferenceByType
        , T.ReferenceBySchema
        , T.ReferenceByObject
        , T.ReferenceOfType
        , T.ReferenceOfSchema
        , T.ReferenceOfObject
--   INTO SQLFacts.dbo.Fact_23
     FROM #Task AS T
    WHERE T.ReferenceByType IN (      'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
      AND T.ReferenceByObject NOT LIKE 'uspG[SIUD]%'
      AND T.ReferenceByObject NOT LIKE 'trgG[SIUD]%'
      AND T.ReferenceByID
        =  @GeneralID
 ORDER BY CASE T.ReferenceByType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , T.ReferenceBySchema
        , T.ReferenceByObject
        , CASE T.ReferenceOfType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , T.ReferenceOfSchema
        , T.ReferenceOfObject

-- SQLFacts <> 24 Internal References, by object called

PRINT '-- Fact 24 Internal References, by object called'

   SELECT '24' AS Fact
        , T.ReferenceByType
        , T.ReferenceBySchema
        , T.ReferenceByObject
        , T.ReferenceOfType
        , T.ReferenceOfSchema
        , T.ReferenceOfObject
--   INTO SQLFacts.dbo.Fact_24
     FROM #Task AS T
    WHERE T.ReferenceByType IN (      'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
      AND T.ReferenceByObject NOT LIKE 'uspG[SIUD]%'
      AND T.ReferenceByObject NOT LIKE 'trgG[SIUD]%'
      AND T.ReferenceOfID
        =  @GeneralID
 ORDER BY CASE T.ReferenceOfType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , T.ReferenceOfSchema
        , T.ReferenceOfObject
        , CASE T.ReferenceByType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , T.ReferenceBySchema
        , T.ReferenceByObject

-- SQLFacts <> 17 Routine Columns

PRINT '-- Fact 17 Routine Columns'

   SELECT '17' AS Fact
        , T.GeneralType
        , T.GeneralSchema
        , T.GeneralObject
        , T.column_id
        , T.GeneralColumn
        , T.SQLServerType
        , T.collation_name
        , T.is_nullable
--      , T.is_identity
--      , T.[From]
--      , T.[Plus]
--      , T.[Used]
--      , T.index_column_id AS PK_column_id
--      , T.DefaultName
--      , T.DefaultCode
--      , T.FormulaCode
--   INTO SQLFacts.dbo.Fact_17
     FROM #TKeys AS T
    WHERE T.GeneralType IN (      'V ', 'P ', 'FN', 'IF', 'TF')
      AND T.GeneralID
        =  @GeneralID
 ORDER BY CASE T.GeneralType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , T.GeneralSchema
        , T.GeneralObject
        , T.column_id

-- SQLFacts <> 18 Routine Parameters

PRINT '-- Fact 18 Routine Parameters'

   SELECT '18' AS Fact
        , U.GeneralType
        , U.GeneralSchema
        , U.GeneralObject
        , U.parameter_id
        , U.GeneralColumn
        , U.SQLServerType
        , U.is_nullable
        , U.is_output
--   INTO SQLFacts.dbo.Fact_18
     FROM #UKeys AS U
    WHERE U.GeneralType IN (            'P ', 'FN', 'IF', 'TF')
      AND U.GeneralObject NOT LIKE 'uspG[SIUD]%'
      AND U.GeneralObject NOT LIKE 'trgG[SIUD]%'
      AND U.GeneralID
        =  @GeneralID
 ORDER BY CASE U.GeneralType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , U.GeneralSchema
        , U.GeneralObject
        , U.parameter_id

-- SQLFacts <> 47 Questionable Parameters

PRINT '-- Fact 47 Questionable Parameters'

   SELECT '47' AS Fact
        , U.GeneralType
        , U.GeneralSchema
        , U.GeneralObject
        , U.parameter_id
        , U.GeneralColumn
        , U.SQLServerType
        , T.GeneralType   AS GeneralType_
        , T.GeneralSchema AS GeneralSchema_
        , T.GeneralObject AS GeneralObject_
        , T.column_id
        , T.GeneralColumn AS GeneralColumn_
        , T.SQLServerType AS SQLServerType_
--   INTO SQLFacts.dbo.Fact_47
     FROM #UKeys AS U
     JOIN #Task  AS V
       ON U.GeneralID
        = V.ReferenceByID
     JOIN #TKeys AS T
       ON V.ReferenceOfID
        = T.GeneralID
      AND SUBSTRING(U.GeneralColumn, 002, 128)
        =           T.GeneralColumn
    WHERE U.GeneralType IN (            'P ', 'FN', 'IF', 'TF')
      AND U.GeneralObject NOT LIKE 'uspG[SIUD]%'
      AND U.GeneralObject NOT LIKE 'trgG[SIUD]%'
      AND U.SQLServerType
       != T.SQLServerType
      AND U.GeneralID
        =  @GeneralID
 ORDER BY CASE U.GeneralType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , U.GeneralSchema
        , U.GeneralObject
        , U.parameter_id

-- break definition into lines to avoid PRINT limitation of 8000 characters

DECLARE @U int

DECLARE @I TABLE (I int)

DECLARE @O TABLE (O int)

DECLARE @A TABLE (SQLServerCode varchar(8000), Line int)

DECLARE @SQLServerCode varchar(max )

DECLARE @SQLServerTome varchar(max )

DECLARE @E char(0002) = CHAR(13) + CHAR(10)

INSERT @O VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)

INSERT @I SELECT 1 + O.O + (W.O * 10) + (X.O * 100) + (Y.O * 1000) + (Z.O * 10000) FROM @O AS O, @O AS W, @O AS X, @O AS Y, @O AS Z

SET @SQLServerCode = OBJECT_DEFINITION(@GeneralID)

SET @SQLServerTome = @E + @SQLServerCode + @E

SET @U = LEN(@SQLServerCode)

PRINT @E

PRINT 'GO'

PRINT @E

   INSERT @A
   SELECT SUBSTRING(@SQLServerCode, I.I, CHARINDEX(@E, @SQLServerTome, I.I + 2) - I.I - 2)
        , ROW_NUMBER() OVER (ORDER BY I.I)
     FROM @I AS I
    WHERE SUBSTRING(@SQLServerTome, I.I, 2) = @E
      AND I.I !> @U
 ORDER BY I.I

  DECLARE Lines CURSOR FAST_FORWARD FOR
   SELECT A.SQLServerCode
     FROM @A AS A
 ORDER BY A.Line

OPEN Lines

FETCH NEXT FROM Lines INTO @SQLServerCode

WHILE @@FETCH_STATUS = 0

    BEGIN

    PRINT @SQLServerCode

    FETCH NEXT FROM Lines INTO @SQLServerCode

    END

CLOSE Lines DEALLOCATE Lines

PRINT 'GO'

PRINT @E

PRINT 'EXECUTE sp_recompile ' + CHAR(39) + @GeneralSchema + '.' + @GeneralObject + CHAR(39)

PRINT @E

  DECLARE Tables CURSOR FAST_FORWARD FOR
   SELECT T.ReferenceOfSchema
        , T.ReferenceOfObject
     FROM #Task AS T
    WHERE T.ReferenceOfType IN ('U ')
      AND T.ReferenceByID
        =  @GeneralID
 ORDER BY T.ReferenceOfSchema
        , T.ReferenceOfObject

OPEN Tables

FETCH NEXT FROM Tables INTO @GeneralSchema, @GeneralObject

WHILE @@FETCH_STATUS = 0

    BEGIN

    PRINT 'UPDATE STATISTICS ' + @GeneralSchema + '.' + @GeneralObject

    FETCH NEXT FROM Tables INTO @GeneralSchema, @GeneralObject

    END

CLOSE Tables DEALLOCATE Tables

PRINT @E

END

DROP TABLE #Base

DROP TABLE #More

DROP TABLE #Task

DROP TABLE #PKey

DROP TABLE #FKey
DROP TABLE #FKeys

DROP TABLE #ZKey
DROP TABLE #ZKeys

DROP TABLE #TKey
DROP TABLE #TKeys

DROP TABLE #UKey
DROP TABLE #UKeys

DROP TABLE #VKey

DROP TABLE #WKey

SET NOCOUNT OFF

