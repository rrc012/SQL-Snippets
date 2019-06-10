/*
 ===============================================================================
 Author:	     MADHIVANAN
 Source:       http://beyondrelational.com/modules/2/blogs/70/posts/18694/sorting-mixed-value-strings-numerically.aspx
 Create Date:  16-JAN-2013
 Description:  This script sorts mixed value strings numerically.	
 Revision History:
 17-JAN-2013 - RAGHUNANDAN CUMBAKONAM
			Added the source and history.
 Usage:		N/A			   
 ===============================================================================
*/  

--METHOD 1: REMOVE NON-NUMERICS FROM STRING AND SORT THEM AS NUMBERS 
SELECT *
  FROM Tbl_Name
 ORDER BY STUFF(Column_Name+'a',PATINDEX('%[^0-9]%',Column_Name+'a'),LEN(Column_Name),'')*1;

--METHOD 2: EXTRACT NUMERICS FROM STRING AND SORT THEM AS NUMBERS 
SELECT *
  FROM Tbl_Name
 ORDER BY SUBSTRING(COLUMN_NAME+'a',1,PATINDEX('%[a-zA-Z]%',COLUMN_NAME+'a')-1)*1;

--METHOD 3: SORT FIRST BY THE "STRING" PART AND THEN BY THE "NUMBER" PART (AND THE "NUMBER" MUST BE SORTED NUMERICALLY)
SELECT COLUMN_NAME
  FROM Tbl_Name
 ORDER BY LEFT(COLUMN_NAME+'0', PATINDEX('%[0-9]%', COLUMN_NAME+'0')-1),
		(SUBSTRING(COLUMN_NAME+'0', PATINDEX('%[0-9]%', COLUMN_NAME+'0'), LEN(COLUMN_NAME+'0') - PATINDEX('%[0-9]%', COLUMN_NAME+'0')))*1, 
		COLUMN_NAME;