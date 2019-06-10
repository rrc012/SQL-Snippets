/*
 ===============================================================================
 Author:	     Eric Cobb
 Source:       http://www.sqlnuggets.com/blog/sql-scripts-find-index-usage/
 Article Name: SQL Scripts: How To Find Index Usage
 Create Date:  11-JUL-2017
 Description:  This script checks the usage of indexes on a given database.	
 Revision History:
 17-JUL-2017 - RAGHUNANDAN CUMBAKONAM
			 - Formatted the code.
			 - Added the history.
			 - Replaced the CASE statement with IIF in SELECT statement.
			 - Added is_included & type_desc columns.
			 - Added linefeed to the CREATE/ALTER statements.
 Usage:		N/A			   
 ===============================================================================
*/
SET NOCOUNT ON;

SELECT DB_NAME() AS DatabaseName,
	  SCHEMA_NAME(s.schema_id) +'.'+OBJECT_NAME(i.OBJECT_ID) AS TableName,
	  i.name AS IndexName,
	  ius.user_seeks AS Seeks,
	  ius.user_scans AS Scans,
	  ius.user_lookups AS Lookups,
	  ius.user_updates AS Updates,
	  IIF(ps.usedpages > ps.pages, (ps.usedpages - ps.pages), 0) * 8 / 1024 AS IndexSizeMB,
	  ius.last_user_seek AS LastSeek,
	  ius.last_user_scan AS LastScan,
	  ius.last_user_lookup AS LastLookup,
	  ius.last_user_update AS LastUpdate
  FROM sys.indexes AS i
       INNER JOIN sys.dm_db_index_usage_stats AS ius ON ius.index_id = i.index_id AND ius.OBJECT_ID = i.OBJECT_ID
       INNER JOIN (SELECT sch.name, sch.schema_id, o.OBJECT_ID, o.create_date
	                FROM sys.schemas AS sch 
       			      INNER JOIN sys.objects AS o ON o.schema_id = sch.schema_id) AS s ON s.OBJECT_ID = i.OBJECT_ID
       LEFT JOIN (SELECT OBJECT_ID, index_id, SUM(used_page_count) AS usedpages,
                         SUM(CASE WHEN (index_id < 2) 
                                  THEN (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count) 
                                  ELSE lob_used_page_count + row_overflow_used_page_count 
                              END
                            ) AS pages
                    FROM sys.dm_db_partition_stats
       		    GROUP BY object_id, index_id) AS ps ON i.object_id = ps.object_id
			                                       AND i.index_id = ps.index_id
 WHERE OBJECTPROPERTY(i.OBJECT_ID,'IsUserTable') = 1
   --optional parameters
   AND ius.database_id = DB_ID() --only check indexes in current database
   AND i.type_desc = 'nonclustered' --only check nonclustered indexes
   AND i.is_primary_key = 0 --do not check primary keys
   AND i.is_unique_constraint = 0 --do not check unique constraints
   --AND (ius.user_seeks+ius.user_scans+ius.user_lookups) < 1  --only return unused indexes
   --AND OBJECT_NAME(i.OBJECT_ID) = 'tableName'--only check indexes on specified table
   --AND i.name = 'IX_Your_Index_Name' --only check a specified index
 ORDER BY i.name;