IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'udf_enst_SplitAddress' AND xtype = 'IF')
BEGIN
	 DROP FUNCTION dbo.udf_enst_SplitAddress;
END
GO

CREATE FUNCTION dbo.udf_enst_SplitAddress(@address VARCHAR(1000))
RETURNS TABLE AS 
RETURN

/*
 ======================================================================
 Author:	   Naomi Nosonovsky
 Source:       http://blogs.lessthandot.com/index.php/DataMgmt/DataDesign/parsing-the-address-field-to-its-individ
 Create Date:  04-FEB-2013
 Description:  This user-defined function splits 1 column into 3
			   columns having address combined into 
			   into City, State and Zip
 Revision History:
 04-FEB-2013 - RICHARD LEMIEUX
			   Added code to remove Period (.) and Comma (,).
			   Formatted the code.
			   Renamed the function.
			   Added the usage and history.
 Usage:		   SELECT F.* 
			   FROM T
			   CROSS APPLY dbo.udf_enst_SplitAddress(T.Address) F			   
 ======================================================================
*/

(
SELECT F6.City, 
	   F5.[State], 
	   F2.[Zip Code] 
  FROM (SELECT @address AS GROUP_ADDRESS) T
       CROSS APPLY (SELECT REPLACE(REPLACE(GROUP_ADDRESS,'.',''),',',' ') AS ADDR0) F0
       --Find Zip
       CROSS APPLY (SELECT PATINDEX('%[0-9]%',ADDR0) AS DigitPos) F1
       CROSS APPLY (SELECT CASE WHEN DigitPos > 1 THEN SUBSTRING(ADDR0, DigitPos, LEN(ADDR0)) END AS [Zip Code]) F2
       CROSS APPLY (SELECT CASE WHEN [Zip Code] IS NOT NULL THEN RTRIM(REPLACE(ADDR0,[Zip Code],'')) ELSE RTRIM(ADDR0) END AS ADDR3) F3
       -- Deal with N C --> NC
       CROSS APPLY (SELECT CASE WHEN SUBSTRING(ADDR3, LEN(ADDR3)-1, 1) = ' ' AND LEN(ADDR3) >= 3 THEN LTRIM(RTRIM(LEFT(ADDR3, LEN(ADDR3)-2) + RIGHT(ADDR3,1))) ELSE LTRIM(RTRIM(ADDR3)) END AS ADDR4) F4	   
       -- Grab final word as state...could be CALIF, for example
       CROSS APPLY (SELECT CASE WHEN PATINDEX('% %',REVERSE(ADDR4)) > 0 THEN LTRIM(RIGHT(ADDR4,PATINDEX('% %',REVERSE(ADDR4))-1)) END AS STATE) F5
       CROSS APPLY (SELECT CASE WHEN STATE > '' THEN RTRIM(LEFT(ADDR4,LEN(ADDR4)-LEN(STATE))) ELSE ADDR4 END AS City) F6
);