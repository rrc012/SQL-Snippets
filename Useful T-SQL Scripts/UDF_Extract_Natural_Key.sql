/*
***************************************************************************
Database    : HPG_EDV
Name        : dbo.UDF_EXTRACT_NATURAL_KEY
Purpose     : This function retrieves the list of columns present in a index
              and appends the columns into a CSV if more than 1 column is
		    present in a index.
Used By     : This UDF is used by the proc - dbo.USP_ERRORTABLES_COLUMN_INFO
              to retrieve the natural key for the hub table(s) for a given 
		    HS/LSE table.
Author      : Raghunandan Cumbakonam
Created     : 2016-06-06
Usage       : 
***************************************************************************
Change History
***************************************************************************
Name               Date               Reason for modification
---------------    -----------        -----------------------
Author             YYYY-MM-DD         
***************************************************************************
*/

CREATE FUNCTION dbo.UDF_EXTRACT_NATURAL_KEY
                (@SCHEMA_NAME VARCHAR(10), @TABLE_NAME VARCHAR(128))
RETURNS TABLE AS 
RETURN

WITH IDX_COLUMNS
 AS
(
SELECT SCHEMA_NAME(SO.schema_id) AS Schema_Nm,
       SO.name AS Table_Name,
	  SI.type_desc AS Idx_Type,
	  IIF(SI.is_unique = 1, 'YES', 'NO') AS Is_Unique,
	  IIF(SI.is_primary_key = 1, 'YES', 'NO') AS Is_Primary_Key,
	  IIF(SI.is_unique_constraint = 1, 'YES', 'NO') AS Is_Unique_Constraint,
	  COL_NAME(IC.object_id, IC.column_id) AS Column_Name,
	  IC.index_column_id AS Index_Column_ID,
	  SI.object_id, SI.index_id  
  FROM sys.indexes AS SI
       INNER JOIN sys.objects AS SO ON SI.object_id = SO.object_id
	         AND SO.type IN ('U')	   
	  INNER JOIN sys.index_columns AS IC ON SI.index_id = IC.index_id
	         AND SO.object_id = IC.object_id
	  INNER JOIN sys.columns AS SC ON SO.object_id = SC.object_id
	         AND IC.column_id = SC.column_id
)
SELECT DISTINCT Schema_Nm, Table_Name, Idx_Type, Is_Unique, Is_Primary_Key, Is_Unique_Constraint,
       STUFF /* IN THE EVENT OF COMPOSITE PKs/BKs, APPEND THEM INTO A SINGLE ROW AS A CSV */
	  (
       (SELECT ', ' + Column_Name
	     FROM IDX_COLUMNS AS IC2
	    WHERE IC2.object_id = IC1.object_id
		 AND IC2.index_id = IC1.index_id
	    ORDER BY IC2.Index_Column_ID
	      FOR XML PATH(''), TYPE
	  ).value('.', 'VARCHAR(MAX)'),
	  1, 2,''
       ) AS Key_Column
  FROM IDX_COLUMNS AS IC1
 WHERE 1 = 1
   AND IC1.Schema_Nm = @SCHEMA_NAME
   AND IC1.Table_Name = @TABLE_NAME;