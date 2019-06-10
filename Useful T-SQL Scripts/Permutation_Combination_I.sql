SET NOCOUNT ON
GO

/*
 ========================================================
 Author:	   RAGHUNANDAN CUMBAKONAM
 Source:       N/A
 Create Date:  03-AUG-2012
 Description:  This script computes permutation and 
			   combination for a given 'n' & 'r' value.	
 Revision History:
 00-JAN-0001 - N/A
 Usage:		   N/A			   
 ========================================================
*/ 

DECLARE @n    TINYINT,
        @r    TINYINT,
        @nPr  BIGINT,
        @fact BIGINT;

SET @n = 10;
SET @r = 5;
SET @nPr = 1;
SET @fact = 1;

--Calculate Factorial - r!
SELECT @fact = @fact * number
  FROM master.dbo.spt_values
 WHERE number BETWEEN 2 AND @r
   AND type = 'P';

--Calculate Permutation - nPr
SELECT @nPr = @nPr * number
  FROM master.dbo.spt_values
 WHERE number BETWEEN (@n-@r+1) AND @n
   AND type = 'P';

--Calculate Combination - nCr
SELECT @nPr AS [Permutation - nPr], @fact AS [Factorial - r!], @nPr/@fact AS [Combination - nCr];

SET NOCOUNT OFF
GO