/*
 ======================================================================
 Author:	     Madhivanan
 Source:       http://www.sqlservercurry.com/2012/12/remove-non-alphabet-characters-from.html
 Create Date:  02-JAN-2016
 Description:  This code removes non-alphabets from a string.	
 Revision History:
 05-JAN-2016 - RAGHUNANDAN CUMBAKONAM 
               Added the source details
               Replaced WHILE LOOP with TALLY Table
 ======================================================================
*/

DECLARE @str VARCHAR(20) = 'ab12#89L(h12k',
        @temp_str VARCHAR(20) = '';

WITH Tally
AS
(
SELECT TOP (LEN(@str)) ROW_NUMBER() OVER (ORDER BY(SELECT 1)) AS Nbrs
  FROM sys.all_columns ac1 
       CROSS JOIN sys.all_columns ac2
)
SELECT @temp_str = @temp_str + CASE WHEN SUBSTRING(@str, Nbrs, 1) LIKE '[a-zA-Z]' THEN SUBSTRING(@str, Nbrs, 1) ELSE '' END
  FROM Tally;

SELECT @temp_str;