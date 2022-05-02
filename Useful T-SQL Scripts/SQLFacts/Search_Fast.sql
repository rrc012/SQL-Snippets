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

DECLARE @Search varchar(0200) = '' -- enter search string here

DECLARE @SearchInComments bit = 1 -- set variable to 0 (zero) to exclude comments from the search

DECLARE @RowsAffected smallint

DECLARE @GeneralID               int
DECLARE @GeneralType      char(0002)
DECLARE @GeneralSchema varchar(0128)
DECLARE @GeneralObject varchar(0128)

DECLARE @SQLServerCode varchar(max )

DECLARE @SQLServerTome varchar(max )

DECLARE @CR char(0002) = CHAR(13) + CHAR(10)
DECLARE @CK char(0002) = CHAR(45) + CHAR(45)
DECLARE @CA char(0002) = CHAR(47) + CHAR(42)
DECLARE @CZ char(0002) = CHAR(42) + CHAR(47)

DECLARE @E int = 0
DECLARE @I int = 0
DECLARE @O int = 0
DECLARE @U int = 0

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        , O.create_date
        , O.modify_date
        , O.parent_object_id AS VariousID
        , CONVERT(varchar(max ), ISNULL(M.definition, SPACE(0))) AS SQLServerCode
--      , CONVERT(varchar(max ), ISNULL(M.definition, SPACE(0))) AS SQLServerTome
        , CONVERT(int, 1) AS Search1
        , CONVERT(int, 1) AS Search2
        , CONVERT(int, 0) AS Glitch1
        , CONVERT(int, 0) AS Glitch2
--      , CONVERT(int, 0) AS Change1
--      , CONVERT(int, 0) AS Change2
     INTO #Base
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
LEFT JOIN sys.sql_modules AS M
       ON O.object_id
        = M.object_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN (      'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
      AND O.name NOT LIKE 'uspG[SIUD]%'
      AND O.name NOT LIKE 'trgG[SIUD]%'
 ORDER BY O.type
        , S.name
        , O.name

   SELECT @GeneralID = CASE WHEN MIN(E.GeneralID) > 0 THEN 0 ELSE MIN(E.GeneralID) END
     FROM #Base AS E

   INSERT #Base
   SELECT @GeneralID - ROW_NUMBER() OVER (ORDER BY J.name, S.step_name)
        , 'JB'
        , S.step_name
        , J.name
        , J.date_created
        , J.date_modified
        , 0
        , CONVERT(varchar(max ), ISNULL(S.command, SPACE(0))) AS SQLServerCode
--      , CONVERT(varchar(max ), ISNULL(S.command, SPACE(0))) AS SQLServerTome
        , CONVERT(int, 1) AS Search1
        , CONVERT(int, 1) AS Search2
        , CONVERT(int, 0) AS Glitch1
        , CONVERT(int, 0) AS Glitch2
--      , CONVERT(int, 0) AS Change1
--      , CONVERT(int, 0) AS Change2
     FROM msdb.dbo.sysjobs     AS J
     JOIN msdb.dbo.sysjobsteps AS S
       ON J.job_id
        = S.job_id
    WHERE S.subsystem = 'TSQL'
      AND S.database_name = DB_NAME()
 ORDER BY J.name
        , S.step_name

   SELECT @GeneralType   AS GeneralType
        , @GeneralSchema AS GeneralSchema
        , @GeneralObject AS GeneralObject
        , @E             AS Line
        , @SQLServerCode AS SQLServerCode
     INTO #Work
    WHERE 0 = 1

   SELECT E.GeneralID
        , E.Search1 AS Search
        , E.Glitch1 AS Glitch
     INTO #Fine
     FROM #Base AS E
    WHERE 0 = 1

SET   @RowsAffected = CASE WHEN @SearchInComments = 0 THEN 1 ELSE 0 END

WHILE @RowsAffected > 0

    BEGIN

       UPDATE #Base SET Search1 = CHARINDEX(@CK, E.SQLServerCode, E.Search1)
         FROM #Base AS E
        WHERE E.Search1 > 0

       UPDATE #Base SET Glitch1 = CHARINDEX(@CR, E.SQLServerCode, E.Search1)
         FROM #Base AS E
        WHERE E.Search1 > 0

       INSERT #Fine
       SELECT E.GeneralID
            , E.Search1
            , CASE WHEN E.Glitch1 = 0 THEN LEN(E.SQLServerCode) ELSE E.Glitch1 + 1 END
         FROM #Base AS E
        WHERE E.Search1 > 0

       UPDATE #Base SET Search1 = CASE WHEN E.Glitch1 = 0 THEN LEN(E.SQLServerCode) ELSE E.Glitch1 + 2 END
         FROM #Base AS E
        WHERE E.Search1 > 0

    SET @RowsAffected = @@ROWCOUNT

    END

SET   @RowsAffected = CASE WHEN @SearchInComments = 0 THEN 1 ELSE 0 END

WHILE @RowsAffected > 0

    BEGIN

       UPDATE #Base SET Search2 = CHARINDEX(@CA, E.SQLServerCode, E.Search2)
         FROM #Base AS E
        WHERE E.Search2 > 0

       UPDATE #Base SET Glitch2 = CHARINDEX(@CZ, E.SQLServerCode, E.Search2)
         FROM #Base AS E
        WHERE E.Search2 > 0

       INSERT #Fine
       SELECT E.GeneralID
            , E.Search2
            , CASE WHEN E.Glitch2 = 0 THEN LEN(E.SQLServerCode) ELSE E.Glitch2 + 1 END
         FROM #Base AS E
        WHERE E.Search2 > 0

       UPDATE #Base SET Search2 = CASE WHEN E.Glitch2 = 0 THEN LEN(E.SQLServerCode) ELSE E.Glitch2 + 2 END
         FROM #Base AS E
        WHERE E.Search2 > 0

    SET @RowsAffected = @@ROWCOUNT

    END

  DECLARE DBItems CURSOR FAST_FORWARD FOR
   SELECT E.GeneralID
        , E.GeneralType
        , E.GeneralSchema
        , E.GeneralObject
        , E.SQLServerCode AS SQLServerCode
     FROM #Base AS E
    WHERE E.SQLServerCode LIKE '%' + @Search + '%'
 ORDER BY CASE E.GeneralType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , E.GeneralSchema
        , E.GeneralObject

OPEN DBItems

FETCH NEXT FROM DBItems INTO @GeneralID, @GeneralType, @GeneralSchema, @GeneralObject, @SQLServerCode

WHILE @@FETCH_STATUS = 0

    BEGIN

    SET @E = 0
    SET @I = 0
    SET @O = 1 - LEN(@CR)
    SET @U = CHARINDEX(@Search, @SQLServerCode, 1)

    WHILE @U > 0

        BEGIN

        WHILE @O < @U

            BEGIN

            SET @E = @E + 1

            SET @I = @O + LEN(@CR)

            SET @O = CHARINDEX(@CR, @SQLServerCode, @I)

            IF @O = 0 SET @O = @U

            END

           INSERT #Work
           SELECT @GeneralType
                , @GeneralSchema
                , @GeneralObject
                , @E
                , SUBSTRING(@SQLServerCode, @I, @O - @I)
            WHERE NOT EXISTS
          (SELECT *
             FROM #Fine AS T
            WHERE T.GeneralID
                =  @GeneralID
              AND T.Search  < @U
              AND T.Glitch !< @U)

        SET @U = CHARINDEX(@Search, @SQLServerCode, @O + LEN(@CR))

        END

    FETCH NEXT FROM DBItems INTO @GeneralID, @GeneralType, @GeneralSchema, @GeneralObject, @SQLServerCode

    END

CLOSE DBItems DEALLOCATE DBItems

   SELECT W.GeneralType
        , W.GeneralSchema
        , W.GeneralObject
        , COUNT(*) AS Lines
     FROM #Work AS W
 GROUP BY W.GeneralType
        , W.GeneralSchema
        , W.GeneralObject
 ORDER BY Lines DESC
        , CASE W.GeneralType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , W.GeneralSchema
        , W.GeneralObject

   SELECT W.GeneralType
        , W.GeneralSchema
        , W.GeneralObject
        , W.Line
        , W.SQLServerCode
     FROM #Work AS W
 ORDER BY CASE W.GeneralType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , W.GeneralSchema
        , W.GeneralObject
        , W.Line

DROP TABLE #Base

DROP TABLE #Fine

DROP TABLE #Work

SET NOCOUNT OFF

