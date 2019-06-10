/*
 ===============================================================
 Author:	    NILADRI BISWAS 
 Source:      http://beyondrelational.com/blogs/niladribiswas/archive/2012/01/01/split-a-set-of-contiguous-string-into-individual-characters-letters-using-set-based-approach.aspx
 Create Date: 25-JAN-2012
 Description: This UDF splits a set of contiguous string into individual characters/letters 
		    using Set-Based approach.	
 ===============================================================
*/
--FUNCTION DEFINITION
IF  EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'[dbo].[SplitIntoIndividualLetters]') AND TYPE IN (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[SplitIntoIndividualLetters]
GO

CREATE FUNCTION [dbo].[SplitIntoIndividualLetters] (@Str VARCHAR(8000))
RETURNS @Lettertable TABLE (letters VARCHAR(8000))
AS  
BEGIN
		;WITH NumCte AS
		(
			SELECT Number = 1 UNION ALL
			SELECT Number +1 FROM NumCte 
			WHERE Number < 1000
		)
		INSERT INTO @Lettertable(letters)
		SELECT SUBSTRING(@str,Number,1)        
		  FROM  NumCte
		 WHERE Number BETWEEN 1 AND LEN(@str)
		OPTION (MAXRECURSION 0);
	RETURN
END          
 
--USAGE ON A STRING
DECLARE @str VARCHAR(50) = 'abcde'
SELECT *
  FROM dbo.SplitIntoIndividualLetters(@str);

--USAGE ON A TABLE
SELECT OriginalData = A.City,
	  l.Letters
  FROM AdventureWorks.Person.Address AS A
       CROSS APPLY dbo.SplitIntoIndividualLetters(A.City) AS l
 WHERE A.AddressID = 570;

/**************************************************
 Using the master.dbo.spt_values as a Number Table
**************************************************/
--USAGE ON A STRING
DECLARE @str VARCHAR(50) = 'abcde'
SELECT Data = SUBSTRING(@str,Number,1)        
  FROM master.dbo.spt_values
 WHERE Number BETWEEN 1 AND LEN(@str)
   AND TYPE = 'P' 

--USAGE ON A TABLE
SELECT Data = SUBSTRING(A.City,Number,1)        
  FROM AdventureWorks.Person.Address AS A
       INNER JOIN master.dbo.spt_values ON Number BETWEEN 1 AND LEN(A.City)
              AND TYPE = 'P'
 WHERE A.AddressID = 1;