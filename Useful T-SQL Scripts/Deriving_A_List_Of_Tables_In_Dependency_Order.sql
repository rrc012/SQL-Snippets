/*
 ===============================================================================
 Author:	     JAMIE THOMSON
 Source:       http://sqlblog.com/blogs/jamie_thomson/archive/2009/09/08/deriving-a-list-of-tables-in-dependency-order.aspx
 Article Name: Deriving a list of tables in dependency order
 Create Date:  08-SEP-2009
 Description:  This script would loop over all the tables and empty them 
               one-by-one by respecting referential integrity constraints 
			(i.e. foreign keys) or the dependency hierarchy.
 Caution:      This script won�t work across databases as SCHEMA_NAME() is
               confined to the current database. To work across databases,
			either replace SCHEMA_NAME() with OBJECT_SCHEMA_NAME and pass in
			DB_ID() as the 2nd parameter or JOIN with sys.schemas.
			             
 Revision History:
 15-MAR-2017 - RAGHUNANDAN CUMBAKONAM
			Formatted the code.
			Added RowCount logic to provide the number of rows/table.
			Replaced the sys.schemas with SCHEMA_NAME.
			Removed the derived table and modified the final SELECT statement.
			Added the Parent_Schema, Parent_Table & Parent_Level to the final SELECT statement.
			Added the history.

 Usage:		N/A			   
 ===============================================================================
*/ 

WITH FK_TABLES
AS 
(
SELECT SCHEMA_NAME(CT.schema_id) AS Child_Schema,
       CT.Name AS Child_Table,
	  CASP.Row_Count,
       SCHEMA_NAME(PT.schema_id) AS Parent_Schema,
       PT.Name AS Parent_Table,
	  CT.schema_id
  FROM sys.foreign_keys AS FK
       INNER JOIN sys.tables AS CT ON FK.parent_object_id = CT.object_id
       INNER JOIN sys.tables AS PT ON FK.referenced_object_id = PT.object_id
	  CROSS APPLY (SELECT SUM(SP.row_count) AS Row_Count FROM sys.dm_db_partition_stats AS SP WHERE CT.object_id = SP.object_id AND SP.index_id < 2) CASP  
/*For the purposes of finding dependency hierarchy we're not worried about self-referencing tables*/
 WHERE 1 = 1
   AND CT.name NOT IN ('dtproperties', 'sysdiagrams')
   AND CT.name != PT.name
),
ORDERED_TABLES
AS
(
SELECT SCHEMA_NAME(ST.schema_id) AS Schema_Nm,
       ST.name AS Table_Name,
	  CASP.Row_Count,
       0 AS Level,
	  CAST('-' AS sysname) AS Parent_Schema_Nm,
	  CAST('-' AS sysname) AS Parent_Table_Name
  FROM sys.tables AS ST
       LEFT JOIN FK_TABLES AS FK ON ST.schema_id = FK.schema_id
                                AND ST.name = FK.Child_Table
       CROSS APPLY (SELECT SUM(SP.row_count) AS Row_Count FROM sys.dm_db_partition_stats AS SP WHERE ST.object_id = SP.object_id AND SP.index_id < 2) CASP 
 WHERE FK.Child_Schema IS NULL
   AND ST.name NOT IN ('dtproperties', 'sysdiagrams')
 UNION ALL
SELECT FK.Child_Schema,
       FK.Child_Table,
	  FK.Row_Count,
       OT.Level + 1,
	  FK.Parent_Schema,
	  FK.Parent_Table
  FROM fk_tables AS FK
       INNER JOIN ORDERED_TABLES AS OT ON FK.Parent_Schema = OT.Schema_Nm
                                      AND FK.Parent_Table = OT.Table_Name
),
HIERARCHICAL_PATH
AS
(
SELECT DISTINCT
       Schema_Nm,
       Table_Name,
       MAX(Level) OVER (PARTITION BY Schema_Nm, Table_Name) AS Level,	  
	  Row_Count,
	  Parent_Schema_Nm,
	  Parent_Table_Name
  FROM ORDERED_TABLES
),
UNIQUE_SET
AS
(
SELECT Schema_Nm, Table_Name, Level, Parent_Schema_Nm, Parent_Table_Name,
	  ROW_NUMBER() OVER(PARTITION BY Schema_Nm, Table_Name ORDER BY Schema_Nm, Table_Name) AS RN,
	  ROW_NUMBER() OVER(PARTITION BY Parent_Schema_Nm, Parent_Table_Name ORDER BY Parent_Schema_Nm, Parent_Table_Name) AS RN1       
  FROM HIERARCHICAL_PATH
),
FK_REFERENCES
AS
(
SELECT Schema_Nm,
       Table_Name,
       MAX(Level) OVER (PARTITION BY Schema_Nm, Table_Name) AS Level,
	  Row_Count,
	  Parent_Schema_Nm,
	  Parent_Table_Name,
	  COALESCE(Parent_Level, '-') As Parent_Level
  FROM HIERARCHICAL_PATH AS C1
       OUTER APPLY (SELECT CAST(MAX(T1.Level) OVER (PARTITION BY T1.Schema_Nm, T1.Table_Name) AS VARCHAR(5)) AS Parent_Level
	                 FROM UNIQUE_SET AS T1
				       INNER JOIN UNIQUE_SET AS T2 ON T1.Schema_Nm = T2.Parent_Schema_Nm
					                             AND T1.Table_Name = T2.Parent_Table_Name
										    AND T1.RN = T2.RN1
										    AND T1.RN = 1
				 WHERE C1.Parent_Schema_Nm = T2.Parent_Schema_Nm
				   AND C1.Parent_Table_Name = T2.Parent_Table_Name
			    ) OA
)
SELECT *
  FROM FK_REFERENCES
 WHERE 1 = 1
   --AND Schema_Nm = ''
   --AND Table_Name = ''
   --AND Level = 0
   --AND Parent_Schema_Nm = ''
   --AND Parent_Table_Name = ''
   --AND Parent_Level = 0
 ORDER BY 3, 1, 2, 7;