/*
 ===============================================================================
 Author:	     ED POLLACK
 Source:       http://www.sqlshack.com/searching-sql-server-made-easy-searching-catalog-views/
 Article Name: Searching SQL Server made easy – Searching catalog views
 Create Date:  09-MAR-2016
 Description:  This script generates a full list of both referenced and referencing
               objects in order to better understand the foreign key. In the event
			that column names differ between parent and child, this will allow us
			to see both side-by-side.
			             
 Revision History:
 07-APR-2016 - RAGHUNANDAN CUMBAKONAM
			Formatted the code.
			Replaced table names in joins and columns with table aliases.
			Added the history.

 Usage:		N/A			   
 ===============================================================================
*/
;WITH LIST_FOREIGN_KEY_COLUMNS
AS 
(
SELECT parent_schema.name AS Parent_Schema,
       parent_table.name AS Parent_Table,
       referenced_schema.name AS Referenced_Schema,
       referenced_table.name AS Referenced_Table,
       FK.name AS Foreign_Key_Name,
       STUFF(
             (SELECT ', ' + referencing_column.name
                FROM sys.foreign_key_columns AS FKC
                     INNER JOIN sys.objects AS SO ON SO.object_id = FKC.constraint_object_id
                     INNER JOIN sys.tables AS parent_table ON FKC.parent_object_id = parent_table.object_id
                     INNER JOIN sys.schemas AS parent_schema ON parent_schema.schema_id = parent_table.schema_id
                     INNER JOIN sys.columns AS referencing_column ON FKC.parent_object_id = referencing_column.object_id
                                                                 AND FKC.parent_column_id = referencing_column.column_id
                     INNER JOIN sys.tables AS referenced_table ON referenced_table.object_id = FKC.referenced_object_id
                     INNER JOIN sys.schemas AS referenced_schema ON referenced_schema.schema_id = referenced_table.schema_id
                     INNER JOIN sys.columns AS referenced_column ON FKC.referenced_object_id = referenced_column.object_id
                                                                AND FKC.referenced_column_id = referenced_column.column_id
               WHERE SO.object_id = FK.object_id
               ORDER BY FKC.constraint_column_id ASC
                 FOR XML PATH('')
             ), 1, 2, ''
		  ) AS Foreign_Key_Column_List,
       STUFF(
             (SELECT ', ' + referenced_column.name
                FROM sys.foreign_key_columns AS FKC
                     INNER JOIN sys.objects AS SO ON SO.object_id = FKC.constraint_object_id
                     INNER JOIN sys.tables AS parent_table ON FKC.parent_object_id = parent_table.object_id
                     INNER JOIN sys.schemas AS parent_schema ON parent_schema.schema_id = parent_table.schema_id
                     INNER JOIN sys.columns AS referencing_column ON FKC.parent_object_id = referencing_column.object_id
                                                                 AND FKC.parent_column_id = referencing_column.column_id
                     INNER JOIN sys.tables AS referenced_table ON referenced_table.object_id = FKC.referenced_object_id
                     INNER JOIN sys.schemas AS referenced_schema ON referenced_schema.schema_id = referenced_table.schema_id
                     INNER JOIN sys.columns AS referenced_column ON FKC.referenced_object_id = referenced_column.object_id
                                                                AND FKC.referenced_column_id = referenced_column.column_id
               WHERE SO.object_id = FK.object_id
               ORDER BY FKC.constraint_column_id ASC
                 FOR XML PATH('')
             ), 1, 2, ''
		  ) AS Referenced_Column_List
  FROM sys.foreign_keys AS FK
       INNER JOIN sys.tables AS parent_table ON FK.parent_object_id = parent_table.object_id
       INNER JOIN sys.schemas AS parent_schema ON parent_schema.schema_id = parent_table.schema_id
       INNER JOIN sys.tables AS referenced_table ON FK.referenced_object_id = referenced_table.object_id
       INNER JOIN sys.schemas AS referenced_schema ON referenced_schema.schema_id = referenced_table.schema_id
)
SELECT Parent_Schema,
       Parent_Table,
       Referenced_Schema,
       Referenced_Table,
       Foreign_Key_Name,
       Foreign_Key_Column_List,
       Referenced_Column_List
  FROM LIST_FOREIGN_KEY_COLUMNS
 WHERE 1 = 1
   --AND foreign_key_column_list LIKE '%SpecialOfferID%'
   --AND referenced_column_list LIKE '%SpecialOfferID%'
 ORDER BY 1, 2, 3, 4
;