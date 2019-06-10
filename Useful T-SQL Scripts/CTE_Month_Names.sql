/*
 ======================================================================
 Author:	    KARTHIKEYAN MANI
 Source:      http://www.sqlservercentral.com/articles/Reporting+Services+%28SSRS%29/87058/
 Create Date: 14-MAR-2012
 Description: This CTE generates the month names in order.	
 ======================================================================
*/
WITH CTEMonth
AS
(
      SELECT 1 AS Month_Number

       UNION ALL

      SELECT Month_Number + 1 -- add month number to 1 recursively
        FROM CTEMonth
       WHERE Month_Number < 12 -- just to restrict the monthnumber upto 12
)
SELECT Month_Number,
       DATENAME(MONTH,DATEADD(MONTH,Month_Number,0)- 1) AS Month_Name -- function to list the monthname.
  FROM CTEMonth;