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

DECLARE @Pages_MINIMUM int = 1000 -- minimum number of index pages necessary for potentially taking action

DECLARE @Percent_MINIMUM decimal(05,02) = 10.0 -- percent of fragmentation for doing REORGANIZATION

DECLARE @Percent_REBUILD decimal(05,02) = 30.0 -- percent of fragmentation for doing REBUILD

DECLARE @GeneralID               int
DECLARE @GeneralObject varchar(0128)
DECLARE @GeneralSchema varchar(0128)
DECLARE @SQLServerName varchar(0128)

DECLARE @partition_number int

DECLARE @percentage decimal(05,02)

DECLARE @SQLCode varchar(2000)

   SELECT T.*
     INTO #Action
     FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') AS T

   SELECT S.name AS GeneralSchema
        , O.name AS GeneralObject
        , I.name AS SQLServerName
        , CASE WHEN Z.MyCOUNT > 1 THEN T.partition_number ELSE NULL END AS [Partition]
        , CONVERT(decimal(05,02), T.avg_fragmentation_in_percent)       AS [Percent]
     INTO #Action_Plus
     FROM #Action AS T
     JOIN sys.indexes AS I
       ON T.object_id
        = I.object_id
      AND T.index_id
        = I.index_id
     JOIN sys.objects AS O
       ON I.object_id
        = O.object_id
     JOIN sys.schemas AS S
       ON O.schema_id
        = S.schema_id
     JOIN
  (SELECT P.object_id
        , P.index_id
        , COUNT(*) AS MyCOUNT
     FROM sys.partitions AS P
 GROUP BY P.object_id
        , P.index_id)    AS Z
       ON T.object_id
        = Z.object_id
      AND T.index_id
        = Z.index_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
      AND I.type IN (1, 2)
      AND T.page_count !< @Pages_MINIMUM
      AND T.avg_fragmentation_in_percent > @Percent_MINIMUM
 ORDER BY S.name
        , O.name
        , I.name
        , T.partition_number

   SELECT T.GeneralSchema
        , T.GeneralObject
        , T.SQLServerName
        , T.[Partition]
        , T.[Percent]
     FROM #Action_Plus AS T
 ORDER BY T.GeneralSchema
        , T.GeneralObject
        , T.SQLServerName
        , T.[Partition]

  DECLARE DBItems CURSOR FAST_FORWARD FOR
   SELECT T.GeneralSchema
        , T.GeneralObject
        , T.SQLServerName
        , T.[Partition]
        , T.[Percent]
     FROM #Action_Plus AS T
 ORDER BY T.GeneralSchema
        , T.GeneralObject
        , T.SQLServerName
        , T.[Partition]

OPEN DBItems

FETCH NEXT FROM DBItems INTO @GeneralSchema, @GeneralObject, @SQLServerName, @partition_number, @percentage

WHILE @@FETCH_STATUS = 0

    BEGIN

    SET @SQLCode = 'ALTER INDEX [' + @SQLServerName + '] ON [' + @GeneralSchema + '].[' + @GeneralObject + CASE WHEN @percentage > @Percent_REBUILD THEN '] REBUILD' ELSE '] REORGANIZE' END + CASE WHEN @partition_number IS NOT NULL THEN ' PARTITION = ' + CONVERT(varchar(0010), @partition_number) ELSE SPACE(0) END

    PRINT @SQLCode

--  EXECUTE (@SQLCode)

    FETCH NEXT FROM DBItems INTO @GeneralSchema, @GeneralObject, @SQLServerName, @partition_number, @percentage

    END

CLOSE DBItems DEALLOCATE DBItems

DROP TABLE #Action

DROP TABLE #Action_Plus

SET NOCOUNT OFF

