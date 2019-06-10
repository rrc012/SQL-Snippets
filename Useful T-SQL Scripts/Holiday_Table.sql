/*
 ===============================================================================
 Author:	     RAGHUNANDAN CUMBAKONAM
 Source:       N/A
 Create Date:  20-JUL-2012
 Description:  This script generates dates and also a list of U.S. holidys 
			for the given date range.	
 Revision History:
 01-AUG-2012 - RAGHUNANDAN CUMBAKONAM
			  http://www.mssqltips.com/sqlservertip/1537/tsql-function-to-determine-holidays-in-sql-server/
			- Added the UDF by TIM CULLEN to calculate Easter Date.
			- Added Mardi-Gras, Good Friday & Easter to the list of holidays.
			- Added the history.
 Usage:		   N/A			   
 ===============================================================================
*/

SET NOCOUNT ON
GO

DECLARE @ProcStartDate DATETIME = '01/01/1980',
	   @ProcEndDate DATETIME = '12/31/2020',
	   @Days INT;

IF OBJECT_ID('tempdb..#Calendar', 'U') IS NOT NULL DROP TABLE #Calendar;
CREATE TABLE #Calendar
(
 Date_Id         INT         NOT NULL,
 Calendar_Date   DATE        NOT NULL,
 Day_Of_The_Week VARCHAR(9)  NOT NULL,
 Month_Name      VARCHAR(9)  NOT NULL,
 Calendar_Day    TINYINT     NOT NULL,
 Day_Number      TINYINT     NOT NULL,
 Week_Number     TINYINT     NOT NULL,
 Month_Number    TINYINT     NOT NULL,
 Year_Number     SMALLINT    NOT NULL,
 Is_Workday      BIT         NOT NULL,
 Is_Weekend      BIT         NOT NULL,
 Is_Holiday      BIT         NOT NULL,
 Is_Floating     BIT         NOT NULL,
 Holiday_Name    VARCHAR(30) NOT NULL,
 Season_Name     VARCHAR(6)  NOT NULL,
 PRIMARY KEY CLUSTERED (Date_Id ASC)
);

SET @Days = DATEDIFF(dd, @ProcStartDate, @ProcEndDate+1);

;WITH Nbrs_4(Numbers) AS (SELECT 0 UNION SELECT 1),
      Nbrs_3(Numbers) AS (SELECT 1 FROM Nbrs_4 n1 CROSS JOIN Nbrs_4 n2),
      Nbrs_2(Numbers) AS (SELECT 1 FROM Nbrs_3 n1 CROSS JOIN Nbrs_3 n2),
      Nbrs_1(Numbers) AS (SELECT 1 FROM Nbrs_2 n1 CROSS JOIN Nbrs_2 n2),
      Nbrs_0(Numbers) AS (SELECT 1 FROM Nbrs_1 n1 CROSS JOIN Nbrs_1 n2),
      Nbrs  (Numbers) AS (SELECT ROW_NUMBER() OVER (ORDER BY Numbers)-1 FROM Nbrs_0), 
CTE_Calendar (Date_Id, Calendar_Date, Day_Of_The_Week, Is_Weekend, Calendar_Day, Day_Number, Week_Number, Month_Number, Year_Number, Month_Name, Season_Name)
AS
(
SELECT TOP(@Days)
	  CONVERT(VARCHAR(8), DATEADD(dd,Numbers,@ProcStartDate), 112) AS 'Date_Id',
	  DATEADD(dd,Numbers,@ProcStartDate) AS 'Calendar_Date',
	  DATENAME(dw, DATEADD(dd,Numbers,@ProcStartDate)) AS 'Day_Of_The_Week',
	  IIF(DATEPART(dw, DATEADD(dd,Numbers,@ProcStartDate)) IN (1, 7), 1, 0) AS 'Is_Weekend',
	  DATEPART(dd, DATEADD(dd,Numbers,@ProcStartDate)) AS 'Calendar_Day',
	  DATEPART(dw, DATEADD(dd,Numbers,@ProcStartDate)) AS 'Day_Number',
	  DATEPART(ww, DATEADD(dd,Numbers,@ProcStartDate)) AS 'Week_Number',
	  MONTH(DATEADD(dd,Numbers,@ProcStartDate)) AS 'Month_Number',
	  DATEPART(yy, DATEADD(dd,Numbers,@ProcStartDate)) AS 'Year_Number',
	  DATENAME(mm, DATEADD(dd,Numbers,@ProcStartDate)) AS 'Month_Name',
	  CASE MONTH(DATEADD(dd,Numbers,@ProcStartDate))
		  WHEN 12 THEN 'Winter'
		  WHEN 1 THEN 'Winter'
		  WHEN 2 THEN 'Winter'
		  WHEN 3 THEN 'Spring'
		  WHEN 4 THEN 'Spring'
		  WHEN 5 THEN 'Spring'			
		  WHEN 6 THEN 'Summer'
		  WHEN 7 THEN 'Summer'
		  WHEN 8 THEN 'Summer'
		  ELSE 'Fall'
	  END AS 'Season_Name'
  FROM Nbrs
),
CTE_Holidays (Date_Id, Calendar_Date, Day_Of_The_Week, Is_Weekend, Calendar_Day, Day_Number, Week_Number, Month_Number, Year_Number, Holiday_Name, Month_Name, Season_Name)
AS
(
SELECT Date_Id,
       Calendar_Date,
       Day_Of_The_Week,
	  Is_Weekend,
       Calendar_Day,     
       Day_Number,
       Week_Number,
       Month_Number,
       Year_Number,
       CASE WHEN Year_Number > 1982 AND Month_Number = 1 AND Calendar_Day BETWEEN 15 AND 21 AND Day_Number = 2 THEN 'Martin Luther King Day' --3rd Monday In January, beginning 1983
		  WHEN Month_Number = 2 AND Calendar_Day BETWEEN 15 AND 21 AND Day_Number = 2 THEN 'President''s Day' --3rd Monday In February
		  WHEN Calendar_Date = DATEADD(DAY, -47, UDF.Easter_Date) THEN 'Mardi Gras'
		  WHEN Calendar_Date = DATEADD(DAY, -02, UDF.Easter_Date) THEN 'Good Friday'
		  WHEN Calendar_Date = UDF.Easter_Date THEN 'Easter'
		  WHEN Month_Number = 5 AND Calendar_Day BETWEEN 8 AND 14 AND Day_Number = 1 THEN 'Mother''s Day' --2nd Sunday In May
		  WHEN Month_Number = 5 AND Calendar_Day > 24 AND Day_Number = 2 THEN 'Memorial Day' --Last Monday in May
		  WHEN Month_Number = 6 AND Calendar_Day BETWEEN 15 AND 21 AND Day_Number = 1 THEN 'Father''s Day' --3rd Sunday In June
		  WHEN Month_Number = 9 AND Calendar_Day BETWEEN 1 AND 7 AND Day_Number = 2 THEN 'Labor Day' --1st Monday In September
		  WHEN Month_Number = 10 AND Calendar_Day BETWEEN 8 AND 14 AND Day_Number = 2 THEN 'Columbus Day' --2nd Monday In October
		  WHEN Month_Number = 11 AND Calendar_Day BETWEEN 22 AND 28 AND Day_Number = 5 THEN 'Thanksgiving Day' --4th Thursday In November
		  WHEN Month_Number = 11 AND Calendar_Day BETWEEN 23 AND 29 AND Day_Number = 6 THEN 'Black Friday' --The Friday after Thanksgiving
		  
		  WHEN Month_Number = 12 AND Calendar_Day = 31 AND Day_Number = 6 THEN 'Observed Holiday'
		  WHEN Month_Number = 1 AND Calendar_Day = 1 THEN 'New Year'
		  WHEN Month_Number = 1 AND Calendar_Day = 2 AND Day_Number = 2 THEN 'Observed Holiday'
		  
		  WHEN Month_Number = 2 AND Calendar_Day = 14 THEN 'Valentine''s Day' --14th of February

		  WHEN Month_Number = 3 AND Calendar_Day = 17 THEN 'Saint Patrick''s Day' --17th of March

		  WHEN Month_Number = 7 AND Calendar_Day = 3 AND Day_Number = 6 THEN 'Observed Holiday'
		  WHEN Month_Number = 7 AND Calendar_Day = 4 THEN 'Independence Day' --4th of July
		  WHEN Month_Number = 7 AND Calendar_Day = 5 AND Day_Number = 2 THEN 'Observed Holiday'
		  
		  WHEN Month_Number = 10 AND Calendar_Day = 31 THEN 'Halloween' --31st of October

		  WHEN Month_Number = 11 AND Calendar_Day = 10 AND Day_Number = 6 THEN 'Observed Holiday'
		  WHEN Month_Number = 11 AND Calendar_Day = 11 THEN 'Veteran''s Day' --11th of November
		  WHEN Month_Number = 11 AND Calendar_Day = 12 AND Day_Number = 2 THEN 'Observed Holiday'
		  
		  WHEN Month_Number = 12 AND Calendar_Day = 24 AND Day_Number = 6 THEN 'Observed Holiday'
		  WHEN Month_Number = 12 AND Calendar_Day = 25 THEN 'Christmas'
		  WHEN Month_Number = 12 AND Calendar_Day = 26 AND Day_Number = 2 THEN 'Observed Holiday'
		  ELSE '-' 
       END AS 'Holiday_Name',       
       Month_Name,
       Season_Name
  FROM CTE_Calendar
       CROSS APPLY (SELECT dbo.udf_EasterSundayByYear(Year_Number) AS Easter_Date) AS UDF
)
INSERT INTO #Calendar
(Date_Id, Calendar_Date, Day_Of_The_Week, Is_Workday, Is_Weekend, Calendar_Day, Day_Number, Week_Number, Month_Number, Year_Number, Is_Holiday, Is_Floating, Holiday_Name, Month_Name, Season_Name)
SELECT Date_Id,
       Calendar_Date,
       Day_Of_The_Week,
       IIF(Is_Weekend = 0 AND Holiday_Name = '-', 1, 0) AS 'Is_Workday',
       Is_Weekend,
       Calendar_Day,
       Day_Number,
       Week_Number,
       Month_Number,
       Year_Number,
	  IIF(Holiday_Name = '-', 0, 1) AS 'Is_Holiday',
	  CASE WHEN Holiday_Name IN ('New Year', 'Valentine''s Day', 'Mardi Gras', 'Saint Patrick''s Day', 'Good Friday', 'Easter', 'Independence Day', 'Halloween', 'Veteran''s Day', 'Christmas') THEN 1
	       ELSE 0
       END AS Is_Floating,
       Holiday_Name,
       Month_Name,
       Season_Name
  FROM CTE_Holidays;

SELECT *
  FROM #Calendar
 WHERE 1 = 1
   AND Is_Holiday = 1 AND Is_Floating = 1
   --AND Month_Name = 'November'
 ORDER BY Date_Id;

SET NOCOUNT OFF
GO