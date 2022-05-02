/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

DECLARE @BaseVersion varchar(1000) = CONVERT(varchar(1000), SERVERPROPERTY('ProductVersion'))

DECLARE @Information varchar(4000) = 'SQL Server '
+ CASE WHEN @BaseVersion LIKE  '8.%'  THEN '2000 '
       WHEN @BaseVersion LIKE  '9.%'  THEN '2005 '
       WHEN @BaseVersion LIKE '10.0%' THEN '2008 '
       WHEN @BaseVersion LIKE '10.5%' THEN '2008 R2 '
       WHEN @BaseVersion LIKE '11.%'  THEN '2012 '
       WHEN @BaseVersion LIKE '12.%'  THEN '2014 '
       WHEN @BaseVersion LIKE '13.%'  THEN '2016 '
       WHEN @BaseVersion LIKE '14.%'  THEN '2017 '
       WHEN @BaseVersion LIKE '15.%'  THEN '2019 '
       WHEN @BaseVersion LIKE '16.%'  THEN '2022 ' ELSE '20XX ' END
+ CONVERT(varchar(1000), SERVERPROPERTY('Edition')) + ' has been running since '
+ CONVERT(varchar(1000), (SELECT I.sqlserver_start_time FROM sys.dm_os_sys_info AS I), 120)

PRINT @Information

CREATE TABLE #Action
     ( DBName       varchar(0128)
     , SchemaName   varchar(0128)
     , ObjectName   varchar(0128)
     , name         varchar(0128)
     , type               tinyint
     , cache_pages         bigint
     , cache_rows          bigint
     , index_pages         bigint
     , index_rows          bigint )

DECLARE @database_id int

DECLARE @DBName varchar(0128)

DECLARE @DBCode varchar(4000)

   SELECT B.database_id
        , B.allocation_unit_id
        , COUNT(*) AS data_pages
        , SUM(CONVERT(bigint, B.row_count)) AS rows
     INTO #Action_Buffer
     FROM sys.dm_os_buffer_descriptors AS B
     JOIN sys.databases AS D
       ON B.database_id
        = D.database_id
    WHERE B.database_id BETWEEN 5 AND 32766
      AND D.name NOT LIKE 'ReportServer%'
      AND B.page_type = 'DATA_PAGE'
 GROUP BY B.database_id
        , B.allocation_unit_id

CREATE UNIQUE CLUSTERED INDEX IX_Action ON #Action_Buffer (database_id, allocation_unit_id)

  DECLARE DBNames CURSOR FAST_FORWARD FOR
   SELECT D.name
        , D.database_id
     FROM sys.databases AS D
     JOIN
  (SELECT T.database_id
     FROM #Action_Buffer AS T
 GROUP BY T.database_id) AS K
       ON D.database_id
        = K.database_id
 GROUP BY D.name
        , D.database_id
 ORDER BY D.name

OPEN DBNames

FETCH NEXT FROM DBNames INTO @DBName, @database_id

WHILE @@FETCH_STATUS = 0

    BEGIN

    SET @DBCode = 'USE [' + @DBName + ']; 
       SELECT ' + CHAR(39) + @DBName + CHAR(39) + '
            , S.name
            , O.name
            , I.name
            , I.type
            , W.pages
            , W.rows
            , X.pages
            , Y.rows
         FROM sys.schemas AS S
         JOIN sys.objects AS O
           ON S.schema_id
            = O.schema_id
         JOIN sys.indexes AS I
           ON O.object_id
            = I.object_id
         JOIN
      (SELECT P.object_id
            , P.index_id
            , SUM(T.data_pages) AS pages
            , SUM(T.rows)       AS rows
         FROM sys.partitions AS P
         JOIN sys.allocation_units AS A
           ON P.partition_id
            = A.container_id
          AND A.type != 0
         JOIN #Action_Buffer AS T
           ON A.allocation_unit_id
            = T.allocation_unit_id
          AND T.database_id = ' + CONVERT(varchar(0010), @database_id) + '
     GROUP BY P.object_id
            , P.index_id) AS W
           ON I.object_id
            = W.object_id
          AND I.index_id
            = W.index_id
         JOIN
      (SELECT P.object_id
            , P.index_id
            , SUM(A.data_pages) AS pages
         FROM sys.partitions AS P
         JOIN sys.allocation_units AS A
           ON P.partition_id
            = A.container_id
          AND A.type != 0
     GROUP BY P.object_id
            , P.index_id) AS X
           ON I.object_id
            = X.object_id
          AND I.index_id
            = X.index_id
         JOIN
      (SELECT P.object_id
            , P.index_id
            , SUM(P.rows)       AS rows
         FROM sys.partitions AS P
     GROUP BY P.object_id
            , P.index_id) AS Y
           ON I.object_id
            = Y.object_id
          AND I.index_id
            = Y.index_id
        WHERE S.name != ''sys''
          AND O.name != ''sysdiagrams''
     ORDER BY S.name
            , O.name
            , I.type
            , I.name'

    INSERT #Action EXECUTE (@DBCode)

    FETCH NEXT FROM DBNames INTO @DBName, @database_id

    END

CLOSE DBNames DEALLOCATE DBNames

   SELECT T.DBName
        , T.SchemaName
        , T.ObjectName
        , T.type AS index_type
        , T.name AS index_name
        , CONVERT(decimal(19,05), T.cache_pages / 128.0 / 1024.0) AS cache_GBs
        ,                         T.cache_rows                    AS cache_rows
        , CONVERT(decimal(19,05), T.index_pages / 128.0 / 1024.0) AS index_GBs
        ,                         T.index_rows                    AS index_rows
        , CONVERT(decimal(05,02), CASE WHEN T.index_pages > 0 THEN T.cache_pages * 100.0 / T.index_pages ELSE 100 END) AS P_of_GBs
        , CONVERT(decimal(05,02), CASE WHEN T.index_rows  > 0 THEN T.cache_rows  * 100.0 / T.index_rows  ELSE 100 END) AS P_of_rows
     FROM #Action AS T
 ORDER BY T.DBName
        , T.SchemaName
        , T.ObjectName
        , T.type
        , T.name

DROP TABLE #Action

DROP TABLE #Action_Buffer

SET NOCOUNT OFF

