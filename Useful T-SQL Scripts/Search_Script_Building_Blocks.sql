/*
 ===============================================================================
 Author:	     ED POLLACK
 Source:       http://www.sqlshack.com/searching-sql-server-made-easy-searching-catalog-views/
 Article Name: Searching SQL Server made easy – Searching catalog views
 Create Date:  09-MAR-2016
 Description:  This is a subdivision of scripts into sections based on the objects
               that are being searched and bring it all together at the end into a
			single script that will do the bidding.			             
 Revision History:
 09-APR-2016 - RAGHUNANDAN CUMBAKONAM
			Formatted the code.
			Replaced dbo.sysservers with sys.servers
			Replaced table names in joins and columns with table aliases.
			Added search criteria for Table Types & Types.
			Added the history.

 Usage:		N/A			   
 ===============================================================================
*/

/*******************
 SERVER WIDE SEARCH
*******************/
--Database Names
SELECT name AS database_name,
       'Database' AS search_type
  FROM sys.databases
 WHERE name LIKE '%Adventure%'
 ORDER BY 1;

--Logins
SELECT name AS login_name,
       'Server Login' AS search_type
  FROM sys.syslogins
 WHERE name LIKE '%edward%'
 ORDER BY 1;

--Jobs
SELECT srvrs.name AS server_name,
       jobs.name AS objectname,
       jobs.description AS object_description,
       jobs.enabled,
       'SQL Agent Job' AS search_type
  FROM msdb.dbo.sysjobs AS jobs
       INNER JOIN master.sys.servers AS srvrs ON jobs.originating_server_id = srvrs.server_id
 WHERE jobs.name LIKE '%verification%'
    OR jobs.description LIKE '%verification%'
 ORDER BY 1, 2;

--Job Steps
SELECT srvrs.name AS server_name,
       jobs.name AS objectname,
       jsteps.step_name,
       jobs.description AS object_description,
       jsteps.command AS objectdefinition,
       jobs.enabled,
       'SQL Agent Job Step' AS search_type
  FROM msdb.dbo.sysjobs AS jobs
       INNER JOIN msdb.dbo.sysjobsteps AS jsteps ON jobs.job_id = jsteps.job_id
       INNER JOIN master.sys.servers AS srvrs ON jobs.originating_server_id = srvrs.server_id
 WHERE jsteps.command LIKE '%verification%'
    OR jsteps.step_name LIKE '%verification%'
 ORDER BY 1, 2, 3;

--Linked Servers
SELECT name AS server_name,
       data_source AS objectdefinition,
       'Linked Server' AS search_type
  FROM sys.servers
 WHERE name LIKE '%2016%'
    OR data_source LIKE '%2016%'
 ORDER BY 1;

--Server Triggers
SELECT STG.name AS trigger_name,
       parent_class_desc AS trigger_type,
       MDL.definition AS trigger_definition,
       'Server Trigger' AS serach_type
  FROM sys.server_triggers AS STG
       INNER JOIN sys.server_sql_modules AS MDL ON STG.object_id = MDL.object_id
 WHERE STG.name LIKE '%Create%'
    OR MDL.definition LIKE '%Create%';

/*******************
 SEARCH BY DATABASE
*******************/
--Schemas
SELECT DB_NAME() AS database_name,
       schemas.name AS schemaname,
       'Schema' AS search_type
  FROM sys.schemas
 WHERE schemas.name LIKE '%Person%'
 ORDER BY 2;

--Tables
SELECT DB_NAME() AS database_name,
       SS.name AS schemaname,
       ST.name AS table_name,
       'Table' AS search_type
  FROM sys.tables AS ST
       INNER JOIN sys.schemas AS SS ON ST.schema_id = SS.schema_id
 WHERE ST.name LIKE '%Person%'
 ORDER BY 2, 3;

--Columns
SELECT DB_NAME() AS database_name,
       SS.name AS schemaname,
       IIF(SO.type = 'TT', STT.name, SO.name) AS table_name,
 	  SO.type_desc AS object_type,
 	  SC.name AS column_name,
	  'Column' AS search_type
  FROM sys.columns AS SC
       LEFT JOIN sys.objects AS SO ON SC.object_id = SO.object_id
	                             AND SO.type IN ('TT', 'U', 'V')
 	  LEFT JOIN sys.table_types AS STT ON SC.object_id = STT.type_table_object_id
       INNER JOIN sys.schemas AS SS ON IIF(SO.type = 'TT', STT.schema_id, SO.schema_id) = SS.schema_id
 WHERE SC.name LIKE '%BusinessEntityID%'
 ORDER BY 2, 4, 3, SC.column_id;

--Synonyms
SELECT DB_NAME() AS database_name,
       name AS synonym_name,
       base_object_name,
       'Synonym' AS search_type
  FROM sys.synonyms
 WHERE name LIKE '%product%'
    OR base_object_name LIKE '%product%'
 ORDER BY 2;

--Indexes
SELECT DB_NAME() AS database_name,
       SS.name AS schemaname,
       IIF(SO.type = 'TT', STT.name, SO.name) AS table_name,
	  SO.type_desc AS object_type,
	  SI.name AS index_name,
	  'Index' AS search_type
  FROM sys.indexes AS SI
       INNER JOIN sys.objects AS SO ON SI.object_id = SO.object_id	  
	  LEFT JOIN sys.table_types AS STT ON SO.object_id = STT.type_table_object_id
	  INNER JOIN sys.schemas AS SS ON IIF(SO.type = 'TT', STT.schema_id, SO.schema_id) = SS.schema_id
 WHERE SI.type > 0
   AND SO.type IN ('TT', 'U')
   AND SI.name LIKE '%ProductCategory%'
 ORDER BY 2, 4 DESC, 3, SI.type
;

--Index Columns
;WITH CTE_INDEX_COLUMNS
 AS 
(
SELECT DB_NAME() AS database_name,
       TBL.name AS table_name,
       IDX.name AS index_name,
       STUFF(
             (SELECT ', ' + SC.name
                FROM sys.tables AS ST
                     INNER JOIN sys.indexes AS SI ON ST.object_id = SI.object_id
                     INNER JOIN sys.index_columns AS IC ON SI.object_id = IC.object_id
                                                 AND SI.index_id = IC.index_id
                     INNER JOIN sys.columns AS SC ON ST.object_id = SC.object_id
                                                 AND IC.column_id = SC.column_id
                WHERE IDX.object_id = SI.object_id
                  AND IDX.index_id = SI.index_id
                  AND IC.is_included_column = 0
                ORDER BY IC.key_ordinal
                FOR XML PATH('')
             ), 1, 2, ''
		  ) AS key_column_list,
       STUFF(
             (SELECT ', ' + SC.name
                FROM sys.tables AS ST
                     INNER JOIN sys.indexes AS SI ON ST.object_id = SI.object_id
                     INNER JOIN sys.index_columns AS IC ON SI.object_id = IC.object_id
                                                 AND SI.index_id = IC.index_id
                     INNER JOIN sys.columns AS SC ON ST.object_id = SC.object_id
                                                 AND IC.column_id = SC.column_id
                WHERE IDX.object_id = SI.object_id
                  AND IDX.index_id = SI.index_id
                  AND IC.is_included_column = 1
                ORDER BY IC.key_ordinal
                FOR XML PATH('')
             ), 1, 2, ''
		  ) AS include_column_list,
       'Index Column' AS search_type
  FROM sys.indexes AS IDX
       INNER JOIN sys.tables AS TBL ON TBL.object_id = IDX.object_id
 WHERE IDX.type > 0
)
SELECT database_name,
       table_name,
       index_name,
       key_column_list,
       ISNULL(include_column_list, '') AS include_column_list,
	  search_type
  FROM CTE_INDEX_COLUMNS
 WHERE CTE_INDEX_COLUMNS.key_column_list LIKE '%PurchaseOrderID%'
    OR CTE_INDEX_COLUMNS.include_column_list LIKE '%PurchaseOrderID%'
 ORDER BY 2, 3;

--Service Broker Queues
SELECT DB_NAME() AS database_name,
       name,
       'Queue' AS search_type
  FROM sys.service_queues
 WHERE name LIKE '%Test_Queue%'
 ORDER BY 1;

--Table Types
SELECT DB_NAME() AS database_name,
       name AS table_type_name,
       'Table Type' AS search_type
  FROM sys.table_types
 WHERE name LIKE '%UDT_ACCOUNT_MANAGER%'
 ORDER BY 1;

--Types
SELECT DB_NAME() AS database_name,
       name,
       'Types' AS search_type 
  FROM sys.types
 WHERE is_user_defined = 1
   AND name LIKE '%Phone%'
 ORDER BY 2
;

--Foreign Keys
SELECT DB_NAME() AS database_name,
       SS.name AS schemaname,
       SO.name AS parent_table,
       FK.name AS foreign_key_name,
       'Foreign Key' AS search_type
  FROM sys.foreign_keys AS FK
       INNER JOIN sys.schemas AS SS ON FK.schema_id = SS.schema_id
       INNER JOIN sys.objects AS SO ON SO.object_id = FK.parent_object_id
 WHERE FK.name LIKE '%Customer%'
 ORDER BY 2, 3, 4;

--Foreign Key Columns
;WITH CTE_FOREIGN_KEY_COLUMNS 
 AS
(
SELECT DB_NAME() AS database_name,
       parent_schema.name AS parent_schema,
       parent_table.name AS parent_table,
       referenced_schema.name AS referenced_schema,
       referenced_table.name AS referenced_table,
       FK.name AS foreign_key_name,
       STUFF(
             (SELECT ', ' + referencing_column.name
                FROM sys.foreign_key_columns AS FKC
                     INNER JOIN sys.objects AS SO ON SO.object_id = FKC.constraint_object_id
                     INNER JOIN sys.tables AS parent_table ON FKC.parent_object_id = parent_table.object_id
                     INNER JOIN sys.schemas AS parent_schema ON parent_schema.schema_id = parent_table.schema_id
                     INNER JOIN sys.columns AS referencing_column ON FKC.parent_object_id = referencing_column.object_id
                                                                 AND FKC.parent_column_id = referencing_column.column_id
                     INNER JOIN sys.columns AS referenced_column ON FKC.referenced_object_id = referenced_column.object_id
                                                                AND FKC.referenced_column_id = referenced_column.column_id
                     INNER JOIN sys.tables AS referenced_table ON referenced_table.object_id = FKC.referenced_object_id
                     INNER JOIN sys.schemas AS referenced_schema ON referenced_schema.schema_id = referenced_table.schema_id
               WHERE SO.object_id = FK.object_id
               ORDER BY FKC.constraint_column_id ASC
                 FOR XML PATH('')
             ), 1, 2, ''
            ) AS foreign_key_column_list,
       STUFF(
             (SELECT ', ' + referenced_column.name
                FROM sys.foreign_key_columns AS FKC
                     INNER JOIN sys.objects AS SO ON SO.object_id = FKC.constraint_object_id
                     INNER JOIN sys.tables AS parent_table ON FKC.parent_object_id = parent_table.object_id
                     INNER JOIN sys.schemas AS parent_schema ON parent_schema.schema_id = parent_table.schema_id
                     INNER JOIN sys.columns AS referencing_column ON FKC.parent_object_id = referencing_column.object_id
                                                                 AND FKC.parent_column_id = referencing_column.column_id
                     INNER JOIN sys.columns AS referenced_column ON FKC.referenced_object_id = referenced_column.object_id
                                                                AND FKC.referenced_column_id = referenced_column.column_id
                     INNER JOIN sys.tables AS referenced_table ON referenced_table.object_id = FKC.referenced_object_id
                     INNER JOIN sys.schemas AS referenced_schema ON referenced_schema.schema_id = referenced_table.schema_id
               WHERE SO.object_id = FK.object_id
               ORDER BY FKC.constraint_column_id ASC
                 FOR XML PATH('')
             ), 1, 2, ''
            ) AS referenced_column_list,
       'Foreign Key Column' AS search_type
  FROM sys.foreign_keys AS FK
       INNER JOIN sys.tables AS parent_table ON FK.parent_object_id = parent_table.object_id
       INNER JOIN sys.schemas AS parent_schema ON parent_schema.schema_id = parent_table.schema_id
       INNER JOIN sys.tables AS referenced_table ON referenced_table.object_id = FK.referenced_object_id
       INNER JOIN sys.schemas AS referenced_schema ON referenced_schema.schema_id = referenced_table.schema_id)
SELECT database_name,
       parent_schema,
	  parent_table,
	  referenced_schema,
	  referenced_table,
	  foreign_key_name,
	  foreign_key_column_list AS foreign_key_column_list,
	  referenced_column_list AS referenced_column_list
  FROM CTE_FOREIGN_KEY_COLUMNS
 WHERE foreign_key_column_list LIKE '%SpecialOfferID%'
    OR referenced_column_list LIKE '%SpecialOfferID%'
 ORDER BY 2, 3, 4, 5;

--Default Constraints
SELECT DB_NAME() AS database_name,
       DC.name AS default_constraint_name,
       SS.name AS parent_schema_name,
       IIF(SO.type = 'TT', STT.name, OBJECT_NAME(DC.parent_object_id)) AS parent_object_name,
       SC.name AS parent_column_name,
       SO.type_desc AS object_type,
       DC.definition AS default_definition,
       'Default Constraint' AS search_type
  FROM sys.default_constraints AS DC
       INNER JOIN sys.objects AS SO ON DC.parent_object_id = SO.object_id
       INNER JOIN sys.columns AS SC ON DC.object_id = SC.default_object_id
                                   AND DC.parent_column_id = SC.column_id
       LEFT JOIN sys.table_types AS STT ON DC.parent_object_id = STT.type_table_object_id
       INNER JOIN sys.schemas AS SS ON IIF(SO.type = 'TT', STT.schema_id, SO.schema_id) = SS.schema_id
 WHERE DC.name LIKE '%Quantity%'
    OR DC.definition LIKE '%Quantity%'
 ORDER BY 2, 5, 3;

--Check Constraints
SELECT DB_NAME() AS database_name,      
       SS.name AS schemaname,
       IIF(SO.type = 'TT', STT.name, OBJECT_NAME(CC.parent_object_id)) AS objectname,
       SO.type_desc AS object_type,
	  CC.name AS check_constraint_name,
       CC.definition AS check_definition,
       'Check Constraint' AS serach_type
  FROM sys.check_constraints AS CC
       INNER JOIN sys.objects AS SO ON CC.parent_object_id = SO.object_id
       LEFT JOIN sys.table_types AS STT ON CC.parent_object_id = STT.type_table_object_id
       INNER JOIN sys.schemas AS SS ON IIF(SO.type = 'TT', STT.schema_id, SO.schema_id) = SS.schema_id
 WHERE CC.name LIKE '%Discount%'
   AND CC.definition LIKE '%Discount%'
 ORDER BY 2, 4, 3;

--DDL Triggers
SELECT DB_NAME() AS database_name,
       TGR.name AS trigger_name,
       TGR.parent_class_desc AS trigger_type,
       MDL.definition AS trigger_definition,
       'Database DDL Trigger' AS serach_type
  FROM sys.triggers AS TGR
       INNER JOIN sys.sql_modules AS MDL ON TGR.object_id = MDL.object_id
 WHERE TGR.parent_class_desc = 'DATABASE'
   AND (TGR.name LIKE '%test%' OR MDL.definition LIKE '%test%');

--Stored Procedures, Views, Functions, Rules, and Triggers
SELECT DB_NAME() AS database_name,       
       parent_schema.name AS parent_schema_name,
       parent_object.name AS parent_object_name,
	  child_object.name AS objectname,
       MDL.definition AS objectdefinition,
       child_object.type_desc AS serach_type
  FROM sys.sql_modules AS MDL
       INNER JOIN sys.objects AS child_object ON MDL.object_id = child_object.object_id
       LEFT JOIN sys.objects AS parent_object ON parent_object.object_id = child_object.parent_object_id
       LEFT JOIN sys.schemas AS parent_schema ON parent_object.schema_id = parent_schema.schema_id
 WHERE child_object.name LIKE '%Purchase%'
    OR MDL.definition LIKE '%Purchase%'
 ORDER BY child_object.type_desc;

/******************************
 SQL Server Reporting Services
******************************/
/*
Everything that is accessed when searching SSRS will be found specifically within the ReportServer database
that is built when Reporting Services is first configured. If it is name anything besides ReportServer, 
then substitute the correct name in its place.
*/
--Reports
SELECT CTG.Path AS SSRS_object_path,
       CTG.Name AS SSRS_object_name,
       CONVERT(XML, CONVERT(VARBINARY(MAX), CTG.content)) AS xml_definition,
       CONVERT(NVARCHAR(MAX), CONVERT(XML, CONVERT(VARBINARY(MAX), CTG.content))) AS text_definition,
       CASE CTG.Type
            WHEN 1 THEN 'Folder'
            WHEN 2 THEN 'Report'
            WHEN 3 THEN 'Resource'
            WHEN 4 THEN 'Linked Report'
            WHEN 5 THEN 'Data Source'
            WHEN 6 THEN 'Report Model'
            WHEN 7 THEN 'Report Part'
            WHEN 8 THEN 'Shared Dataset'
            ELSE 'Unknown'
       END AS SSRS_object_type
  FROM ReportServer.dbo.Catalog AS CTG
       LEFT JOIN ReportServer.dbo.Subscriptions AS SCR ON CTG.ItemID = SCR.Report_OID
 WHERE CTG.Path LIKE '%Test%'
    OR CTG.Name LIKE '%Test%'
    OR CONVERT(NVARCHAR(MAX), CONVERT(XML, CONVERT(VARBINARY(MAX), CTG.content))) LIKE '%Test%'
    OR SCR.DataSettings LIKE '%Test%'
    OR SCR.ExtensionSettings LIKE '%Test%'
    OR SCR.Description LIKE '%Test%';

--Subscriptions
SELECT Description AS subscription_description,
       ExtensionSettings AS subscription_details,
       DeliveryExtension AS subscription_delivery_method,
       LastStatus AS subscription_status,
       'SSRS Subscription' AS serach_type
  FROM ReportServer.dbo.Subscriptions
 WHERE ExtensionSettings LIKE '%Test%'
    OR Description LIKE '%Test%'
    OR DataSettings LIKE '%Test%';

/********************************
 SQL Server Integration Services
********************************/
--Search MSDB
;WITH CTE_SSIS
 AS 
(
SELECT PF.foldername + '\' + PKG.name AS full_path,
       CONVERT(XML, CONVERT(VARBINARY(MAX), PKG.packagedata)) AS package_details_XML,
       CONVERT(NVARCHAR(MAX), CONVERT(XML, CONVERT(VARBINARY(MAX), PKG.packagedata))) AS package_details_text,
       'SSIS Package (MSDB)' AS serach_type
  FROM msdb.dbo.sysssispackages AS PKG
       INNER JOIN msdb.dbo.sysssispackagefolders AS PF ON PKG.folderid = PF.folderid
)
SELECT *
  FROM CTE_SSIS
 WHERE package_details_text LIKE '%test%'
    OR full_path LIKE '%test%';

--Search Disk
DECLARE @pkg_directory NVARCHAR(MAX) = 'C:\SSIS_Packages';
DECLARE @ssis_package_name NVARCHAR(MAX);
DECLARE @sql_command VARCHAR(4000);
 
SELECT @sql_command = 'dir "' + @pkg_directory + '" /A-D /B /S ';

CREATE TABLE ##ssis_data
(  
full_path	           NVARCHAR(MAX),
package_details_XML  XML,
package_details_text NVARCHAR(MAX) 
);

INSERT INTO ##ssis_data (full_path)
EXEC xp_cmdshell @sql_command;
 
DECLARE SSIS_CURSOR CURSOR FOR
SELECT full_path FROM ##ssis_data;
 
OPEN SSIS_CURSOR;
 
FETCH NEXT FROM SSIS_CURSOR INTO @ssis_package_name;
 
WHILE @@FETCH_STATUS = 0
  BEGIN
      SELECT @sql_command = ';WITH CTE_SSIS_PACKAGES
                              AS
                             (
                             SELECT ''' + @ssis_package_name + ''' AS full_path,
                                    CONVERT( XML, SSIS_PACKAGE.bulkcolumn) AS package_details_XML
                               FROM OPENROWSET(BULK ''' + @ssis_package_name + ''', SINGLE_BLOB) AS SSIS_PACKAGE
                             )
                             UPDATE SSIS_DATA
                                SET package_details_XML = PKG.package_details_XML
                               FROM CTE_SSIS_PACKAGES AS PKG
                                    INNER JOIN ##ssis_data AS SSIS_DATA ON PKG.full_path = SSIS_DATA.full_path;'
        FROM ##ssis_data; 
      EXEC (@sql_command);
      FETCH NEXT FROM SSIS_CURSOR INTO @ssis_package_name;
  END
 
CLOSE SSIS_CURSOR;
DEALLOCATE SSIS_CURSOR;
 
UPDATE ##ssis_data
   SET package_details_text = CONVERT( NVARCHAR(MAX), package_details_XML);
 
SELECT *,
       'SSIS Package (File System)' AS search_type
  FROM ##ssis_data AS SSIS_DATA
 WHERE package_details_text LIKE '%test%'
    OR full_path LIKE '%test%';
 
DROP TABLE ##ssis_data;