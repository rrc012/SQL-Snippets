USE AdventureWorks
GO

--For Best Experience:
--Enable Actual Execution Plan

/*****************************
--Bad Thing #1: Lookups (that sneak in)
*****************************/

--Make the situation as bad as it can be
DBCC DROPCLEANBUFFERS
GO

--Our query, totally tuned up...
SELECT
	*
INTO #x
FROM Production.TransactionHistory
WHERE 
	ProductID BETWEEN 1000 AND 1100
GO

ALTER TABLE Production.TransactionHistory
ADD CustomerId INT NULL
GO

DROP TABLE #x
GO

DBCC DROPCLEANBUFFERS
GO

--The same query... a bit slower
SELECT
	*
INTO #x
FROM Production.TransactionHistory
WHERE 
	ProductID BETWEEN 1000 AND 1100
GO

--Clean up
ALTER TABLE Production.TransactionHistory
DROP COLUMN CustomerId
GO

/*****************************
--Bad Thing #2: Spool
*****************************/

--prep -- create a table of non-distinct product IDs
SELECT 
	ProductID
INTO #products
FROM Production.TransactionHistory
CROSS APPLY 
(
	SELECT 
		1

	UNION ALL

	SELECT
		2
	WHERE
		ProductID % 5 = 0

	UNION ALL

	SELECT
		3
	WHERE
		ProductID % 7 = 0
) x(m)
WHERE
	ProductID BETWEEN 1001 AND 12001
GO

--The dreaded "performance spool"
SELECT
	p.ProductID,
	AVG(x.ActualCost) AS AvgCostTop40
FROM #products AS p
CROSS APPLY
(
	SELECT
		t.*,
		ROW_NUMBER() OVER 
		(
			PARTITION BY 
				p.ProductID 
			ORDER BY 
				t.ActualCost DESC
		) AS r
	FROM Production.TransactionHistory AS t 
	WHERE
		p.ProductID = t.ProductID
) AS x
WHERE
	x.r BETWEEN 1 AND 40
GROUP BY
	p.ProductID
GO

--Two options:
	--Give the optimizer more information (yes!)
	--Use TF 8690 (last resort)

--How non-unique does it have to be to actually be better?
--Try once, then do 8690 vs normal
INSERT #products
SELECT *
FROM #products
GO

--Still not faster..? Try again...
INSERT #products
SELECT *
FROM #products
GO

--Clean up
DROP TABLE #products
GO


/*****************************
--Bad Thing #3: Oversized Sorts
*****************************/

--Find the 500 (or so) products that sold for the highest cost, among those that sold for > 5000
--(Filtered on ProductID BETWEEN 1000 AND 20000 so that the demo finishes in a timely manner)
SELECT TOP(500) WITH TIES
	ProductID,
	ActualCost
FROM
(

	SELECT
		ProductID,
		ActualCost,
		ROW_NUMBER() OVER
		(
			PARTITION BY
				ProductID
			ORDER BY
				ActualCost DESC
		) AS r
	FROM Production.TransactionHistory
	WHERE
		ActualCost >= 5000
		AND ProductID BETWEEN 1000 AND 20000
) AS x
WHERE
	x.r = 1
ORDER BY
	x.ActualCost DESC
GO


--Not giving the optimizer enough information == SLOW!

--Solution: Create an index. OR, give the optimizer more to work with...
--Remember: Scan == O(N). Sort == O(N * LOG(N)).

--More, smaller sorts == better performance
SELECT TOP(500) WITH TIES
	p.ProductID,
	x.ActualCost
FROM Production.Product AS p
CROSS APPLY
(
	SELECT
		bt.ActualCost,
		ROW_NUMBER() OVER
		(
			ORDER BY
				bt.ActualCost DESC
		) AS r
	FROM Production.TransactionHistory AS bt
	WHERE
		bt.ProductID = p.ProductID
		AND bt.ActualCost >= 5000
) AS x
WHERE
	p.ProductID BETWEEN 1000 AND 20000
	AND x.r = 1
ORDER BY
	x.ActualCost DESC
GO

/*****************************
--Bad Thing #4: Inappropriate Hash Match
*****************************/

--Scenario: we've loaded some transactions from an external source
--We want to verify the data against our existing transactions


--Here are our new transactions, in a temp table
SELECT TOP(1500000)
	ProductID,
	TransactionDate,
	Quantity,
	ActualCost
INTO #bth
FROM Production.TransactionHistory
WHERE
	ProductID BETWEEN 1 AND 40001
GO


--Exacerbate the problem
DBCC DROPCLEANBUFFERS
GO

--hash match MAY indicate lack of appropriate indexes

--how many transactions do we have in our temp table for products 1501 through 2201?
SELECT 
	COUNT(*)
FROM #bth AS b
WHERE 
	EXISTS
	(
		SELECT 
			*
		FROM Production.TransactionHistory AS bth
		WHERE
			bth.TransactionDate = b.TransactionDate
			AND bth.ProductID = b.ProductID
			AND bth.ProductID BETWEEN 1501 AND 2201
	)
OPTION (MAXDOP 1)
GO


--Try creating an index...
CREATE CLUSTERED INDEX ix_ProductID_TransactionDate
ON #bth
(
	ProductID,
	TransactionDate
)
GO

/*****************************
--Bad Thing #5: Serial Nested Loops
*****************************/

--Set up a temp table with most of the products...
SELECT 
	ProductID,
	Name
INTO #p
FROM Production.Product
WHERE
	ProductID <= 44999
GO

--Index the table
CREATE UNIQUE CLUSTERED INDEX ix_x 
ON #p 
(
	ProductID
)
GO

--Now insert some more products... 
INSERT #p 
(
	ProductID
)
SELECT 
	ProductID
FROM Production.Product
WHERE
	ProductID > 44999
GO

--Fast query?
SELECT
	p.Name AS ProductName,
	x.TheYear,
	x.TheMonth,
	x.TotalSales
FROM #p AS p
INNER JOIN
(
	SELECT
		ProductID,
		YEAR(TransactionDate) AS TheYear,
		MONTH(TransactionDate) AS TheMonth,
		SUM(ActualCost) AS TotalSales
	FROM dbo.Production.TransactionHistory
	GROUP BY
		ProductID,
		YEAR(TransactionDate),
		MONTH(TransactionDate)
) AS x ON
	p.ProductID = x.ProductID
WHERE
	p.ProductID > 44999
GO

--Try again after a stats update...
UPDATE STATISTICS #p
GO

--Trouble with autostats thresholds on large tables?
--SQL Server 2008 R2+ -- TF 2371
--https://blogs.msdn.com/b/saponsqlserver/archive/2011/09/07/changes-to-automatic-update-statistics-in-sql-server-traceflag-2371.aspx

/*****************************
--Bad Thing #6: Scans That Don't Look Like Scans
*****************************/

--A one-row estimate. Cheap query, right?
SELECT
	*
FROM Production.TransactionHistory AS bth
WHERE
	ProductID BETWEEN 1001 AND 50001
	AND ActualCost > 5000000
GO


--Do a bit more evaluation...
SET STATISTICS IO ON
GO

SELECT
	*
FROM Production.TransactionHistory AS bth
WHERE
	ProductID BETWEEN 1001 AND 50001
	AND ActualCost > 5000000
GO


--UNDOCUMENTED trace flag to see more detail...
SELECT
	*
FROM Production.TransactionHistory AS bth
WHERE
	ProductID BETWEEN 1001 AND 50001
	AND ActualCost > 5000000
OPTION (QUERYTRACEON 9130)
GO

--Scenario:
--For reporting purposes, we need to constrain the dates for products
--So we put that information into a table somewhere...
CREATE TABLE #validProductRanges
(
	ProductID INT,
	StartDate DATETIME,
	EndDate DATETIME,
	PRIMARY KEY (ProductID)
)

INSERT #validProductRanges 
SELECT
	ProductID,
	'20040101', 
	'20120101'
FROM Production.Product
WHERE
	ProductID BETWEEN 1001 AND 10001
GO

--Exacerbate problems...
DBCC DROPCLEANBUFFERS
GO

--Ask for the first 100 transactions per product, in range, after a certain start date
DECLARE @start_date DATE = '2010-08-10'

SELECT
	p.*
FROM #validProductRanges AS vr
CROSS APPLY
(
	SELECT TOP(100)
		bt.TransactionDate,
		bt.ProductID,
		bt.ActualCost
	FROM dbo.Production.TransactionHistory AS bt
	WHERE
		bt.ProductID = vr.ProductID
		AND bt.TransactionDate BETWEEN vr.StartDate and vr.EndDate
		AND bt.TransactionDate >= @start_date
	ORDER BY
		bt.TransactionDate
) AS p
GO

DBCC DROPCLEANBUFFERS
GO

--Try again, but re-write the date predicates
DECLARE @start_date DATE = '2010-08-10'

SELECT
	p.*
FROM #validProductRanges AS vr
CROSS APPLY
(
	SELECT TOP(100)
		bt.TransactionDate,
		bt.ProductID,
		bt.ActualCost
	FROM dbo.Production.TransactionHistory AS bt
	WHERE
		bt.ProductID = vr.ProductID
		AND bt.TransactionDate >= 
			CASE
				WHEN @start_date > vr.StartDate THEN @start_date
				ELSE vr.StartDate
			END 
		AND bt.TransactionDate <= vr.EndDate
) AS p
GO