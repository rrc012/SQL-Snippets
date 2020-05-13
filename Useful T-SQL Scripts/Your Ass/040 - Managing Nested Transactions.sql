USE
	YourAss;
GO


-- Demonstrate the behavior of COMMIT TRANSACTION

SELECT
	TranCount = @@TRANCOUNT;
GO


BEGIN TRANSACTION;
GO


SELECT
	TranCount = @@TRANCOUNT;
GO


INSERT INTO
	Casino.Games
(
	GameType ,
	PlayerId ,
	BetAmount ,
	Profit
)
SELECT
	GameType	=	CASE RandomValueTable.RandomValue
						WHEN 1	THEN N'Roulette'
						WHEN 2	THEN N'Slot'
						WHEN 3	THEN N'Blackjack'
						WHEN 4	THEN N'Poker'
						WHEN 5	THEN N'Bingo'
					END ,
	PlayerId	= ABS (CHECKSUM (NEWID ())) % 10000 + 1 ,
	BetAmount	= CAST ((ABS (CHECKSUM (NEWID ())) % 10 + 1) AS MONEY) ,
	Profit		= CAST ((CHECKSUM (NEWID ()) % 101) AS MONEY)
FROM
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 5 + 1
	)
	AS
		RandomValueTable;
GO


SELECT
	GameCount = COUNT (*)
FROM
	Casino.Games;
GO


BEGIN TRANSACTION;
GO


SELECT
	TranCount = @@TRANCOUNT;
GO


INSERT INTO
	Casino.Games
(
	GameType ,
	PlayerId ,
	BetAmount ,
	Profit
)
SELECT
	GameType	=	CASE RandomValueTable.RandomValue
						WHEN 1	THEN N'Roulette'
						WHEN 2	THEN N'Slot'
						WHEN 3	THEN N'Blackjack'
						WHEN 4	THEN N'Poker'
						WHEN 5	THEN N'Bingo'
					END ,
	PlayerId	= ABS (CHECKSUM (NEWID ())) % 10000 + 1 ,
	BetAmount	= CAST ((ABS (CHECKSUM (NEWID ())) % 10 + 1) AS MONEY) ,
	Profit		= CAST ((CHECKSUM (NEWID ()) % 101) AS MONEY)
FROM
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 5 + 1
	)
	AS
		RandomValueTable;
GO


SELECT
	GameCount = COUNT (*)
FROM
	Casino.Games;
GO


COMMIT TRANSACTION;
GO


SELECT
	TranCount = @@TRANCOUNT;
GO


SELECT
	GameCount = COUNT (*)
FROM
	Casino.Games;
GO


COMMIT TRANSACTION;
GO


SELECT
	TranCount = @@TRANCOUNT;
GO


SELECT
	GameCount = COUNT (*)
FROM
	Casino.Games;
GO


COMMIT TRANSACTION;
GO


-- Demonstrate the behavior of ROLLBACK TRANSACTION

BEGIN TRANSACTION;
GO


SELECT
	TranCount = @@TRANCOUNT;
GO


INSERT INTO
	Casino.Games
(
	GameType ,
	PlayerId ,
	BetAmount ,
	Profit
)
SELECT
	GameType	=	CASE RandomValueTable.RandomValue
						WHEN 1	THEN N'Roulette'
						WHEN 2	THEN N'Slot'
						WHEN 3	THEN N'Blackjack'
						WHEN 4	THEN N'Poker'
						WHEN 5	THEN N'Bingo'
					END ,
	PlayerId	= ABS (CHECKSUM (NEWID ())) % 10000 + 1 ,
	BetAmount	= CAST ((ABS (CHECKSUM (NEWID ())) % 10 + 1) AS MONEY) ,
	Profit		= CAST ((CHECKSUM (NEWID ()) % 101) AS MONEY)
FROM
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 5 + 1
	)
	AS
		RandomValueTable;
GO


SELECT
	GameCount = COUNT (*)
FROM
	Casino.Games;
GO


BEGIN TRANSACTION;
GO


SELECT
	TranCount = @@TRANCOUNT;
GO


INSERT INTO
	Casino.Games
(
	GameType ,
	PlayerId ,
	BetAmount ,
	Profit
)
SELECT
	GameType	=	CASE RandomValueTable.RandomValue
						WHEN 1	THEN N'Roulette'
						WHEN 2	THEN N'Slot'
						WHEN 3	THEN N'Blackjack'
						WHEN 4	THEN N'Poker'
						WHEN 5	THEN N'Bingo'
					END ,
	PlayerId	= ABS (CHECKSUM (NEWID ())) % 10000 + 1 ,
	BetAmount	= CAST ((ABS (CHECKSUM (NEWID ())) % 10 + 1) AS MONEY) ,
	Profit		= CAST ((CHECKSUM (NEWID ()) % 101) AS MONEY)
FROM
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 5 + 1
	)
	AS
		RandomValueTable;
GO


SELECT
	GameCount = COUNT (*)
FROM
	Casino.Games;
GO


ROLLBACK TRANSACTION;
GO


SELECT
	TranCount = @@TRANCOUNT;
GO


SELECT
	GameCount = COUNT (*)
FROM
	Casino.Games;
GO


-- Demonstrate the behavior of ROLLBACK TRANSACTION with named transactions

BEGIN TRANSACTION
	InsertNewGame;
GO


SELECT
	TranCount = @@TRANCOUNT;
GO


INSERT INTO
	Casino.Games
(
	GameType ,
	PlayerId ,
	BetAmount ,
	Profit
)
SELECT
	GameType	=	CASE RandomValueTable.RandomValue
						WHEN 1	THEN N'Roulette'
						WHEN 2	THEN N'Slot'
						WHEN 3	THEN N'Blackjack'
						WHEN 4	THEN N'Poker'
						WHEN 5	THEN N'Bingo'
					END ,
	PlayerId	= ABS (CHECKSUM (NEWID ())) % 10000 + 1 ,
	BetAmount	= CAST ((ABS (CHECKSUM (NEWID ())) % 10 + 1) AS MONEY) ,
	Profit		= CAST ((CHECKSUM (NEWID ()) % 101) AS MONEY)
FROM
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 5 + 1
	)
	AS
		RandomValueTable;
GO


SELECT
	GameCount = COUNT (*)
FROM
	Casino.Games;
GO


BEGIN TRANSACTION
	InsertNewGame2;
GO


SELECT
	TranCount = @@TRANCOUNT;
GO


INSERT INTO
	Casino.Games
(
	GameType ,
	PlayerId ,
	BetAmount ,
	Profit
)
SELECT
	GameType	=	CASE RandomValueTable.RandomValue
						WHEN 1	THEN N'Roulette'
						WHEN 2	THEN N'Slot'
						WHEN 3	THEN N'Blackjack'
						WHEN 4	THEN N'Poker'
						WHEN 5	THEN N'Bingo'
					END ,
	PlayerId	= ABS (CHECKSUM (NEWID ())) % 10000 + 1 ,
	BetAmount	= CAST ((ABS (CHECKSUM (NEWID ())) % 10 + 1) AS MONEY) ,
	Profit		= CAST ((CHECKSUM (NEWID ()) % 101) AS MONEY)
FROM
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 5 + 1
	)
	AS
		RandomValueTable;
GO


SELECT
	GameCount = COUNT (*)
FROM
	Casino.Games;
GO


ROLLBACK TRANSACTION
	InsertNewGame2;
GO


ROLLBACK TRANSACTION
	InsertNewGame;
GO


SELECT
	TranCount = @@TRANCOUNT;
GO


SELECT
	GameCount = COUNT (*)
FROM
	Casino.Games;
GO


-- Demonstrate the behavior of ROLLBACK TRANSACTION with SAVE TRANSACTION

SAVE TRANSACTION
	InsertNewGame;
GO


BEGIN TRANSACTION
	InsertNewGame;
GO


SELECT
	TranCount = @@TRANCOUNT;
GO


INSERT INTO
	Casino.Games
(
	GameType ,
	PlayerId ,
	BetAmount ,
	Profit
)
SELECT
	GameType	=	CASE RandomValueTable.RandomValue
						WHEN 1	THEN N'Roulette'
						WHEN 2	THEN N'Slot'
						WHEN 3	THEN N'Blackjack'
						WHEN 4	THEN N'Poker'
						WHEN 5	THEN N'Bingo'
					END ,
	PlayerId	= ABS (CHECKSUM (NEWID ())) % 10000 + 1 ,
	BetAmount	= CAST ((ABS (CHECKSUM (NEWID ())) % 10 + 1) AS MONEY) ,
	Profit		= CAST ((CHECKSUM (NEWID ()) % 101) AS MONEY)
FROM
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 5 + 1
	)
	AS
		RandomValueTable;
GO


SELECT
	GameCount = COUNT (*)
FROM
	Casino.Games;
GO


SAVE TRANSACTION
	InsertNewGame2;
GO


SELECT
	TranCount = @@TRANCOUNT;
GO


INSERT INTO
	Casino.Games
(
	GameType ,
	PlayerId ,
	BetAmount ,
	Profit
)
SELECT
	GameType	=	CASE RandomValueTable.RandomValue
						WHEN 1	THEN N'Roulette'
						WHEN 2	THEN N'Slot'
						WHEN 3	THEN N'Blackjack'
						WHEN 4	THEN N'Poker'
						WHEN 5	THEN N'Bingo'
					END ,
	PlayerId	= ABS (CHECKSUM (NEWID ())) % 10000 + 1 ,
	BetAmount	= CAST ((ABS (CHECKSUM (NEWID ())) % 10 + 1) AS MONEY) ,
	Profit		= CAST ((CHECKSUM (NEWID ()) % 101) AS MONEY)
FROM
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 5 + 1
	)
	AS
		RandomValueTable;
GO


SELECT
	GameCount = COUNT (*)
FROM
	Casino.Games;
GO


ROLLBACK TRANSACTION
	InsertNewGame2;
GO


SELECT
	TranCount = @@TRANCOUNT;
GO


SELECT
	GameCount = COUNT (*)
FROM
	Casino.Games;
GO


COMMIT TRANSACTION
	InsertNewGame;
GO


SELECT
	TranCount = @@TRANCOUNT;
GO


SELECT
	GameCount = COUNT (*)
FROM
	Casino.Games;
GO


-- Create a stored procedure that inserts a new game and updates the bankroll of the relevant player

CREATE PROCEDURE
	Casino.usp_InsertNewGame
(
	@GameType		AS NVARCHAR(50) ,
	@PlayerId		AS INT ,
	@BetAmount		AS MONEY ,
	@Profit			AS MONEY
)
AS

BEGIN TRY

	BEGIN TRANSACTION;

	INSERT INTO
		Casino.Games
	(
		GameType ,
		PlayerId ,
		BetAmount ,
		Profit
	)
	VALUES
	(
		@GameType ,
		@PlayerId ,
		@BetAmount ,
		@Profit
	);

	UPDATE
		Casino.Players
	SET
		Bankroll += @Profit
	WHERE
		PlayerId = @PlayerId;

	COMMIT TRANSACTION;

	PRINT OBJECT_NAME (@@PROCID) + N': The execution was successful!';

END TRY
BEGIN CATCH

	PRINT OBJECT_NAME (@@PROCID) + N': There was an error - ' + ERROR_MESSAGE ();

	ROLLBACK TRANSACTION;

	-- More error handling...

END CATCH;
GO


-- Test the stored procedure with a successful execution

EXECUTE Casino.usp_InsertNewGame
	@GameType	= N'Slot' ,
	@PlayerId	= 1234 ,
	@BetAmount	= 5.00 ,
	@Profit		= -5.00;
GO


-- Test the stored procedure with a failed execution

EXECUTE Casino.usp_InsertNewGame
	@GameType	= N'Slot' ,
	@PlayerId	= 1234 ,
	@BetAmount	= 11.00 ,
	@Profit		= -11.00;
GO


-- Create a stored procedure that inserts a new player as well as the first game played by that player

CREATE PROCEDURE
	Casino.usp_InsertFirstGame
(
	@PlayerName	AS NVARCHAR(50) ,
	@Bankroll	AS MONEY ,
	@GameType	AS NVARCHAR(50) ,
	@BetAmount	AS MONEY ,
	@Profit		AS MONEY
)
AS

DECLARE
	@PlayerId AS INT;

BEGIN TRY

	BEGIN TRANSACTION;

	INSERT INTO
		Casino.Players
	(
		PlayerName ,
		Bankroll
	)
	VALUES
	(
		@PlayerName ,
		@Bankroll
	);

	SET @PlayerId = SCOPE_IDENTITY ();

	EXECUTE Casino.usp_InsertNewGame
		@GameType	= @GameType ,
		@PlayerId	= @PlayerId ,
		@BetAmount	= @BetAmount ,
		@Profit		= @Profit;

	COMMIT TRANSACTION;

	PRINT OBJECT_NAME (@@PROCID) + N': The execution was successful!';

END TRY
BEGIN CATCH

	PRINT OBJECT_NAME (@@PROCID) + N': There was an error - ' + ERROR_MESSAGE ();

	ROLLBACK TRANSACTION;

	-- More error handling...

END CATCH;
GO


-- Test the stored procedure with a successful execution

EXECUTE Casino.usp_InsertFirstGame
	@PlayerName	= N'Guy' ,
	@Bankroll	= 100.00 ,
	@GameType	= N'Slot' ,
	@BetAmount	= 5.00 ,
	@Profit		= -5.00;
GO


-- Test the stored procedure with a failed execution

EXECUTE Casino.usp_InsertFirstGame
	@PlayerName	= N'Guy' ,
	@Bankroll	= 100.00 ,
	@GameType	= N'Slot' ,
	@BetAmount	= 11.00 ,
	@Profit		= -11.00;
GO


-- Alter the "Casino.usp_InsertNewGame" stored procedure to support nested transactions

ALTER PROCEDURE
	Casino.usp_InsertNewGame
(
	@GameType	AS NVARCHAR(50) ,
	@PlayerId	AS INT ,
	@BetAmount	AS MONEY ,
	@Profit		AS MONEY
)
AS

DECLARE
	@TransactionCount	AS INT			= @@TRANCOUNT ,
	@TransactionName	AS NVARCHAR(32)	= N'InsertNewGame';

BEGIN TRY

	IF
		@TransactionCount > 0
	BEGIN

		SAVE TRANSACTION
			@TransactionName;

	END
	ELSE
	BEGIN

		BEGIN TRANSACTION
			@TransactionName;

	END;

	INSERT INTO
		Casino.Games
	(
		GameType ,
		PlayerId ,
		BetAmount ,
		Profit
	)
	VALUES
	(
		@GameType ,
		@PlayerId ,
		@BetAmount ,
		@Profit
	);

	UPDATE
		Casino.Players
	SET
		Bankroll += @Profit
	WHERE
		PlayerId = @PlayerId;

	IF
		@TransactionCount = 0
	BEGIN

		COMMIT TRANSACTION
			@TransactionName;

	END;

	PRINT OBJECT_NAME (@@PROCID) + N': The execution was successful!';

	RETURN 0;

END TRY
BEGIN CATCH

	PRINT OBJECT_NAME (@@PROCID) + N': There was an error - ' + ERROR_MESSAGE ();

	IF
		@TransactionCount = 0
	BEGIN

		ROLLBACK TRANSACTION
			@TransactionName;

	END
	ELSE	-- @TransactionCount > 0
	BEGIN

		IF
			XACT_STATE () != -1
		BEGIN

			ROLLBACK TRANSACTION
				@TransactionName;

		END;

	END;

	-- More error handling...

	RETURN -1;

END CATCH;
GO


-- Test the stored procedure with a successful execution

DECLARE
	@ReturnedValue AS INT;

EXECUTE @ReturnedValue = Casino.usp_InsertNewGame
	@GameType	= N'Slot' ,
	@PlayerId	= 1234 ,
	@BetAmount	= 5.00 ,
	@Profit		= -5.00;

SELECT
	ReturnedValue = @ReturnedValue;
GO


-- Test the stored procedure with a failed execution

DECLARE
	@ReturnedValue AS INT;

EXECUTE @ReturnedValue = Casino.usp_InsertNewGame
	@GameType	= N'Slot' ,
	@PlayerId	= 1234 ,
	@BetAmount	= 11.00 ,
	@Profit		= -11.00;

SELECT
	ReturnedValue = @ReturnedValue;
GO



-- Alter the "Casino.usp_InsertFirstGame" stored procedure to support nested transactions

ALTER PROCEDURE
	Casino.usp_InsertFirstGame
(
	@PlayerName	AS NVARCHAR(50) ,
	@Bankroll	AS MONEY ,
	@GameType	AS NVARCHAR(50) ,
	@BetAmount	AS MONEY ,
	@Profit		AS MONEY
)
AS

DECLARE
	@PlayerId			AS INT ,
	@TransactionCount	AS INT			= @@TRANCOUNT ,
	@TransactionName	AS NVARCHAR(32)	= N'InsertFirstGame' ,
	@ReturnedValue		AS INT;

BEGIN TRY

	IF
		@TransactionCount > 0
	BEGIN

		SAVE TRANSACTION
			@TransactionName;

	END
	ELSE
	BEGIN

		BEGIN TRANSACTION
			@TransactionName;

	END;

	INSERT INTO
		Casino.Players
	(
		PlayerName ,
		Bankroll
	)
	VALUES
	(
		@PlayerName ,
		@Bankroll
	);

	SET @PlayerId = SCOPE_IDENTITY ();

	EXECUTE @ReturnedValue = Casino.usp_InsertNewGame
		@GameType	= @GameType ,
		@PlayerId	= @PlayerId ,
		@BetAmount	= @BetAmount ,
		@Profit		= @Profit;

	IF
		@ReturnedValue != 0
	BEGIN

		RAISERROR (N'The stored procedure "Casino.usp_InsertNewGame" returned an error' , 16 , 1);

	END;

	IF
		@TransactionCount = 0
	BEGIN

		COMMIT TRANSACTION
			@TransactionName;

	END;

	PRINT OBJECT_NAME (@@PROCID) + N': The execution was successful!';

	RETURN 0;

END TRY
BEGIN CATCH

	PRINT OBJECT_NAME (@@PROCID) + N': There was an error - ' + ERROR_MESSAGE ();

	IF
		@TransactionCount = 0
	BEGIN

		ROLLBACK TRANSACTION
			@TransactionName;

	END
	ELSE	-- @TransactionCount > 0
	BEGIN

		IF
			XACT_STATE() != -1
		BEGIN

			ROLLBACK TRANSACTION
				@TransactionName;

		END;

	END;

	-- More error handling...

	RETURN -1;

END CATCH;
GO


-- Test the stored procedure with a successful execution

DECLARE
	@ReturnedValue AS INT;

EXECUTE @ReturnedValue = Casino.usp_InsertFirstGame
	@PlayerName	= N'Guy' ,
	@Bankroll	= 100.00 ,
	@GameType	= N'Slot' ,
	@BetAmount	= 5.00 ,
	@Profit		= -5.00;

SELECT
	ReturnedValue = @ReturnedValue;
GO


-- Test the stored procedure with a failed execution

DECLARE
	@ReturnedValue AS INT;

EXECUTE @ReturnedValue = Casino.usp_InsertFirstGame
	@PlayerName	= N'Guy' ,
	@Bankroll	= 100.00 ,
	@GameType	= N'Slot' ,
	@BetAmount	= 11.00 ,
	@Profit		= -11.00;

SELECT
	ReturnedValue = @ReturnedValue;
GO


-- Alter the "Casino.usp_InsertNewGame" stored procedure to support nested transactions in a different way

ALTER PROCEDURE
	Casino.usp_InsertNewGame
(
	@GameType	AS NVARCHAR(50) ,
	@PlayerId	AS INT ,
	@BetAmount	AS MONEY ,
	@Profit		AS MONEY
)
AS

DECLARE
	@TransactionCount	AS INT			= @@TRANCOUNT ,
	@TransactionName	AS NVARCHAR(32)	= N'InsertNewGame' ,
	@SavePointName		AS NVARCHAR(32)	= N'InsertNewGame_SavePoint';

BEGIN TRY

	BEGIN TRANSACTION
		@TransactionName;

	SAVE TRANSACTION
		@SavePointName;

	INSERT INTO
		Casino.Games
	(
		GameType ,
		PlayerId ,
		BetAmount ,
		Profit
	)
	VALUES
	(
		@GameType ,
		@PlayerId ,
		@BetAmount ,
		@Profit
	);

	UPDATE
		Casino.Players
	SET
		Bankroll += @Profit
	WHERE
		PlayerId = @PlayerId;

	COMMIT TRANSACTION
		@TransactionName;

	PRINT OBJECT_NAME (@@PROCID) + N': The execution was successful!';

	RETURN 0;

END TRY
BEGIN CATCH

	PRINT OBJECT_NAME (@@PROCID) + N': There was an error - ' + ERROR_MESSAGE ();

	IF
		XACT_STATE () != -1
	BEGIN

		ROLLBACK TRANSACTION
			@SavePointName;

		COMMIT TRANSACTION
			@TransactionName;

	END
	ELSE
	BEGIN

		IF
			@TransactionCount = 0
		BEGIN

			ROLLBACK TRANSACTION
				@TransactionName;

		END;

	END;

	-- More error handling...

	RETURN -1;

END CATCH;
GO


-- Test the stored procedure with a successful execution

DECLARE
	@ReturnedValue AS INT;

EXECUTE @ReturnedValue = Casino.usp_InsertNewGame
	@GameType	= N'Slot' ,
	@PlayerId	= 1234 ,
	@BetAmount	= 5.00 ,
	@Profit		= -5.00;

SELECT
	ReturnedValue = @ReturnedValue;
GO


-- Test the stored procedure with a failed execution

DECLARE
	@ReturnedValue AS INT;

EXECUTE @ReturnedValue = Casino.usp_InsertNewGame
	@GameType	= N'Slot' ,
	@PlayerId	= 1234 ,
	@BetAmount	= 11.00 ,
	@Profit		= -11.00;

SELECT
	ReturnedValue = @ReturnedValue;
GO



-- Alter the "Casino.usp_InsertFirstGame" stored procedure to support nested transactions

ALTER PROCEDURE
	Casino.usp_InsertFirstGame
(
	@PlayerName	AS NVARCHAR(50) ,
	@Bankroll	AS MONEY ,
	@GameType	AS NVARCHAR(50) ,
	@BetAmount	AS MONEY ,
	@Profit		AS MONEY
)
AS

DECLARE
	@PlayerId			AS INT ,
	@TransactionCount	AS INT			= @@TRANCOUNT ,
	@TransactionName	AS NVARCHAR(32)	= N'InsertFirstGame' ,
	@SavePointName		AS NVARCHAR(32)	= N'InsertFirstGame_SavePoint' ,
	@ReturnedValue		AS INT;

BEGIN TRY

	BEGIN TRANSACTION
		@TransactionName;

	SAVE TRANSACTION
		@SavePointName;

	INSERT INTO
		Casino.Players
	(
		PlayerName ,
		Bankroll
	)
	VALUES
	(
		@PlayerName ,
		@Bankroll
	);

	SET @PlayerId = SCOPE_IDENTITY ();

	EXECUTE @ReturnedValue = Casino.usp_InsertNewGame
		@GameType	= @GameType ,
		@PlayerId	= @PlayerId ,
		@BetAmount	= @BetAmount ,
		@Profit		= @Profit;

	IF
		@ReturnedValue != 0
	BEGIN

		RAISERROR (N'The stored procedure "Casino.usp_InsertNewGame" returned an error' , 16 , 1);

	END;

	COMMIT TRANSACTION
		@TransactionName;

	PRINT OBJECT_NAME (@@PROCID) + N': The execution was successful!';

	RETURN 0;

END TRY
BEGIN CATCH

	PRINT OBJECT_NAME (@@PROCID) + N': There was an error - ' + ERROR_MESSAGE ();

	IF
		XACT_STATE() != -1
	BEGIN

		ROLLBACK TRANSACTION
			@SavePointName;

		COMMIT TRANSACTION
			@TransactionName;

	END
	ELSE
	BEGIN

		IF
			@TransactionCount = 0
		BEGIN

			ROLLBACK TRANSACTION
				@TransactionName;

		END;

	END;

	-- More error handling...

	RETURN -1;

END CATCH;
GO


-- Test the stored procedure with a successful execution

DECLARE
	@ReturnedValue AS INT;

EXECUTE @ReturnedValue = Casino.usp_InsertFirstGame
	@PlayerName	= N'Guy' ,
	@Bankroll	= 100.00 ,
	@GameType	= N'Slot' ,
	@BetAmount	= 5.00 ,
	@Profit		= -5.00;

SELECT
	ReturnedValue = @ReturnedValue;
GO


-- Test the stored procedure with a failed execution

DECLARE
	@ReturnedValue AS INT;

EXECUTE @ReturnedValue = Casino.usp_InsertFirstGame
	@PlayerName	= N'Guy' ,
	@Bankroll	= 100.00 ,
	@GameType	= N'Slot' ,
	@BetAmount	= 11.00 ,
	@Profit		= -11.00;

SELECT
	ReturnedValue = @ReturnedValue;
GO
