IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'udf_UniversalCurrencyFormatter' AND xtype = 'TF')
BEGIN
	 DROP FUNCTION dbo.udf_UniversalCurrencyFormatter;
END
GO

CREATE FUNCTION [dbo].[udf_UniversalCurrencyFormatter] 
(
    @BigMoney              DECIMAL(38,3) -- The amount to be formatted
   ,@CountryCode           CHAR(2)		 -- The 2 character ISO country code
   ,@Currency              INT			 -- How to format the currency symbols - allowed values are:
										 -- 0 = none(default), 1 = symbol, 2 = code
)
RETURNS @Results TABLE (FormattedCurrency NVARCHAR(100))
WITH SCHEMABINDING
AS
BEGIN

/*
 ======================================================================
 Author:	   DWAIN CAMPS
 Source:       https://www.simple-talk.com/sql/learn-sql-server/a-sql-based-universal-currency-formatter/
 Create Date:  04-FEB-2013
 Description:  UniversalCurrencyFormatter is designed to apply international formatting
			   standards to a decimal amount including decorators (e.g., comma separators
			   in the correct positions and decimal symbol), along with the currency code
			   or symbol depending on which is selected.
 Revision History:
 07-MAR-2013 - RAGHUNANDAN CUMBAKONAM 
			   Formatted the code.
			   Renamed the function.
			   Added the usage and history.
 Usage:		   			   
 ======================================================================
*/

    DECLARE @FormattedMoney    NVARCHAR(100) = @BigMoney
		   ,@CurrencyDecimals  INT
		   ,@CurrencySymbol    NVARCHAR(3)
		   ,@CurrencyCode      CHAR(3)
		   ,@DecimalChar       CHAR(1);

    DECLARE @LMoney         INT = LEN(@FormattedMoney) - CHARINDEX('-', @FormattedMoney);

    -- STUFF the separator character into the formatted currency as often as needed
    -- The CASE is for special handling when RecordCount = 0 (no formatting required)
    SELECT @FormattedMoney = 
        CASE RecordCount 
            WHEN 0 THEN @FormattedMoney
            ELSE STUFF(@FormattedMoney ,LEN(@FormattedMoney) - Offset, 0, a.SeparatorChar) 
		END
        -- These 4 pieces of information are retained for final formatting of the output string
        ,@CurrencyDecimals  = a.CurrencyDecimals    -- Number of decimal digits
        ,@CurrencyCode      = a.CurrencyCode        -- Three character ISO currency code
        ,@CurrencySymbol    = a.CurrencySymbol      -- The UNICODE currency symbol
        ,@DecimalChar       = a.DecimalChar         -- The decimal (decorator) character
    FROM dbo.Countries a
    -- Calculate the number of records to use from the CurrencyFormats table
    CROSS APPLY (SELECT LeadingDigits = PATINDEX('%[^#]%', CurrencyFormat)-1) b
    CROSS APPLY (SELECT RecordCount = ISNULL((@LMoney-(8-LeadingDigits))/LeadingDigits, 0)) c
    -- Our CurrencyFormats table provides the offsets from the right for each format type
    OUTER APPLY (/*Use OUTER APPLY in case RecordCount = 0
        Rows are retrieved in increasing offset sequence due to CLUSTERED INDEX*/
        SELECT TOP (RecordCount) CurrencyFormat, Offset
        FROM dbo.CurrencyFormats b
        WHERE a.CurrencyFormat = b.CurrencyFormat
        ) d 
    WHERE a.CountryCode2Letter = @CountryCode
    OPTION(MAXDOP 1);

    INSERT INTO @Results
    -- Decide what leading currency symbol to include 
    SELECT CASE WHEN @Currency IS NULL THEN N''
				WHEN @Currency = 1 THEN
									-- Use the UNICODE currency symbol 
								   CASE WHEN @CurrencySymbol IS NULL THEN N'' ELSE @CurrencySymbol END
            -- Use the currency code with a trailing blank space
				WHEN @Currency=2 THEN @CurrencyCode + N' ' 
				ELSE N'' 
		   END +
        -- Include the formatted whole currency amount
        LEFT(@FormattedMoney, LEN(@FormattedMoney) - 4) + 
        -- And the correct decimal decorator if required
        CASE @CurrencyDecimals WHEN 0 THEN N'' ELSE @DecimalChar END +
        -- Strip off any unneeded decimal digits from our formatted currency string
        LEFT(RIGHT(@FormattedMoney, 3), @CurrencyDecimals); 

		RETURN;

END