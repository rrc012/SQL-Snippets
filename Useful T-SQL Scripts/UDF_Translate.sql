IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'udf_Translate' AND xtype = 'FN')
BEGIN
	 DROP FUNCTION dbo.udf_Translate;
END
GO

CREATE FUNCTION [dbo].[udf_Translate](@inputString VARCHAR(50), @stringToReplace VARCHAR(10), @replacementString VARCHAR(10))
RETURNS VARCHAR(50)
     AS
  BEGIN

/*
 ==========================================================================
 Author:	     RAGHUNANDAN CUMBAKONAM
 Source:       Based on TSQL Beginners Challenge
			http://beyondrelational.com/modules/19/tsql-beginners/336/tsql-beginners-challenge-23-create-sql-server-version-of-the-oracle-translate-function.aspx?tab=info
 Create Date:  06-AUG-2012
 Description:  This udf mimics the TRANSLATE fn in Oracle/PLSQL by
			replacing the 1st character in the string_to_replace 
			with the 1st character in the replacement_string, replace 
			the 2nd character in the string_to_replace with the 
			2nd character in the replacement_string, and so on.
 Revision History:
 00-JAN-0001 - N/A
 Usage:		SELECT dbo.udf_Translate('Raghu', 'au', 'eo')
 ==========================================================================
*/ 

	  DECLARE @translatedString VARCHAR(50);
	  
	  ;WITH CTE1 (DataToReplace, ReplacedWithData)
	  AS
	  (
	  SELECT SUBSTRING(@stringToReplace, number, 1), 
	  	    SUBSTRING(@replacementString, number, 1)
	    FROM master.dbo.spt_values
	   WHERE number BETWEEN 1 AND LEN(@replacementString)
	     AND type = 'P'
	  ),
	  CTE2 (Data)
	  AS
	  (
	  SELECT SUBSTRING(@inputString, number, 1)
	    FROM master.dbo.spt_values
	   WHERE number BETWEEN 1 AND LEN(@inputString)
	     AND type = 'P'
	  )
	  SELECT @translatedString = COALESCE(@translatedString + '','') + COALESCE(ReplacedWithData, Data)
	    FROM CTE2
	         LEFT OUTER JOIN CTE1 ON Data = DataToReplace;
	  
RETURN @translatedString;
   END