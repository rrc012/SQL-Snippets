USE
	YourAss;
GO


SET STATISTICS IO ON;
GO


-- Update 100 rows based on an IN predicate

UPDATE
	Sales.Orders
SET
	OrderStatusId = 2
WHERE
	Id IN
		(
			SELECT TOP (100)
				Id
			FROM
				Sales.Orders
			ORDER BY
				Amount DESC
		);
GO


-- Update 100 rows using a join with a derived table

UPDATE
	Orders
SET
	OrderStatusId = 2
FROM
	Sales.Orders AS Orders
INNER JOIN
	(
		SELECT TOP (100)
			Id
		FROM
			Sales.Orders
		ORDER BY
			Amount DESC
	)
	AS
		RowsToUpdate
ON
	Orders.Id = RowsToUpdate.Id;
GO


-- Update 100 rows by updating a derived table directly

UPDATE
	RowsToUpdate
SET
	OrderStatusId = 2
FROM
	(
		SELECT TOP (100)
			Id ,
			OrderStatusId
		FROM
			Sales.Orders
		ORDER BY
			Amount DESC
	)
	AS
		RowsToUpdate
GO
