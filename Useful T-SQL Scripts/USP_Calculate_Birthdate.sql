IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'usp_calculate_birthDate' AND xtype = 'P')
BEGIN
	 DROP PROC usp_calculate_birthDate
END
GO

CREATE PROCEDURE usp_calculate_birthDate
@Num INT
AS
BEGIN

/*
 ===============================================================
 Author:      RAMIREDDY
 Source:      http://beyondrelational.com/modules/1/justlearned/412/tips/9502/mathematics-puzzle-birthdate.aspx
 Create Date: 20-MAR-2012
 Description: This stored proc calculates the birth date. The 
		    input number is obtained by taking one's birth 
		    date and multiplying day with 12 and Month with 31 
		    and add those results.
 Usage:       EXEC usp_calculate_birthDate 297
 ===============================================================
*/

SET NOCOUNT ON

SELECT 
    MonthNum,
    (@Num-31*MonthNum)/12 AS DayNum 
FROM ( 
    SELECT  
        CASE 
            WHEN @Num%2 = 1 THEN 1 + ((@Num-31)%12) 
            ELSE 2 + (@Num-62)%12 
        END AS MonthNum 
) t

SET NOCOUNT OFF
END