/*
 ===============================================================================
 Author:	     ADAM ASPIN
 Source:       http://www.sqlservercentral.com/articles/Data+Profiling/96398/
 Article Name: Data Profiling with T-SQL
 Create Date:  25-FEB-2013
 Description:  This script analyses the data.	
 Revision History:
 02-APR-2013 - RAGHUNANDAN CUMBAKONAM
		   - Formatted the code.
		   - Added the history.
 Usage:	     N/A			   
 ===============================================================================
*/ 

/*
This script is given "As Is" with no warranties and plenty of caveats. Use at your own risk!
 
For more on data profiling, see Chapter 10 in "SQL Server 2012 Data Integration Recipes", Apress, 2012
*/-----------------------------------------------------------------------
-- User-defined variables
-----------------------------------------------------------------------

USE HPG_EDW -- Your database here
GO

SET NOCOUNT ON;

DECLARE  @TABLE_SCHEMA          NVARCHAR(128) = 'ct',                  -- Your schema here
	    @TABLE_NAME            NVARCHAR(128) = 'CoreTrust_Logistics', -- Your table here
	    @ColumnListIN          NVARCHAR(4000) = '',                   -- Enter a comma-separated list of specific columns to profile, or leave blank for all
	    @TextCol               BIT = 1,					      -- Analyse all text (char/varchar/nvarchar) data type columns
	    @NumCol                BIT = 1,					      -- Analyse all numeric data type columns
	    @DateCol               BIT = 1,					      -- Analyse all date data type data type columns
	    @LobCol                BIT = 1,					      -- Analyse all VAR(char/nchar/binary) MAX data type columns (potentially time-consuming)
	    @AdvancedAnalysis      BIT = 0,			                -- Perform advanced analysis (threshold counts/domain analysis) (potentially time-consuming)
	    @DistinctValuesMinimum INT = 200,		                     -- Minimum number of distinct values to suggest a reference table and/or perform domain analysis
	    @BoundaryPercent       NUMERIC(3,2) = 0.57,		           -- Percent of records at upper/lower threshold to suggest a possible anomaly
	    @NullBoundaryPercent   NUMERIC(5,2) = 90.00,	                -- Percent of NULLs to suggest a possible anomaly
	    @DataTypePercentage    INT = 2;                               -- Percentage variance allowed when suggesting another data type for a column

-----------------------------------------------------------------------
-- Process variables
-----------------------------------------------------------------------

DECLARE  @DATA_TYPE                VARCHAR(128) = '',
	    @FULLSQL                  VARCHAR(MAX) = '',
	    @SQLMETADATA              VARCHAR(MAX) = '',
	    @NUMSQL                   VARCHAR(MAX) = '',
	    @DATESQL                  VARCHAR(MAX) = '',
	    @LOBSQL                   VARCHAR(MAX) = '',
	    @COLUMN_NAME              VARCHAR(128),
	    @CHARACTER_MAXIMUM_LENGTH INT,
	    @ROWCOUNT                 BIGINT = 0,
	    @ColumnList               VARCHAR(4000) = '  ',
	    @TableCheck               TINYINT,
	    @ColumnCheck              SMALLINT,
	    @DataTypeVariance         INT,
	    @CharPosition             INT,
         @ROWCOUNTTEXT             NVARCHAR(1000) = '',
         @ROWCOUNTPARAM            NVARCHAR(50) = '',
	    @advancedtestSQL          VARCHAR(MAX);

-----------------------------------------------------------------------

-- Start the process:

BEGIN TRY

-- Test that the schema and table exist

SELECT @TableCheck = COUNT (*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = @TABLE_SCHEMA AND TABLE_NAME = @TABLE_NAME;

IF @TableCheck <> 1
BEGIN
	RAISERROR ('The table does not exist',16,1);
	RETURN
END

-----------------------------------------------------------------------
-- Parse list of columns to process / get list of columns according to types required
-----------------------------------------------------------------------

IF OBJECT_ID('tempdb..#ColumnList') IS NOT NULL DROP TABLE tempdb..#ColumnList;

 -- Used to hold list of columns to process
CREATE TABLE #ColumnList 
(
 COLUMN_NAME VARCHAR(128),
 DATA_TYPE VARCHAR(128),
 CHARACTER_MAXIMUM_LENGTH INT
);

IF @ColumnListIN <> '' -- See if there is a list of columns to process
     BEGIN
     	-- Process list
     	SET @ColumnList = @ColumnListIN + ',';
     
     	WHILE CHARINDEX(',', @ColumnList) > 0
     	BEGIN
     		SET @CharPosition = CHARINDEX(',', @ColumnList)
     		INSERT INTO #ColumnList (COLUMN_NAME)
			SELECT LTRIM(RTRIM(LEFT(@ColumnList, @CharPosition - 1)));
     		SET @ColumnList = STUFF(@ColumnList, 1, @CharPosition, '');
     	END  -- While loop
     
     	-- Update with datatype and length
     	UPDATE CL
     	   SET CL.CHARACTER_MAXIMUM_LENGTH = ISNULL(ISC.CHARACTER_MAXIMUM_LENGTH,0),
     		  CL.DATA_TYPE = ISC.DATA_TYPE
     	  FROM #ColumnList AS CL
     		  INNER JOIN INFORMATION_SCHEMA.COLUMNS AS ISC ON CL.COLUMN_NAME = ISC.COLUMN_NAME
     	 WHERE ISC.TABLE_NAME = @TABLE_NAME
     	   AND ISC.TABLE_SCHEMA = @TABLE_SCHEMA;
     END -- If test for list of column names
ELSE
     BEGIN  -- Use all column names, to avoid filtering
     	IF @TextCol = 1
     	BEGIN
     		INSERT INTO #ColumnList (COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH)
     		SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
     		  FROM INFORMATION_SCHEMA.COLUMNS
     		 WHERE DATA_TYPE IN ('varchar', 'nvarchar', 'char', 'nchar', 'binary')
     		   AND TABLE_NAME = @TABLE_NAME
     		   AND TABLE_SCHEMA = @TABLE_SCHEMA
     		   AND CHARACTER_MAXIMUM_LENGTH > 0;
     	END
     
     	IF @NumCol = 1
     	BEGIN
     		INSERT INTO #ColumnList (COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH)
     		SELECT COLUMN_NAME, DATA_TYPE, ISNULL(CHARACTER_MAXIMUM_LENGTH,0)
     		  FROM INFORMATION_SCHEMA.COLUMNS
     		 WHERE DATA_TYPE IN ('numeric', 'int', 'bigint', 'tinyint', 'smallint', 'decimal', 'money', 'smallmoney', 'float', 'real')
     		   AND TABLE_NAME = @TABLE_NAME
     		   AND TABLE_SCHEMA = @TABLE_SCHEMA;
     	END
     
     	IF @DateCol = 1
     	BEGIN
     		INSERT INTO #ColumnList (COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH)
     		SELECT COLUMN_NAME, DATA_TYPE, ISNULL(CHARACTER_MAXIMUM_LENGTH,0)
     		  FROM INFORMATION_SCHEMA.COLUMNS
     		 WHERE DATA_TYPE IN ('Date', 'DateTime', 'SmallDateTime', 'DateTime2', 'Time')
     		   AND TABLE_NAME = @TABLE_NAME
     		   AND TABLE_SCHEMA = @TABLE_SCHEMA;
     	END
     
     	IF @LOBCol = 1
     	BEGIN
     		INSERT INTO #ColumnList (COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH)
     		SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
     		  FROM INFORMATION_SCHEMA.COLUMNS
     		 WHERE DATA_TYPE IN ('varchar', 'nvarchar', 'varbinary', 'xml')
     		   AND TABLE_NAME = @TABLE_NAME
     		   AND TABLE_SCHEMA = @TABLE_SCHEMA
     		   AND CHARACTER_MAXIMUM_LENGTH = -1;
     	END
     END -- Else test to get all column names

-----------------------------------------------------------------------

-- Test that there are columns to analyse

SELECT @ColumnCheck = COUNT (*) FROM #ColumnList WHERE DATA_TYPE IS NOT NULL
IF @ColumnCheck = 0
BEGIN
	RAISERROR ('The columns do not exist in the selected database or no columns are selected',16,1);
	RETURN
END

-----------------------------------------------------------------------
-- Create Temp table used to hold profiling data
-----------------------------------------------------------------------

IF OBJECT_ID('tempdb..#ProfileData') IS NOT NULL DROP TABLE tempdb..#ProfileData;

CREATE TABLE #ProfileData
(
 TABLE_SCHEMA               NVARCHAR(128),
 TABLE_NAME                 NVARCHAR(128),
 COLUMN_NAME                NVARCHAR(128),
 ColumnDataLength           INT,
 DataType                   VARCHAR(128),
 MinDataLength              BIGINT,
 MaxDataLength              BIGINT,
 AvgDataLength              BIGINT,
 MinDate                    SQL_VARIANT,
 MaxDate                    SQL_VARIANT,
 NoDistinct                 BIGINT,
 NoNulls                    NUMERIC(32,4),
 NoZeroLength               NUMERIC(32,4),
 PercentageNulls            NUMERIC(9,4),
 PercentageZeroLength       NUMERIC(9,4),
 NoDateWithHourminuteSecond BIGINT,
 NoDateWithSecond           BIGINT,
 NoIsNumeric                BIGINT,
 NoIsDate                   BIGINT,
 NoAtLimit                  BIGINT,
 IsFK                       BIT NULL DEFAULT 0,
 DataTypeComments           NVARCHAR(1500)
);

-- Get row count

SET @ROWCOUNTTEXT  = 'SELECT @ROWCOUNTOUT = COUNT (*) FROM ' + QUOTENAME(@TABLE_SCHEMA)  + '.' + QUOTENAME(@TABLE_NAME) + ' WITH (NOLOCK)'
SET @ROWCOUNTPARAM = '@ROWCOUNTOUT INT OUTPUT'

EXECUTE sp_executesql @ROWCOUNTTEXT, @ROWCOUNTPARAM, @ROWCOUNTOUT = @ROWCOUNT OUTPUT;

-----------------------------------------------------------------------

-- Test that there are records to analyse

IF @ROWCOUNT = 0
BEGIN
	RAISERROR ('There is no data in the table to analyse',16,1);
	RETURN
END
			
-----------------------------------------------------------------------
-- Define the dynamic SQL used for each column to analyse
-----------------------------------------------------------------------
		
SET @SQLMETADATA = 'INSERT INTO #ProfileData (ColumnDataLength,COLUMN_NAME,TABLE_SCHEMA,TABLE_NAME,DataType,MaxDataLength,MinDataLength,AvgDataLength,MaxDate,MinDate,NoDateWithHourminuteSecond,NoDateWithSecond,NoIsNumeric,NoIsDate,NoNulls,NoZeroLength,NoDistinct)'
				
DECLARE SQLMETADATA_CUR CURSOR LOCAL FAST_FORWARD FOR  

SELECT COLUMN_NAME, CHARACTER_MAXIMUM_LENGTH, DATA_TYPE FROM #ColumnList

OPEN SQLMETADATA_CUR   
FETCH NEXT FROM SQLMETADATA_CUR INTO @COLUMN_NAME, @CHARACTER_MAXIMUM_LENGTH, @DATA_TYPE   

WHILE @@FETCH_STATUS = 0   
BEGIN   

	SET @SQLMETADATA = @SQLMETADATA + '
	SELECT TOP 100 PERCENT ' + 
	CAST(@CHARACTER_MAXIMUM_LENGTH AS VARCHAR(20)) + ',
	''' + QUOTENAME(@COLUMN_NAME) + ''',
	''' + QUOTENAME(@TABLE_SCHEMA) + ''',
	''' + QUOTENAME(@TABLE_NAME) + ''',
	''' + @DATA_TYPE + '''' +
	CASE WHEN @DATA_TYPE IN ('varchar', 'nvarchar', 'char', 'nchar') AND @CHARACTER_MAXIMUM_LENGTH >= 0 THEN + ',
	          MAX(LEN(' + QUOTENAME(@COLUMN_NAME) + ')),
	          MIN(LEN(' + QUOTENAME(@COLUMN_NAME) + ')),
	          AVG(LEN(' + QUOTENAME(@COLUMN_NAME) + ')),
	          NULL,
	          NULL,
	          NULL,
	          NULL,
	          (SELECT COUNT (*) from ' + QUOTENAME(@TABLE_SCHEMA) + '.' + QUOTENAME(@TABLE_NAME) + ' WHERE ISNUMERIC(' + QUOTENAME(@COLUMN_NAME) + ') = 1) ,
	          (SELECT COUNT (*) from ' + QUOTENAME(@TABLE_SCHEMA) + '.' + QUOTENAME(@TABLE_NAME) + ' WHERE ISDATE(' + QUOTENAME(@COLUMN_NAME) + ') = 1) '
	     WHEN @DATA_TYPE IN ('numeric', 'int', 'bigint', 'tinyint', 'smallint', 'decimal', 'money', 'smallmoney', 'float','real') THEN + ',
	          MAX(' + QUOTENAME(@COLUMN_NAME) + '),
	          MIN(' + QUOTENAME(@COLUMN_NAME) + '),
	          AVG(CAST(' + QUOTENAME(@COLUMN_NAME) + ' AS NUMERIC(36,2))),
	          NULL,
	          NULL,
	          NULL,
	          NULL,
	          NULL,
	          NULL'
	     WHEN @DATA_TYPE IN ('DateTime', 'SmallDateTime') THEN + ',
               NULL,
               NULL,
               NULL,
               MAX(' + QUOTENAME(@COLUMN_NAME) + '),
               MIN(' + QUOTENAME(@COLUMN_NAME) + '),
               (SELECT COUNT (*) from ' + QUOTENAME(@TABLE_SCHEMA) + '.' + QUOTENAME(@TABLE_NAME) + ' WHERE (CONVERT(NUMERIC(20,12), ' + QUOTENAME(@COLUMN_NAME) + ' ) - FLOOR(CONVERT(NUMERIC(20,12), ' + QUOTENAME(@COLUMN_NAME) + ')) <> 0)),
               (SELECT COUNT (*) from ' + QUOTENAME(@TABLE_SCHEMA) + '.' + QUOTENAME(@TABLE_NAME) + ' WHERE DATEPART(ss,' + QUOTENAME(@COLUMN_NAME) + ') <> 0 OR DATEPART(mcs,' + QUOTENAME(@COLUMN_NAME) + ') <> 0),
               NULL,
               NULL '
          WHEN @DATA_TYPE IN ('DateTime2') THEN + ',
               NULL, 
               NULL, 
               NULL, 
               MAX(' + QUOTENAME(@COLUMN_NAME) + '), 
               MIN(' + QUOTENAME(@COLUMN_NAME) + '),
               NULL,
               NULL,
               NULL, 
               NULL '
	     WHEN @DATA_TYPE IN ('Date') THEN + ',
               NULL, 
               NULL, 
               NULL, 
               MAX(' + QUOTENAME(@COLUMN_NAME) + '), 
               MIN(' + QUOTENAME(@COLUMN_NAME) + '),
               NULL, 
               NULL, 
               NULL, 
               NULL '
	     WHEN @DATA_TYPE IN ('xml') THEN + ',
               MAX(LEN(CAST(' + QUOTENAME(@COLUMN_NAME) + ' AS NVARCHAR(MAX)))),   
               MIN(LEN(CAST(' + QUOTENAME(@COLUMN_NAME) + ' AS NVARCHAR(MAX)))),    
               AVG(LEN(CAST(' + QUOTENAME(@COLUMN_NAME) + ' AS NVARCHAR(MAX)))),  
               NULL,
               NULL, 
               NULL, 
               NULL, 
               NULL, 
               NULL '
	     WHEN @DATA_TYPE IN ('varbinary','varchar','nvarchar') AND @CHARACTER_MAXIMUM_LENGTH = -1 THEN + ',
               MAX(LEN(' + QUOTENAME(@COLUMN_NAME) + ')),  
               MIN(LEN(' + QUOTENAME(@COLUMN_NAME) + ')),  
               AVG(LEN(' + QUOTENAME(@COLUMN_NAME) + ')),
               NULL,
               NULL, 
               NULL, 
               NULL, 
               NULL, 
               NULL '
	     WHEN @DATA_TYPE IN ('binary') THEN + ',
               MAX(LEN(' + QUOTENAME(@COLUMN_NAME) + ')),  
               MIN(LEN(' + QUOTENAME(@COLUMN_NAME) + ')),  
               AVG(LEN(' + QUOTENAME(@COLUMN_NAME) + ')),
               NULL,
               NULL, 
               NULL, 
               NULL, 
               NULL, 
               NULL '
	     WHEN @DATA_TYPE IN ('time') THEN + ',
               NULL, 
               NULL, 
               NULL, 
               MAX(' + QUOTENAME(@COLUMN_NAME) + '),
               MIN(' + QUOTENAME(@COLUMN_NAME) + '),
               NULL, 
               NULL, 
               NULL, 
               NULL '
	     ELSE + ',
               NULL, 
               NULL,
               NULL,
               NULL,
               NULL,
               NULL, 
               NULL, 
               NULL, 
               NULL '
	END	+ ',
	(SELECT COUNT(*) FROM ' + QUOTENAME(@TABLE_SCHEMA) + '.' + QUOTENAME(@TABLE_NAME) + ' WHERE ' + QUOTENAME(@COLUMN_NAME) + ' IS NULL)' +
	CASE WHEN @DATA_TYPE IN ('varchar', 'nvarchar', 'char', 'nchar') THEN + ',
	          (SELECT COUNT(*) FROM ' + QUOTENAME(@TABLE_SCHEMA) + '.' + QUOTENAME(@TABLE_NAME) + ' WHERE LEN(LTRIM(RTRIM(' + QUOTENAME(@COLUMN_NAME) + '))) = '''')'
	     ELSE + ',NULL'
	END	+ ',
	(SELECT COUNT(DISTINCT ' + QUOTENAME(@COLUMN_NAME) + ') FROM ' + QUOTENAME(@TABLE_SCHEMA) + '.' + QUOTENAME(@TABLE_NAME) + ' WHERE ' + QUOTENAME(@COLUMN_NAME) + ' IS NOT NULL )
	FROM ' + QUOTENAME(@TABLE_SCHEMA) + '.' + QUOTENAME(@TABLE_NAME) + ' WITH (NOLOCK)

	UNION'

	FETCH NEXT FROM SQLMETADATA_CUR INTO @COLUMN_NAME, @CHARACTER_MAXIMUM_LENGTH, @DATA_TYPE      
END   

CLOSE SQLMETADATA_CUR   
DEALLOCATE SQLMETADATA_CUR 

SET @SQLMETADATA = LEFT(@SQLMETADATA, LEN(@SQLMETADATA) -5);

EXEC (@SQLMETADATA);

-----------------------------------------------------------------------
-- Final Calculations
-----------------------------------------------------------------------

-- Indicate Foreign Keys

;WITH FK_CTE (FKColumnName)
AS
(
SELECT DISTINCT CU.COLUMN_NAME
  FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS TC
       INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS CU ON TC.CONSTRAINT_NAME = CU.CONSTRAINT_NAME 
	         AND TC.TABLE_SCHEMA = CU.TABLE_SCHEMA 
	         AND TC.TABLE_NAME = CU.TABLE_NAME
	         AND TC.TABLE_SCHEMA = @TABLE_SCHEMA
	         AND TC.TABLE_NAME = @TABLE_NAME
	         AND CONSTRAINT_TYPE = 'FOREIGN KEY'
)
UPDATE P
   SET P.IsFK = 1
  FROM #ProfileData AS P
	   INNER JOIN FK_CTE AS CTE ON P.COLUMN_NAME = CTE.FKColumnName;

-- Calculate percentages
UPDATE #ProfileData
   SET PercentageNulls = (NoNulls / @ROWCOUNT) * 100,
	  PercentageZeroLength = (NoZeroLength / @ROWCOUNT) * 100;	

-- Add any comments

-- Datatype suggestions

-- First get number of records where a variation could be an anomaly
SET @DataTypeVariance = ROUND((@ROWCOUNT * @DataTypePercentage) / 100, 0);

UPDATE #ProfileData
   SET DataTypeComments = 'Possibly could be one of the DATE types. '
 WHERE NoIsDate BETWEEN (@ROWCOUNT -@DataTypeVariance) AND (@ROWCOUNT + @DataTypeVariance)
   AND DataType IN ('varchar', 'nvarchar', 'char', 'nchar');

UPDATE #ProfileData
   SET DataTypeComments = 'Possibly could be one of the NUMERIC types. '
 WHERE NoIsNumeric BETWEEN (@ROWCOUNT -@DataTypeVariance) AND (@ROWCOUNT + @DataTypeVariance)
   AND DataType IN ('varchar', 'nvarchar', 'char', 'nchar');

UPDATE #ProfileData
   SET DataTypeComments = 'Possibly could be INT type. '
 WHERE MinDataLength >= -2147483648
   AND MaxDataLength <= 2147483648
   AND DataType IN ('bigint');

UPDATE #ProfileData
   SET DataTypeComments = 'Possibly could be SMALLINT type. '
 WHERE MinDataLength >= -32768
   AND MaxDataLength <= 32767
   AND DataType IN ('bigint','int');

UPDATE #ProfileData
   SET DataTypeComments = 'Possibly could be TINYINT type. '
 WHERE MinDataLength >= 0
   AND MaxDataLength <= 255
   AND DataType IN ('bigint','int','smallint');

UPDATE #ProfileData
   SET DataTypeComments = 'Possibly could be SMALLDATE type. '
 WHERE NoDateWithSecond = 0
   AND MinDate >= '19000101'
   AND MaxDate <= '20790606'
   AND DataType IN ('datetime','datetime2');

UPDATE #ProfileData
   SET DataTypeComments = 'Possibly could be DATE type (SQL Server 2008 only). '
 WHERE NoDateWithHourminuteSecond = 0
   AND DataType IN ('datetime','datetime2');

UPDATE #ProfileData
   SET DataTypeComments = 'Possibly could be DATETIME type. '
 WHERE MinDate >= '17530101'
   AND MaxDate <= '99991231'
   AND DataType IN ('datetime2');

-- Empty column suggestions
UPDATE #ProfileData
   SET DataTypeComments = ISNULL(DataTypeComments,'') + 'Seems empty - is it required? '
 WHERE (PercentageNulls = 100 OR PercentageZeroLength = 100)
   AND IsFK = 0;

-- Null column suggestions
UPDATE #ProfileData
   SET DataTypeComments = ISNULL(DataTypeComments,'') + 'There is a large percentage of NULLs - attention may be required. '
 WHERE PercentageNulls >= @NullBoundaryPercent;

-- Distinct value suggestions
UPDATE #ProfileData
   SET DataTypeComments = ISNULL(DataTypeComments,'') + 'Few distinct elements - potential for reference/lookup table (contains NULLs).'
 WHERE NoDistinct < @DistinctValuesMinimum
   AND @ROWCOUNT > @DistinctValuesMinimum
   AND IsFK = 0
   AND PercentageNulls <> 100
   AND NoNulls <> 0;

-- FK suggestions
UPDATE #ProfileData
   SET DataTypeComments = ISNULL(DataTypeComments,'') + 'Few distinct elements - potential for Foreign Key.'
 WHERE NoDistinct < @DistinctValuesMinimum
   AND @ROWCOUNT > @DistinctValuesMinimum
   AND IsFK = 0
   AND NoNulls = 0
   AND DataType NOT LIKE '%Date%'
   AND DataType <> 'Time';

-- Filestream suggestions
UPDATE #ProfileData
   SET DataTypeComments = 'Possibly a good candidate for FILESTREAM (SQL Server 2008 only).'
 WHERE AvgDataLength >= 1000000
   AND DataType IN ('varbinary')
   AND ColumnDataLength = -1;

UPDATE #ProfileData
   SET DataTypeComments = 'Possibly not a good candidate for FILESTREAM (SQL Server 2008 only).'
 WHERE AvgDataLength < 1000000
   AND DataType IN ('varbinary')
   AND ColumnDataLength = -1;

-- Sparse Column Suggestions
IF OBJECT_ID('tempdb..#SparseThresholds') IS NOT NULL DROP TABLE tempdb..#SparseThresholds;

CREATE TABLE #SparseThresholds (DataType VARCHAR(128), Threshold NUMERIC(9,4));

INSERT INTO #SparseThresholds (DataType, Threshold)
SELECT 'tinyint', 86 UNION ALL
SELECT 'smallint', 76 UNION ALL
SELECT 'int', 64 UNION ALL
SELECT 'bigint', 52 UNION ALL
SELECT 'real', 64 UNION ALL
SELECT 'float', 52 UNION ALL
SELECT 'money', 64 UNION ALL
SELECT 'smallmoney', 64 UNION ALL
SELECT 'smalldatetime', 52 UNION ALL
SELECT 'datetime', 52 UNION ALL
SELECT 'uniqueidentifier', 43 UNION ALL
SELECT 'date', 69 UNION ALL
SELECT 'datetime2', 52 UNION ALL
SELECT 'decimal', 42 UNION ALL
SELECT 'nuumeric', 42 UNION ALL
SELECT 'char', 60 UNION ALL
SELECT 'varchar', 60 UNION ALL
SELECT 'nchar', 60 UNION ALL
SELECT 'nvarchar', 60 UNION ALL
SELECT 'binary', 60 UNION ALL
SELECT 'varbinary', 60 UNION ALL
SELECT 'xml', 60;

WITH Sparse_CTE (COLUMN_NAME, SparseComment)
AS
(
SELECT P.COLUMN_NAME,
	  CASE WHEN P.PercentageNulls >= T.Threshold THEN 'Could benefit from sparse columns. '
	       ELSE ''
	  END AS SparseComment
  FROM #ProfileData AS P
	  INNER JOIN #SparseThresholds AS T ON P.DataType = T.DataType
)
UPDATE PT
   SET PT.DataTypeComments = 
	  CASE WHEN PT.DataTypeComments IS NULL THEN CTE.SparseComment
            ELSE ISNULL(PT.DataTypeComments,'') + CTE.SparseComment + '. '
	  END
  FROM #ProfileData AS PT
       INNER JOIN Sparse_CTE AS CTE ON PT.COLUMN_NAME = CTE.COLUMN_NAME;

-----------------------------------------------------------------------
-- Optional advanced analysis
-----------------------------------------------------------------------

IF @AdvancedAnalysis = 1
BEGIN

-----------------------------------------------------------------------
-- Data at data boundaries
-----------------------------------------------------------------------

     IF OBJECT_ID('tempdb..#LimitTest') IS NOT NULL DROP TABLE tempdb..#LimitTest;
     
     CREATE TABLE #LimitTest (COLUMN_NAME VARCHAR(128), NoAtLimit BIGINT);
     
     SET @advancedtestSQL = 'INSERT INTO #LimitTest (COLUMN_NAME, NoAtLimit)' + CHAR(13);
     
     SELECT @advancedtestSQL = @advancedtestSQL + 'SELECT '''+ COLUMN_NAME + ''', COUNT('+ COLUMN_NAME + ') FROM ' + @TABLE_SCHEMA + '.' + @TABLE_NAME + 
            CASE WHEN DataType IN ('numeric', 'int', 'bigint', 'tinyint', 'smallint', 'decimal', 'money', 'smallmoney', 'float','real') THEN ' WHERE '+ COLUMN_NAME + ' = ' + CAST(ISNULL(MaxDataLength,0) AS VARCHAR(40)) + ' OR '+ COLUMN_NAME + ' = ' + CAST(ISNULL(MinDataLength,0) AS VARCHAR(40)) + CHAR(13) + ' UNION' + CHAR(13)
                 ELSE ' WHERE LEN('+ COLUMN_NAME + ') = ' + CAST(ISNULL(MaxDataLength,0) AS VARCHAR(40)) + ' OR LEN('+ COLUMN_NAME + ') = ' + CAST(ISNULL(MinDataLength,0) AS VARCHAR(40)) + CHAR(13) + ' UNION' + CHAR(13)
            END
       FROM #ProfileData
      WHERE DataType IN ('numeric', 'int', 'bigint', 'tinyint', 'smallint', 'decimal', 'money', 'smallmoney', 'float','real','varchar', 'nvarchar', 'char', 'nchar', 'binary')
     
     SET @advancedtestSQL = LEFT(@advancedtestSQL,LEN(@advancedtestSQL) -6);
     
	EXEC (@advancedtestSQL);

     UPDATE M
        SET M.NoAtLimit = T.NoAtLimit,
     	  M.DataTypeComments = CASE WHEN CAST(T.NoAtLimit AS NUMERIC(36,2)) / CAST(@ROWCOUNT AS NUMERIC(36,2)) >= @BoundaryPercent THEN ISNULL(M.DataTypeComments,'') + 'Large numbers of data elements at the max/minvalues. '
                                      ELSE M.DataTypeComments
                                 END
       FROM #ProfileData AS M
     	  INNER JOIN #LimitTest AS T ON M.COLUMN_NAME = T.COLUMN_NAME;

-----------------------------------------------------------------------
-- Domain analysis
-----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#DomainAnalysis') IS NOT NULL DROP TABLE tempdb..#DomainAnalysis;

	CREATE TABLE #DomainAnalysis
	(
	 DomainName    NVARCHAR(128),
	 DomainElement NVARCHAR(4000),
	 DomainCounter BIGINT,
	 DomainPercent NUMERIC(7,4)
	);

	DECLARE @DOMAINSQL VARCHAR(MAX) = 'INSERT INTO #DomainAnalysis (DomainName, DomainElement, DomainCounter) ';

	DECLARE SQLDOMAIN_CUR CURSOR LOCAL FAST_FORWARD FOR  
	
	SELECT COLUMN_NAME, DataType FROM #ProfileData WHERE NoDistinct < @DistinctValuesMinimum
	
	OPEN SQLDOMAIN_CUR   
	FETCH NEXT FROM SQLDOMAIN_CUR INTO @COLUMN_NAME, @DATA_TYPE 

	WHILE @@FETCH_STATUS = 0   
	BEGIN   

	SET @DOMAINSQL = @DOMAINSQL + 'SELECT ''' + @COLUMN_NAME + ''' AS DomainName, CAST( '+ @COLUMN_NAME + ' AS VARCHAR(4000)) AS DomainElement, COUNT(ISNULL(CAST(' + @COLUMN_NAME + ' AS NVARCHAR(MAX)),'''')) AS DomainCounter FROM ' + @TABLE_SCHEMA + '.' + @TABLE_NAME + ' GROUP BY ' + @COLUMN_NAME + ''
	+ ' UNION '

	FETCH NEXT FROM SQLDOMAIN_CUR INTO @COLUMN_NAME, @DATA_TYPE     
	END   

	CLOSE SQLDOMAIN_CUR   
	DEALLOCATE SQLDOMAIN_CUR 

	SET @DOMAINSQL = LEFT(@DOMAINSQL, LEN(@DOMAINSQL) -5) + ' ORDER BY DomainName ASC, DomainCounter DESC ';

	EXEC (@DOMAINSQL);

     -- Now calculate percentages (this appraoch is faster than doing it when performing the domain analysis)
	;WITH DomainCounter_CTE
	AS
	(
	 SELECT DomainName, SUM(ISNULL(DomainCounter,0)) AS DomainCounterTotal
	   FROM #DomainAnalysis 
	  GROUP BY DomainName
	)
	UPDATE D
	   SET D.DomainPercent = (CAST(D.DomainCounter AS NUMERIC(36,4)) / CAST(CTE.DomainCounterTotal AS NUMERIC(36,4))) * 100
	  FROM #DomainAnalysis AS D
	       INNER JOIN DomainCounter_CTE AS CTE ON D.DomainName = CTE.DomainName
	 WHERE D.DomainCounter <> 0;

END  -- Advanced analysis

-----------------------------------------------------------------------
-- Output results from the profile and domain data tables
-----------------------------------------------------------------------

SELECT *
  FROM #ProfileData;

IF @AdvancedAnalysis = 1
BEGIN
    SELECT *
      FROM #DomainAnalysis;
END;
END TRY

BEGIN CATCH
	SELECT ERROR_NUMBER() AS ErrorNumber,
		  ERROR_SEVERITY() AS ErrorSeverity,
		  ERROR_STATE() AS ErrorState,
		  ERROR_PROCEDURE() AS ErrorProcedure,
		  ERROR_LINE() AS ErrorLine,
		  ERROR_MESSAGE() AS ErrorMessage;
END CATCH