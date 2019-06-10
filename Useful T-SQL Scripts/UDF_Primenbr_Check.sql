IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'udf_primeNbr_check' AND xtype = 'FN')
BEGIN
	 DROP FUNCTION dbo.udf_primeNbr_check
END
GO

 CREATE FUNCTION [dbo].[udf_primeNbr_check](@n BIGINT)
RETURNS VARCHAR(100)
     AS
  BEGIN

/*
 ==========================================================================
 Author:	   RAGHUNANDAN CUMBAKONAM
 Source:       N/A
 Create Date:  13-AUG-2012
 Description:  This udf checks if a given no is prime or not.
 Revision History:
 00-JAN-0001 - N/A
 Usage:		   SELECT dbo.udf_primeNbr_check(99904829)
 ==========================================================================
*/ 

DECLARE @i BIGINT
	   ,@ones TINYINT
	   ,@result VARCHAR(100);

SET @i = 3;	   
SET @ones = RIGHT(@n, 1);
   
IF (@n < 10)
BEGIN
	SELECT @result = 
		   CASE WHEN @n < 1 THEN 'Enter a positive integer'
				WHEN @n = 1 THEN '1 is neither prime nor composite'
				WHEN @n = 2 THEN '2 is an even-prime'
				WHEN @n IN (3, 5, 7) THEN CAST(@n AS CHAR(1)) + ' is a prime number'
				ELSE CAST(@n AS CHAR(1)) + ' is a composite number'
		   END
	RETURN @result;
END

ELSE IF (@n > 9) AND @ones IN (0, 2, 4, 5, 6, 8) 
BEGIN
	SELECT @result = CAST(@n AS VARCHAR(15)) + ' is a composite number';
	RETURN @result;
END

ELSE IF (@n > 9) AND @ones IN (1, 3, 7, 9)
BEGIN
	WHILE (@i<=@n/2+1)
	BEGIN
		IF (@n%@i=0)
		BEGIN
			SELECT @result = CAST(@n AS VARCHAR(15)) + ' is a composite number. ' 
						   + CAST(@i AS VARCHAR(15)) + ' is the first factor.';
			BREAK;
		END
		ELSE
			SET @i = @i+2;--Numbers ending in 1, 3, 7 and 9 are divisible by numbers ending in 1, 3, 7 and 9 only.
	END
	SELECT @result = CAST(@n AS VARCHAR(15)) + ' is a prime number';
END
	
RETURN @result;
   END