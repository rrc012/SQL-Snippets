USE
	YourAss;
GO


SET STATISTICS IO ON;
GO


-- Drop the "ix_Members_nc_u_Node" unique index

DROP INDEX
	ix_Members_nc_u_Node
ON
	Operation.Members;
GO


-- Insert a new member into "Operation.Members"

INSERT INTO
	Operation.Members
(
	UserName ,
	Password ,
	FirstName ,
	LastName ,
	StreetAddress ,
	CountryId ,
	PhoneNumber ,
	EmailAddress ,
	GenderId ,
	BirthDate ,
	SexualPreferenceId ,
	MaritalStatusId ,
	Picture ,
	RegistrationDateTime ,
	ReferringMemberId ,
	Node
)
SELECT
	UserName				= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 10 + 1) ,
	Password				= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 10 + 1) ,
	FirstName				= N'MemberFirstName' ,
	LastName				= N'MemberLastName' ,
	StreetAddress			=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 100 + 1)
								END ,
	CountryId				= ABS (CHECKSUM (NEWID ())) % 5 + 1 ,
	PhoneNumber				=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										CAST ((ABS (CHECKSUM (NEWID ())) % 1000000000 + 100000000) AS NVARCHAR(20))
								END ,
	EmailAddress			= REPLICATE (N'x' , ABS (CHECKSUM (NEWID ())) % 10 + 1) + N'@gmail.com' ,
	GenderId				= ABS (CHECKSUM (NEWID ())) % 2 + 1 ,
	BirthDate				= CAST (DATEADD (DAY , DATEDIFF (DAY , '1900-01-01' , SYSDATETIME ()) - (19 * 365) - (ABS (CHECKSUM (NEWID ())) % (30 * 365)) , '1900-01-01') AS DATE) ,
	SexualPreferenceId		=	CASE RandomValueTable.RandomValue
									WHEN 1
										THEN 1
									WHEN 2
										THEN 2
									WHEN 3
										THEN NULL
								END ,	
	MaritalStatusId			=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										ABS (CHECKSUM (NEWID ())) % 4 + 1
								END ,
	Picture					=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 30
										THEN NULL
									ELSE
										CAST (REPLICATE (N'Picture' , ABS (CHECKSUM (NEWID ())) % 1000 + 1) AS VARBINARY(MAX))
								END ,
	RegistrationDateTime	= SYSDATETIME () ,
	ReferringMemberId		= NULL ,
	Node					= HIERARCHYID::GetRoot ()
FROM
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 3 + 1
	)
	AS
		RandomValueTable;
GO


-- Get rid of the extra "rows affected" messages

ALTER TRIGGER
	Operation.trg_Members_a_i_CreateFolderForMember
ON
	Operation.Members
AFTER
	INSERT
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE
		@intMemberId	AS INT ,
		@nvcCommand		AS NVARCHAR(4000);

	DECLARE
		csrNewMembers
	CURSOR
		LOCAL STATIC READ_ONLY FORWARD_ONLY
	FOR
		SELECT
			Id
		FROM
			inserted;

	OPEN csrNewMembers;

	FETCH NEXT FROM
		csrNewMembers
	INTO
		@intMemberId;

	WHILE
		@@FETCH_STATUS = 0
	BEGIN

		SET @nvcCommand = N'md C:\MemberFolders\Member_' + CAST (@intMemberId AS NVARCHAR(4000));

		EXECUTE sys.xp_cmdshell
			@nvcCommand ,
			no_output;

		FETCH NEXT FROM
			csrNewMembers
		INTO
			@intMemberId;

	END;

	CLOSE csrNewMembers;

	DEALLOCATE csrNewMembers;

END;
GO


INSERT INTO
	Operation.Members
(
	UserName ,
	Password ,
	FirstName ,
	LastName ,
	StreetAddress ,
	CountryId ,
	PhoneNumber ,
	EmailAddress ,
	GenderId ,
	BirthDate ,
	SexualPreferenceId ,
	MaritalStatusId ,
	Picture ,
	RegistrationDateTime ,
	ReferringMemberId ,
	Node
)
SELECT
	UserName				= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 10 + 1) ,
	Password				= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 10 + 1) ,
	FirstName				= N'MemberFirstName' ,
	LastName				= N'MemberLastName' ,
	StreetAddress			=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 100 + 1)
								END ,
	CountryId				= ABS (CHECKSUM (NEWID ())) % 5 + 1 ,
	PhoneNumber				=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										CAST ((ABS (CHECKSUM (NEWID ())) % 1000000000 + 100000000) AS NVARCHAR(20))
								END ,
	EmailAddress			= REPLICATE (N'x' , ABS (CHECKSUM (NEWID ())) % 10 + 1) + N'@gmail.com' ,
	GenderId				= ABS (CHECKSUM (NEWID ())) % 2 + 1 ,
	BirthDate				= CAST (DATEADD (DAY , DATEDIFF (DAY , '1900-01-01' , SYSDATETIME ()) - (19 * 365) - (ABS (CHECKSUM (NEWID ())) % (30 * 365)) , '1900-01-01') AS DATE) ,
	SexualPreferenceId		=	CASE RandomValueTable.RandomValue
									WHEN 1
										THEN 1
									WHEN 2
										THEN 2
									WHEN 3
										THEN NULL
								END ,	
	MaritalStatusId			=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										ABS (CHECKSUM (NEWID ())) % 4 + 1
								END ,
	Picture					=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 30
										THEN NULL
									ELSE
										CAST (REPLICATE (N'Picture' , ABS (CHECKSUM (NEWID ())) % 1000 + 1) AS VARBINARY(MAX))
								END ,
	RegistrationDateTime	= SYSDATETIME () ,
	ReferringMemberId		= NULL ,
	Node					= HIERARCHYID::GetRoot ()
FROM
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 3 + 1
	)
	AS
		RandomValueTable;
GO


-- Rewrite the trigger to support single-row inserts

ALTER TRIGGER
	Operation.trg_Members_a_i_CreateFolderForMember
ON
	Operation.Members
AFTER
	INSERT
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE
		@intMemberId	AS INT ,
		@nvcCommand		AS NVARCHAR(4000);

	SELECT
		@intMemberId = Id
	FROM
		inserted;

	SET @nvcCommand = N'md C:\MemberFolders\Member_' + CAST (@intMemberId AS NVARCHAR(4000));

	EXECUTE sys.xp_cmdshell
		@nvcCommand ,
		no_output;

END;
GO


INSERT INTO
	Operation.Members
(
	UserName ,
	Password ,
	FirstName ,
	LastName ,
	StreetAddress ,
	CountryId ,
	PhoneNumber ,
	EmailAddress ,
	GenderId ,
	BirthDate ,
	SexualPreferenceId ,
	MaritalStatusId ,
	Picture ,
	RegistrationDateTime ,
	ReferringMemberId ,
	Node
)
SELECT
	UserName				= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 10 + 1) ,
	Password				= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 10 + 1) ,
	FirstName				= N'MemberFirstName' ,
	LastName				= N'MemberLastName' ,
	StreetAddress			=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 100 + 1)
								END ,
	CountryId				= ABS (CHECKSUM (NEWID ())) % 5 + 1 ,
	PhoneNumber				=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										CAST ((ABS (CHECKSUM (NEWID ())) % 1000000000 + 100000000) AS NVARCHAR(20))
								END ,
	EmailAddress			= REPLICATE (N'x' , ABS (CHECKSUM (NEWID ())) % 10 + 1) + N'@gmail.com' ,
	GenderId				= ABS (CHECKSUM (NEWID ())) % 2 + 1 ,
	BirthDate				= CAST (DATEADD (DAY , DATEDIFF (DAY , '1900-01-01' , SYSDATETIME ()) - (19 * 365) - (ABS (CHECKSUM (NEWID ())) % (30 * 365)) , '1900-01-01') AS DATE) ,
	SexualPreferenceId		=	CASE RandomValueTable.RandomValue
									WHEN 1
										THEN 1
									WHEN 2
										THEN 2
									WHEN 3
										THEN NULL
								END ,	
	MaritalStatusId			=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										ABS (CHECKSUM (NEWID ())) % 4 + 1
								END ,
	Picture					=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 30
										THEN NULL
									ELSE
										CAST (REPLICATE (N'Picture' , ABS (CHECKSUM (NEWID ())) % 1000 + 1) AS VARBINARY(MAX))
								END ,
	RegistrationDateTime	= SYSDATETIME () ,
	ReferringMemberId		= NULL ,
	Node					= HIERARCHYID::GetRoot ()
FROM
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 3 + 1
	)
	AS
		RandomValueTable;
GO


INSERT INTO
	Operation.Members
(
	UserName ,
	Password ,
	FirstName ,
	LastName ,
	StreetAddress ,
	CountryId ,
	PhoneNumber ,
	EmailAddress ,
	GenderId ,
	BirthDate ,
	SexualPreferenceId ,
	MaritalStatusId ,
	Picture ,
	RegistrationDateTime ,
	ReferringMemberId ,
	Node
)
SELECT TOP (5)
	UserName				= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 10 + 1) ,
	Password				= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 10 + 1) ,
	FirstName				= N'MemberFirstName' ,
	LastName				= N'MemberLastName' ,
	StreetAddress			=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 100 + 1)
								END ,
	CountryId				= ABS (CHECKSUM (NEWID ())) % 5 + 1 ,
	PhoneNumber				=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										CAST ((ABS (CHECKSUM (NEWID ())) % 1000000000 + 100000000) AS NVARCHAR(20))
								END ,
	EmailAddress			= REPLICATE (N'x' , ABS (CHECKSUM (NEWID ())) % 10 + 1) + N'@gmail.com' ,
	GenderId				= ABS (CHECKSUM (NEWID ())) % 2 + 1 ,
	BirthDate				= CAST (DATEADD (DAY , DATEDIFF (DAY , '1900-01-01' , SYSDATETIME ()) - (19 * 365) - (ABS (CHECKSUM (NEWID ())) % (30 * 365)) , '1900-01-01') AS DATE) ,
	SexualPreferenceId		=	CASE RandomValueTable.RandomValue
									WHEN 1
										THEN 1
									WHEN 2
										THEN 2
									WHEN 3
										THEN NULL
								END ,	
	MaritalStatusId			=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										ABS (CHECKSUM (NEWID ())) % 4 + 1
								END ,
	Picture					=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 30
										THEN NULL
									ELSE
										CAST (REPLICATE (N'Picture' , ABS (CHECKSUM (NEWID ())) % 1000 + 1) AS VARBINARY(MAX))
								END ,
	RegistrationDateTime	= SYSDATETIME () ,
	ReferringMemberId		= NULL ,
	Node					= HIERARCHYID::GetRoot ()
FROM
	sys.columns
CROSS JOIN
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 3 + 1
	)
	AS
		RandomValueTable;
GO


-- Rewrite the trigger to support both single-row and multi-row inserts

ALTER TRIGGER
	Operation.trg_Members_a_i_CreateFolderForMember
ON
	Operation.Members
AFTER
	INSERT
AS
BEGIN

	DECLARE
		@intRowCount	AS INT				= @@ROWCOUNT ,
		@intMemberId	AS INT ,
		@nvcCommand		AS NVARCHAR(4000);

	SET NOCOUNT ON;

	IF
		@intRowCount = 1
	BEGIN

		SELECT
			@intMemberId = Id
		FROM
			inserted;

		SET @nvcCommand = N'md C:\MemberFolders\Member_' + CAST (@intMemberId AS NVARCHAR(4000));

		EXECUTE sys.xp_cmdshell
			@nvcCommand ,
			no_output;

	END
	ELSE
	BEGIN

		DECLARE
			csrNewMembers
		CURSOR
			LOCAL STATIC READ_ONLY FORWARD_ONLY
		FOR
			SELECT
				Id
			FROM
				inserted;

		OPEN csrNewMembers;

		FETCH NEXT FROM
			csrNewMembers
		INTO
			@intMemberId;

		WHILE
			@@FETCH_STATUS = 0
		BEGIN

			SET @nvcCommand = N'md C:\MemberFolders\Member_' + CAST (@intMemberId AS NVARCHAR(4000));

			EXECUTE sys.xp_cmdshell
				@nvcCommand ,
				no_output;

			FETCH NEXT FROM
				csrNewMembers
			INTO
				@intMemberId;

		END;

		CLOSE csrNewMembers;

		DEALLOCATE csrNewMembers;

	END;

END;
GO


INSERT INTO
	Operation.Members
(
	UserName ,
	Password ,
	FirstName ,
	LastName ,
	StreetAddress ,
	CountryId ,
	PhoneNumber ,
	EmailAddress ,
	GenderId ,
	BirthDate ,
	SexualPreferenceId ,
	MaritalStatusId ,
	Picture ,
	RegistrationDateTime ,
	ReferringMemberId ,
	Node
)
SELECT
	UserName				= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 10 + 1) ,
	Password				= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 10 + 1) ,
	FirstName				= N'MemberFirstName' ,
	LastName				= N'MemberLastName' ,
	StreetAddress			=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 100 + 1)
								END ,
	CountryId				= ABS (CHECKSUM (NEWID ())) % 5 + 1 ,
	PhoneNumber				=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										CAST ((ABS (CHECKSUM (NEWID ())) % 1000000000 + 100000000) AS NVARCHAR(20))
								END ,
	EmailAddress			= REPLICATE (N'x' , ABS (CHECKSUM (NEWID ())) % 10 + 1) + N'@gmail.com' ,
	GenderId				= ABS (CHECKSUM (NEWID ())) % 2 + 1 ,
	BirthDate				= CAST (DATEADD (DAY , DATEDIFF (DAY , '1900-01-01' , SYSDATETIME ()) - (19 * 365) - (ABS (CHECKSUM (NEWID ())) % (30 * 365)) , '1900-01-01') AS DATE) ,
	SexualPreferenceId		=	CASE RandomValueTable.RandomValue
									WHEN 1
										THEN 1
									WHEN 2
										THEN 2
									WHEN 3
										THEN NULL
								END ,	
	MaritalStatusId			=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										ABS (CHECKSUM (NEWID ())) % 4 + 1
								END ,
	Picture					=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 30
										THEN NULL
									ELSE
										CAST (REPLICATE (N'Picture' , ABS (CHECKSUM (NEWID ())) % 1000 + 1) AS VARBINARY(MAX))
								END ,
	RegistrationDateTime	= SYSDATETIME () ,
	ReferringMemberId		= NULL ,
	Node					= HIERARCHYID::GetRoot ()
FROM
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 3 + 1
	)
	AS
		RandomValueTable;
GO


INSERT INTO
	Operation.Members
(
	UserName ,
	Password ,
	FirstName ,
	LastName ,
	StreetAddress ,
	CountryId ,
	PhoneNumber ,
	EmailAddress ,
	GenderId ,
	BirthDate ,
	SexualPreferenceId ,
	MaritalStatusId ,
	Picture ,
	RegistrationDateTime ,
	ReferringMemberId ,
	Node
)
SELECT TOP (5)
	UserName				= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 10 + 1) ,
	Password				= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 10 + 1) ,
	FirstName				= N'MemberFirstName' ,
	LastName				= N'MemberLastName' ,
	StreetAddress			=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 100 + 1)
								END ,
	CountryId				= ABS (CHECKSUM (NEWID ())) % 5 + 1 ,
	PhoneNumber				=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										CAST ((ABS (CHECKSUM (NEWID ())) % 1000000000 + 100000000) AS NVARCHAR(20))
								END ,
	EmailAddress			= REPLICATE (N'x' , ABS (CHECKSUM (NEWID ())) % 10 + 1) + N'@gmail.com' ,
	GenderId				= ABS (CHECKSUM (NEWID ())) % 2 + 1 ,
	BirthDate				= CAST (DATEADD (DAY , DATEDIFF (DAY , '1900-01-01' , SYSDATETIME ()) - (19 * 365) - (ABS (CHECKSUM (NEWID ())) % (30 * 365)) , '1900-01-01') AS DATE) ,
	SexualPreferenceId		=	CASE RandomValueTable.RandomValue
									WHEN 1
										THEN 1
									WHEN 2
										THEN 2
									WHEN 3
										THEN NULL
								END ,	
	MaritalStatusId			=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 20
										THEN NULL
									ELSE
										ABS (CHECKSUM (NEWID ())) % 4 + 1
								END ,
	Picture					=	CASE
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 30
										THEN NULL
									ELSE
										CAST (REPLICATE (N'Picture' , ABS (CHECKSUM (NEWID ())) % 1000 + 1) AS VARBINARY(MAX))
								END ,
	RegistrationDateTime	= SYSDATETIME () ,
	ReferringMemberId		= NULL ,
	Node					= HIERARCHYID::GetRoot ()
FROM
	sys.columns
CROSS JOIN
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 3 + 1
	)
	AS
		RandomValueTable;
GO
