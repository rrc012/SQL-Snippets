/*
 ======================================================================
 Author:	     paddythegeek
 Source:       http://www.sqlservercentral.com/articles/import/91086/
 Create Date:  23-JAN-2012
 Description:  This code summarizes imported data.	
 Revision History:
 31-JUL-2012 - RAGHUNANDAN CUMBAKONAM Added the source details
 ======================================================================
*/
/*	--- Column Summaries ---
These queries create a new table containing various
summary statistics on all table columns, including
	-empty/non-empty tally
	-minimum value length
	-maximum value length
	-average value length
	-number of distinct values
This assumes all fields are a text type.

BEFORE YOU BEGIN:
	Replace ##TABLE## with your source table name in this script
	Results to TEXT with max characters per line = 999
	Copy results to new query window, remove summary lines and execute*/

SET NOCOUNT ON
	
--Query to drop the _ColumnSummary table if it exists
SELECT 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''[dbo].[##TABLE##_ColumnSummary]'') AND type IN (N''U''))
	   DROP TABLE [dbo].[##TABLE##_ColumnSummary]
	   GO'

--Query to produce the _ColumnSummary table to contain the results
SELECT 'CREATE TABLE [dbo].[##TABLE##_ColumnSummary]
        (
	    [ColumnName] [VARCHAR](255) NULL,
	    [Measure] [VARCHAR](30) NULL,
	    [Value] [INT] NULL
        );'
				
--Query to produce ROWCOUNT of all table rows
SELECT 'INSERT INTO [dbo].[##TABLE##_ColumnSummary] 
	   SELECT ''~All Table Rows~'' AS [ColumnName], 
               ''Non-Empty'' AS [Measure],
			COUNT(*) AS [Value] 
	     FROM ##TABLE##;'

--Query to produce select statements to update EMPTY/NON-EMPTY tallies for each column
SELECT 'INSERT INTO [dbo].[##TABLE##_ColumnSummary] 
	   SELECT ''' + sc.Name + ''' AS [ColumnName], 
	          CASE DATALENGTH([' + sc.Name + ']) WHEN 0 THEN ''Empty'' ELSE ''Non-Empty'' END AS [Measure],
	          COUNT(*) AS [Value] 
	     FROM ##TABLE## 
	    GROUP BY CASE DATALENGTH([' + sc.Name + ']) WHEN 0 THEN ''Empty'' ELSE ''Non-Empty'' END 
	    ORDER BY [ColumnName], [Measure];'
  FROM dbo.sysobjects so
       INNER JOIN dbo.syscolumns sc ON so.id = sc.id
 WHERE so.xtype = 'U'
   AND so.name = '##TABLE##'
 ORDER BY sc.colorder;

--Query to produce select statements to update MIN LENGTH tallies for each column
SELECT 'INSERT INTO [dbo].[##TABLE##_ColumnSummary] 
	   SELECT ''' + sc.Name + ''' AS [ColumnName], 
	          ''Min Length'' AS [Measure],
	          MIN(LEN([' + sc.Name + '])) AS [Value] 
	    FROM ##TABLE## 
	   WHERE DATALENGTH([' + sc.Name + ']) > 0
	   ORDER BY [ColumnName], [Measure];'
  FROM dbo.sysobjects so
       INNER JOIN dbo.syscolumns sc ON so.id = sc.id
 WHERE so.xtype = 'U'
   AND so.name = '##TABLE##'
 ORDER BY sc.colorder;

--Query to produce select statements to update MAX LENGTH tallies for each column
SELECT 'INSERT INTO [dbo].[##TABLE##_ColumnSummary] 
        SELECT ''' + sc.Name + ''' AS [ColumnName], 
               ''Max Length'' AS [Measure],
               MAX(LEN([' + sc.Name + '])) AS [Value] 
	     FROM ##TABLE## 
         WHERE DATALENGTH([' + sc.Name + ']) > 0
         ORDER BY [ColumnName], [Measure];'
  FROM dbo.sysobjects so
       INNER JOIN dbo.syscolumns sc ON so.id = sc.id
 WHERE so.xtype = 'U'
   AND so.name = '##TABLE##'
 ORDER BY sc.colorder;

--Query to produce select statements to update AVG LENGTH tallies for each column
SELECT 'INSERT INTO [dbo].[##TABLE##_ColumnSummary] 
        SELECT ''' + sc.Name + ''' AS [ColumnName], 
               ''Avg Length'' AS [Measure],
               AVG(LEN([' + sc.Name + '])) AS [Value] 
		FROM ##TABLE## 
         WHERE DATALENGTH([' + sc.Name + ']) > 0
         ORDER BY [ColumnName], [Measure];'
  FROM dbo.sysobjects so
       INNER JOIN dbo.syscolumns sc ON so.id = sc.id
 WHERE so.xtype = 'U'
   AND so.name = '##TABLE##'
 ORDER BY sc.colorder;

--Query to produce select statements to update DISTINCT VALUE tallies for each column
SELECT 'INSERT INTO [dbo].[##TABLE##_ColumnSummary] 
        SELECT ''' + sc.Name + ''' AS [ColumnName], 
               ''Distinct Values'' AS [Measure],
               COUNT(DISTINCT [' + sc.Name + ']) AS [Value] 
	     FROM ##TABLE## 
         ORDER BY [ColumnName], [Measure];'
          FROM dbo.sysobjects so
       INNER JOIN dbo.syscolumns sc ON so.id = sc.id
 WHERE so.xtype = 'U'
   AND so.name = '##TABLE##'
 ORDER BY sc.colorder;

--Query to produce PIVOT TABLE of ColumnSummary table results
SELECT 'SELECT * 
          FROM (
			 SELECT [ColumnName], [Measure], [Value]
			        FROM [dbo].[##TABLE##_ColumnSummary]) s
			  PIVOT (MAX([Value]) FOR [Measure] IN ([Empty], [Non-Empty], [Min Length], [Max Length], [Avg Length], [Distinct Values])
			) p
         ORDER BY [ColumnName];'