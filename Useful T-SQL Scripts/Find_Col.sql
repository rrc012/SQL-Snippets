USE [master]
GO

DECLARE @DBName      VARCHAR(50),
        @ColName     VARCHAR(50),
        @Denied_DB   BIT,
        @Search_Type BIT,
        @Data_Type   VARCHAR(30),
        @Row_Count   INT,
        @sql         NVARCHAR(MAX),
        @Where       VARCHAR(100);

SET @DBName = NULL;
SET @Denied_DB = 1; --When 1 display the names of databases on which access is denied
SET @Search_Type = NULL; --(0--->Particular Column, 1--->Particular DataType, NULL--->0&1)
SET @ColName = 'State';
SET @Data_Type = 'CHAR';

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;

IF @Search_Type = 0 
	SET @Where = 'WHERE SC.name = ' + QUOTENAME(@ColName, '''')
ELSE IF @Search_Type = 1 
	SET @Where = 'WHERE SDT.name = ' + QUOTENAME(@Data_Type, '''')
ELSE 
	SET @Where = 'WHERE SC.name = ' + QUOTENAME(@ColName, '''')+ ' AND SDT.name = ' + QUOTENAME(@Data_Type, '''');

IF OBJECT_ID('tempdb..#FoundObject') IS NOT NULL DROP TABLE #FoundObject;
CREATE TABLE #Foundobject
(
 Database_Name SYSNAME,
 Table_Name    SYSNAME,
 Column_Name   SYSNAME,
 Data_Type     SYSNAME
);

IF @DBName IS NULL --Loop through all normal user databases
BEGIN
	DECLARE ObjCursor CURSOR LOCAL FAST_FORWARD FOR 
		SELECT [Name]
		  FROM master.sys.databases
		 WHERE [Name] NOT IN ('AdventureWorks', 'AdventureWorksDW', 'Distribution', 'master', 'msdb', 'model', 'tempdb','LiteSpeed')
		   AND ISNULL(HAS_DBACCESS([Name]),0) = 1
		 ORDER BY [Name];

	OPEN ObjCursor;

	FETCH NEXT FROM ObjCursor INTO @DBName;
	WHILE @@Fetch_Status = 0
	BEGIN
		SET @sql = '		
		SELECT ''' + @DBName + ''' AS Database_Name,
			  ST.name AS Table_Name,
			  SC.name AS Column_Name,
			  CASE WHEN SDT.name LIKE ''%CHAR'' THEN SDT.name + QUOTENAME(CONVERT(VARCHAR(10),SC.max_length),' + ''')'')' + '
				  WHEN SDT.name IN (''decimal'',''numeric'',''float'',''real'',''money'')' + '
				  THEN SDT.name + QUOTENAME(CONVERT(VARCHAR(10), SC.precision) + ' + ''', ''' + ' + CONVERT(VARCHAR(10), SC.scale),' + ''')'')' + '
				  ELSE SDT.name' + '
			  END AS Data_Type		
		  FROM ['+@DBName+'].sys.tables AS ST
		       INNER JOIN ['+@DBName+'].sys.columns AS SC ON ST.Object_ID = SC.Object_ID
		       INNER JOIN ['+@DBName+'].sys.types AS SDT ON SC.system_type_id = SDT.system_type_id' + CHAR(10) + SPACE(8) +
		@Where + CHAR(10) + SPACE(8) +
		'ORDER BY 2,3;' --PRINT @sql
		
		INSERT INTO #FoundObject 
		(
		Database_Name,
		Table_Name,
		Column_Name,
		Data_Type
		)
		EXEC (@SQL)

		FETCH NEXT FROM ObjCursor INTO @DBName;
	END;

	CLOSE ObjCursor;

	DEALLOCATE ObjCursor;
END
ELSE --Only look through given database
BEGIN
		SET @sql = '
		SELECT ''' + @DBName + ''' AS Database_Name,
			  ST.name AS Table_Name,
			  SC.name AS Column_Name,
			  CASE WHEN SDT.name LIKE ''%CHAR'' THEN SDT.name + QUOTENAME(CONVERT(VARCHAR(10),SC.max_length),' + ''')'')' + '
				  WHEN SDT.name IN (''decimal'',''numeric'',''float'',''real'',''money'')' + '
				  THEN SDT.name + QUOTENAME(CONVERT(VARCHAR(10), SC.precision) + ' + ''', ''' + ' + CONVERT(VARCHAR(10), SC.scale),' + ''')'')' + '
				  ELSE SDT.name' + '
			  END AS Data_Type		
		  FROM ['+@DBName+'].sys.tables AS ST
		       INNER JOIN ['+@DBName+'].sys.columns AS SC ON ST.Object_ID = SC.Object_ID
		       INNER JOIN ['+@DBName+'].sys.types AS SDT ON SC.system_type_id = SDT.system_type_id' + CHAR(10) + SPACE(8) +
		@Where + CHAR(10) + SPACE(8) +
		'ORDER BY 2,3;' --PRINT @sql

		INSERT INTO #FoundObject 
		(
		Database_Name,
		Table_Name,
		Column_Name,
		Data_Type
		)
		EXEC (@SQL)
END		
		SELECT Database_Name,
	            Table_Name,
	            Column_Name,
			  Data_Type
		  FROM #FoundObject

IF @Denied_DB = 1
BEGIN
		SELECT @Row_Count = COUNT(*)
		  FROM master.sys.databases
		 WHERE [Name] NOT IN ('AdventureWorks', 'AdventureWorksDW', 'Distribution', 'master', 'msdb', 'model', 'tempdb','LiteSpeed')
		   AND ISNULL(HAS_DBACCESS([Name]),0) = 0

	    IF @Row_Count = 0 
		BEGIN 
			SELECT SYSTEM_USER + ' user has access on all the available user-defined databases.' AS 'Denied Databases' 
			SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
			SET NOCOUNT OFF			
			RETURN 
		END
        
		INSERT INTO #FoundObject 
		(
		Database_Name,
		Table_Name,
		Column_Name,
		Data_Type
		)
		SELECT [Name],
			  'Database Access Denied' AS Table_Name,
			  'Database Access Denied' AS Column_Name,
			  'Database Access Denied' AS Data_Type
		  FROM master.sys.databases
		 WHERE [Name] NOT IN ('AdventureWorks', 'AdventureWorksDW', 'Distribution', 'master', 'msdb', 'model', 'tempdb','LiteSpeed')
		   AND ISNULL(HAS_DBACCESS([Name]),0) = 0
		 ORDER BY [Name]
		
		SELECT Database_Name,
			   Table_Name,
			   Column_Name,
			   Data_Type
		  FROM #FoundObject
		 WHERE ISNULL(HAS_DBACCESS([Database_Name]),0) = 0
END

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET NOCOUNT OFF;