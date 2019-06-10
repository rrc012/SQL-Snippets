USE HPG_EDV
GO

/*
 ======================================================================
 Author:	    Jeffrey Yao
 Source:      https://www.mssqltips.com/sqlservertip/4059/script-to-delete-data-from-sql-server-tables-with-foreign-key-constraints/#comments
 Create Date: 15-OCT-2015
 Description: This Stored Procedure identifies tables referred by foreign keys 
              and list of the multiple tables again referenced by other tables 
		    via FKs. However, this proc cannot handle tables with self-referencing FKs
 Usage:       EXEC dbo.USP_SearchFK 'ORG.FACILITY_H';
 Revision History:
 03-MAR-2016 - RAGHUNANDAN CUMBAKONAM Renamed the SP
			Formatted the code
 ======================================================================
*/

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'USP_SearchFK' AND SCHEMA_NAME(schema_id) = 'dbo' AND type = 'P')
BEGIN
	 DROP PROC dbo.USP_SearchFK;
END
GO

CREATE PROC dbo.USP_SearchFK 
            @table VARCHAR(256), -- use two part name convention
            @lvl TINYINT = 0, -- do not change
            @ParentTable VARCHAR(256) = '', -- do not change
            @debug BIT = 1
AS

BEGIN
	SET NOCOUNT ON;

	DECLARE @dbg BIT = @debug,
	        @curS cursor;

	IF object_id('tempdb..#tbl', 'U') IS NULL
	CREATE TABLE #tbl 
	(
	 Id TINYINT IDENTITY, 
	 TableName VARCHAR(256), 
	 Level TINYINT, 
	 ParentTable VARCHAR(256)
	);

	INSERT INTO #tbl (TableName, Level, ParentTable)
	SELECT @table, @lvl, IIF(@lvl = 0, NULL, @ParentTable);

	IF @dbg = 1	
		PRINT REPLICATE('----', @lvl) + 'lvl ' + CAST(@lvl AS VARCHAR(10)) + ' = ' + @table;
	
	IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE referenced_object_id = object_id(@table))
		RETURN;
	ELSE
	     BEGIN --ELSE
	     	SET @ParentTable = @table;
	     
	     	SET @curS = cursor for
	     	SELECT tablename = OBJECT_SCHEMA_NAME(parent_object_id) + '.' + OBJECT_NAME(parent_object_id)
	     	  FROM sys.foreign_keys 
	     	 WHERE referenced_object_id = object_id(@table)
	     	   AND parent_object_id <> referenced_object_id; --ADD THIS TO PREVENT SELF-REFERENCING WHICH CAN CREATE AN INDEFINITIVE LOOP;
	     
	     	OPEN @curS;
	     	FETCH NEXT FROM @curS INTO @table;
	     
	     	WHILE @@fetch_status = 0
	     	BEGIN --WHILE
	     		SET @lvl += 1;
	     		--RECURSIVE CALL
	     		EXEC dbo.usp_SearchFK @table, @lvl, @ParentTable, @dbg;
	     		SET @lvl = @lvl-1;
	     		FETCH NEXT FROM @curS INTO @table;
	     	END --WHILE
	     
	     	CLOSE @curS;
	     	DEALLOCATE @curS;
	     
	     END --ELSE

	IF @lvl = 0
		SELECT *,
		       CONCAT('DELETE ', TableName, ';') AS Delete_Order
		  FROM #tbl
		 ORDER BY Level DESC;
	RETURN;

     SET NOCOUNT OFF
      
END --End of SP Block