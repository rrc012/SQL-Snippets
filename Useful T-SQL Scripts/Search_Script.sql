/*
 ===============================================================================
 Author:	     ED POLLACK
 Source:       http://www.sqlshack.com/searching-sql-server-made-easy-building-the-perfect-search-script/
 Article Name: Searching SQL Server made easy – Building the perfect search script
 Create Date:  09-MAR-2016
 Description:  This single script searches through database schema for specific words 
               or phrases quickly and accurately.			             
 Revision History:
 09-APR-2016 - RAGHUNANDAN CUMBAKONAM
			Formatted the code.
			Added the preview_text, object_type in #object_data.
			Replaced dbo.sysservers with sys.servers.
			Replaced table names in joins and columns with table aliases.
			Added search criteria for Table Types & Types.
			Added the history.

 Usage:		N/A			   
 ===============================================================================
*/

USE [master];
GO

--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;
---------------------------------------------------------------
---------------------Configure Search Here---------------------
---------------------------------------------------------------
DECLARE @search_string     NVARCHAR(MAX) = 'Department',
        @search_text       NVARCHAR(MAX),
        @search_SSRS       BIT = 0,
        @search_SSIS_MSDB  BIT = 0,
        @search_SSIS_disk  BIT = 0,
	   @debug_sql         BIT = 0,
	   @preview_text_size SMALLINT = 200,
	   @database_id       SMALLINT = ISNULL(DB_ID(N''), 0), --Pass a valid databasename to confine search against the given database instead of all databases
        @pkg_directory     NVARCHAR(MAX) = 'C:\SSIS_Packages',
	   @sql_command       NVARCHAR(MAX),
	   @database_name     NVARCHAR(MAX),
	   @ssis_package_name NVARCHAR(MAX);

SET @search_text = @search_string;
SET @search_string = '%' + @search_string + '%';
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------

DECLARE @database TABLE
	  (database_name NVARCHAR(MAX), is_online BIT);
 
IF OBJECT_ID('tempdb.sys.#object_data') IS NOT NULL DROP TABLE #object_data;
 
CREATE TABLE #object_data
(
 server_name         NVARCHAR(MAX) NULL,
 database_name       NVARCHAR(MAX) NULL,
 schemaname          NVARCHAR(MAX) NULL,
 table_name          SYSNAME       NULL,
 object_type         SYSNAME       NULL,
 column_name         SYSNAME       NULL,
 objectname          SYSNAME       NULL,
 step_name           NVARCHAR(MAX) NULL,
 object_description  NVARCHAR(MAX) NULL,
 preview_text        NVARCHAR(MAX) NULL, --To show a little bit of the code
 objectdefinition    NVARCHAR(MAX) NULL,
 key_column_list     NVARCHAR(MAX) NULL,
 include_column_list NVARCHAR(MAX) NULL,
 xml_content         XML           NULL,
 text_content        NVARCHAR(MAX) NULL,
 enabled             BIT           NULL,
 status              NVARCHAR(MAX) NULL,
 search_type         NVARCHAR(50)  NULL
);
 
IF @database_id = 0 --To search all databases
BEGIN
     INSERT INTO @database
     (database_name, is_online)
     SELECT name,
            IIF(state = 0, 1, 0) AS is_online
       FROM sys.databases
      WHERE ISNULL(HAS_DBACCESS(name),0) = 1;
END
ELSE IF (@database_id > 0) --To search a specific database
BEGIN
     INSERT INTO @database
     (database_name, is_online)
     SELECT name,
            IIF(state = 0, 1, 0) AS is_online
       FROM sys.databases
      WHERE ISNULL(HAS_DBACCESS(name),0) = 1
	   AND database_id = @database_id;
END

/*******************
 SERVER WIDE SEARCH
*******************/
--Jobs
INSERT INTO #object_data
(server_name, objectname, object_description, enabled, search_type)
SELECT srvrs.name AS server_name,
       jobs.name AS job_name,
       jobs.description AS object_description,
       jobs.enabled,
       'SQL Agent Job' AS search_type
  FROM msdb.dbo.sysjobs AS jobs
       INNER JOIN master.sys.servers AS srvrs ON jobs.originating_server_id = srvrs.server_id
 WHERE jobs.name LIKE @search_string
    OR jobs.description LIKE @search_string
 ORDER BY 1, 2;

 --Job Steps
INSERT INTO #object_data
(server_name, objectname, step_name, object_description, objectdefinition, enabled, search_type, preview_text)
SELECT srvrs.name AS server_name,
       jobs.name AS job_name,
       jsteps.step_name,
       jobs.description AS object_description,
       jsteps.command AS objectdefinition,
       jobs.enabled,
       'SQL Agent Job Step' AS search_type,
	  REPLACE(
               REPLACE(
			        SUBSTRING(jsteps.command,
			                  CHARINDEX(@search_text, jsteps.command) - @preview_text_size/2,
						   @preview_text_size
						  ), 
				   CHAR(13) + CHAR(10),
				   ''
				  ),
			@search_text,
			'***' + @search_text + '***'
		    )
  FROM msdb.dbo.sysjobs AS jobs
       INNER JOIN msdb.dbo.sysjobsteps AS jsteps ON jobs.job_id = jsteps.job_id
       INNER JOIN master.sys.servers AS srvrs ON jobs.originating_server_id = srvrs.server_id
 WHERE jsteps.command LIKE @search_string
    OR jsteps.step_name LIKE @search_string
 ORDER BY 1, 2, 3;

--Databases
INSERT INTO #object_data
(objectname, search_type)
SELECT name AS database_name,
       'Database' AS search_type
  FROM sys.databases
 WHERE name LIKE @search_string
 ORDER BY 1;

--Logins
INSERT INTO #object_data
(objectname, search_type)
SELECT name AS login_name,
       'Server Login' AS search_type
  FROM sys.syslogins
 WHERE name LIKE @search_string
 ORDER BY 1;

--Linked Servers
INSERT INTO #object_data
(objectname, objectdefinition, search_type)
SELECT name AS server_name,
       data_source AS objectdefinition,
       'Linked Server' AS search_type
  FROM sys.servers
 WHERE name LIKE @search_string
    OR data_source LIKE @search_string
 ORDER BY 1;

--Server Triggers
INSERT INTO #object_data
(objectname, object_description, objectdefinition, search_type, preview_text)
SELECT STG.name AS trigger_name,
       parent_class_desc AS trigger_type,
       MDL.definition AS trigger_definition,
       'Server Trigger' AS search_type,
	  REPLACE(
               REPLACE(
			        SUBSTRING(MDL.definition,
			                  CHARINDEX(@search_text, MDL.definition) - @preview_text_size/2,
						   @preview_text_size
						  ), 
				   CHAR(13) + CHAR(10),
				   ''
				  ),
			@search_text,
			'***' + @search_text + '***'
		    )
  FROM sys.server_triggers AS STG
       INNER JOIN sys.server_sql_modules AS MDL ON STG.object_id = MDL.object_id
 WHERE STG.name LIKE @search_string
    OR MDL.definition LIKE @search_string;

--REPORTING SERVICES
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'ReportServer') AND @search_SSRS = 1
BEGIN
     --Reports
     INSERT INTO #object_data
     (objectname, objectdefinition, xml_content, text_content, search_type)    
     SELECT CTG.Name AS SSRS_object_name,
		  CTG.Path AS SSRS_object_path,
            CONVERT(XML, CONVERT(VARBINARY(MAX), CTG.content)) AS xml_content,
            CONVERT(NVARCHAR(MAX), CONVERT(XML, CONVERT(VARBINARY(MAX), CTG.content))) AS text_content,
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
         OR SCR.DataSettings LIKE @search_string
         OR SCR.ExtensionSettings LIKE @search_string
         OR SCR.Description LIKE @search_string;
     
     --Subscriptions
     INSERT INTO #object_data
     (object_description, objectdefinition, text_content, status, search_type)
     SELECT Description AS subscription_description,
            ExtensionSettings AS subscription_details,              
            DeliveryExtension AS subscription_delivery_method,
            LastStatus AS subscription_status,
            'SSRS Subscription' AS search_type
       FROM ReportServer.dbo.Subscriptions
      WHERE ExtensionSettings LIKE @search_string
         OR Description LIKE @search_string
         OR DataSettings LIKE @search_string;
END

--INTEGRATION SERVICES
--Search MSDB
IF @search_SSIS_MSDB = 1
BEGIN    
     ;WITH CTE_SSIS
      AS 
     (
     SELECT PF.foldername + '\' + PKG.name AS full_path,
            CONVERT(XML, CONVERT(VARBINARY(MAX), PKG.packagedata)) AS package_details_XML,
            CONVERT(NVARCHAR(MAX), CONVERT(XML, CONVERT(VARBINARY(MAX), PKG.packagedata))) AS package_details_text,
            'SSIS Package (MSDB)' AS search_type
       FROM msdb.dbo.sysssispackages AS PKG
            INNER JOIN msdb.dbo.sysssispackagefolders AS PF ON PKG.folderid = PF.folderid
     )
     INSERT INTO #object_data
     (object_description, xml_content, text_content, search_type)
     SELECT *
       FROM CTE_SSIS
      WHERE package_details_text LIKE @search_string
         OR full_path LIKE @search_string;
END

--Search Disk
IF @search_SSIS_disk = 1
BEGIN
     CREATE TABLE ##ssis_data
     (  
     full_path	           NVARCHAR(MAX),
     package_details_XML  XML,
     package_details_text NVARCHAR(MAX) 
     );
     
     SELECT @sql_command = 'dir "' + @pkg_directory + '" /A-D /B /S ';
     
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
      
     INSERT INTO #object_data
     (object_description, xml_content, text_content, search_type)
     SELECT *,
            'SSIS Package (File System)' AS search_type
       FROM ##ssis_data AS SSIS_DATA
      WHERE package_details_text LIKE @search_string
         OR full_path LIKE @search_string;
      
     DROP TABLE ##ssis_data;
END

/*******************
 SEARCH BY DATABASE
*******************/
--Iterate through databases to retrieve database object metadata
DECLARE DBCURSOR CURSOR FOR
SELECT database_name FROM @database WHERE is_online = 1;
OPEN DBCURSOR;
FETCH NEXT FROM DBCURSOR INTO @database_name;
 
WHILE @@FETCH_STATUS = 0
BEGIN
     SELECT @sql_command = '
     
     USE [' + @database_name + '];
     SET NOCOUNT ON;
     
     --Schemas
     INSERT INTO #object_data
     (database_name, schemaname, search_type)
     SELECT DB_NAME() AS database_name,
            schemas.name AS schemaname,
            ''Schema'' AS search_type
       FROM sys.schemas
      WHERE schemas.name LIKE ''' + @search_string + '''
      ORDER BY 2;
     
     --Tables
     INSERT INTO #object_data
     (database_name, schemaname, table_name, search_type)
     SELECT DB_NAME() AS database_name,
            SS.name AS schemaname,
            ST.name AS table_name,
            ''Table'' AS search_type
       FROM sys.tables AS ST
            INNER JOIN sys.schemas AS SS ON ST.schema_id = SS.schema_id
      WHERE ST.name LIKE ''' + @search_string + '''
      ORDER BY 2, 3;
     
     --Columns
     INSERT INTO #object_data
     (database_name, schemaname, table_name, object_type, column_name, search_type)
     SELECT DB_NAME() AS database_name,
            SS.name AS schemaname,
            IIF(SO.type = ''TT'', STT.name, SO.name) AS table_name,
      	  SO.type_desc AS object_type,
      	  SC.name AS column_name,
     	  ''Column'' AS search_type
       FROM sys.columns AS SC
            LEFT JOIN sys.objects AS SO ON SC.object_id = SO.object_id
     	                             AND SO.type IN (''TT'', ''U'', ''V'')
      	  LEFT JOIN sys.table_types AS STT ON SC.object_id = STT.type_table_object_id
            INNER JOIN sys.schemas AS SS ON IIF(SO.type = ''TT'', STT.schema_id, SO.schema_id) = SS.schema_id
      WHERE SC.name LIKE ''' + @search_string + '''
      ORDER BY 2, 4, 3, SC.column_id;
     
     --Synonyms
     INSERT INTO #object_data
     (database_name, objectname, objectdefinition, search_type)
     SELECT DB_NAME() AS database_name,
            name AS synonym_name,
            base_object_name,
            ''Synonym'' AS search_type
       FROM sys.synonyms
      WHERE name LIKE ''' + @search_string + '''
         OR base_object_name LIKE ''' + @search_string + '''
      ORDER BY 2;
     
     --Service Broker Queues
     INSERT INTO #object_data
     (database_name, objectname, search_type)
     SELECT DB_NAME() AS database_name,
            name,
            ''Queue'' AS search_type
       FROM sys.service_queues
      WHERE name LIKE ''' + @search_string + '''
      ORDER BY 1;
     
     --Table Types
     INSERT INTO #object_data
     (database_name, objectname, search_type)
     SELECT DB_NAME() AS database_name,
            name AS table_type_name,
            ''Table Type'' AS search_type
       FROM sys.table_types
      WHERE name LIKE ''' + @search_string + '''
      ORDER BY 1;
     
     --Types
     INSERT INTO #object_data
     (database_name, objectname, search_type)
     SELECT DB_NAME() AS database_name,
            name,
            ''Types'' AS search_type 
       FROM sys.types
      WHERE is_user_defined = 1
        AND name LIKE ''' + @search_string + '''
      ORDER BY 2;
     
     --Indexes
     INSERT INTO #object_data
     (database_name, schemaname, table_name, object_type, objectname, search_type)
     SELECT DB_NAME() AS database_name,
            SS.name AS schemaname,
            IIF(SO.type = ''TT'', STT.name, SO.name) AS table_name,
     	  SO.type_desc AS object_type,
     	  SI.name AS index_name,
     	  ''Index'' AS search_type
       FROM sys.indexes AS SI
            INNER JOIN sys.objects AS SO ON SI.object_id = SO.object_id	  
     	  LEFT JOIN sys.table_types AS STT ON SO.object_id = STT.type_table_object_id
     	  INNER JOIN sys.schemas AS SS ON IIF(SO.type = ''TT'', STT.schema_id, SO.schema_id) = SS.schema_id
      WHERE SI.type > 0
        AND SO.type IN (''TT'', ''U'')
        AND SI.name LIKE ''' + @search_string + '''
      ORDER BY 2, 4 DESC, 3, SI.type;
     
     --Index Columns
     ;WITH CTE_INDEX_COLUMNS
      AS 
     (
     SELECT DB_NAME() AS database_name,
            TBL.name AS table_name,
            IDX.name AS index_name,
            STUFF(
                  (SELECT '', '' + SC.name
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
                     FOR XML PATH('''')
                  ), 1, 2, ''''
     		  ) AS key_column_list,
            STUFF(
                  (SELECT '', '' + SC.name
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
                     FOR XML PATH('''')
                  ), 1, 2, ''''
     		  ) AS include_column_list,
            ''Index Column'' AS search_type
       FROM sys.indexes AS IDX
            INNER JOIN sys.tables AS TBL ON TBL.object_id = IDX.object_id
      WHERE IDX.type > 0
     )
     INSERT INTO #object_data
     (database_name, table_name, objectname, key_column_list, include_column_list, search_type)
     SELECT database_name,
            table_name,
            index_name,
            key_column_list,
            ISNULL(include_column_list, '''') AS include_column_list,
     	  search_type
       FROM CTE_INDEX_COLUMNS
      WHERE CTE_INDEX_COLUMNS.key_column_list LIKE ''' + @search_string + '''
         OR CTE_INDEX_COLUMNS.include_column_list LIKE ''' + @search_string + '''
      ORDER BY 2, 3;
     
     --Foreign Keys
     INSERT INTO #object_data
     (database_name, schemaname, table_name, objectname, search_type)
     SELECT DB_NAME() AS database_name,
            SS.name AS schemaname,
            SO.name AS parent_table,
            FK.name AS foreign_key_name,
            ''Foreign Key'' AS search_type
       FROM sys.foreign_keys AS FK
            INNER JOIN sys.schemas AS SS ON FK.schema_id = SS.schema_id
            INNER JOIN sys.objects AS SO ON SO.object_id = FK.parent_object_id
      WHERE FK.name LIKE ''' + @search_string + '''
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
                  (SELECT '', '' + referencing_column.name
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
                      FOR XML PATH('''')
                  ), 1, 2, ''''
                 ) AS foreign_key_column_list,
            STUFF(
                  (SELECT '', '' + referenced_column.name
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
                      FOR XML PATH('''')
                  ), 1, 2, ''''
                 ) AS referenced_column_list,
            ''Foreign Key Column'' AS search_type
       FROM sys.foreign_keys AS FK
            INNER JOIN sys.tables AS parent_table ON FK.parent_object_id = parent_table.object_id
            INNER JOIN sys.schemas AS parent_schema ON parent_schema.schema_id = parent_table.schema_id
            INNER JOIN sys.tables AS referenced_table ON referenced_table.object_id = FK.referenced_object_id
            INNER JOIN sys.schemas AS referenced_schema ON referenced_schema.schema_id = referenced_table.schema_id
     )' + '
     INSERT INTO #object_data
     (database_name, schemaname, table_name, objectname, key_column_list, search_type)
     SELECT database_name,
            parent_schema + '' --> '' + referenced_schema,
     	  parent_table + '' --> '' + referenced_table,
     	  foreign_key_name,
     	  foreign_key_column_list + '' --> '' + referenced_column_list AS key_column_list,
     	  search_type
       FROM CTE_FOREIGN_KEY_COLUMNS
      WHERE foreign_key_column_list LIKE ''' + @search_string + '''
         OR referenced_column_list LIKE ''' + @search_string + '''
      ORDER BY 2, 3, 4, 5;
     
     --Default Constraints
     INSERT INTO #object_data
     (database_name, schemaname, table_name, object_type, column_name, objectname, objectdefinition, search_type)
     SELECT DB_NAME() AS database_name,            
            SS.name AS parent_schema_name,
            IIF(SO.type = ''TT'', STT.name, OBJECT_NAME(DC.parent_object_id)) AS parent_object_name,
     	  SO.type_desc AS object_type,
            SC.name AS parent_column_name,
     	  DC.name AS default_constraint_name,            
            DC.definition AS default_definition,
            ''Default Constraint'' AS search_type
       FROM sys.default_constraints AS DC
            INNER JOIN sys.objects AS SO ON DC.parent_object_id = SO.object_id
            INNER JOIN sys.columns AS SC ON DC.object_id = SC.default_object_id
                                        AND DC.parent_column_id = SC.column_id
            LEFT JOIN sys.table_types AS STT ON DC.parent_object_id = STT.type_table_object_id
            INNER JOIN sys.schemas AS SS ON IIF(SO.type = ''TT'', STT.schema_id, SO.schema_id) = SS.schema_id
      WHERE DC.name LIKE ''' + @search_string + '''
         OR DC.definition LIKE ''' + @search_string + '''
      ORDER BY 2, 5, 3;
     
     --Check Constraints
     INSERT INTO #object_data
     (database_name, schemaname, table_name, object_type, objectname, objectdefinition, search_type, preview_text)
     SELECT DB_NAME() AS database_name,
            SS.name AS schemaname,                    
            IIF(SO.type = ''TT'', STT.name, OBJECT_NAME(CC.parent_object_id)) AS objectname,
            SO.type_desc AS object_type,
     	  CC.name AS check_constraint_name,
            CC.definition AS check_definition,
            ''Check Constraint'' AS search_type,
            REPLACE(REPLACE(SUBSTRING(CC.definition, CHARINDEX(''' + @search_text + ''', CC.definition) - ' + CAST(@preview_text_size / 2 AS NVARCHAR) + ', ' + 
            CAST(@preview_text_size AS NVARCHAR) + '), CHAR(13) + CHAR(10), ''''), ''' + @search_text + ''', ''***' + @search_text + '***'')
       FROM sys.check_constraints AS CC
            INNER JOIN sys.objects AS SO ON CC.parent_object_id = SO.object_id
            LEFT JOIN sys.table_types AS STT ON CC.parent_object_id = STT.type_table_object_id
            INNER JOIN sys.schemas AS SS ON IIF(SO.type = ''TT'', STT.schema_id, SO.schema_id) = SS.schema_id
      WHERE CC.name LIKE ''' + @search_string + '''
        AND CC.definition LIKE ''' + @search_string + '''
      ORDER BY 2, 4, 3;
     
     --DDL Triggers
     INSERT INTO #object_data
     (database_name, objectname, object_description, objectdefinition, search_type, preview_text)
     SELECT DB_NAME() AS database_name,
            TGR.name AS trigger_name,
            TGR.parent_class_desc AS trigger_type,
            MDL.definition AS trigger_definition,
            ''Database DDL Trigger'' AS search_type,
            REPLACE(REPLACE(SUBSTRING(MDL.definition, CHARINDEX(''' + @search_text + ''', MDL.definition) - ' + CAST(@preview_text_size / 2 AS NVARCHAR) + ', ' + 
            CAST(@preview_text_size AS NVARCHAR) + '), CHAR(13) + CHAR(10), ''''), ''' + @search_text + ''', ''***' + @search_text + '***'')
       FROM sys.triggers AS TGR
            INNER JOIN sys.sql_modules AS MDL ON TGR.object_id = MDL.object_id
      WHERE TGR.parent_class_desc = ''DATABASE''
        AND (TGR.name LIKE ''' + @search_string + ''' OR MDL.definition LIKE ''' + @search_string + ''');
     
     --Stored Procedures, Views, Functions, Rules, and Triggers
     INSERT INTO #object_data
     (database_name, schemaname, table_name, objectname, objectdefinition, search_type, preview_text)
     SELECT DB_NAME() AS database_name,            
            parent_schema.name AS parent_schema_name,
            parent_object.name AS parent_object_name,
     	  child_object.name AS objectname,
            MDL.definition AS objectdefinition,
            child_object.type_desc AS search_type,
            REPLACE(REPLACE(SUBSTRING(MDL.definition, CHARINDEX(''' + @search_text + ''', MDL.definition) - ' + CAST(@preview_text_size / 2 AS NVARCHAR) + ', ' + 
            CAST(@preview_text_size AS NVARCHAR) + '), CHAR(13) + CHAR(10), ''''), ''' + @search_text + ''', ''***' + @search_text + '***'')
       FROM sys.sql_modules AS MDL
            INNER JOIN sys.objects AS child_object ON MDL.object_id = child_object.object_id
            LEFT JOIN sys.objects AS parent_object ON parent_object.object_id = child_object.parent_object_id
            LEFT JOIN sys.schemas AS parent_schema ON parent_object.schema_id = parent_schema.schema_id
      WHERE child_object.name LIKE ''' + @search_string + '''
         OR MDL.definition LIKE ''' + @search_string + '''
      ORDER BY child_object.type_desc;'

     IF @debug_sql = 1
	   PRINT @sql_command
     ELSE
        EXEC sp_executesql @sql_command;
     
	FETCH NEXT FROM DBCURSOR INTO @database_name;
END
 
CLOSE DBCURSOR;
DEALLOCATE DBCURSOR;

SELECT server_name,
       database_name,
       schemaname,
       table_name,	  
	  search_type,
	  object_type,
       column_name,
       objectname,
       step_name,
       object_description,
	  preview_text,
       objectdefinition,
       key_column_list,
       include_column_list,
       xml_content,
       text_content,
       enabled,
       status       
  FROM #object_data
 WHERE 1 = 1;

--SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET NOCOUNT OFF;