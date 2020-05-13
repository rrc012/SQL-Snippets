USE
	YourAss;
GO


-- This query returns the first 100 rows sorted by the account and then by the transaction date & time

SELECT TOP (100)
	TransactionId ,
	AccountId ,
	TransactionDateTime ,
	Amount
FROM
	Billing.Transactions
ORDER BY
	AccountId			ASC ,
	TransactionDateTime	ASC;
GO


-- This statement adds the "Balance" column to the "Billing.Transactions" table.
-- Currently the column contains NULL for all rows.

ALTER TABLE
	Billing.Transactions
ADD
	Balance MONEY NULL;
GO


-- The following batch calculates the running totals using a cursor

DECLARE @AccountId				AS INT;
DECLARE @TransactionDateTime	AS DATETIME2(0);
DECLARE @Amount					AS MONEY;
DECLARE @PrevAccountId			AS INT;
DECLARE @PrevBalance			AS MONEY;

DECLARE
	Transactions
CURSOR
	LOCAL
	STATIC
	READ_ONLY
	FORWARD_ONLY
FOR
	SELECT
		AccountId ,
		TransactionDateTime ,
		Amount
	FROM
		Billing.Transactions
	ORDER BY
		AccountId			ASC ,
		TransactionDateTime	ASC;

OPEN Transactions;

FETCH NEXT FROM
	Transactions
INTO
	@AccountId ,
	@TransactionDateTime ,
	@Amount;

WHILE
	@@FETCH_STATUS = 0
BEGIN

	IF
		@AccountId = @PrevAccountId
	BEGIN
	
		UPDATE
			Billing.Transactions
		SET
			Balance = @PrevBalance + @Amount
		WHERE
			AccountId = @AccountId
		AND
			TransactionDateTime = @TransactionDateTime;

		SET @PrevBalance = @PrevBalance + @Amount;
			
	END
	ELSE
	BEGIN
	
		UPDATE
			Billing.Transactions
		SET
			Balance = @Amount
		WHERE
			AccountId = @AccountId
		AND
			TransactionDateTime = @TransactionDateTime;

		SET @PrevBalance = @Amount;
	
	END;
	
	SET @PrevAccountId = @AccountId;
	
	FETCH NEXT FROM
		Transactions
	INTO
		@AccountId ,
		@TransactionDateTime ,
		@Amount;

END;

CLOSE Transactions;

DEALLOCATE Transactions;
GO


-- This query displays the results of the balance calculation for the first 100 rows

SELECT TOP (100)
	TransactionId ,
	AccountId ,
	TransactionDateTime ,
	Amount ,
	Balance
FROM
	Billing.Transactions
ORDER BY
	AccountId			ASC ,
	TransactionDateTime	ASC;
GO


-- This query displays the amount of rows that have been processed out of the total number of rows

SELECT
	ProcessedRowCount	= COUNT (Balance) ,
	TotalRowCount		= COUNT (*)
FROM
	Billing.Transactions;
GO


-- This statement sets the "Balance" column back to NULL before the next calculation

UPDATE
	Billing.Transactions
SET
	Balance = NULL;
GO


-- The following batches calculate the running totals using a cursor and a temporary table.
-- The "Billing.Transactions" table is updated only once at the end.

CREATE TABLE
	#Transactions
(
	TransactionId	INT		NOT NULL ,
	Balance			MONEY	NOT NULL
);
GO


DECLARE @TransactionId	AS INT;
DECLARE @AccountId		AS INT;
DECLARE @Amount			AS MONEY;
DECLARE @PrevAccountId	AS INT;
DECLARE @PrevBalance	AS MONEY;

DECLARE
	Transactions
CURSOR
	LOCAL
	STATIC
	READ_ONLY
	FORWARD_ONLY
FOR
	SELECT
		TransactionId ,
		AccountId ,
		Amount
	FROM
		Billing.Transactions
	ORDER BY
		AccountId			ASC ,
		TransactionDateTime	ASC;

OPEN Transactions;

FETCH NEXT FROM
	Transactions
INTO
	@TransactionId ,
	@AccountId ,
	@Amount;

WHILE
	@@FETCH_STATUS = 0
BEGIN

	IF
		@AccountId = @PrevAccountId
	BEGIN
	
		INSERT INTO
			#Transactions
		(
			TransactionId ,
			Balance
		)
		VALUES
		(
			@TransactionId ,
			@PrevBalance + @Amount
		)

		SET @PrevBalance = @PrevBalance + @Amount;
			
	END
	ELSE
	BEGIN
	
		INSERT INTO
			#Transactions
		(
			TransactionId ,
			Balance
		)
		VALUES
		(
			@TransactionId ,
			@Amount
		)

		SET @PrevBalance = @Amount;
	
	END;
	
	SET @PrevAccountID = @AccountID;
	
	FETCH NEXT FROM
		Transactions
	INTO
		@TransactionId ,
		@AccountId ,
		@Amount;

END;

CLOSE Transactions;

DEALLOCATE Transactions;
GO


CREATE CLUSTERED INDEX
	ix_Transactions_c_TransactionId
ON
	#Transactions (TransactionId ASC);
GO


UPDATE
	Billing.Transactions
SET
	Balance =	(
					SELECT
						#Transactions.Balance
					FROM
						#Transactions
					WHERE
						#Transactions.TransactionId = Billing.Transactions.TransactionId
				);
GO


DROP TABLE
	#Transactions;
GO


-- This query displays the results of the balance calculation for the first 100 rows

SELECT TOP (100)
	TransactionId ,
	AccountId ,
	TransactionDateTime ,
	Amount ,
	Balance
FROM
	Billing.Transactions
ORDER BY
	AccountId			ASC ,
	TransactionDateTime	ASC;
GO


-- This statement sets the "Balance" column back to NULL before the next calculation

UPDATE
	Billing.Transactions
SET
	Balance = NULL;
GO


-- This statement calculates the running totals using a single UPDATE statement with a self-join.

UPDATE
	Billing.Transactions
SET
	Balance =	(
					SELECT
						SUM (AggregationsTable.Amount)
					FROM
						Billing.Transactions AS AggregationsTable
					WHERE
						AggregationsTable.AccountId = Billing.Transactions.AccountId
					AND
						AggregationsTable.TransactionDateTime <= Billing.Transactions.TransactionDateTime
				);
GO


-- This query displays the results of the balance calculation for the first 100 rows

SELECT TOP (100)
	TransactionId ,
	AccountId ,
	TransactionDateTime ,
	Amount ,
	Balance
FROM
	Billing.Transactions
ORDER BY
	AccountId			ASC ,
	TransactionDateTime	ASC;
GO


-- This statement sets the "Balance" column back to NULL before the next calculation

UPDATE
	Billing.Transactions
SET
	Balance = NULL;
GO


-- The following query calculates the running totals using a window function

UPDATE
	Transactions
SET
	Balance = CalculatedTransactions.Balance
FROM
	Billing.Transactions AS Transactions
INNER JOIN
	(
		SELECT
			TransactionId	= TransactionId ,
			Balance			= SUM (Amount) OVER (PARTITION BY AccountId ORDER BY TransactionDateTime ASC)
		FROM
			Billing.Transactions
	)
	AS
		CalculatedTransactions
ON
	Transactions.TransactionId = CalculatedTransactions.TransactionId
GO


-- This query displays the results of the balance calculation for the first 100 rows

SELECT TOP (100)
	TransactionId ,
	AccountId ,
	TransactionDateTime ,
	Amount ,
	Balance
FROM
	Billing.Transactions
ORDER BY
	AccountId			ASC ,
	TransactionDateTime	ASC;
GO


-- This statement sets the "Balance" column back to NULL before the next calculation

UPDATE
	Billing.Transactions
SET
	Balance = NULL;
GO


-- The following batch calculates the running totals using a single UPDATE statement
-- and a join in order to force ordering

DECLARE @AccountId	AS INT;
DECLARE @Balance	AS MONEY;

UPDATE
	BaseTable
SET
	@Balance = Balance =	CASE
								WHEN AccountId = @AccountId	THEN @Balance + Amount
								ELSE						Amount
							END ,
	@AccountId = AccountId
FROM
	Billing.Transactions AS BaseTable
INNER JOIN
	(
		SELECT TOP (100) PERCENT
			TransactionId
		FROM
			Billing.Transactions
		ORDER BY
			AccountId			ASC ,
			TransactionDateTime	ASC
	)
	AS SortingTable
ON
	BaseTable.TransactionId = SortingTable.TransactionId;
GO


-- This query displays the results of the balance calculation for the first 100 rows

SELECT TOP (100)
	TransactionId ,
	AccountId ,
	TransactionDateTime ,
	Amount ,
	Balance
FROM
	Billing.Transactions
ORDER BY
	AccountId			ASC ,
	TransactionDateTime	ASC;
GO


-- This statement sets the "Balance" column back to NULL before the next calculation

UPDATE
	Billing.Transactions
SET
	Balance = NULL;
GO


-- The following batch calculates the running totals using a single UPDATE statement
-- and an index hint in order to force ordering


DECLARE @AccountId	AS INT;
DECLARE @Balance	AS MONEY;

UPDATE
	Billing.Transactions
SET
	@Balance = Balance =	CASE
								WHEN AccountId = @AccountId	THEN @Balance + Amount
								ELSE						Amount
							END ,
	@AccountId = AccountId
FROM
	Billing.Transactions WITH (INDEX = ix_Transactions_AccountId#TransactionDateTime);
GO


-- This query displays the results of the balance calculation for the first 100 rows

SELECT TOP (100)
	TransactionId ,
	AccountId ,
	TransactionDateTime ,
	Amount ,
	Balance
FROM
	Billing.Transactions
ORDER BY
	AccountId			ASC ,
	TransactionDateTime	ASC;
GO


-- Only SELECT

SELECT
	AggregationsTable.AccountId ,
	AggregationsTable.TransactionDateTime ,
	SUM (AggregationsTable.Amount)
FROM
	Billing.Transactions AS AggregationsTable
GROUP BY
	AggregationsTable.AccountId ,
	AggregationsTable.TransactionDateTime
ORDER BY
	AggregationsTable.AccountId ,
	AggregationsTable.TransactionDateTime;
GO


SELECT
	AccountId ,
	TransactionDateTime ,
	Balance			= SUM (Amount) OVER (PARTITION BY AccountId ORDER BY TransactionDateTime ASC)
FROM
	Billing.Transactions AS Transactions
ORDER BY
	AccountId ,
	TransactionDateTime;
GO
