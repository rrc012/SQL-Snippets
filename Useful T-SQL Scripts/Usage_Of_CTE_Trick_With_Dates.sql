/*
 ===============================================================================
 Author:	   SURESH MAGANTI
 Source:       http://www.sqlservercentral.com/articles/Cursor+vs+Recursive+CTE/99795/
 Article Name: Usage of CTE - Trick with Dates
 Create Date:  18-JUN-2013
 Description:  This script duplicates each row in the table as many times as 
			   the value of Month_Count in that row and that each new row has 
			   its Date_Field value incremented by one month. The duplication  
			   has to be stopped as soon as the month value in the column 
			   Month_Count for that row is reached.	
 Revision History:
 18-JUN-2013 - RAGHUNANDAN CUMBAKONAM
			 - Formatted the code.
			 - Added the history.

 Usage:		   N/A			   
 ===============================================================================
*/  

--If the table exists, drop it.
IF OBJECT_ID('tempdb..#abc') IS NOT NULL DROP TABLE #abc;
GO

--Create the source table - dbo.abc.
CREATE TABLE #abc
(SeqNo SMALLINT
,Date_Field SMALLDATETIME
,Month_Count TINYINT
,Payment DECIMAL(10,2))
GO

--Populate the source table - dbo.abc
INSERT INTO #abc (SeqNo, Date_Field, Month_Count, Payment)
SELECT 1, '20090101', 10, 100 UNION ALL
SELECT 2, '20100101',  7, 200 UNION ALL
SELECT 3, '20110101',  5, 300
GO

;WITH CTE_Base
 AS
(SELECT SeqNo, Date_Field, Month_Count, Payment, Date_Field AS Begin_Date, DATEADD(mm, Month_Count-1, Date_Field) AS End_Date, 1 AS Frequency
   FROM #abc
	    UNION ALL
 SELECT SeqNo, DATEADD(mm, Frequency, Date_Field), Month_Count, Payment, Begin_Date, End_Date, Frequency
   FROM CTE_Base
  WHERE DATEADD(mm, Frequency, Date_Field) BETWEEN Begin_Date AND End_Date
)
SELECT SeqNo, Date_Field, Month_Count, Payment
  FROM CTE_Base
 ORDER BY SeqNo, Date_Field