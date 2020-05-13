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
 Author:	    RAGHUNANDAN CUMBAKONAM
 Source:      N/A
 Create Date: 13-AUG-2012
 Description: This udf checks if a given no is prime or not.
 Revision History:
 00-JAN-0001 - N/A
 Usage:		SELECT dbo.udf_primeNbr_check(21)
 ==========================================================================
*/ 

DECLARE @i BIGINT = 3,
        @pflag BIT = 1,
	   @ones TINYINT,
	   @result VARCHAR(100);
	   
SET @ones = RIGHT(@n, 1);
   
IF (@n < 10)
BEGIN
	SELECT @result = 
		   CASE WHEN @n < 1 THEN 'Enter a positive integer'
			   WHEN @n = 1 THEN '1 is neither prime nor composite'
			   WHEN @n = 2 THEN '2 is an even-prime'
			   WHEN @n IN (3, 5, 7) THEN CONCAT(@n, ' is a prime number')
			   ELSE CONCAT(@n, ' is a composite number')
		   END
	RETURN @result;
END

ELSE IF (@n > 9) AND @ones IN (0, 2, 4, 5, 6, 8) 
BEGIN
	SELECT @result = CONCAT(@n, ' is a composite number');
	RETURN @result;
END

ELSE IF (@n > 9) AND @ones IN (1, 3, 7, 9)
BEGIN
	WHILE (@i<=@n/2+1)
	BEGIN
		IF (@n%@i=0)
		BEGIN
		     SET @pflag = 0;
			SELECT @result = CONCAT(@n, ' is a composite number. ', @i, ' is the first factor.');
			BREAK;
		END
		ELSE
			SET @i = @i+IIF(RIGHT(@i, 1) = 3, 4, 2);--Numbers ending in 1, 3, 7 and 9 are divisible by numbers ending in 1, 3, 7 and 9 only.
	END
	SELECT @result = CONCAT(@n, ' is a prime number') WHERE @pflag = 1;
END
	
RETURN @result;
END