/*
***************************************************************************
Database    : HPG_EDV
Name        : dbo.UDF_PARENT_CHILD_HIERARCHY
Purpose     : This function generates the list of parents for a given table
              and repeats the process until tables with no parents are found.
Used By     : This UDF is used by the proc - dbo.USP_ERRORTABLES_COLUMN_INFO
              to retrieve the hub table(s) for a given HS/LSE table.
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

CREATE FUNCTION dbo.UDF_PARENT_CHILD_HIERARCHY
                (@SCHEMA_NAME VARCHAR(10), @TABLE_NAME VARCHAR(128))
RETURNS TABLE AS 
RETURN

WITH FK_TABLES
AS 
(
SELECT SCHEMA_NAME(CT.schema_id) AS Child_Schema,
       CT.Name AS Child_Table,
       SCHEMA_NAME(PT.schema_id) AS Parent_Schema,
       PT.Name AS Parent_Table,
	  CT.schema_id
  FROM sys.foreign_keys AS FK
       INNER JOIN sys.tables AS CT ON FK.parent_object_id = CT.object_id
       INNER JOIN sys.tables AS PT ON FK.referenced_object_id = PT.object_id
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
	  0 AS Level,
	  CAST('-' AS sysname) AS Parent_Schema_Nm,
	  CAST('-' AS sysname) AS Parent_Table_Name
  FROM sys.tables AS ST
       LEFT JOIN FK_TABLES AS FK ON ST.schema_id = FK.schema_id
                                AND ST.name = FK.Child_Table
 WHERE FK.Child_Schema IS NULL
   AND ST.name NOT IN ('dtproperties', 'sysdiagrams')
 UNION ALL
SELECT FK.Child_Schema,
       FK.Child_Table,
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
	  Parent_Schema_Nm,
	  Parent_Table_Name
  FROM ORDERED_TABLES
),
/* CHECK IF A TABLE HAS A PARENT AND REPEAT THE PROCESS UNTIL TABLES HAVE NO PARENTS */
TABLE_TREE
AS
(
SELECT *
  FROM HIERARCHICAL_PATH
 WHERE 1 = 1
   AND Schema_Nm = @SCHEMA_NAME
   AND Table_Name = @TABLE_NAME
 UNION ALL
SELECT CHILD.*
  FROM HIERARCHICAL_PATH AS CHILD
       INNER JOIN TABLE_TREE AS PARENT ON CHILD.Schema_Nm = PARENT.Parent_Schema_Nm
	         AND CHILD.Table_Name = PARENT.Parent_Table_Name
)
SELECT *,
       ROW_NUMBER() OVER(PARTITION BY Level ORDER BY Schema_Nm, Table_Name) As Parent_Number
  FROM TABLE_TREE;