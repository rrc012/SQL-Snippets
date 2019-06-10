IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'usp_primeNbr_generation' AND xtype = 'P')
BEGIN
	 DROP PROC dbo.usp_primeNbr_generation
END
GO

CREATE PROC dbo.usp_primeNbr_generation
@n INT
AS
BEGIN 
SET NOCOUNT ON

/*
 =============================================
 Author:	  RAGHUNANDAN CUMBAKONAM
 Create Date: 14-AUG-2012
 Description: This stored proc generates the
		      first 'n' prime numbers.	
 Usage:       EXEC dbo.usp_primeNbr_generation 100
 =============================================
*/
/*
DECLARE @n INT;
SET @n = 15;
*/

DECLARE @i INT
	   ,@j BIGINT
	   ,@l BIGINT;

SET @i = 0;
SET @j = 3;
SET @l = 7;

IF (@n < 1)
BEGIN
	SELECT 'Enter a positive integer';
	RETURN;
END

IF OBJECT_ID('tempdb..#tbl_primeNbrs') IS NOT NULL DROP TABLE #tbl_primeNbrs;
CREATE TABLE #tbl_primeNbrs
(
 primeNo BIGINT
);

INSERT INTO #tbl_primeNbrs (primeNo)
SELECT 2 UNION ALL
SELECT 3 UNION ALL
SELECT 5;

WHILE (@i<=@n)
BEGIN
	WHILE (@j<=@l/2)
	BEGIN
		IF (@l%@j=0)
		BEGIN
			SET @l = @l + 2;
			SET @j = 3;
			CONTINUE;
		END
		ELSE 
		SET @j = @j + 2;--Numbers ending in 1, 3, 7 and 9 are divisible by numbers ending in 1, 3, 7 and 9 only.
	END
	INSERT INTO #tbl_primeNbrs (primeNo)
	SELECT @l;
	SET @j = 3;
	SET @l = @l + 2;
	SET @i = @i + 1;
END

SELECT TOP (@n) *
FROM #tbl_primeNbrs

SET NOCOUNT OFF
END