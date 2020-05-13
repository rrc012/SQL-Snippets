USE [AdventureWorks]
GO

/*
1. Get the list of tables in dependency order along with IDENTITY KEY column.
2. Loop through the list and load the tables via Dynamic SQL.
3. Audit the loading process.
*/

/*
***************************************************************************
Database     : 
Name         : dbo.USP_RANK_TABLES_IN_ORDER
Purpose      : This procedure ranks tables by respecting referential
               integrity constraints (i.e. foreign keys) or the
		     dependency hierarchy. 
Author       : JAMIE THOMSON
Source       : http://sqlblog.com/blogs/jamie_thomson/archive/2009/09/08/deriving-a-list-of-tables-in-dependency-order.aspx
Article Name : Deriving a list of tables in dependency order
Created      : 08-SEP-2009
Usage        : EXEC dbo.USP_RANK_TABLES_IN_ORDER;
***************************************************************************
Change History
***************************************************************************
Name                    Date               Description
----------------------  -----------        -----------------------
RAGHUNANDAN CUMBAKONAM  14-APR-2019        1. Formatted the code.
                                           2. Added RowCount logic to provide the number of rows/table.
								   3. Removed the derived table and modified the final SELECT statement.
								   4. Added the column list for a given table excluding the IDENTITY Key.
***************************************************************************
*/

--/*
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'USP_RANK_TABLES_IN_ORDER' AND type = 'P')
DROP PROC dbo.USP_RANK_TABLES_IN_ORDER;
GO

CREATE PROCEDURE dbo.USP_RANK_TABLES_IN_ORDER
AS 

SET NOCOUNT ON;

BEGIN TRY
--*/
     ;WITH FK_TABLES
     AS 
     (
     SELECT CS.Name AS Child_Schema,
            CT.Name AS Child_Table,
     	  CASP.Row_Count,
            PS.Name AS Parent_Schema,
            PT.Name AS Parent_Table,
     	  CT.schema_id,
		  CT.object_id
       FROM sys.foreign_keys AS FK
            INNER JOIN sys.tables AS CT ON FK.parent_object_id = CT.object_id
     	  INNER JOIN sys.schemas AS CS ON CT.schema_id = CS.schema_id
            INNER JOIN sys.tables AS PT ON FK.referenced_object_id = PT.object_id
     	  INNER JOIN sys.schemas AS PS ON PT.schema_id = PS.schema_id
     	  CROSS APPLY (SELECT SUM(SP.row_count) AS Row_Count FROM sys.dm_db_partition_stats AS SP WHERE CT.object_id = SP.object_id AND SP.index_id < 2) CASP	  
     /*For the purposes of finding dependency hierarchy we're not worried about self-referencing tables*/
      WHERE 1 = 1
        AND CT.name NOT IN ('dtproperties', 'sysdiagrams')
        AND CT.name != PT.name
     ),
     ORDERED_TABLES
     AS
     (
     SELECT ST.object_id,
	       SS.Name AS Schema_Nm,
            ST.name AS Table_Name,
     	  CASP.Row_Count,
            0 AS Level
       FROM sys.tables AS ST
            INNER JOIN sys.schemas AS SS ON ST.schema_id = SS.schema_id
            LEFT JOIN FK_TABLES AS FK ON ST.schema_id = FK.schema_id
                                     AND ST.name = FK.Child_Table
            CROSS APPLY (SELECT SUM(SP.row_count) AS Row_Count FROM sys.dm_db_partition_stats AS SP WHERE ST.object_id = SP.object_id AND SP.index_id < 2) CASP 
      WHERE FK.Child_Schema IS NULL
        AND ST.name NOT IN ('dtproperties', 'sysdiagrams', 'Audit')
      UNION ALL
     SELECT FK.object_id,
	       FK.Child_Schema,
            FK.Child_Table,
     	  FK.Row_Count,
            OT.Level + 1
       FROM FK_TABLES AS FK
            INNER JOIN ORDERED_TABLES AS OT ON FK.Parent_Schema = OT.Schema_Nm
                                           AND FK.Parent_Table = OT.Table_Name
     ),
     HIERARCHICAL_PATH
     AS
     (
     SELECT DISTINCT
            Schema_Nm + '.' + Table_Name AS Table_Name,
     	  MAX(Level) OVER (PARTITION BY Schema_Nm, Table_Name) AS [Level],
		  Row_Count,
		  STUFF(CA2.Key_Columns, 1, 2, '') AS Key_Columns,
		  STUFF(CA3.Join_Clause, 1, 5, '') AS Join_Clause,
		  COALESCE(IC.is_identity, 0) AS Is_Identity,
		  STUFF(CA1.Column_Name, 1, 2, '') AS Column_List		  
       FROM ORDERED_TABLES AS OT
	       CROSS APPLY (SELECT ', ' + QUOTENAME(SC.name, '') FROM sys.columns AS SC WHERE OT.object_id = SC.object_id AND SC.is_identity = 0 AND SC.is_computed = 0 ORDER BY SC.column_id FOR XML PATH('')) AS CA1(Column_Name)
		  LEFT JOIN sys.identity_columns AS IC ON OT.object_id = IC.object_id
		  LEFT JOIN sys.indexes AS PK ON OT.object_id = PK.object_id 
                  AND PK.is_primary_key = 1
            CROSS APPLY (SELECT ', ' + QUOTENAME(COL.[name], '')
                           FROM sys.index_columns AS IXC
                                INNER JOIN sys.columns AS COL ON IXC.object_id = COL.object_id
                                       AND IXC.column_id = COL.column_id
                          WHERE IXC.object_id = OT.object_id
                            AND IXC.index_id = PK.index_id
                          ORDER BY COL.column_id
                            FOR XML PATH ('')) CA2(Key_Columns)
            CROSS APPLY (SELECT CONCAT(' AND ', 'SRC.', QUOTENAME(COL.[name], ''), ' = TGT.', QUOTENAME(COL.[name], ''))
                           FROM sys.index_columns AS IXC
                                INNER JOIN sys.columns AS COL ON IXC.object_id = COL.object_id
                                       AND IXC.column_id = COL.column_id
                          WHERE IXC.object_id = OT.object_id
                            AND IXC.index_id = PK.index_id
                          ORDER BY COL.column_id
                            FOR XML PATH ('')) CA3(Join_Clause)
     )
     SELECT *
       FROM HIERARCHICAL_PATH
      ORDER BY [Level], Table_Name;
--/*
END TRY

BEGIN CATCH
 
     THROW;

END CATCH
--*/