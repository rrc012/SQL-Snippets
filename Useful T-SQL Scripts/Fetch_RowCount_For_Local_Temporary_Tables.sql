/*
 ===============================================================================
 Author:	     NAKUL VACHHRAJANI
 Source:       https://nakulvachhrajani.com/2020/02/03/0417-sql-server-select-row-count-of-local-temp-tables/
 Article Name: #0417 – SQL Server – Select row count of local temp tables
 Create Date:  03-FEB-2020
 Description:  This script fetches RowCount for local temporary tables using
               SQL Server DMVs.	
 Revision History:
 11-FEB-2020 - RAGHUNANDAN CUMBAKONAM
		   - Formatted the code.
		   - Added the history.
 Usage:	     N/A			   
 ===============================================================================
*/

SET NOCOUNT ON;

SELECT st.[name] AS TableName,
       ps.row_count AS [RowCount]
  FROM tempdb.sys.dm_db_partition_stats AS ps
       INNER JOIN tempdb.sys.tables AS st ON st.object_id = ps.object_id
 WHERE 1 = 1
  --AND st.[name] LIKE '%SQLTwinsDemo%'
  AND (ps.index_id = 0 --Table is a heap
       OR
       ps.index_id = 1 --Table has a clustered index
      );