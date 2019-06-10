/****************************************************************
To DROP the constraints before firing the TRUNCATE 
when there are Foreign Key references present for that table
****************************************************************/
DECLARE @stmt VARCHAR(8000),
	   @rowcnt INT;
	   
IF OBJECT_ID('tempdb..#Dropping_Constraints') IS NOT NULL DROP TABLE #Dropping_Constraints;

CREATE TABLE #Dropping_Constraints
(
Cmd VARCHAR(8000)
);

INSERT INTO #Dropping_Constraints
SELECT 'ALTER TABLE [' +
	   t2.Table_Schema + '.' +
	   t2.Table_Name +
	   '] DROP CONSTRAINT ' +
	   t1.Constraint_Name
  FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS t1
       INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE t2 ON t1.CONSTRAINT_NAME = t2.CONSTRAINT_NAME
 WHERE t2.TABLE_NAME = 'Your_tablename_goes_here'; --Table_name in which the foreign key is present.

SELECT TOP 1 @stmt = Cmd FROM #Dropping_Constraints;
SET @rowcnt = @@ROWCOUNT;

WHILE @rowcnt <> 0
BEGIN
	EXEC (@stmt);
	SET @stmt = 'DELETE FROM #Dropping_Constraints WHERE cmd = ' + QUOTENAME(@stmt,'''');
	EXEC (@stmt);
	SELECT TOP 1 @stmt = Cmd FROM #Dropping_Constraints;
	SET @rowcnt = @@ROWCOUNT;
END

DROP TABLE #Dropping_Constraints;