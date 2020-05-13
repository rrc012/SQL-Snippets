USE
	YourAss;
GO


SET STATISTICS IO ON;
GO


-- Change the compatibility level of the database to 110 (SQL Server 2012)

ALTER DATABASE
	YourAss
SET
	COMPATIBILITY_LEVEL = 110;
GO


-- Use SYSDATETIME ()

SELECT
	*
FROM
	Sales.Orders
WHERE
	DateAndTime >= DATEADD (YEAR , -1 , SYSDATETIME ());
GO


-- Use GETDATE ()

SELECT
	*
FROM
	Sales.Orders
WHERE
	DateAndTime >= DATEADD (YEAR , -1 , GETDATE ());
GO


-- Insert orders in the future

INSERT INTO
	Sales.Orders WITH (TABLOCK)
(
	DateAndTime ,
	CustomerId ,
	Amount ,
	OrderStatusId
)
SELECT TOP (100)
	DateAndTime		= DATEADD (MINUTE , ABS (CHECKSUM (NEWID ())) % (60 * 24 * 365) , SYSDATETIME ()) ,
	CustomerId		= ABS (CHECKSUM (NEWID ())) % 10000 + 1 ,
	Amount			= CAST ((ABS (CHECKSUM (NEWID ())) % 100000)  AS MONEY) / 100.0 ,
	OrderStatusId	= ABS (CHECKSUM (NEWID ())) % 5 + 1
FROM
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2;
GO


UPDATE STATISTICS
	Sales.Orders (ix_Orders_nc_nu_DateAndTime)
WITH
	FULLSCAN;
GO


-- Use SYSDATETIME ()

SELECT
	*
FROM
	Sales.Orders
WHERE
	DateAndTime >= DATEADD (YEAR , -1 , SYSDATETIME ());
GO


-- Use GETDATE ()

SELECT
	*
FROM
	Sales.Orders
WHERE
	DateAndTime >= DATEADD (YEAR , -1 , GETDATE ());
GO


-- Change the compatibility level of the database back to 120 (SQL Server 2014)

ALTER DATABASE
	YourAss
SET
	COMPATIBILITY_LEVEL = 120;
GO


-- Use SYSDATETIME ()

SELECT
	*
FROM
	Sales.Orders
WHERE
	DateAndTime >= DATEADD (YEAR , -1 , SYSDATETIME ());
GO


-- Use GETDATE ()

SELECT
	*
FROM
	Sales.Orders
WHERE
	DateAndTime >= DATEADD (YEAR , -1 , GETDATE ());
GO
