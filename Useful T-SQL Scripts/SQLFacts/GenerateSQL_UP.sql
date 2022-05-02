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

DECLARE @GeneralID               int
DECLARE @GeneralType      char(0002)
DECLARE @GeneralObject varchar(0128)
DECLARE @GeneralSchema varchar(0128)
DECLARE @GeneralColumn varchar(0128)

DECLARE @SQLServerCode varchar(0020)
DECLARE @SQLServerName varchar(0010)

DECLARE @A smallint = 0
DECLARE @I smallint
DECLARE @O smallint
DECLARE @W smallint
DECLARE @Z smallint
DECLARE @T smallint

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
     INTO #Base
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
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

-- generate SQL

  DECLARE Objects CURSOR FAST_FORWARD FOR
   SELECT E.GeneralID
        , E.GeneralSchema
        , E.GeneralObject
        , E.SQLServerName
        , E.I
        , (SELECT MIN(T.column_id) FROM #TKey AS T WHERE T.GeneralID = E.GeneralID AND T.is_computed = 0 AND T.is_identity = 0) AS Z
     FROM #Base AS E
 ORDER BY E.GeneralSchema
        , E.GeneralObject

OPEN Objects

FETCH NEXT FROM Objects INTO @GeneralID, @GeneralSchema, @GeneralObject, @SQLServerName, @W, @Z

WHILE @@FETCH_STATUS = 0

    BEGIN

    PRINT '   UPDATE ' + @GeneralSchema + '.' + @X + @GeneralObject + @Y + ' SET'

    SET @SQLServerCode = '          '

      DECLARE Columns CURSOR FAST_FORWARD FOR
       SELECT T.column_id
            , T.GeneralColumn
         FROM #Base AS E
         JOIN #TKey AS T
           ON E.GeneralID
            = T.GeneralID
        WHERE E.GeneralID
            =  @GeneralID
          AND T.is_computed = 0
          AND T.is_identity = 0
     ORDER BY T.column_id

    OPEN Columns

    FETCH NEXT FROM Columns INTO @T, @GeneralColumn

    WHILE @@FETCH_STATUS = 0

        BEGIN

        IF @T = @Z PRINT '          ' + SPACE(LEN(@SQLServerName) + 1) + @X + @GeneralColumn + @Y

        IF @T > @Z PRINT '        , ' + SPACE(LEN(@SQLServerName) + 1) + @X + @GeneralColumn + @Y

                   PRINT '        = ' +           @SQLServerName + '.' + @X + @GeneralColumn + @Y

        FETCH NEXT FROM Columns INTO @T, @GeneralColumn

        END

    CLOSE Columns DEALLOCATE Columns

    PRINT '     FROM ' + @GeneralSchema + '.' + @X + @GeneralObject + @Y + ' AS ' + @SQLServerName

    PRINT '    WHERE 0 = 1'

    PRINT CHAR(13) + CHAR(10)

    FETCH NEXT FROM Objects INTO @GeneralID, @GeneralSchema, @GeneralObject, @SQLServerName, @W, @Z

    END

CLOSE Objects DEALLOCATE Objects

DROP TABLE #Base

DROP TABLE #TKey

SET NOCOUNT OFF

