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

DECLARE @PKey varchar(0010) = 'PK_'
DECLARE @FKey varchar(0010) = 'FK_'
DECLARE @ZKey varchar(0010) = 'IX_'

   SELECT S.name AS GeneralSchema
        , O.name AS GeneralObject
        , C.name AS GeneralColumn
     INTO #Base
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.columns AS C
       ON O.object_id
        = C.object_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
      AND C.name
        = O.name + 'ID'
 ORDER BY S.name
        , O.name

   SELECT S.name AS ForeignSchema
        , O.name AS ForeignObject
        , E.GeneralSchema
        , E.GeneralObject
        , E.GeneralColumn
     INTO #More
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.columns AS C
       ON O.object_id
        = C.object_id
     JOIN #Base AS E
       ON CASE WHEN S.name = E.GeneralSchema
                AND O.name = E.GeneralObject THEN 0
               WHEN C.name = E.GeneralColumn THEN 1 ELSE 0 END != 0
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY S.name
        , O.name
        , E.GeneralSchema
        , E.GeneralObject

  DECLARE @SQLServerCode varchar(2000)

  DECLARE @ForeignSchema varchar(0128)
  DECLARE @ForeignObject varchar(0128)
  DECLARE @GeneralSchema varchar(0128)
  DECLARE @GeneralObject varchar(0128)
  DECLARE @GeneralColumn varchar(0128)

  DECLARE @Z char(0002) = CHAR(13) + CHAR(10)

PRINT '-- primary keys'
PRINT @Z

  DECLARE DBItems CURSOR FAST_FORWARD FOR
   SELECT E.GeneralSchema
        , E.GeneralObject
        , E.GeneralColumn
     FROM #Base AS E
    WHERE NOT EXISTS
  (SELECT *
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.indexes AS I
       ON O.object_id
        = I.object_id
      AND I.is_primary_key != 0
     JOIN sys.index_columns AS M
       ON I.object_id
        = M.object_id
      AND I.index_id
        = M.index_id
      AND M.index_column_id = 1
     JOIN sys.columns AS C
       ON M.object_id
        = C.object_id
      AND M.column_id
        = C.column_id
    WHERE S.name = E.GeneralSchema
      AND O.name = E.GeneralObject
      AND C.name = E.GeneralColumn)
 ORDER BY E.GeneralSchema
        , E.GeneralObject

OPEN DBItems

FETCH NEXT FROM DBItems INTO @GeneralSchema, @GeneralObject, @GeneralColumn

WHILE @@FETCH_STATUS = 0

    BEGIN

    SET @SQLServerCode = 'ALTER TABLE ' + @GeneralSchema + '.' + @GeneralObject + ' ADD CONSTRAINT ' + @PKey + @GeneralObject + ' PRIMARY KEY CLUSTERED (' + @GeneralColumn + ')'

    PRINT @SQLServerCode

    FETCH NEXT FROM DBItems INTO @GeneralSchema, @GeneralObject, @GeneralColumn

    END

CLOSE DBItems DEALLOCATE DBItems

PRINT @Z

PRINT '-- foreign keys'
PRINT @Z

  DECLARE DBItems CURSOR FAST_FORWARD FOR
   SELECT E.ForeignSchema
        , E.ForeignObject
        , E.GeneralSchema
        , E.GeneralObject
        , E.GeneralColumn
     FROM #More AS E
    WHERE NOT EXISTS
  (SELECT *
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
      AND M.constraint_column_id = 1
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
    WHERE S.name = E.ForeignSchema
      AND O.name = E.ForeignObject
      AND Z.name = E.GeneralSchema
      AND W.name = E.GeneralObject
      AND K.name = E.GeneralColumn)
 ORDER BY E.ForeignSchema
        , E.ForeignObject
        , E.GeneralSchema
        , E.GeneralObject

OPEN DBItems

FETCH NEXT FROM DBItems INTO @ForeignSchema, @ForeignObject, @GeneralSchema, @GeneralObject, @GeneralColumn

WHILE @@FETCH_STATUS = 0

    BEGIN

    SET @SQLServerCode = 'ALTER TABLE ' + @ForeignSchema + '.' + @ForeignObject + ' ADD CONSTRAINT ' + @FKey + @ForeignObject + @GeneralObject + ' FOREIGN KEY (' + @GeneralColumn + ') REFERENCES ' + @GeneralSchema + '.' + @GeneralObject + ' (' + @GeneralColumn + ')'

    PRINT @SQLServerCode

    FETCH NEXT FROM DBItems INTO @ForeignSchema, @ForeignObject, @GeneralSchema, @GeneralObject, @GeneralColumn

    END

CLOSE DBItems DEALLOCATE DBItems

PRINT @Z

PRINT '-- foreign key indexes'
PRINT @Z

  DECLARE DBItems CURSOR FAST_FORWARD FOR
   SELECT E.ForeignSchema
        , E.ForeignObject
        , E.GeneralColumn
     FROM #More AS E
    WHERE NOT EXISTS
  (SELECT *
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
    WHERE S.name = E.ForeignSchema
      AND O.name = E.ForeignObject
      AND C.name = E.GeneralColumn)
 ORDER BY E.ForeignSchema
        , E.ForeignObject
        , E.GeneralColumn

OPEN DBItems

FETCH NEXT FROM DBItems INTO @ForeignSchema, @ForeignObject, @GeneralColumn

WHILE @@FETCH_STATUS = 0

    BEGIN

    SET @SQLServerCode = 'CREATE NONCLUSTERED INDEX ' + @ZKey + @GeneralColumn + ' ON ' + @ForeignSchema + '.' + @ForeignObject + ' (' + @GeneralColumn + ')'

    PRINT @SQLServerCode

    FETCH NEXT FROM DBItems INTO @ForeignSchema, @ForeignObject, @GeneralColumn

    END

CLOSE DBItems DEALLOCATE DBItems

PRINT @Z

DROP TABLE #Base

DROP TABLE #More

SET NOCOUNT OFF

