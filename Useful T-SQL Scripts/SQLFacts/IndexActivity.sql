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

PRINT CHAR(13) + CHAR(10)

PRINT 'Nature PK means primary   key'
PRINT 'Nature AK means alternate key (unique constraint)'
PRINT 'Nature U  means unique'
PRINT 'Nature UF means unique filtered'
PRINT 'Nature S  means simple'
PRINT 'Nature SF means simple filtered'

PRINT CHAR(13) + CHAR(10)

PRINT 'table_type 0 means a table as heap'
PRINT 'table_type 1 means a table as clustered index'
PRINT 'table_type 5 means a table as clustered index (columnstore)'

PRINT CHAR(13) + CHAR(10)

PRINT 'index_type 0 means a table as heap'
PRINT 'index_type 1 means a table as clustered index'
PRINT 'index_type 5 means a table as clustered index (columnstore)'
PRINT 'index_type 2 means a       nonclustered index'
PRINT 'index_type 6 means a       nonclustered index (columnstore)'

PRINT CHAR(13) + CHAR(10)

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
        , ISNULL(I.filter_definition, SPACE(0)) AS GeneralFilter
     INTO #ZKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.indexes AS I
       ON O.object_id
        = I.object_id
     JOIN sys.data_spaces AS H
       ON I.data_space_id
        = H.data_space_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY   GeneralSchema
        ,   GeneralObject
        ,   SQLServerName

   UPDATE Z SET
            table_type
        = W.index_type
     FROM #ZKey AS Z
     JOIN #ZKey AS W
       ON Z.GeneralID
        = W.GeneralID
      AND W.index_type IN (0, 1, 5)

   SELECT I.GeneralSchema
        , I.GeneralObject
        , I.SQLServerName
--      , I.SQLServerFile
        , CASE WHEN I.index_type            = 0 THEN 'S '
               WHEN I.index_type            = 5 THEN 'S '
               WHEN I.index_type            = 6 THEN 'S '
               WHEN I.is_primary_key       != 0 THEN 'PK'
               WHEN I.is_unique_constraint != 0 THEN 'AK'
               WHEN I.is_unique            != 0 AND LEN(I.GeneralFilter) = 0 THEN 'U '
               WHEN I.is_unique            != 0 AND LEN(I.GeneralFilter) > 0 THEN 'UF'
               WHEN I.is_unique             = 0 AND LEN(I.GeneralFilter) = 0 THEN 'S '
               WHEN I.is_unique             = 0 AND LEN(I.GeneralFilter) > 0 THEN 'SF' END AS Nature
--      , I.fill_factor AS Factor
--      , I.is_primary_key
--      , I.is_unique_constraint
--      , I.is_unique
--      , I.is_disabled
--      , STR(I.table_type, 1) + ' / ' + STR(I.index_type, 1) AS types
        , I.table_type
        , I.index_type
        , E.index_rows
        , CONVERT(decimal(19,05), T.pages_total      / 128.0 / 1024.0) AS GBs_total_size
        , CONVERT(decimal(19,05), U.pages_fetch_LOB  / 128.0 / 1024.0) AS GBs_fetch_LOB
        , CONVERT(decimal(19,05), U.pages_fetch_over / 128.0 / 1024.0) AS GBs_fetch_over
        , U.leaf_inserts
        , U.leaf_updates
        , U.leaf_deletes
        , U.leaf_splits
        , U.limb_inserts
        , U.limb_updates
        , U.limb_deletes
        , U.limb_splits
        , U.forwards
        , U.range_scans
        , U.row_lookups
        , U.row_locks
        , U.row_lock_waits
        , CONVERT(decimal(19,03), U.row_lock_stall      / 1000.0) AS row_lock_stall
        , U.page_locks
        , U.page_lock_waits
        , CONVERT(decimal(19,03), U.page_lock_stall     / 1000.0) AS page_lock_stall
        , U.page_latch_waits
        , CONVERT(decimal(19,03), U.page_latch_stall    / 1000.0) AS page_latch_stall
        , U.page_io_latch_waits
        , CONVERT(decimal(19,03), U.page_io_latch_stall / 1000.0) AS page_io_latch_stall
     FROM #ZKey AS I
     JOIN
  (SELECT P.object_id
        , P.index_id
        , SUM(P.rows) AS index_rows
     FROM sys.partitions AS P
 GROUP BY P.object_id
        , P.index_id)    AS E
       ON I.GeneralID
        = E.object_id
      AND I.index_id
        = E.index_id
     JOIN
  (SELECT P.object_id
        , P.index_id
        , SUM(A.total_pages) AS pages_total
     FROM sys.partitions AS P
     JOIN sys.allocation_units AS A
       ON P.partition_id
        = A.container_id
      AND A.type != 0
 GROUP BY P.object_id
        , P.index_id)    AS T
       ON I.GeneralID
        = T.object_id
      AND I.index_id
        = T.index_id
LEFT JOIN
  (SELECT E.object_id
        , E.index_id
        , SUM(E.leaf_insert_count          ) AS leaf_inserts
        , SUM(E.leaf_update_count          ) AS leaf_updates
        , SUM(E.leaf_delete_count          ) AS leaf_deletes
        , SUM(E.leaf_allocation_count      ) AS leaf_splits
        , SUM(E.nonleaf_insert_count       ) AS limb_inserts
        , SUM(E.nonleaf_update_count       ) AS limb_updates
        , SUM(E.nonleaf_delete_count       ) AS limb_deletes
        , SUM(E.nonleaf_allocation_count   ) AS limb_splits
        , SUM(E.forwarded_fetch_count      ) AS forwards
        , SUM(E.range_scan_count           ) AS range_scans
        , SUM(E.singleton_lookup_count     ) AS row_lookups
        , SUM(E.row_lock_count             ) AS row_locks
        , SUM(E.row_lock_wait_count        ) AS row_lock_waits
        , SUM(E.row_lock_wait_in_ms        ) AS row_lock_stall
        , SUM(E.page_lock_count            ) AS page_locks
        , SUM(E.page_lock_wait_count       ) AS page_lock_waits
        , SUM(E.page_lock_wait_in_ms       ) AS page_lock_stall
        , SUM(E.page_latch_wait_count      ) AS page_latch_waits
        , SUM(E.page_latch_wait_in_ms      ) AS page_latch_stall
        , SUM(E.page_io_latch_wait_count   ) AS page_io_latch_waits
        , SUM(E.page_io_latch_wait_in_ms   ) AS page_io_latch_stall
        , SUM(E.lob_fetch_in_pages         ) AS pages_fetch_LOB
        , SUM(E.row_overflow_fetch_in_pages) AS pages_fetch_over
     FROM sys.dm_db_index_operational_stats(DB_ID(), NULL, NULL, NULL) AS E
 GROUP BY E.object_id
        , E.index_id) AS U
       ON I.GeneralID
        = U.object_id
      AND I.index_id
        = U.index_id
 ORDER BY I.GeneralSchema
        , I.GeneralObject
        , CASE I.index_type
          WHEN 0 THEN 0
          WHEN 1 THEN 0
          WHEN 5 THEN 0
          WHEN 2 THEN 1
          WHEN 6 THEN 2 ELSE 3 END
        , I.SQLServerName

DROP TABLE #ZKey

SET NOCOUNT OFF

