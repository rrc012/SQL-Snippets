IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'udf_EasterSundayByYear' AND xtype = 'FN')
BEGIN
	 DROP FUNCTION dbo.udf_EasterSundayByYear
END
GO

CREATE FUNCTION [dbo].[udf_EasterSundayByYear](@Year CHAR(4))
RETURNS DATETIME
AS
BEGIN

/*
 ======================================================================
 Author:	     Initial Concept
 Source:       http://aa.usno.navy.mil/faq/docs/easter.php
 Create Date:  00-JAN-0001
 Description:  This user-defined function calculates the EASTER date
			for a given year.	
 Revision History:
 07-OCT-2008 - TIM CULLEN 
			http://www.mssqltips.com/sqlservertip/1537/tsql-function-to-determine-holidays-in-sql-server/
 01-AUG-2012 - RAGHUNANDAN CUMBAKONAM 
			Formatted the code.
			Renamed the function.
			Added semicolon after each statement.
			Added the usage and history.
 Usage:		SELECT dbo.udf_EasterSundayByYear('2012')			   
 ======================================================================
*/
	
DECLARE @c INT,
	   @n INT,
	   @k INT,
	   @i INT,
	   @j INT,
	   @l INT,
	   @m INT,
	   @d INT,
	   @Easter DATETIME;
	   
--y is the Year, m is the Month of occurrence, and d is the Day of occurrence
	
SET @c = (@Year/100);
SET @n = @Year - 19 * (@Year/19);
SET @k = (@c - 17)/25;
SET @i = @c - @c/4 - (@c - @k)/3 + 19 * @n + 15;
SET @i = @i - 30 * (@i/30);
SET @i = @i - (@i/28) * (1 - (@i/28) * (29/(@i + 1)) * ((21 - @n)/11));
SET @j = @Year + @Year/4 + @i + 2 - @c + @c/4;
SET @j = @j - 7 * (@j/7);
SET @l = @i - @j;
SET @m = 3 + (@l + 40)/44;
SET @d = @l + 28 - 31 * (@m/4);

SET @Easter = (SELECT RIGHT('0' + CONVERT(VARCHAR(2),@m),2) + '/' + RIGHT('0' + CONVERT(VARCHAR(2),@d),2) + '/' + CONVERT(CHAR(4),@Year));

RETURN @Easter;

END