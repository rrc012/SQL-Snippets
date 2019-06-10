USE [DB_MDM]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE name = 'usp_tbl_truncate' AND type = 'P')
BEGIN
      DROP PROC dbo.usp_tbl_truncate;
END
GO

CREATE PROCEDURE dbo.usp_tbl_truncate
@wkTblName VARCHAR(300)
WITH EXECUTE AS OWNER
AS
BEGIN
SET NOCOUNT ON

/*
==================================================
Author:      RAGHUNANDAN CUMBAKONAM
Create Date: 14-JAN-2013
Description: This stored proc trunctes the tables.     
Usage:       EXEC dbo.usp_tbl_truncate 'mdm.tblStgMemberAttribute'
==================================================
*/

DECLARE @query VARCHAR(4000) = '';
SELECT @query = @query + 'TRUNCATE TABLE ' + item  + ' '
  FROM dbo.udf_DelimitedSplit8K(@wkTblName,',')
--PRINT @query
EXEC (@query);

SET NOCOUNT OFF
END