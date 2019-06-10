/*
 ===============================================================================
 Author:	     RAGHUNANDAN CUMBAKONAM
 Source:       N/A
 Create Date:  17-FEB-2012
 Description:  This script generates "Running Total" for a column using cursor. 
			The cursor approach is much faster than the subquery. Ignore 
			this method & use the OVER Clause for SQL 2012 onwards.	
 Revision History:
 01-AUG-2012 - RAGHUNANDAN CUMBAKONAM
			Refer to the below URL to know the disadvantages of using a
			subquery (TRIANGULAR JOIN) for calculating "Running Total."
			http://www.sqlservercentral.com/articles/T-SQL/61539/
			Added the history.
 Usage:		N/A			   
 ===============================================================================
*/  

SET NOCOUNT ON

DECLARE @RunningTotal NUMERIC(38,6),
	   @Col_1 DATA_TYPE,
	   @Col_2 DATA_TYPE
SET @RunningTotal = 0

IF OBJECT_ID('tempdb..#RunningTotal') IS NOT NULL DROP TABLE #RunningTotal
CREATE TABLE #RunningTotal
(
 Col_1 DATA_TYPE,
 Col_2 DATA_TYPE, --Column whose running total is to be calculated
 RunningTotal NUMERIC(38,6)
)

DECLARE ObjCursor CURSOR LOCAL FAST_FORWARD FOR 
SELECT Col_1, Col_2
  FROM DB_NAME.dbo.TABLE_NAME
 ORDER BY Col_2;

OPEN ObjCursor;

FETCH NEXT FROM ObjCursor INTO @Col_1,@Col_2;
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @RunningTotal = @RunningTotal + @Col_2
	INSERT INTO #RunningTotal (Col_1,Col_2,RunningTotal)VALUES(@Col_1,@Col_2,@RunningTotal)
	FETCH NEXT FROM ObjCursor INTO @Col_1,@Col_2;
END;

CLOSE ObjCursor;

DEALLOCATE ObjCursor;

SELECT *
  FROM #RunningTotal
 ORDER BY Col_2;

DROP TABLE #RunningTotal;

SET NOCOUNT OFF