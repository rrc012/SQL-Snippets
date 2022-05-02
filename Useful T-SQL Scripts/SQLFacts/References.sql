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

DECLARE @Layer smallint

DECLARE @Batch smallint

DECLARE @ReferenceByID               int
DECLARE @ReferenceOfID               int
DECLARE @ReferenceByType      char(0002)
DECLARE @ReferenceOfType      char(0002)
DECLARE @ReferentialType      char(0002)
DECLARE @ReferenceByObject varchar(0128)
DECLARE @ReferenceOfObject varchar(0128)
DECLARE @ReferenceBySchema varchar(0128)
DECLARE @ReferenceOfSchema varchar(0128)

   SELECT @ReferenceByID     = O.object_id
        , @ReferenceOfID     = O.object_id
        , @ReferenceByType   = O.type
        , @ReferenceOfType   = O.type
		, @ReferentialType   = O.type
        , @ReferenceByObject = O.name
        , @ReferenceOfObject = O.name
        , @ReferenceBySchema = S.name
        , @ReferenceOfSchema = S.name
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
    WHERE S.name = @GeneralSchema
      AND O.name = @GeneralObject

   SELECT @ReferenceByID     AS ReferenceByID
        , @ReferenceByType   AS ReferenceByType
        , @ReferenceByObject AS ReferenceByObject
        , @ReferenceBySchema AS ReferenceBySchema
        , @ReferenceOfID     AS ReferenceOfID
        , @ReferenceOfType   AS ReferenceOfType
        , @ReferenceOfObject AS ReferenceOfObject
        , @ReferenceOfSchema AS ReferenceOfSchema
     INTO #ReferenceList
    WHERE 0 = 1

IF @ReferentialType != 'U '

    BEGIN

       INSERT #ReferenceList
       SELECT O.object_id AS ReferenceByID
            , O.type      AS ReferenceByType
            , O.name      AS ReferenceByObject
            , S.name      AS ReferenceBySchema
            , W.object_id AS ReferenceOfID
            , W.type      AS ReferenceOfType
            , W.name      AS ReferenceOfObject
            , Z.name      AS ReferenceOfSchema
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
          AND Z.name IN (SELECT [Schema] FROM @Match)
        WHERE S.name IN (SELECT [Schema] FROM @Match)
          AND W.type NOT IN ('U ')
     ORDER BY   ReferenceByID
            ,   ReferenceOfID

    END
    ELSE
    BEGIN

       INSERT #ReferenceList
       SELECT O.object_id AS ReferenceByID
            , O.type      AS ReferenceByType
            , O.name      AS ReferenceByObject
            , S.name      AS ReferenceBySchema
            , W.object_id AS ReferenceOfID
            , W.type      AS ReferenceOfType
            , W.name      AS ReferenceOfObject
            , Z.name      AS ReferenceOfSchema
         FROM sys.schemas AS S
         JOIN sys.objects AS O
           ON S.schema_id
            = O.schema_id
         JOIN sys.foreign_keys AS F
           ON        O.object_id
            = F.parent_object_id
         JOIN sys.objects AS W
           ON F.referenced_object_id
            =            W.object_id
--        AND            O.object_id
--         !=            W.object_id
         JOIN sys.schemas AS Z
           ON W.schema_id
            = Z.schema_id
          AND Z.name IN (SELECT [Schema] FROM @Match)
        WHERE S.name IN (SELECT [Schema] FROM @Match)
          AND O.type IN ('U ')
     ORDER BY   ReferenceByID
            ,   ReferenceOfID

    END

SET @Layer = 0

SET @Batch = 0

   SELECT @Layer AS Layer
        , T.ReferenceByID
        , T.ReferenceByType
        , T.ReferenceByObject
        , T.ReferenceBySchema
        , T.ReferenceOfID
        , T.ReferenceOfType
        , T.ReferenceOfObject
        , T.ReferenceOfSchema
     INTO #ReferenceByID
     FROM #ReferenceList AS T
    WHERE T.ReferenceByID
        =  @ReferenceByID
 ORDER BY T.ReferenceByID
        , T.ReferenceOfID

   SELECT @Batch = COUNT(*)
     FROM #ReferenceByID AS W
    WHERE W.ReferenceByID
       != W.ReferenceOfID
      AND W.Layer = @Layer

WHILE @Batch > 0 AND @Layer < 50

    BEGIN

    SET @Layer = @Layer + 1

      DECLARE DBItems CURSOR FAST_FORWARD FOR
       SELECT W.ReferenceOfID
            , W.ReferenceOfType
            , W.ReferenceOfObject
            , W.ReferenceOfSchema
         FROM #ReferenceByID AS W
        WHERE W.ReferenceByID
           != W.ReferenceOfID
          AND W.Layer = @Layer - 1
     ORDER BY W.ReferenceOfID

    OPEN DBItems

    FETCH NEXT FROM DBItems INTO @ReferenceByID, @ReferenceByType, @ReferenceByObject, @ReferenceBySchema

    WHILE @@FETCH_STATUS = 0

        BEGIN

           INSERT #ReferenceByID
           SELECT @Layer AS Layer
                , T.ReferenceByID
                , T.ReferenceByType
                , T.ReferenceByObject
                , T.ReferenceBySchema
                , T.ReferenceOfID
                , T.ReferenceOfType
                , T.ReferenceOfObject
                , T.ReferenceOfSchema
             FROM #ReferenceList AS T
        LEFT JOIN #ReferenceByID AS W
               ON T.ReferenceByID
                = W.ReferenceByID
              AND T.ReferenceOfID
                = W.ReferenceOfID
            WHERE T.ReferenceByID
                =  @ReferenceByID
              AND W.Layer IS NULL
         ORDER BY T.ReferenceByID
                , T.ReferenceOfID

        FETCH NEXT FROM DBItems INTO @ReferenceByID, @ReferenceByType, @ReferenceByObject, @ReferenceBySchema

        END

    CLOSE DBItems DEALLOCATE DBItems

       SELECT @Batch = COUNT(*)
         FROM #ReferenceByID AS W
        WHERE W.ReferenceByID
           != W.ReferenceOfID
          AND W.Layer = @Layer

    END

SET @Layer = 0

SET @Batch = 0

   SELECT @Layer AS Layer
        , T.ReferenceByID
        , T.ReferenceByType
        , T.ReferenceByObject
        , T.ReferenceBySchema
        , T.ReferenceOfID
        , T.ReferenceOfType
        , T.ReferenceOfObject
        , T.ReferenceOfSchema
     INTO #ReferenceOfID
     FROM #ReferenceList AS T
    WHERE T.ReferenceOfID
        =  @ReferenceOfID
 ORDER BY T.ReferenceByID
        , T.ReferenceOfID

   SELECT @Batch = COUNT(*)
     FROM #ReferenceOfID AS W
    WHERE W.ReferenceByID
       != W.ReferenceOfID
      AND W.Layer = @Layer

WHILE @Batch > 0 AND @Layer < 50

    BEGIN

    SET @Layer = @Layer + 1

      DECLARE DBItems CURSOR FAST_FORWARD FOR
       SELECT W.ReferenceByID
            , W.ReferenceByType
            , W.ReferenceByObject
            , W.ReferenceBySchema
         FROM #ReferenceOfID AS W
        WHERE W.ReferenceByID
           != W.ReferenceOfID
          AND W.Layer = @Layer - 1
     ORDER BY W.ReferenceByID

    OPEN DBItems

    FETCH NEXT FROM DBItems INTO @ReferenceOfID, @ReferenceOfType, @ReferenceOfObject, @ReferenceOfSchema

    WHILE @@FETCH_STATUS = 0

        BEGIN

           INSERT #ReferenceOfID
           SELECT @Layer AS Layer
                , T.ReferenceByID
                , T.ReferenceByType
                , T.ReferenceByObject
                , T.ReferenceBySchema
                , T.ReferenceOfID
                , T.ReferenceOfType
                , T.ReferenceOfObject
                , T.ReferenceOfSchema
             FROM #ReferenceList AS T
        LEFT JOIN #ReferenceOfID AS W
               ON T.ReferenceByID
                = W.ReferenceByID
              AND T.ReferenceOfID
                = W.ReferenceOfID
            WHERE T.ReferenceOfID
                =  @ReferenceOfID
              AND W.Layer IS NULL
         ORDER BY T.ReferenceByID
                , T.ReferenceOfID

        FETCH NEXT FROM DBItems INTO @ReferenceOfID, @ReferenceOfType, @ReferenceOfObject, @ReferenceOfSchema

        END

    CLOSE DBItems DEALLOCATE DBItems

       SELECT @Batch = COUNT(*)
         FROM #ReferenceOfID AS W
        WHERE W.ReferenceByID
           != W.ReferenceOfID
          AND W.Layer = @Layer

    END

   SELECT Z.Layer
        , Z.ReferenceByType
        , Z.ReferenceBySchema
        , Z.ReferenceByObject
        , Z.ReferenceOfType
        , Z.ReferenceOfSchema
        , Z.ReferenceOfObject
        , CASE WHEN EXISTS (SELECT * FROM #ReferenceByID AS T WHERE T.ReferenceByID = Z.ReferenceOfID AND T.Layer < Z.Layer) THEN 'LOOP' WHEN Z.ReferenceByID = Z.ReferenceOfID THEN 'LOOP' ELSE SPACE(0) END AS [LOOP]
     FROM
  (SELECT MAX(W.Layer) AS Layer
        , W.ReferenceByID
        , W.ReferenceByType
        , W.ReferenceByObject
        , W.ReferenceBySchema
        , W.ReferenceOfID
        , W.ReferenceOfType
        , W.ReferenceOfObject
        , W.ReferenceOfSchema
     FROM #ReferenceByID AS W
 GROUP BY W.ReferenceByID
        , W.ReferenceByType
        , W.ReferenceByObject
        , W.ReferenceBySchema
        , W.ReferenceOfID
        , W.ReferenceOfType
        , W.ReferenceOfObject
        , W.ReferenceOfSchema) AS Z
 ORDER BY Z.Layer
        , CASE Z.ReferenceByType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , Z.ReferenceBySchema
        , Z.ReferenceByObject
        , CASE Z.ReferenceOfType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , Z.ReferenceOfSchema
        , Z.ReferenceOfObject

   SELECT Z.Layer
        , Z.ReferenceByType
        , Z.ReferenceBySchema
        , Z.ReferenceByObject
        , Z.ReferenceOfType
        , Z.ReferenceOfSchema
        , Z.ReferenceOfObject
        , CASE WHEN EXISTS (SELECT * FROM #ReferenceOfID AS T WHERE T.ReferenceOfID = Z.ReferenceByID AND T.Layer < Z.Layer) THEN 'LOOP' WHEN Z.ReferenceOfID = Z.ReferenceByID THEN 'LOOP' ELSE SPACE(0) END AS [LOOP]
     FROM
  (SELECT MAX(W.Layer) AS Layer
        , W.ReferenceByID
        , W.ReferenceByType
        , W.ReferenceByObject
        , W.ReferenceBySchema
        , W.ReferenceOfID
        , W.ReferenceOfType
        , W.ReferenceOfObject
        , W.ReferenceOfSchema
     FROM #ReferenceOfID AS W
 GROUP BY W.ReferenceByID
        , W.ReferenceByType
        , W.ReferenceByObject
        , W.ReferenceBySchema
        , W.ReferenceOfID
        , W.ReferenceOfType
        , W.ReferenceOfObject
        , W.ReferenceOfSchema) AS Z
 ORDER BY Z.Layer
        , CASE Z.ReferenceOfType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , Z.ReferenceOfSchema
        , Z.ReferenceOfObject
        , CASE Z.ReferenceByType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , Z.ReferenceBySchema
        , Z.ReferenceByObject

DROP TABLE #ReferenceList

DROP TABLE #ReferenceByID

DROP TABLE #ReferenceOfID

SET NOCOUNT OFF

