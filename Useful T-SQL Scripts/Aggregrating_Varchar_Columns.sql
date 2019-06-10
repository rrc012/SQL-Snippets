/*
 ===============================================================================
 Author:	     VIKRAM TAKRANI
 Source:       http://www.sqlservercentral.com/scripts/Grouping+VARCHAR+Columns/68155/
 Article Name: Aggregrating Varchar Columns
 Create Date:  22-SEP-2009
 Description:  This script groups all the rows with the 
			same index as a comma delimited string.	
 Revision History:
 26-FEB-2013 - RAGHUNANDAN CUMBAKONAM
			Added code to enable/disable SET commands.
			Formatted the code.
			Added the usage and history.
 Usage:		N/A			   
 ===============================================================================
*/

SET NOCOUNT ON
GO

IF OBJECT_ID('dbo.Employee', 'U') IS NOT NULL DROP TABLE dbo.Employee;
GO  

CREATE TABLE dbo.Employee
(
 id     INT         NOT NULL,
 status VARCHAR(20) NOT NULL,
 add1   VARCHAR(20) NOT NULL,
 add2   VARCHAR(20) NULL
);
GO

--POPULATE TEST DATA
INSERT INTO dbo.Employee
SELECT 1,'S1','S1Add1','S1Add2' UNION ALL
SELECT 1,'S2','S2Add1',NULL UNION ALL
SELECT 1,'S3','S3Add1',NULL UNION ALL
SELECT 1,'S4','S4Add1','S4Add2' UNION ALL
SELECT 2,'S1','S1Add1','S1Add2' UNION ALL
SELECT 2,'S2','S2Add1',NULL UNION ALL
SELECT 2,'S3','S3Add1','S3Add2'
GO

;WITH CTE2
AS
(
--ASSIGN ROW NUMBERS TO THE RECORDS
 SELECT id,
	   ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) col3,
	   status,
	   add1,
	   ISNULL(add2,'') AS add2 
   FROM dbo.Employee
)
,CTE AS
(
 --ANCHOR ROW WILL HAVE THE ID AND THE ROWS FOR THAT ID + 1 
 -- MAX + 1 SINCE THIS WILL BE A BREAK CONDITION FOR RECURSIVE LOOP 
 SELECT id,
	   MAX(col3)+1 AS Col3,
	   CAST('' AS VARCHAR(100)) AS Col2 
  FROM CTE2 
 GROUP BY id

 UNION ALL

 SELECT t.id,
	   t.col3,
	   CAST(t.status + ',' + t.add1 + ',' + t.add2 + ',' + c.col2 AS VARCHAR(100)) AS Col2 
   FROM CTE2 AS t 
	   INNER JOIN CTE AS c ON c.id = t.id
  WHERE c.col3 = t.col3+1 
)
SELECT id,
       SUBSTRING(Col2, 1, LEN(col2)-1) AS CSVs 
  FROM CTE 
 WHERE col3 = 1 
 ORDER BY id;

SET NOCOUNT OFF
GO