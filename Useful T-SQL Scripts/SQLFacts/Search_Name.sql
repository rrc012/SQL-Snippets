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

DECLARE @Search varchar(0200) = '%%' -- enter search string here, use LIKE wildcards as necessary

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        , O.create_date
        , O.modify_date
     INTO #Base
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ', 'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
      AND O.name NOT LIKE 'uspG[SIUD]%'
      AND O.name NOT LIKE 'trgG[SIUD]%'
 ORDER BY O.type
        , S.name
        , O.name

   SELECT T.GeneralType
        , T.GeneralSchema
        , T.GeneralObject
        , T.GeneralColumn
--      , T.create_date
--      , T.modify_date
     FROM
  (SELECT E.GeneralType
        , E.GeneralSchema
        , E.GeneralObject
        , SPACE(0) AS GeneralColumn
        , CONVERT(varchar(0040), E.create_date, 120) AS create_date
        , CONVERT(varchar(0040), E.modify_date, 120) AS modify_date
     FROM #Base AS E
    WHERE E.GeneralObject LIKE @Search
    UNION
   SELECT E.GeneralType
        , E.GeneralSchema
        , E.GeneralObject
        , C.name AS GeneralColumn
        , CONVERT(varchar(0040), E.create_date, 120) AS create_date
        , CONVERT(varchar(0040), E.modify_date, 120) AS modify_date
     FROM #Base AS E
     JOIN sys.columns AS C
       ON E.GeneralID
        = C.object_id
    WHERE C.name LIKE @Search
    UNION
   SELECT E.GeneralType
        , E.GeneralSchema
        , E.GeneralObject
        , C.name AS GeneralColumn
        , CONVERT(varchar(0040), E.create_date, 120) AS create_date
        , CONVERT(varchar(0040), E.modify_date, 120) AS modify_date
     FROM #Base AS E
     JOIN sys.parameters AS C
       ON E.GeneralID
        = C.object_id
    WHERE SUBSTRING(C.name, 2, 128) LIKE @Search) AS T
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
        , T.GeneralColumn

DROP TABLE #Base

SET NOCOUNT OFF

