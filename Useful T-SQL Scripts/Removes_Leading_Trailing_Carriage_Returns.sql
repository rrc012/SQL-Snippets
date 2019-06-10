/*
 ===============================================================================
 Author:	     RAGHUNANDAN CUMBAKONAM
 Source:       https://stackoverflow.com/questions/31035836/sql-remove-only-leading-or-trailing-carriage-returns
 Create Date:  08-JUN-2017
 Description:  This script removes only leading or trailing carriage returns.
 Usage:		N/A			   
 ===============================================================================
*/

SET NOCOUNT ON
GO

--Find the first character that is not CHAR(13) or CHAR(10) and subtract its position from the string's length.

DECLARE @sLeadingText VARCHAR(MAX),
        @sTrailingText VARCHAR(MAX);

SET @sLeadingText = '
Hello World!';

SET @sTrailingText = 'Hello World!
';

/*Remove only LEADING carriage-returns*/
SELECT @sLeadingText AS With_Leading_CR, RIGHT(@sLeadingText, LEN(@sLeadingText)-PATINDEX('%[^'+CHAR(13)+CHAR(10)+']%',@sLeadingText)+1) AS With_NO_Leading_CR;

/*Remove only TRAILING carriage-returns*/
SELECT @sTrailingText AS With_Trailing_CR, LEFT(@sTrailingText,LEN(@sTrailingText)-PATINDEX('%[^'+CHAR(13)+CHAR(10)+']%',REVERSE(@sTrailingText))+1) AS With_NO_Trailing_CR;