/*
 ===============================================================================
 Author      :	AARON BERTRAND
 Source      : https://stackoverflow.com/questions/18138464/list-all-columns-referenced-in-all-procedures-of-all-databases
 Article Name: List all columns referenced in all procedures of all databases.
 Create Date : 09-AUG-2013
 Description : This script either loops through all the user defined databses
               or a the given list of databases and retrieves the list of all
               columns referenced in all the procedures.

 Revision History:
 27-AUG-2019 - RAGHUNANDAN CUMBAKONAM
               1. Added the logic to specify a CSV list of databases.
               2. Parametrized the Dynamic SQL by adding the "Procname" as the parameter.		   
 ===============================================================================
*/

USE master
GO

SET NOCOUNT ON;

/********************************************
-----DECLARE & CONFIGURE VARIABLES HERE------
********************************************/
DECLARE @sDBNamesList VARCHAR(1000) = 'HPG_EDW_Stg_GHX', --IF NULL/BLANK, LOOP THROUGH ALL THE USER DEFINED DATABASES, ELSE LOOP THROUGH THE LIST OF GIVEN DATABASES. ENTER A COMMA-SEPARATED LIST OF JOB NAMES.
        @sProcName NVARCHAR(100) = 'Contract_FF_Get_v5',--IF NULL, LOOP THROUGH ALL THE PROCS, ELSE RETRIEVE INFO RELATED TO THE SPECIFIC PROC.
        @sDynamicSQL NVARCHAR(MAX) = N'',
        @bExecuteSQL BIT = 1,
        @iCharPosition TINYINT;
/*******************************************
--------END OF CONFIGURING VARIABLES--------
*******************************************/

--Used to hold the list of User Defined Database names to loop through
IF OBJECT_ID('tempdb..#DBNamesList') IS NOT NULL DROP TABLE #DBNamesList;
CREATE TABLE #DBNamesList 
(
 [database_name] VARCHAR(128) NOT NULL
);

--Process list
SET @sDBNamesList = CONCAT(@sDBNamesList, ',');

WHILE CHARINDEX(',', @sDBNamesList) > 0
BEGIN
	SET @iCharPosition = CHARINDEX(',', @sDBNamesList);
	INSERT INTO #DBNamesList ([database_name])
	SELECT LTRIM(RTRIM(LEFT(@sDBNamesList, @iCharPosition - 1)));
	SET @sDBNamesList = STUFF(@sDBNamesList, 1, @iCharPosition, '');
END  -- While loop

--SELECT * FROM #DBNamesList;

SELECT @sDynamicSQL  = @sDynamicSQL + CHAR(13) + N' UNION ALL
SELECT [database]    = ''' + REPLACE(sd.name, '''', '''''') + ''',
       [stored_proc] = QUOTENAME(s.name) + ''.'' + QUOTENAME(p.name) COLLATE Latin1_General_CI_AI, 
       [table]       = QUOTENAME(referenced_schema_name) + ''.'' + QUOTENAME(referenced_entity_name) COLLATE Latin1_General_CI_AI,
       [column]      = QUOTENAME(referenced_minor_name) COLLATE Latin1_General_CI_AI
  FROM ' + QUOTENAME(sd.name) + '.sys.schemas AS s
       INNER JOIN ' + QUOTENAME(sd.name) + '.sys.procedures AS p ON s.[schema_id] = p.[schema_id]
       CROSS APPLY ' + QUOTENAME(sd.name) + '.sys.dm_sql_referenced_entities'+ '(QUOTENAME(s.name) + ''.'' + QUOTENAME(p.name), N''OBJECT'') AS d
 WHERE d.referenced_minor_id > 0
   AND p.name = COALESCE(@sProcName, p.name)'
  FROM sys.databases AS sd
       INNER JOIN #DBNamesList AS dnl ON sd.name = IIF(dnl.[database_name] > '', dnl.[database_name], sd.name)
 WHERE 1 = 1
   AND sd.database_id > 4
   AND sd.[state] = 0
 ORDER BY sd.name;

SET @sDynamicSQL = STUFF(@sDynamicSQL, 1, 11, '') + CHAR(13) + ' ORDER BY 1, 2, 3, 4;';

IF (@bExecuteSQL = 1)
    EXEC sp_executesql @sDynamicSQL, N'@sProcName NVARCHAR(100)', @sProcName;
ELSE
    --PRINT @sDynamicSQL;
    SELECT @sDynamicSQL FOR XML PATH('x');