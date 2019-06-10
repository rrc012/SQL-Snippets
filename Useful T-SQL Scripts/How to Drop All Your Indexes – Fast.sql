/*
 ===============================================================================
 Author:	     Brent Ozar
 Source:       https://www.brentozar.com/archive/2017/08/drop-indexes-fast/
 Article Name: How to Drop All Your Indexes – Fast
 Create Date:  11-AUG-2017
 Description:  This script drops all the nonclustered indexes on a database.	
 Revision History:
 20-SEP-2017 - RAGHUNANDAN CUMBAKONAM
			Formatted the code.
			Added the history.
 Usage:		EXEC dbo.DropIndexes;
 ===============================================================================
*/

CREATE PROCEDURE dbo.DropIndexes
AS
SET NOCOUNT ON

DECLARE @CurrentCommand NVARCHAR(2000);

CREATE TABLE #commands 
(
 ID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
 Command NVARCHAR(2000)
);

INSERT INTO #commands (Command)
SELECT 'DROP INDEX ' + i.name + ' ON ' + s.name + '.' + t.name + ';'
  FROM sys.tables t
       INNER JOIN sys.indexes i ON t.object_id = i.object_id
       INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
 WHERE i.type = 2; --NONCLUSTERED

INSERT INTO #commands (Command)
SELECT 'DROP STATISTICS ' + SCHEMA_NAME(t.schema_id) + '.'  + OBJECT_NAME(s.object_id) + '.' + s.name
  FROM sys.stats AS s
       INNER JOIN sys.tables AS t ON s.object_id = t.object_id
 WHERE s.name LIKE '[_]WA[_]Sys[_]%'
   AND OBJECT_NAME(s.object_id) NOT LIKE 'sys%';

DECLARE result_cursor CURSOR FOR
SELECT Command FROM #commands;

OPEN result_cursor
FETCH NEXT FROM result_cursor INTO @CurrentCommand
WHILE @@FETCH_STATUS = 0
BEGIN 
  EXEC(@CurrentCommand);
  FETCH NEXT FROM result_cursor into @CurrentCommand
END
--end loop

--clean up
CLOSE result_cursor;
DEALLOCATE result_cursor;
GO