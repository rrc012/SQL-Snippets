USE [master]
GO

DECLARE @DBName VARCHAR(50) = NULL
	   ,@TblName VARCHAR(200) = 'LU_Vendor_Family'
	   ,@sql NVARCHAR(MAX)
	   ,@Whr VARCHAR(50)
	   ,@WhrType BIT = 0
	   ,@Debug BIT = 0;

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#FoundObject') IS NOT NULL DROP TABLE #FoundObject
CREATE TABLE #FoundObject 
	(
	  Database_Name SYSNAME
	 ,Sch_Name SYSNAME
	 ,Table_Name SYSNAME
	)

IF @WhrType = 0
	BEGIN
		SET @Whr = CHAR(10) + SPACE(11) + 'AND ST.name = ' + QUOTENAME(@TblName, '''')
	END
ELSE
	BEGIN
		SET @Whr = CHAR(10) + SPACE(11) + 'AND ST.name LIKE ' + QUOTENAME('%' + @TblName + '%', '''')
	END

IF @DBName IS NULL --Loop through all normal user databases
	BEGIN
		DECLARE ObjCursor CURSOR LOCAL FAST_FORWARD FOR 
			SELECT [Name]
			  FROM master.sys.databases
			 WHERE owner_sid != 0x01
			   AND ISNULL(HAS_DBACCESS([Name]),0) = 1
			 ORDER BY [Name];

		OPEN ObjCursor;

		FETCH NEXT FROM ObjCursor INTO @DBName;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @sql = N'
			SELECT ' + QUOTENAME(@DBName, '''') + ' AS DB_Name
			      ,SS.name AS Sch_Name
				  ,ST.name AS Table_Name
			  FROM ' + QUOTENAME(@DBName, '[') + '.sys.tables AS ST
			       INNER JOIN ' + QUOTENAME(@DBName, '[') + '.sys.schemas AS SS ON ST.schema_id = SS.schema_id
			 WHERE 1 = 1 ' + @Whr

			IF @Debug = 1
				BEGIN
					PRINT @sql
				END
			ELSE
				BEGIN
					INSERT INTO #FoundObject 
					(
					Database_Name,
					Sch_Name,
					Table_Name
					)
					EXEC sp_executesql @SQL;
				END
							
			FETCH NEXT FROM ObjCursor INTO @DBName;
		END;

		CLOSE ObjCursor;

		DEALLOCATE ObjCursor;
	END
ELSE --Only look through given database
	BEGIN
			SET @sql = N'
			SELECT ' + QUOTENAME(@DBName, '''') + ' AS DB_Name
			      ,SS.name AS Sch_Name
				  ,ST.name AS Table_Name
			  FROM ' + QUOTENAME(@DBName, '[') + '.sys.tables AS ST
			       INNER JOIN ' + QUOTENAME(@DBName, '[') + '.sys.schemas AS SS ON ST.schema_id = SS.schema_id
			 WHERE 1 = 1 ' + @Whr

			IF @Debug = 1
				BEGIN
					PRINT @sql
				END
			ELSE
				BEGIN
					INSERT INTO #FoundObject 
					(
					Database_Name,
					Sch_Name,
					Table_Name
					)
					EXEC sp_executesql @SQL;
				END
	END
			
SELECT Database_Name
	  ,Sch_Name
	  ,Table_Name
  FROM #FoundObject
 ORDER BY 1, 3, 2