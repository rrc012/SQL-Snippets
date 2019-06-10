IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'udf_InitialCap' AND xtype = 'FN')
BEGIN
	 DROP FUNCTION dbo.udf_InitialCap
END
GO

 CREATE FUNCTION dbo.udf_InitialCap(@String VARCHAR(8000))
RETURNS VARCHAR(8000)
     AS
  BEGIN

/*
 ===============================================================================
 Author:	     GEORGE MASTROS
 Source:       http://blogs.lessthandot.com/index.php/DataMgmt/DBProgramming/sql-server-proper-case-function
 Create Date:  24-FEB-2010
 Description:  This user-defined function capitalizes any lower case alpha 
			   character which follows any non alpha character or single quote.	
 Revision History:
 25-SEP-2010 - JEFF MODEN
			http://www.sqlservercentral.com/articles/T-SQL/91724/
		   - Redaction for personal use and added documentation.
		   - Slight speed enhancement by adding additional COLLATE clauses and the reduction of
		     multiple SET statements to just 2 SELECT statements.
		   - Add no-cap single-quote by single-quote to the filter.
 01-AUG-2012 - RAGHUNANDAN CUMBAKONAM
			Renamed the function. 
			Added the usage and history.			 
 Usage:		SELECT dbo.udf_InitialCap('my firstname is raGHUnandan.')			   
 ===============================================================================
*/  

DECLARE @Position INT;

--===== Update the first character no matter what and then find the next position that we
     -- need to update.  The collation here is essential to making this so simple.
     -- A-z is equivalent to the slower A-Z
 SELECT @String   = STUFF(LOWER(@String),1,1,UPPER(LEFT(@String,1))) COLLATE Latin1_General_Bin,
        @Position = PATINDEX('%[^A-Za-z''][a-z]%',@String COLLATE Latin1_General_Bin);

--===== Do the same thing over and over until we run out of places to capitalize.
     -- Note the reason for the speed here is that ONLY places that need capitalization
     -- are even considered for @Position using the speed of PATINDEX.
  WHILE @Position > 0
 SELECT @String   = STUFF(@String,@Position,2,UPPER(SUBSTRING(@String,@Position,2))) COLLATE Latin1_General_Bin,
        @Position = PATINDEX('%[^A-Za-z''][a-z]%',@String COLLATE Latin1_General_Bin);

 RETURN @String;
    END