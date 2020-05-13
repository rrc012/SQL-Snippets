USE
	YourAss;
GO


-- Empty the procedure cache

DBCC FREEPROCCACHE;
GO


-- Create the "Marketing.usp_CustomersByLastPurchaseDate" stored procedure,
-- which retrieves customers who last purchsed after a certain date.
-- This stored procedure uses a default value (NULL) for the @Date parameter.

CREATE PROCEDURE
	Marketing.usp_CustomersByLastPurchaseDate
(
	@Date AS DATE = NULL
)
WITH
	RECOMPILE
AS

IF
	@Date IS NULL
BEGIN

	SET @Date = DATEADD (WEEK , -1 , SYSDATETIME ())

END;

SELECT
	Id ,
	Name ,
	Country ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	LastPurchaseDate >= @Date;
GO


-- Create a non-clustered index on the "LastPurchaseDate" column

CREATE NONCLUSTERED INDEX
	ix_Customers_nc_nu_LastPurchaseDate
ON
	Marketing.Customers (LastPurchaseDate ASC);
GO


-- Execute the "Marketing.usp_CustomersByLastPurchaseDate" stored procedure with @Date = '2011-09-01'

EXECUTE Marketing.usp_CustomersByLastPurchaseDate
	@Date = '2011-09-01';
GO


-- Execute the "Marketing.usp_CustomersByLastPurchaseDate" stored procedure with the default value
-- for the @Date parameter (NULL)

EXECUTE Marketing.usp_CustomersByLastPurchaseDate;
GO


-- Solution #1: Use OPTION (RECOMPILE)

ALTER PROCEDURE
	Marketing.usp_CustomersByLastPurchaseDate
(
	@Date AS DATE = NULL
)
WITH
	RECOMPILE
AS

IF
	@Date IS NULL
BEGIN

	SET @Date = DATEADD (WEEK , -1 , SYSDATETIME ())

END;

SELECT
	Id ,
	Name ,
	Country ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	LastPurchaseDate >= @Date
OPTION
	(RECOMPILE);
GO


-- Execute the "Marketing.usp_CustomersByLastPurchaseDate" stored procedure with the default value
-- for the @Date parameter (NULL)

EXECUTE Marketing.usp_CustomersByLastPurchaseDate;
GO


-- Solution #2: Create an inner stored procedure - "Marketing.usp_CustomersByLastPurchaseDate_Inner",
-- which receives the final @Date parameter without modifying it

CREATE PROCEDURE
	Marketing.usp_CustomersByLastPurchaseDate_Inner
(
	@Date AS DATE
)
WITH
	RECOMPILE
AS

SELECT
	Id ,
	Name ,
	Country ,
	LastPurchaseDate
FROM
	Marketing.Customers
WHERE
	LastPurchaseDate >= @Date;
GO


-- Alter the "Marketing.usp_CustomersByLastPurchaseDate" stored procedure to only
-- prepare the value for the @Date parameter and call the
-- "Marketing.usp_CustomersByLastPurchaseDate_Inner" stored procedure

ALTER PROCEDURE
	Marketing.usp_CustomersByLastPurchaseDate
(
	@Date AS DATE = NULL
)
WITH
	RECOMPILE
AS

IF
	@Date IS NULL
BEGIN

	SET @Date = DATEADD (WEEK , -1 , SYSDATETIME ());

END;

EXECUTE Marketing.usp_CustomersByLastPurchaseDate_Inner
	@Date = @Date;
GO


-- Execute the "Marketing.usp_CustomersByLastPurchaseDate" stored procedure with the default value
-- for the @Date parameter (NULL)

EXECUTE Marketing.usp_CustomersByLastPurchaseDate;
GO
