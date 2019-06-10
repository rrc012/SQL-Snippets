IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'usp_FlushRecords_AllTables' AND xtype = 'P')
BEGIN
	 DROP PROC usp_FlushRecords_AllTables
END
GO

CREATE PROCEDURE usp_FlushRecords_AllTables
AS
BEGIN

/*
 ===============================================================
 Author:      VADIVEL MOHANAKRISHNAN
 Source:      http://vadivel.blogspot.com/2006/07/easiest-fastest-way-to-delete-all.html
 Create Date: 09-FEB-2012
 Description: This stored proc Deletes/Truncates ALL records 
			  within ALL the tables in a DB with ease.
 Usage:       EXEC usp_FlushRecords_AllTables 
 ===============================================================
*/

SET NOCOUNT ON

EXEC sp_MSForEachTable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'

EXEC sp_MSForEachTable '
DECLARE @MSG nvarchar(4000)
IF ObjectProperty(Object_ID(''?''), ''TableHasForeignRef'') = 1
	BEGIN
		-- Just to know which tables used delete syntax.
		SET @MSG = ''DELETE FROM '' + ''?''
		RAISERROR(@MSG,0,1) WITH NOWAIT
		DELETE FROM ?
	END
ELSE
	BEGIN
		-- Just to know which tables used Truncate syntax.
		SET @MSG = ''TRUNCATE TABLE '' + ''?''
		RAISERROR(@MSG,0,1) WITH NOWAIT
		TRUNCATE TABLE ?
	END
'
EXEC sp_MSForEachTable 'ALTER TABLE ? CHECK CONSTRAINT ALL'

SET NOCOUNT OFF
END