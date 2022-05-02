/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

DECLARE @Benefit bigint = 100 -- minimum index Benefit

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

CREATE TABLE #DBA
     ( group_handle                int
     , statement         varchar(0400)
     , Last_Seek              datetime
     , Last_Scan              datetime
     , Seeks                    bigint
     , Scans                    bigint
     , Plans                    bigint
     , Benefit                  bigint
     , DBName            varchar(0200)
     , SchemaName        varchar(0200)
     , ObjectName        varchar(0200)
     , Key_Part_1        varchar(1200)
     , Key_Part_2        varchar(1200)
     , Include_Columns   varchar(4000) )

   INSERT #DBA
        ( group_handle
        , statement
        , Last_Seek
        , Last_Scan
        , Seeks
        , Scans
        , Plans
        , Benefit
        , DBName
        , SchemaName
        , ObjectName
        , Key_Part_1
        , Key_Part_2
        , Include_Columns )
   SELECT G.index_group_handle
        , D.statement
        , S.last_user_seek
        , S.last_user_scan
        , S.user_seeks
        , S.user_scans
        , S.unique_compiles
        , CONVERT(bigint, S.avg_total_user_cost * (S.avg_user_impact / 100.0) * (S.user_seeks + S.user_scans))
        , PARSENAME(D.statement, 3)
        , PARSENAME(D.statement, 2)
        , PARSENAME(D.statement, 1)
        , ISNULL(  D.equality_columns, '')
        , ISNULL(D.inequality_columns, '')
        , ISNULL(  D.included_columns, '')
     FROM sys.dm_db_missing_index_groups      AS G
     JOIN sys.dm_db_missing_index_group_stats AS S
       ON G.index_group_handle
        =       S.group_handle
     JOIN sys.dm_db_missing_index_details     AS D
       ON G.index_handle
        = D.index_handle
--  WHERE CONVERT(bigint, S.avg_total_user_cost * (S.avg_user_impact / 100.0) * (S.user_seeks + S.user_scans)) !< @Benefit
 ORDER BY G.index_handle

   SELECT O.DBName
        , O.SchemaName
        , O.ObjectName
--      , O.group_handle
        , CONVERT(varchar(0040), O.Last_Seek, 120) AS Last_Seek
        , CONVERT(varchar(0040), O.Last_Scan, 120) AS Last_Scan
        , O.Seeks
        , O.Scans
        , O.Plans
        , O.Benefit
        , O.Key_Part_1
        , O.Key_Part_2
        , O.Include_Columns
        , 'CREATE NONCLUSTERED INDEX IX_' + RIGHT(STR(ROW_NUMBER() OVER (PARTITION BY O.statement ORDER BY O.Key_Part_1, O.Key_Part_2, O.Include_Columns) + 1000, 4), 3)
        + ' ON ' + O.DBName + '.' + O.SchemaName + '.' + O.ObjectName
        + ' (' + O.Key_Part_1 + CASE WHEN LEN(O.Key_Part_1) > 0
                                      AND LEN(O.Key_Part_2) > 0 THEN ', ' ELSE '' END + O.Key_Part_2 + ')'
        + CASE WHEN LEN(O.Include_Columns) > 0 THEN ' INCLUDE (' + O.Include_Columns + ')' ELSE '' END AS CREATE_INDEX
     FROM #DBA AS O
     JOIN
  (SELECT I.DBName
        , I.SchemaName
        , I.ObjectName
        , SUM(I.Benefit) AS Benefit
     FROM #DBA AS I
    WHERE I.Benefit
       !<  @Benefit
 GROUP BY I.DBName
        , I.SchemaName
        , I.ObjectName) AS Z
       ON O.DBName
        = Z.DBName
      AND O.SchemaName
        = Z.SchemaName
      AND O.ObjectName
        = Z.ObjectName
    WHERE O.Benefit
       !<  @Benefit
 ORDER BY Z.Benefit DESC
        , O.DBName
        , O.SchemaName
        , O.ObjectName
        , O.Benefit DESC

   SELECT O.DBName
        , O.SchemaName
        , O.ObjectName
--      , O.group_handle
        , CONVERT(varchar(0040), O.Last_Seek, 120) AS Last_Seek
        , CONVERT(varchar(0040), O.Last_Scan, 120) AS Last_Scan
        , O.Seeks
        , O.Scans
        , O.Plans
        , O.Benefit
        , O.Key_Part_1
        , O.Key_Part_2
        , O.Include_Columns
        , 'CREATE NONCLUSTERED INDEX IX_' + RIGHT(STR(ROW_NUMBER() OVER (PARTITION BY O.statement ORDER BY O.Key_Part_1, O.Key_Part_2, O.Include_Columns) + 1000, 4), 3)
        + ' ON ' + O.DBName + '.' + O.SchemaName + '.' + O.ObjectName
        + ' (' + O.Key_Part_1 + CASE WHEN LEN(O.Key_Part_1) > 0
                                      AND LEN(O.Key_Part_2) > 0 THEN ', ' ELSE '' END + O.Key_Part_2 + ')'
        + CASE WHEN LEN(O.Include_Columns) > 0 THEN ' INCLUDE (' + O.Include_Columns + ')' ELSE '' END AS CREATE_INDEX
     FROM #DBA AS O
    WHERE O.Benefit
       !<  @Benefit
 ORDER BY O.DBName
        , O.SchemaName
        , O.ObjectName
        , O.Key_Part_1
        , O.Key_Part_2
        , O.Include_Columns

/*

   SELECT E.CREATE_INDEX
        , E.DBName_
        , E.SchemaName_
        , E.ObjectName_
        , E.user_seeks
        , E.user_scans
        , SUBSTRING(E.text, E.I, E.O - E.I) AS SQL_code
        ,           E.text                  AS SQL_code_all
     FROM
  (SELECT O.DBName
        , O.SchemaName
        , O.ObjectName
--      , O.group_handle
--      , CONVERT(varchar(0040), O.Last_Seek, 120) AS Last_Seek
--      , CONVERT(varchar(0040), O.Last_Scan, 120) AS Last_Scan
--      , O.Seeks
--      , O.Scans
--      , O.Plans
--      , O.Benefit
--      , O.Key_Part_1
--      , O.Key_Part_2
--      , O.Include_Columns
        , 'CREATE NONCLUSTERED INDEX IX_' + RIGHT(STR(ROW_NUMBER() OVER (PARTITION BY O.statement ORDER BY O.Key_Part_1, O.Key_Part_2, O.Include_Columns) + 1000, 4), 3)
        + ' ON ' + O.DBName + '.' + O.SchemaName + '.' + O.ObjectName
        + ' (' + O.Key_Part_1 + CASE WHEN LEN(O.Key_Part_1) > 0
                                      AND LEN(O.Key_Part_2) > 0 THEN ', ' ELSE '' END + O.Key_Part_2 + ')'
        + CASE WHEN LEN(O.Include_Columns) > 0 THEN ' INCLUDE (' + O.Include_Columns + ')' ELSE '' END AS CREATE_INDEX
        , U.user_seeks
        , U.user_scans
--      , U.system_seeks
--      , U.system_scans
--      , CONVERT(varchar(0040), U.last_user_seek    , 120) AS last_user_seek
--      , CONVERT(varchar(0040), U.last_user_scan    , 120) AS last_user_scan
--      , CONVERT(varchar(0040), U.last_system_seek  , 120) AS last_system_seek
--      , CONVERT(varchar(0040), U.last_system_scan  , 120) AS last_system_scan
        , CASE WHEN U.last_statement_start_offset < 0 THEN     0                                                                                       ELSE U.last_statement_start_offset END / 2 + 1 AS I
        , CASE WHEN U.last_statement_end_offset   < 0 THEN LEN(T.text) * 2 WHEN U.last_statement_end_offset > LEN(T.text) * 2 - 4 THEN LEN(T.text) * 2 ELSE U.last_statement_end_offset   END / 2 + 1 AS O
        , T.text
        ,            DB_NAME(            T.dbid) AS DBName_
        , OBJECT_SCHEMA_NAME(T.objectid, T.dbid) AS SchemaName_
        ,        OBJECT_NAME(T.objectid, T.dbid) AS ObjectName_
        , 'NA'                                   AS ObjectType_
     FROM #DBA AS O
     JOIN sys.dm_db_missing_index_group_stats_query AS U
       ON O.group_handle
        = U.group_handle
    CROSS APPLY sys.dm_exec_sql_text(U.last_sql_handle) AS T) AS E
 ORDER BY E.CREATE_INDEX
        , E.DBName_
        , E.SchemaName_
        , E.ObjectName_

*/

DROP TABLE #DBA

SET NOCOUNT OFF

