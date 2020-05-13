DECLARE @ProcStartDate AS DATETIME,
	   @ProcEndDate AS DATETIME,
	   @Days INT;

/*
 ===============================================================================
 Author:	    RAGHUNANDAN CUMBAKONAM
 Source:      N/A
 Create Date: 27-AUG-2012
 Description: This script generates dates between the given date range.	
 Revision History:
 Usage:		   N/A			   
 ===============================================================================
*/  
		
SET @ProcStartDate = '01/01/2020';
SET @ProcEndDate = '04/30/2020';
SET @Days = DATEDIFF(dd, @ProcStartDate, @ProcEndDate+1);

;WITH Nbrs_4(Numbers) AS (SELECT 0 UNION SELECT 1),
      Nbrs_3(Numbers) AS (SELECT 1 FROM Nbrs_4 n1 CROSS JOIN Nbrs_4 n2),
      Nbrs_2(Numbers) AS (SELECT 1 FROM Nbrs_3 n1 CROSS JOIN Nbrs_3 n2),
      Nbrs_1(Numbers) AS (SELECT 1 FROM Nbrs_2 n1 CROSS JOIN Nbrs_2 n2),
      Nbrs_0(Numbers) AS (SELECT 1 FROM Nbrs_1 n1 CROSS JOIN Nbrs_1 n2),
      Nbrs  (Numbers) AS (SELECT ROW_NUMBER() OVER (ORDER BY Numbers)-1 FROM Nbrs_0), 
Calendar (Date_Id, Date_Nm, Day_Nm, Month_Nm, Day_Part, Day_Nbr, Week_Nbr, Month_Nbr, Year_Nbr, Is_Weekday)
AS
(
SELECT TOP(@Days)
	  CONVERT(VARCHAR(8), DATEADD(dd,Numbers,@ProcStartDate), 112) AS 'Date_Id',
	  DATEADD(dd,Numbers,@ProcStartDate) AS 'Date_Nm',
	  DATENAME(dw, DATEADD(dd,Numbers,@ProcStartDate)) AS 'Day_Nm',
	  DATENAME(mm, DATEADD(dd,Numbers,@ProcStartDate)) AS 'Month_Nm',
	  DATEPART(dd, DATEADD(dd,Numbers,@ProcStartDate)) AS 'Day_Part',
	  DATEPART(dw, DATEADD(dd,Numbers,@ProcStartDate)) AS 'Day_Nbr',
	  DATEPART(ww, DATEADD(dd,Numbers,@ProcStartDate)) AS 'Week_Nbr',
	  MONTH(DATEADD(dd,Numbers,@ProcStartDate)) AS 'Month_Nbr',
	  DATEPART(yy, DATEADD(dd,Numbers,@ProcStartDate)) AS 'Year_Nbr',
	  IIF(DATEPART(dw, DATEADD(dd,Numbers,@ProcStartDate)) IN (1, 7), 'Weekend', 'Weekday') 
  FROM Nbrs
)
SELECT *
  FROM Calendar
 WHERE 1 = 1
   AND Is_Weekday != 'Weekend';