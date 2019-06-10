-- Create the "C:\CourseMaterials\YourAss" folder to hold the database files and the "C:\MemberFolders" folder as well

USE
	master;
GO


EXECUTE sys.sp_configure
	@configname		= 'show advanced options' ,
	@configvalue	= 1;
GO


RECONFIGURE;
GO


EXECUTE sys.sp_configure
	@configname		= 'xp_cmdshell' ,
	@configvalue	= 1;
GO


RECONFIGURE;
GO


EXECUTE sys.xp_cmdshell
	N'md C:\CourseMaterials' ,
	no_output;
GO


EXECUTE sys.xp_cmdshell
	N'md C:\CourseMaterials\YourAss' ,
	no_output;
GO


EXECUTE sys.xp_cmdshell
	N'md C:\MemberFolders' ,
	no_output;
GO


EXECUTE sys.sp_configure
	@configname		= 'show advanced options' ,
	@configvalue	= 0;
GO


RECONFIGURE;
GO


-- Create the "YourAss" database

IF
	DB_ID (N'YourAss') IS NOT NULL
BEGIN

	ALTER DATABASE
		YourAss
	SET
		SINGLE_USER
	WITH
		ROLLBACK IMMEDIATE;

	DROP DATABASE
		YourAss;

END;
GO


CREATE DATABASE
	YourAss
ON PRIMARY
(
	NAME		= N'YourAss_Data' ,
	FILENAME	= N'C:\CourseMaterials\YourAss\YourAss_Data.mdf' ,
	SIZE		= 3GB ,
	FILEGROWTH	= 10%
)
LOG ON
(
	NAME		= N'YourAss_Log' ,
	FILENAME	= N'C:\CourseMaterials\YourAss\YourAss_Log.ldf' ,
	SIZE		= 2GB ,
	FILEGROWTH	= 10%
);
GO


ALTER DATABASE
	YourAss
SET RECOVERY
	SIMPLE;
GO


USE
	YourAss;
GO


-- Create and populate the "Sales.Orders" table

CREATE SCHEMA
	Sales;
GO


CREATE TABLE
	Sales.Orders
(
	Id				INT				NOT NULL	IDENTITY(1,1) ,
	DateAndTime		DATETIME2(0)	NOT NULL ,
	CustomerId		INT				NOT NULL ,
	Amount			MONEY			NOT NULL ,
	OrderStatusId	TINYINT			NOT NULL ,

	CONSTRAINT
		pk_Orders_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
);
GO


INSERT INTO
	Sales.Orders WITH (TABLOCK)
(
	DateAndTime ,
	CustomerId ,
	Amount ,
	OrderStatusId
)
SELECT TOP (100000)
	DateAndTime		= DATEADD (MINUTE , - (ABS (CHECKSUM (NEWID ())) % (60 * 24 * 365 * 10)) , SYSDATETIME ()) ,
	CustomerId		= ABS (CHECKSUM (NEWID ())) % 10000 + 1 ,
	Amount			= CAST ((ABS (CHECKSUM (NEWID ())) % 100000)  AS MONEY) / 100.0 ,
	OrderStatusId	= ABS (CHECKSUM (NEWID ())) % 5 + 1
FROM
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2;
GO


CREATE NONCLUSTERED INDEX
	ix_Orders_nc_nu_DateAndTime
ON
	Sales.Orders (DateAndTime ASC);
GO


-- Create and populate the "Inventory.Items" table

CREATE SCHEMA
	Inventory;
GO


CREATE TABLE
	Inventory.Items
(
	Id			INT				NOT NULL	IDENTITY (1,1) ,
	Name		NVARCHAR(50)	NOT NULL ,
	ItemTypeId	TINYINT			NOT NULL ,
	ListPrice	MONEY			NOT NULL ,
	Quantity	INT				NOT NULL ,
	ImagePath	NVARCHAR(260)	NULL ,

	CONSTRAINT
		pk_Items_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
);
GO


INSERT INTO
	Inventory.Items
(
	Name ,
	ItemTypeId ,
	ListPrice ,
	Quantity ,
	ImagePath
)
SELECT
	Name		= N'עגבניה' ,
	ItemTypeId	= 1 ,
	ListPrice	= 2.55 ,
	Quantity	= 700 ,
	ImagePath	= N'\\HUMMUS\Itzik\Images\Vegetables\Tomato.jpg'

UNION ALL

SELECT
	Name		= N'מלפפון' ,
	ItemTypeId	= 1 ,
	ListPrice	= 5.80 ,
	Quantity	= 600 ,
	ImagePath	= N'\\HUMMUS\Itzik\Images\Vegetables\Cucumber.png'

UNION ALL

SELECT
	Name		= N'גזר' ,
	ItemTypeId	= 1 ,
	ListPrice	= 1.65 ,
	Quantity	= 500 ,
	ImagePath	= N'\\HUMMUS\Itzik\Images\Vegetables\Carrot.jpg'

UNION ALL

SELECT
	Name		= N'בצל' ,
	ItemTypeId	= 1 ,
	ListPrice	= 3.20 ,
	Quantity	= 700 ,
	ImagePath	= N'\\HUMMUS\Itzik\Images\Vegetables\Onion.png'

UNION ALL

SELECT
	Name		= N'תפוז' ,
	ItemTypeId	= 2 ,
	ListPrice	= 2.50 ,
	Quantity	= 400 ,
	ImagePath	= N'\\HUMMUS\Itzik\Images\Fruits\Orange.jpg'

UNION ALL

SELECT
	Name		= N'תות' ,
	ItemTypeId	= 2 ,
	ListPrice	= 6.75 ,
	Quantity	= 400 ,
	ImagePath	= N'\\HUMMUS\Itzik\Images\Fruits\Strawberry.jpg'

UNION ALL

SELECT
	Name		= N'תפוח' ,
	ItemTypeId	= 2 ,
	ListPrice	= 6.00 ,
	Quantity	= 500 ,
	ImagePath	= N'\\HUMMUS\Itzik\Images\Fruits\Apple.jpg'

UNION ALL

SELECT
	Name		= N'בננה' ,
	ItemTypeId	= 2 ,
	ListPrice	= 4.50 ,
	Quantity	= 300 ,
	ImagePath	= N'\\HUMMUS\Itzik\Images\Fruits\Banana.jpg';
GO


-- Create the "Inventory.usp_GetItemsPerType" stored procedure

CREATE PROCEDURE
	Inventory.usp_GetItemsPerType
(
	@iItemTypeId AS TINYINT
)
AS

SELECT
	Id ,
	Name ,
	ListPrice ,
	Quantity ,
	ImagePath
FROM
	Inventory.Items
WHERE
	ItemTypeId = @iItemTypeId
ORDER BY
	Id ASC;
GO


-- Create and populate the "Marketing.Customers" table

CREATE SCHEMA
	Marketing;
GO


CREATE TABLE
	Marketing.Customers
(
	Id					INT				NOT NULL	IDENTITY (1,1) ,
	Name				NVARCHAR(50)	NOT NULL ,
	Country				NCHAR(2)		NOT NULL ,
	Phone				NVARCHAR(20)	NULL ,
	LastPurchaseDate	DATE			NULL ,

	CONSTRAINT
		pk_Customers_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
);
GO


INSERT INTO
	Marketing.Customers WITH (TABLOCK)
(
	Name ,
	Country ,
	Phone ,
	LastPurchaseDate
)
SELECT TOP (100000)
	Name				= N'Customer #' + CAST ((ABS (CHECKSUM (NEWID ())) % 100000) AS NVARCHAR(50)) ,
	Country				=
		CASE
			WHEN
				RandomNumbers.RandomNumber BETWEEN 1 AND 40
			THEN
				N'US'
			WHEN
				RandomNumbers.RandomNumber BETWEEN 41 AND 70
			THEN
				N'CN'
			WHEN
				RandomNumbers.RandomNumber BETWEEN 71 AND 99
			THEN
				N'UK'
			WHEN
				RandomNumbers.RandomNumber = 100
			THEN
				Countries.Country
		END ,
	Phone				=
		CASE
			WHEN
				ABS (CHECKSUM (NEWID ())) % 100 <= 70
			THEN
				LEFT (CAST (NEWID () AS NVARCHAR(MAX)) , 20)
			ELSE
				NULL
		END ,
	LastPurchaseDate	= DATEADD (DAY , - (ABS (CHECKSUM (NEWID ())) % (365)) , SYSDATETIME ())
FROM
	sys.columns AS T1
CROSS JOIN
	sys.columns AS T2
CROSS JOIN
	(
		VALUES
			(N'AF') ,
			(N'BE') ,
			(N'CL') ,
			(N'DK') ,
			(N'EG') ,
			(N'FR') ,
			(N'GR') ,
			(N'IL') ,
			(N'JP') ,
			(N'MT') ,
			(N'NO') ,
			(N'PT') ,
			(N'SE') ,
			(N'TR') ,
			(N'VE')
	)
	AS
		Countries (Country)
CROSS JOIN
	(
		SELECT
			RandomNumber = ABS (CHECKSUM (NEWID ())) % 100 + 1
	)
	AS
		RandomNumbers
ORDER BY
	NEWID () ASC;
GO


CREATE NONCLUSTERED INDEX
	ix_Customers_nc_nu_Country
ON
	Marketing.Customers (Country ASC);
GO


-- Create list tables

CREATE SCHEMA
	Lists;
GO


CREATE TABLE
	Lists.Countries
(
	Id		TINYINT			NOT NULL ,
	Name	NVARCHAR(50)	NOT NULL ,

	CONSTRAINT
		pk_Countries_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
	ON
		[PRIMARY]
)
ON
	[PRIMARY];
GO


CREATE TABLE
	Lists.Genders
(
	Id		TINYINT			NOT NULL ,
	Name	NVARCHAR(50)	NOT NULL

	CONSTRAINT
		pk_Genders_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
	ON
		[PRIMARY]
)
ON
	[PRIMARY];
GO


CREATE TABLE
	Lists.MaritalStatuses
(
	Id		TINYINT			NOT NULL ,
	Name	NVARCHAR(50)	NOT NULL

	CONSTRAINT
		pk_MaritalStatuses_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
	ON
		[PRIMARY]
)
ON
	[PRIMARY];
GO


CREATE TABLE
	Lists.SessionEndReasons
(
	Id		TINYINT			NOT NULL ,
	Name	NVARCHAR(50)	NOT NULL

	CONSTRAINT
		pk_SessionEndReasons_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
	ON
		[PRIMARY]
)
ON
	[PRIMARY];
GO


CREATE TABLE
	Lists.InvitationStatuses
(
	Id		TINYINT			NOT NULL ,
	Name	NVARCHAR(50)	NOT NULL

	CONSTRAINT
		pk_InvitationStatuses_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
	ON
		[PRIMARY]
)
ON
	[PRIMARY];
GO


CREATE TABLE
	Lists.EventTypes
(
	Id		TINYINT			NOT NULL ,
	Name	NVARCHAR(50)	NOT NULL ,

	CONSTRAINT
		pk_EventTypes_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
	ON
		[PRIMARY]
)
ON
	[PRIMARY];
GO


-- Poppulate the list tables with data

INSERT INTO
	Lists.Countries
(
	Id ,
	Name
)
SELECT
	Id		= 1 ,
	Name	= N'Israel'

UNION ALL

SELECT
	Id		= 2 ,
	Name	= N'USA'

UNION ALL

SELECT
	Id		= 3 ,
	Name	= N'England'

UNION ALL

SELECT
	Id		= 4 ,
	Name	= N'France'

UNION ALL

SELECT
	Id		= 5 ,
	Name	= N'Italy';
GO


INSERT INTO
	Lists.Genders
(
	Id ,
	Name
)
SELECT
	Id		= 1 ,
	Name	= N'Male'

UNION ALL

SELECT
	Id		= 2 ,
	Name	= N'Female';
GO


INSERT INTO
	Lists.MaritalStatuses
(
	Id ,
	Name
)
SELECT
	Id		= 1 ,
	Name	= N'Single'

UNION ALL

SELECT
	Id		= 2 ,
	Name	= N'Married'

UNION ALL

SELECT
	Id		= 3 ,
	Name	= N'Divorced'

UNION ALL

SELECT
	Id		= 4 ,
	Name	= N'Widowed';
GO


INSERT INTO
	Lists.SessionEndReasons
(
	Id ,
	Name
)
SELECT
	Id		= 1 ,
	Name	= N'Logout'

UNION ALL

SELECT
	Id		= 2 ,
	Name	= N'Disconnection'

UNION ALL

SELECT
	Id		= 3 ,
	Name	= N'Inactive'

UNION ALL

SELECT
	Id		= 4 ,
	Name	= N'Another Session Opened';
GO


INSERT INTO
	Lists.InvitationStatuses
(
	Id ,
	Name
)
SELECT
	Id		= 1 ,
	Name	= N'Sent'

UNION ALL

SELECT
	Id		= 2 ,
	Name	= N'Accepted'

UNION ALL

SELECT
	Id		= 3 ,
	Name	= N'Denied'

UNION ALL

SELECT
	Id		= 4 ,
	Name	= N'Unknown';
GO


INSERT INTO
	Lists.EventTypes
(
	Id ,
	Name
)
SELECT
	Id		= 1 ,
	Name	= N'Click'

UNION ALL

SELECT
	Id		= 2 ,
	Name	= N'Mouse Move'

UNION ALL

SELECT
	Id		= 3 ,
	Name	= N'Refresh'

UNION ALL

SELECT
	Id		= 4 ,
	Name	= N'Open'

UNION ALL

SELECT
	Id		= 5 ,
	Name	= N'Close';
GO


-- Create and populate the "Operation.Members" table

CREATE SCHEMA
	Operation;
GO


CREATE TABLE
	Operation.Members
(
	Id						INT				NOT NULL	IDENTITY (1,1) ,
	Username				NVARCHAR(10)	NOT NULL ,
	Password				NVARCHAR(10)	NOT NULL ,
	FirstName				NVARCHAR(20)	NOT NULL ,
	LastName				NVARCHAR(20)	NOT NULL ,
	StreetAddress			NVARCHAR(100)	NULL ,
	CountryId				TINYINT			NOT NULL ,
	PhoneNumber				NVARCHAR(20)	NULL ,
	EmailAddress			NVARCHAR(100)	NOT NULL ,
	GenderId				TINYINT			NOT NULL ,
	BirthDate				DATE			NOT NULL ,
	SexualPreferenceId		TINYINT			NULL ,
	MaritalStatusId			TINYINT			NULL ,
	Picture					VARBINARY(MAX)	NULL ,
	RegistrationDateTime	DATETIME2(0)	NOT NULL ,
	ReferringMemberId		INT				NULL ,

	CONSTRAINT
		pk_Members_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
	ON
		[PRIMARY] ,

	CONSTRAINT
		fk_Members_CountryId_Countries_Id
	FOREIGN KEY
		(CountryId)
	REFERENCES
		Lists.Countries (Id) ,

	CONSTRAINT
		fk_Members_GenderId_Genders_Id
	FOREIGN KEY
		(GenderId)
	REFERENCES
		Lists.Genders (Id) ,

	CONSTRAINT
		fk_Members_SexualPreferenceId_Genders_Id
	FOREIGN KEY
		(SexualPreferenceId)
	REFERENCES
		Lists.Genders (Id) ,

	CONSTRAINT
		fk_Members_MaritalStatusId_MaritalStatuses_Id
	FOREIGN KEY
		(MaritalStatusId)
	REFERENCES
		Lists.MaritalStatuses (Id) ,

	CONSTRAINT
		fk_Members_ReferringMemberId_Members_Id
	FOREIGN KEY
		(ReferringMemberId)
	REFERENCES
		Operation.Members (Id)
)
ON
	[PRIMARY];
GO


DECLARE
	@tblFirstNames
TABLE
(
	Name		NVARCHAR(20)	NOT NULL ,
	GenderId	TINYINT			NOT NULL
);

INSERT INTO
	@tblFirstNames
(
	Name ,
	GenderId
)
SELECT
	Name		= N'John' ,
	GenderId	= 1

UNION ALL

SELECT
	Name		= N'David' ,
	GenderId	= 1

UNION ALL

SELECT
	Name		= N'James' ,
	GenderId	= 1

UNION ALL

SELECT
	Name		= N'Ron' ,
	GenderId	= 1

UNION ALL

SELECT
	Name		= N'Bruce' ,
	GenderId	= 1

UNION ALL

SELECT
	Name		= N'Bryan' ,
	GenderId	= 1

UNION ALL

SELECT
	Name		= N'Gimmy' ,
	GenderId	= 1

UNION ALL

SELECT
	Name		= N'Rick' ,
	GenderId	= 1

UNION ALL

SELECT
	Name		= N'Paul' ,
	GenderId	= 1

UNION ALL

SELECT
	Name		= N'Phil' ,
	GenderId	= 1

UNION ALL

SELECT
	Name		= N'Laura' ,
	GenderId	= 2

UNION ALL

SELECT
	Name		= N'Jane' ,
	GenderId	= 2

UNION ALL

SELECT
	Name		= N'Sara' ,
	GenderId	= 2

UNION ALL

SELECT
	Name		= N'Lian' ,
	GenderId	= 2

UNION ALL

SELECT
	Name		= N'Rita' ,
	GenderId	= 2

UNION ALL

SELECT
	Name		= N'Samantha' ,
	GenderId	= 2

UNION ALL

SELECT
	Name		= N'Suzan' ,
	GenderId	= 2

UNION ALL

SELECT
	Name		= N'Marry' ,
	GenderId	= 2

UNION ALL

SELECT
	Name		= N'Monica' ,
	GenderId	= 2

UNION ALL

SELECT
	Name		= N'Julia' ,
	GenderId	= 2

UNION ALL

SELECT
	Name		= N'Shila' ,
	GenderId	= 2

UNION ALL

SELECT
	Name		= N'Angela' ,
	GenderId	= 2;

DECLARE
	@tblLastNames
TABLE
(
	Name NVARCHAR(20) NOT NULL
);

INSERT INTO @tblLastNames
(
	Name
)
SELECT
	Name = N'Jones'

UNION ALL

SELECT
	Name = N'McDonald'

UNION ALL

SELECT
	Name = N'Simon'

UNION ALL

SELECT
	Name = N'Petty'

UNION ALL

SELECT
	Name = N'Bond'

UNION ALL

SELECT
	Name = N'Simpson'

UNION ALL

SELECT
	Name = N'Polsky'

UNION ALL

SELECT
	Name = N'Mayers'

UNION ALL

SELECT
	Name = N'Taylor'

UNION ALL

SELECT
	Name = N'Austin'

UNION ALL

SELECT
	Name = N'Ramsfeld';

INSERT INTO
	Operation.Members WITH (TABLOCK)
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
	ReferringMemberId
)
SELECT TOP (100000)
	UserName				= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 10 + 1) ,
	Password				= CAST (ROW_NUMBER () OVER (ORDER BY (SELECT NULL) ASC) AS NVARCHAR(10)) ,
	FirstName				= FirstNames.Name ,
	LastName				= LastNames.Name ,
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
	GenderId				= FirstNames.GenderId ,
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
	ReferringMemberId		= NULL
FROM
	sys.all_columns
CROSS JOIN
	@tblFirstNames AS FirstNames
CROSS JOIN
	@tblLastNames AS LastNames
CROSS JOIN
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 3 + 1
	)
	AS
		RandomValueTable
ORDER BY
	NEWID () ASC;
GO


UPDATE
	Operation.Members
SET
	RegistrationDateTime	= DATEADD (SECOND , (19 * 365 * 24 * 60 * 60) + (ABS (CHECKSUM (NEWID ())) % DATEDIFF (SECOND , DATEADD (SECOND , 19 * 365 * 24 * 60 * 60 , CAST (BirthDate AS DATETIME2(0))) , SYSDATETIME ())) , CAST (BirthDate AS DATETIME2(0))) ,
	ReferringMemberId		=	CASE
									WHEN Id = 1
										THEN NULL
									WHEN ABS (CHECKSUM (NEWID ())) % 100 < 30
										THEN NULL
									ELSE
										ABS (CHECKSUM (NEWID ())) % (Id - 1) + 1
								END
GO


-- Create and populate the "Operation.MemberSessions" table

CREATE TABLE
	Operation.MemberSessions
(
	Id				INT				NOT NULL	IDENTITY (1,1) ,
	MemberId		INT				NOT NULL ,
	LoginDateTime	DATETIME2(0)	NOT NULL ,
	EndDateTime		DATETIME2(0)	NULL ,
	EndReasonId		TINYINT			NULL ,

	CONSTRAINT
		pk_MemberSessions_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
	ON
		[PRIMARY] ,

	CONSTRAINT
		fk_MemberSessions_MemberId_Members_Id
	FOREIGN KEY
		(MemberId)
	REFERENCES
		Operation.Members (Id) ,

	CONSTRAINT
		fk_MemberSessions_EndReasonId_SessionEndReasons_Id
	FOREIGN KEY
		(EndReasonId)
	REFERENCES
		Lists.SessionEndReasons (Id)
)
ON
	[PRIMARY];
GO


INSERT INTO
	Operation.MemberSessions
(
	MemberId ,
	LoginDateTime ,
	EndDateTime ,
	EndReasonId
)
SELECT TOP (1000000)
	MemberId		= ABS (CHECKSUM (NEWID ())) % 100000 + 1 ,
	LoginDateTime	= DATEADD (SECOND , - ABS (CHECKSUM (NEWID ())) % (365 * 24 * 60 * 60) , SYSDATETIME ()) ,
	EndDateTime		= NULL ,
	EndReasonId		= NULL
FROM
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2;
GO


UPDATE
	Operation.MemberSessions
SET
	EndDateTime	= DATEADD (SECOND , ABS (CHECKSUM (NEWID ())) % (5 * 60 * 60) + 1 , LoginDateTime) ,
	EndReasonId	= ABS (CHECKSUM (NEWID ())) % 4 + 1
WHERE
	LoginDateTime < DATEADD (MINUTE , - (5 * 60) , SYSDATETIME ());
GO


CREATE NONCLUSTERED INDEX
	ix_MemberSessions_nc_nu_LoginDateTime
ON
	Operation.MemberSessions (LoginDateTime ASC);
GO


CREATE NONCLUSTERED INDEX
	ix_MemberSessions_nc_nu_MemberId
ON
	Operation.MemberSessions (MemberId ASC);
GO


-- Create and populate the "Operation.Invitations" table

CREATE TABLE
	Operation.Invitations
(
	Id					INT				NOT NULL	IDENTITY(1,1) ,
	RequestingSessionId	INT				NOT NULL ,
	ReceivingMemberId	INT				NOT NULL ,
	CreationDateTime	DATETIME2(0)	NOT NULL ,
	StatusId			TINYINT			NOT NULL ,
	ResponseDateTime	DATETIME2(0)	NULL ,

	CONSTRAINT
		pk_Invitations_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
	ON
		[PRIMARY] ,

	CONSTRAINT
		fk_Invitations_RequestingSessionId_MemberSessions_Id
	FOREIGN KEY
		(RequestingSessionId)
	REFERENCES
		Operation.MemberSessions (Id) ,

	CONSTRAINT
		fk_Invitations_ReceivingMemberId_Members_Id
	FOREIGN KEY
		(ReceivingMemberId)
	REFERENCES
		Operation.Members (Id) ,

	CONSTRAINT
		fk_Invitations_StatusId_InvitationStatuses_Id
	FOREIGN KEY
		(StatusId)
	REFERENCES
		Lists.InvitationStatuses (Id)
)
ON
	[PRIMARY];
GO


INSERT INTO
	Operation.Invitations WITH (TABLOCK)
(
	RequestingSessionId ,
	ReceivingMemberId ,
	CreationDateTime ,
	StatusId ,
	ResponseDateTime
)
SELECT TOP (5000000)
	RequestingSessionId	= ABS (CHECKSUM (NEWID ())) % 1000000 + 1 ,
	ReceivingMemberId	= ABS (CHECKSUM (NEWID ())) % 100000 + 1 ,
	CreationDateTime	= DATEADD (SECOND , - ABS (CHECKSUM (NEWID ())) % (365 * 24 * 60 * 60) , SYSDATETIME ()) ,
	StatusId			= ABS (CHECKSUM (NEWID ())) % 3 + 1 ,
	ResponseDateTime	= NULL
FROM
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2;
GO


UPDATE
	Operation.Invitations
SET
	ResponseDateTime = DATEADD (SECOND , ABS (CHECKSUM (NEWID ())) % DATEDIFF (SECOND , CreationDateTime , SYSDATETIME ()) , CreationDateTime)
WHERE
	StatusId != 1;	-- Sent
GO


-- Create and populate the "Billing.Transactions" table

CREATE SCHEMA
	Billing;
GO


CREATE TABLE
	Billing.Transactions
(
	TransactionId		INT				NOT NULL	IDENTITY (1,1) ,
	AccountId			INT				NOT NULL ,
	TransactionDateTime	DATETIME2(0)	NOT NULL ,
	Amount				MONEY			NOT NULL ,

	CONSTRAINT
		pk_Transactions_nc_TransactionId
	PRIMARY KEY NONCLUSTERED
		(TransactionId ASC)
);
GO


INSERT INTO
	Billing.Transactions WITH (TABLOCK)
(
	AccountId ,
	TransactionDateTime ,
	Amount
)
SELECT TOP (1000000)
	AccountId			= ABS (CHECKSUM (NEWID ())) % 50000 + 1 ,
	TransactionDateTime	= DATEADD (DAY , - ABS (CHECKSUM (NEWID ())) % 3650 , SYSDATETIME ()) ,
	Amount				= CAST ((CHECKSUM (NEWID ()) % 100) AS MONEY)
FROM
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2;
GO


CREATE CLUSTERED INDEX
	ix_Transactions_AccountId#TransactionDateTime
ON
	Billing.Transactions
		(
			AccountId			ASC ,
			TransactionDateTime	ASC
		);
GO


-- Create and populate the "Casino.Players" table

CREATE SCHEMA
	Casino;
GO


CREATE TABLE
	Casino.Players
(
	PlayerId	INT				NOT NULL	IDENTITY (1,1) ,
	PlayerName	NVARCHAR(50)	NOT NULL ,
	Bankroll	MONEY			NOT NULL ,

	CONSTRAINT
		pk_Players_c_PlayerId
	PRIMARY KEY CLUSTERED
		(PlayerId ASC)
);
GO


INSERT INTO
	Casino.Players WITH (TABLOCK)
(
	PlayerName ,
	Bankroll
)
SELECT TOP (10000)
	PlayerName	= N'Player #' + CAST ((ROW_NUMBER () OVER (ORDER BY (SELECT NULL) ASC)) AS NVARCHAR(50)) ,
	Bankroll	= CAST ((ABS (CHECKSUM (NEWID ())) % 10000) AS MONEY)
FROM
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2;
GO


-- Create and populate the "Casino.Games" table

CREATE TABLE
	Casino.Games
(
	GameId		INT				NOT NULL	IDENTITY (1,1) ,
	GameType	NVARCHAR(50)	NOT NULL ,
	PlayerId	INT				NOT NULL ,
	BetAmount	MONEY			NOT NULL ,
	Profit		MONEY			NOT NULL ,

	CONSTRAINT
		pk_Games_c_GameId
	PRIMARY KEY CLUSTERED
		(GameId ASC) ,

	CONSTRAINT
		fk_Games_PlayerId_Players_PlayerId
	FOREIGN KEY
		(PlayerId)
	REFERENCES
		Casino.Players (PlayerId)
);
GO


ALTER TABLE
	Casino.Games
ADD CONSTRAINT
	ck_Games_BetAmountMustBeBetween1And10
CHECK
	(BetAmount BETWEEN 1.00 AND 10.00);
GO


INSERT INTO
	Casino.Games WITH (TABLOCK)
(
	GameType ,
	PlayerId ,
	BetAmount ,
	Profit
)
SELECT TOP (1000000)
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
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2
CROSS JOIN
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 5 + 1
	)
	AS
		RandomValueTable;
GO


-- Create and populate the "Member.Logins" table

CREATE SCHEMA
	Member;
GO


CREATE TABLE
	Member.Logins
(
	LoginId				INT				NOT NULL	IDENTITY (1,1) ,
	MemberId			INT				NOT NULL ,
	Username			NVARCHAR(20)	NOT NULL ,
	LoginDateTime		DATETIME2(0)	NOT NULL ,
	NumberOfAttempts	INT				NOT NULL ,

	CONSTRAINT
		pk_Logins_c_LoginId
	PRIMARY KEY CLUSTERED
		(LoginId ASC)
);
GO


INSERT INTO
	Member.Logins WITH (TABLOCK)
(
	MemberId ,
	Username ,
	LoginDateTime ,
	NumberOfAttempts
)
SELECT TOP (1000000)
	MemberId			= ABS (CHECKSUM (NEWID ())) % 100000 + 1 ,
	Username			= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 20 + 1) ,
	LoginDateTime		= DATEADD (SECOND , - ABS (CHECKSUM (NEWID ())) % (60 * 60 * 24 * 365) , SYSDATETIME ()) ,
	NumberOfAttempts	= ABS (CHECKSUM (NEWID ())) % 3 + 1
FROM
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2;
GO


CREATE NONCLUSTERED INDEX
	ix_Logins_nc_nu_MemberId
ON
	Member.Logins (MemberId ASC);
GO


CREATE NONCLUSTERED INDEX
	ix_Logins_nc_nu_LoginDateTime
ON
	Member.Logins (LoginDateTime ASC);
GO


-- Create and populate the "Map.Roads" table

CREATE SCHEMA
	Map;
GO


CREATE TABLE
	Map.Roads
(
	RoadId			INT				NOT NULL	IDENTITY (1,1) ,
	RoadNumber		INT				NOT NULL ,
	RoadName		NVARCHAR(50)	NULL ,
	RegionId		INT				NOT NULL ,
	StartLocation	GEOGRAPHY		NOT NULL ,
	EndLocation		GEOGRAPHY		NOT NULL ,
	RoadType		NVARCHAR(50)	NOT NULL ,

	CONSTRAINT
		pk_Roads_c_RoadId
	PRIMARY KEY CLUSTERED
		(RoadId ASC)
);
GO


INSERT INTO
	Map.Roads WITH (TABLOCK)
(
	RoadNumber ,
	RoadName ,
	RegionId ,
	StartLocation ,
	EndLocation ,
	RoadType
)
SELECT TOP (10000)
	RoadNumber		= ROW_NUMBER () OVER (ORDER BY (SELECT NULL) ASC) ,
	RoadName		=	CASE ABS (CHECKSUM (NEWID ())) % 5
							WHEN 0	THEN N'Road #' + CAST ((ROW_NUMBER () OVER (ORDER BY (SELECT NULL) ASC)) AS NVARCHAR(50))
							ELSE	NULL
						END ,
	RegionId		= ABS (CHECKSUM (NEWID ())) % 100 + 1 ,
	StartLocation	= GEOGRAPHY::STGeomFromText ('POINT(' + CAST ((CHECKSUM (NEWID ()) % 15070) AS VARCHAR(100)) + ' ' + CAST ((CHECKSUM (NEWID ()) % 91) AS VARCHAR(100)) + ')' , 4326) ,
	EndLocation		= GEOGRAPHY::STGeomFromText ('POINT(' + CAST ((CHECKSUM (NEWID ()) % 15070) AS VARCHAR(100)) + ' ' + CAST ((CHECKSUM (NEWID ()) % 91) AS VARCHAR(100)) + ')' , 4326) ,
	RoadType		=	CASE RandomValueTable.RandomValue
							WHEN 1	THEN N'Highway'
							WHEN 2	THEN N'Driveway'
							WHEN 3	THEN N'Boulevard'
							WHEN 4	THEN N'Alley'
							WHEN 5	THEN N'Dirt Road'
						END
FROM
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2
CROSS JOIN
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 5 + 1
	)
	AS
		RandomValueTable;
GO


-- Create and populate the "Library.Books" table

CREATE SCHEMA
	Library;
GO


CREATE TABLE
	Library.Books
(
	BookId			INT				NOT NULL	IDENTITY (1,1) ,
	BookISBN		NVARCHAR(50)	NOT NULL ,
	BookTitle		NVARCHAR(50)	NOT NULL ,
	BookAuthor		NVARCHAR(50)	NOT NULL ,
	NumberOfPages	INT				NOT NULL ,

	CONSTRAINT
		pk_Books_c_BookId
	PRIMARY KEY CLUSTERED
		(BookId ASC)
);
GO


INSERT INTO
	Library.Books WITH (TABLOCK)
(
	BookISBN ,
	BookTitle ,
	BookAuthor ,
	NumberOfPages
)
SELECT TOP (10000)
	BookISBN		= CAST (NEWID () AS NVARCHAR(50)) ,
	BookTitle		= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 50 + 1) ,
	BookAuthor		= REPLICATE (N'Y' , ABS (CHECKSUM (NEWID ())) % 50 + 1) ,
	NumberOfPages	= ABS (CHECKSUM (NEWID ())) % 1000 + 1
FROM
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2;
GO


CREATE NONCLUSTERED INDEX
	ix_Books_nc_nu_BookAuthor
ON
	Library.Books (BookAuthor ASC);
GO


-- Create and populate the "Library.Copies" table

CREATE TABLE
	Library.Copies
(
	CopyId			INT				NOT NULL	IDENTITY(1,1) ,
	BookId			INT				NOT NULL ,
	CopyStatus		NVARCHAR(20)	NOT NULL ,
	LastStatusDate	DATE			NOT NULL ,

	CONSTRAINT
		pk_Copies_c_CopyId
	PRIMARY KEY CLUSTERED
		(CopyId ASC) ,

	CONSTRAINT
		fk_Copies_BookId_Books_BookId
	FOREIGN KEY
		(BookId)
	REFERENCES
		Library.Books (BookId)
);
GO


INSERT INTO
	Library.Copies WITH (TABLOCK)
(
	BookId ,
	CopyStatus ,
	LastStatusDate
)
SELECT TOP (100000)
	BookId			= ABS (CHECKSUM (NEWID ())) % 10000 + 1 ,
	CopyStatus		=	CASE RandomValueTable.RandomValue
							WHEN 1	THEN N'On Shelf'
							WHEN 2	THEN N'Borrowed'
							WHEN 3	THEN N'Returned'
							WHEN 4	THEN N'Ruined'
							WHEN 5	THEN N'Lost'
						END ,
	LastStatusDate	= DATEADD (DAY , - ABS (CHECKSUM (NEWID ())) % 365 , SYSDATETIME ())
FROM
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2
CROSS JOIN
	(
		SELECT
			RandomValue = ABS (CHECKSUM (NEWID ())) % 5 + 1
	)
	AS
		RandomValueTable;
GO


CREATE NONCLUSTERED INDEX
	ix_Copies_nc_nu_BookId
ON
	Library.Copies (BookId ASC);
GO


-- Setup the ARITHABORT problem

CREATE PROCEDURE
	Operation.usp_GetInvitationsByStatus
(
	@inStatusId AS TINYINT
)
AS

SELECT TOP (10)
	Id ,
	RequestingSessionId ,
	ReceivingMemberId ,
	CreationDateTime ,
	StatusId ,
	ResponseDateTime
FROM
	Operation.Invitations
WHERE
	StatusId = @inStatusId
ORDER BY
	CreationDateTime ASC;
GO


INSERT INTO
	Operation.Invitations
(
	RequestingSessionId ,
	ReceivingMemberId ,
	CreationDateTime ,
	StatusId ,
	ResponseDateTime
)
SELECT TOP (10)
	RequestingSessionId	= ABS (CHECKSUM (NEWID ())) % 1000000 + 1 ,
	ReceivingMemberId	= ABS (CHECKSUM (NEWID ())) % 100000 + 1 ,
	CreationDateTime	= DATEADD (SECOND , - ABS (CHECKSUM (NEWID ())) % (365 * 24 * 60 * 60) , SYSDATETIME ()) ,
	StatusId			= 4 ,
	ResponseDateTime	= NULL
FROM
	sys.all_columns;
GO


CREATE NONCLUSTERED INDEX
	ix_Invitations_nc_nu_StatusId
ON
	Operation.Invitations (StatusId ASC);
GO






-- Create and populate the "Telecom.Devices" table

CREATE SCHEMA
	Telecom;
GO


CREATE TABLE
	Telecom.Devices
(
	DeviceId		INT				NOT NULL	IDENTITY(1,1) ,
	DeviceModel		NVARCHAR(50)	NOT NULL ,
	DeviceNumber	NVARCHAR(20)	NOT NULL ,

	CONSTRAINT
		pk_Devices_c_DeviceId
	PRIMARY KEY CLUSTERED
		(DeviceId ASC)
);
GO


INSERT INTO
	Telecom.Devices WITH (TABLOCK)
(
	DeviceModel ,
	DeviceNumber
)
SELECT TOP (100000)
	DeviceModel		= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 50 + 1) ,
	DeviceNumber	= REPLICATE (N'9' , ABS (CHECKSUM (NEWID ())) % 20 + 1)
FROM
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2;
GO


-- Create and populate the "Telecom.Conversations" table

CREATE TABLE
	Telecom.Conversations
(
	ConversationId	INT				NOT NULL	IDENTITY(1,1) ,
	SourceDeviceId	INT				NULL ,
	TargetDeviceId	INT				NULL ,
	StartDateTime	DATETIME2(0)	NOT NULL ,
	EndDateTime		DATETIME2(0)	NOT NULL ,

	CONSTRAINT
		pk_Conversations_c_ConversationId
	PRIMARY KEY CLUSTERED
		(ConversationId ASC)
);
GO


INSERT INTO
	Telecom.Conversations WITH (TABLOCK)
(
	SourceDeviceId ,
	TargetDeviceId ,
	StartDateTime ,
	EndDateTime
)
SELECT TOP (1000000)
	SourceDeviceId	= ABS (CHECKSUM (NEWID ())) % 100000 + 1 ,
	TargetDeviceId	= ABS (CHECKSUM (NEWID ())) % 100000 + 1 ,
	StartDateTime	= DATEADD (SECOND , - ABS (CHECKSUM (NEWID ())) % (60 * 60 * 24 * 365) , SYSDATETIME ()) ,
	EndDateTime		= DATEADD (SECOND , - ABS (CHECKSUM (NEWID ())) % (60 * 60 * 24 * 365) , SYSDATETIME ())
FROM
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2;
GO


-- Create and populate the "Telecom.TextMessages" table

CREATE TABLE
	Telecom.TextMessages
(
	MessageId			INT				NOT NULL	IDENTITY(1,1) ,
	SourceDeviceId		INT				NULL ,
	TargetDeviceId		INT				NULL ,
	SentDateTime		DATETIME2(7)	NOT NULL ,
	ReceivedDateTime	DATETIME2(7)	NOT NULL ,
	MessageText			NVARCHAR(100)	NOT NULL ,

	CONSTRAINT
		pk_TextMessages_c_MessageId
	PRIMARY KEY CLUSTERED
		(MessageId ASC)
);
GO


INSERT INTO
	Telecom.TextMessages WITH (TABLOCK)
(
	SourceDeviceId ,
	TargetDeviceId ,
	SentDateTime ,
	ReceivedDateTime ,
	MessageText
)
SELECT TOP (1000000)
	SourceDeviceId		= ABS (CHECKSUM (NEWID ())) % 100000 + 1 ,
	TargetDeviceId		= ABS (CHECKSUM (NEWID ())) % 100000 + 1 ,
	SentDateTime		= DATEADD (SECOND , - ABS (CHECKSUM (NEWID ())) % (60 * 60 * 24 * 365) , SYSDATETIME ()) ,
	ReceivedDateTime	= DATEADD (SECOND , - ABS (CHECKSUM (NEWID ())) % (60 * 60 * 24 * 365) , SYSDATETIME ()) ,
	MessageText			= REPLICATE (N'X' , ABS (CHECKSUM (NEWID ())) % 100 + 1)
FROM
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2;
GO


-- Create and populate the "Billing.Payments" table

CREATE TABLE
	Billing.Payments
(
	Id					INT				NOT NULL	IDENTITY(1,1) ,
	MemberId			NVARCHAR(20)	NOT NULL ,
	Amount				DECIMAL(19,2)	NOT NULL ,
	DateAndTime			DATETIME2(0)	NOT NULL

	CONSTRAINT
		pk_Payments_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
	ON
		[PRIMARY]
)
ON
	[PRIMARY];
GO


INSERT INTO
	Billing.Payments WITH (TABLOCK)
(
	MemberId ,
	Amount ,
	DateAndTime
)
SELECT TOP (2000000)
	MemberId	= CAST (Members.Id AS NVARCHAR(20)) ,
	Amount		= CAST ((ABS (CHECKSUM (NEWID ())) % 100000 / 100.0) AS DECIMAL(19,2)) ,
	DateAndTime	= DATEADD (SECOND , ABS (CHECKSUM (NEWID ())) % DATEDIFF (SECOND , Members.RegistrationDateTime , SYSDATETIME ()) , Members.RegistrationDateTime)
FROM
	Operation.Members AS Members
CROSS JOIN
	sys.tables
ORDER BY
	NEWID () ASC;
GO


INSERT INTO
	Billing.Payments WITH (TABLOCK)
(
	MemberId ,
	Amount ,
	DateAndTime
)
SELECT TOP (100000)
	MemberId	= CAST (Members.Id AS NVARCHAR(20)) ,
	Amount		= CAST ((ABS (CHECKSUM (NEWID ())) % 100000 / 100.0) AS DECIMAL(19,2)) ,
	DateAndTime	= DATEADD (SECOND , ABS (CHECKSUM (NEWID ())) % DATEDIFF (SECOND , Members.RegistrationDateTime , SYSDATETIME ()) , Members.RegistrationDateTime)
FROM
	Operation.Members AS Members
CROSS JOIN
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2
WHERE
	Members.Id = 54321;
GO


INSERT INTO
	Billing.Payments WITH (TABLOCK)
(
	MemberId ,
	Amount ,
	DateAndTime
)
SELECT TOP (100000)
	MemberId	= CAST (Members.Id AS NVARCHAR(20)) ,
	Amount		= CAST ((ABS (CHECKSUM (NEWID ())) % 100000 / 100.0) AS DECIMAL(19,2)) ,
	DateAndTime	= DATEADD (SECOND , ABS (CHECKSUM (NEWID ())) % DATEDIFF (SECOND , Members.RegistrationDateTime , SYSDATETIME ()) , Members.RegistrationDateTime)
FROM
	Operation.Members AS Members
CROSS JOIN
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2
WHERE
	Members.Id = 65432;
GO


INSERT INTO
	Billing.Payments WITH (TABLOCK)
(
	MemberId ,
	Amount ,
	DateAndTime
)
SELECT TOP (100000)
	MemberId	= CAST (Members.Id AS NVARCHAR(20)) ,
	Amount		= CAST ((ABS (CHECKSUM (NEWID ())) % 100000 / 100.0) AS DECIMAL(19,2)) ,
	DateAndTime	= DATEADD (SECOND , ABS (CHECKSUM (NEWID ())) % DATEDIFF (SECOND , Members.RegistrationDateTime , SYSDATETIME ()) , Members.RegistrationDateTime)
FROM
	Operation.Members AS Members
CROSS JOIN
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2
WHERE
	Members.Id = 76543;
GO


INSERT INTO
	Billing.Payments WITH (TABLOCK)
(
	MemberId ,
	Amount ,
	DateAndTime
)
SELECT
	MemberId	= CAST (Members.Id AS NVARCHAR(20)) ,
	Amount		= CAST ((ABS (CHECKSUM (NEWID ())) % 100000 / 100.0) AS DECIMAL(19,2)) ,
	DateAndTime	= DATEADD (SECOND , - ABS (CHECKSUM (NEWID ())) % (60 * 24 * 60 * 60) , SYSDATETIME ())
FROM
	Operation.Members AS Members;
GO


-- Create the "Billing.PendingPayments" table

CREATE TABLE
	Billing.PendingPayments
(
	Id					INT				NOT NULL	IDENTITY(1,1) ,
	MemberId			NVARCHAR(20)	NOT NULL ,
	Amount				DECIMAL(19,2)	NOT NULL ,
	DateAndTime			DATETIME2(0)	NOT NULL

	CONSTRAINT
		pk_PendingPayments_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
	ON
		[PRIMARY]
)
ON
	[PRIMARY];
GO


-- Create and populate the "Operation.PageViews" table

CREATE TABLE
	Operation.PageViews
(
	Id				UNIQUEIDENTIFIER	NOT NULL	ROWGUIDCOL ,
	URL				NVARCHAR(1000)		NOT NULL ,
	EntryDateTime	DATETIME2(7)		NOT NULL ,
	ExitDateTime	DATETIME2(7)		NOT NULL ,
	MemberId		INT					NOT NULL ,

	CONSTRAINT
		pk_PageViews_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
	ON
		[PRIMARY] ,

	CONSTRAINT
		fk_PageViews_MemberId_Members_Id
	FOREIGN KEY
		(MemberId)
	REFERENCES
		Operation.Members (Id)
)
ON
	[PRIMARY];
GO


ALTER TABLE
	Operation.PageViews
ADD CONSTRAINT
	df_PageViews_Id
DEFAULT
	NEWID ()
FOR
	Id;
GO


INSERT INTO
	Operation.PageViews WITH (TABLOCK)
(
	URL ,
	EntryDateTime ,
	ExitDateTime ,
	MemberId
)
SELECT TOP (500000)
	URL					= N'http://www.edate.com/page_' + CAST ((ABS (CHECKSUM (NEWID ())) % 100 + 1) AS NVARCHAR(1000)) ,
	EntryDateTime		= DATEADD (SECOND , ABS (CHECKSUM (NEWID ())) % DATEDIFF (SECOND , Members.RegistrationDateTime , SYSDATETIME ()) - (60 * 60 * 24 * 7) , Members.RegistrationDateTime) ,
	ExitDateTime		= SYSDATETIME () ,
	MemberId			= Members.Id
FROM
	Operation.Members AS Members
CROSS JOIN
	sys.objects
ORDER BY
	NEWID () ASC;
GO


UPDATE
	Operation.PageViews
SET
	ExitDateTime = DATEADD (SECOND , ABS (CHECKSUM (NEWID ())) % 60 + 1 , EntryDateTime);
GO


-- Create an out-of-date statistics scenario on the "Operation.PageViews" table

SELECT
	NULL
FROM
	Operation.PageViews
WHERE
	EntryDateTime > DATEADD (WEEK , -1 , SYSDATETIME ());
GO


INSERT INTO
	Operation.PageViews WITH (TABLOCK)
(
	URL ,
	EntryDateTime ,
	ExitDateTime ,
	MemberId
)
SELECT TOP (10000)
	URL					= N'http://www.edate.com/page_' + CAST ((ABS (CHECKSUM (NEWID ())) % 100 + 1) AS NVARCHAR(1000)) ,
	EntryDateTime		= DATEADD (SECOND , - ABS (CHECKSUM (NEWID ())) % (60 * 60 * 24 * 7) , SYSDATETIME ()) ,
	ExitDateTime		= SYSDATETIME () ,
	MemberId			= Members.Id
FROM
	Operation.Members AS Members
CROSS JOIN
	sys.objects
ORDER BY
	NEWID () ASC;
GO


-- Create and populate the "Operation.SessionEvents" table

CREATE TABLE
	Operation.SessionEvents
(
	Id				INT				NOT NULL	IDENTITY (1,1) ,
	MemberId		INT				NOT NULL ,
	SessionId		INT				NOT NULL ,
	EventTypeId		TINYINT			NOT NULL ,
	DateAndTime		DATETIME2(3)	NOT NULL ,
	URL				NVARCHAR(1000)	NOT NULL ,

	CONSTRAINT
		pk_SessionEvents_c_Id
	PRIMARY KEY CLUSTERED
		(Id ASC)
	ON
		[PRIMARY] ,

	CONSTRAINT
		fk_SessionEvents_MemberId_Members_Id
	FOREIGN KEY
		(MemberId)
	REFERENCES
		Operation.Members (Id) ,

	CONSTRAINT
		fk_SessionEvents_SessionId_MemberSessions_Id
	FOREIGN KEY
		(SessionId)
	REFERENCES
		Operation.MemberSessions (Id) ,

	CONSTRAINT
		fk_SessionEvents_EventTypeId_EventTypes_Id
	FOREIGN KEY
		(EventTypeId)
	REFERENCES
		Lists.EventTypes (Id)
)
ON
	[PRIMARY];
GO


CREATE TABLE
	dbo.DistributionStatistics
(
	SessionId		INT	NOT NULL ,
	NumberOfRows	INT	NOT NULL
);
GO


INSERT INTO
	dbo.DistributionStatistics
(
	SessionId ,
	NumberOfRows
)
SELECT TOP (1000)
	SessionId		= ABS (CHECKSUM (NEWID ())) % 500000 + 1 ,
	NumberOfRows	= ABS (CHECKSUM (NEWID ())) % 10000 + 1
FROM
	sys.all_columns AS T1
CROSS JOIN
	sys.all_columns AS T2;
GO


DECLARE
	@intSessionId		AS INT ,
	@intNumberOfRows	AS INT;

DECLARE
	csrSessions
CURSOR
	LOCAL STATIC FORWARD_ONLY READ_ONLY
FOR
	SELECT
		SessionId ,
		NumberOfRows
	FROM
		dbo.DistributionStatistics;

OPEN csrSessions;

FETCH NEXT FROM
	csrSessions
INTO
	@intSessionId ,
	@intNumberOfRows;

WHILE
	@@FETCH_STATUS = 0
BEGIN

	INSERT INTO
		Operation.SessionEvents
	(
		MemberId ,
		SessionId ,
		EventTypeId ,
		DateAndTime ,
		URL
	)
	SELECT TOP (@intNumberOfRows)
		MemberId	= ABS (CHECKSUM (NEWID ())) % 100000 + 1 ,
		SessionId	= @intSessionId ,
		EventTypeId	= ABS (CHECKSUM (NEWID ())) % 5 + 1 ,
		DateAndTime	= DATEADD (SECOND , ABS (CHECKSUM (NEWID ())) % DATEDIFF (SECOND , MemberSessions.LoginDateTime , ISNULL (MemberSEssions.EndDateTime , SYSDATETIME ())) , MemberSessions.LoginDateTime) ,
		URL			= N'www.madeira.co.il/' + REPLICATE (N'x' , ABS (CHECKSUM (NEWID ())) % 10 + 1)
	FROM
		Operation.MemberSessions AS MemberSessions
	CROSS JOIN
		sys.all_columns AS T1
	CROSS JOIN
		sys.all_columns AS T2
	WHERE
		MemberSessions.Id = @intSessionId;
	
	FETCH NEXT FROM
		csrSessions
	INTO
		@intSessionId ,
		@intNumberOfRows;

END;

CLOSE csrSessions;
DEALLOCATE csrSessions;
GO


DROP TABLE
	dbo.DistributionStatistics;
GO


-- Create programming objects

CREATE PROCEDURE
	Operation.usp_GetOpenInvitationsPerRequestingSession
(
	@inSessionId AS INT
)
AS

SELECT
	Id ,
	ReceivingMemberId ,
	CreationDateTime
FROM
	Operation.Invitations
WHERE
	RequestingSessionId = @inSessionId
AND
	StatusId = 1	-- Sent
ORDER BY
	CreationDateTime ASC;
GO


CREATE FUNCTION
	Operation.udf_InvitationRank
(
	@inStatusId			AS TINYINT ,
	@inCreationDateTime	AS DATETIME2(0) ,
	@inResponseDateTime	AS DATETIME2(0)
)
RETURNS
	NVARCHAR(10)
AS
BEGIN

	DECLARE
		@Result AS NVARCHAR(10);

	IF
		@inStatusId = 1	-- Sent
	BEGIN

		IF
			DATEDIFF (DAY , @inCreationDateTime , SYSDATETIME ()) > 30
		BEGIN

			SET @Result = N'Very Poor';

		END;

		IF
			DATEDIFF (DAY , @inCreationDateTime , SYSDATETIME ()) <= 30
		AND
			DATEDIFF (DAY , @inCreationDateTime , SYSDATETIME ()) > 10
		BEGIN

			SET @Result = N'Poor';

		END;

		IF
			DATEDIFF (DAY , @inCreationDateTime , SYSDATETIME ()) <= 10
		BEGIN

			SET @Result = N'Maybe';

		END;

	END;

	IF
		@inStatusId = 2	-- Accepted
	BEGIN

		IF
			DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) > 30
		BEGIN

			SET @Result = N'Nice';

		END;

		IF
			DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) <= 30
		AND
			DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) > 10
		BEGIN

			SET @Result = N'Good';

		END;

		IF
			DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) <= 10
		BEGIN

			SET @Result = N'Excellent';

		END;

	END;

	IF
		@inStatusId = 3	-- Denied
	BEGIN

		IF
			DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) > 30
		BEGIN

			SET @Result = N'Not Good';

		END;

		IF
			DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) <= 30
		AND
			DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) > 10
		BEGIN

			SET @Result = N'Bad';

		END;

		IF
			DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) <= 10
		BEGIN

			SET @Result = N'Basa';

		END;

	END;

	RETURN @Result;

END;
GO


CREATE PROCEDURE
	Operation.usp_SendFakeInvitations
AS

DECLARE
	@tblPotentialCouples
TABLE
(
	RequestingMemberId	INT	NOT NULL ,
	ReceivingMemberId	INT	NOT NULL
);

INSERT INTO
	@tblPotentialCouples
(
	RequestingMemberId ,
	ReceivingMemberId
)
SELECT
	RequestingMemberId	= RequestingMembers.Id ,
	ReceivingMemberId	= ReceivingMembers.Id
FROM
	(
		SELECT TOP (2000)
			Id ,
			CountryId ,
			BirthDate ,
			SexualPreferenceId
		FROM
			Operation.Members
		ORDER BY
			NEWID () ASC
	)
	AS
		RequestingMembers
CROSS JOIN
	(
		SELECT TOP (2000)
			Id ,
			CountryId ,
			GenderId ,
			BirthDate
		FROM
			Operation.Members
		WHERE
			MaritalStatusId != 2
		OR
			MaritalStatusId IS NULL
		ORDER BY
			NEWID () ASC
	)
	AS
		ReceivingMembers
WHERE
	RequestingMembers.CountryId = ReceivingMembers.CountryId
AND
	(RequestingMembers.SexualPreferenceId = ReceivingMembers.GenderId OR RequestingMembers.SexualPreferenceId IS NULL)
AND
	ABS (DATEDIFF (YEAR , RequestingMembers.BirthDate , ReceivingMembers.BirthDate)) <= 5
AND
	RequestingMembers.Id != ReceivingMembers.Id;

INSERT INTO
	Operation.Invitations
(
	RequestingSessionId ,
	ReceivingMemberId ,
	CreationDateTime ,
	StatusId ,
	ResponseDateTime
)
SELECT
	RequestingSessionId	= RequestingSessions.Id ,
	ReceivingMemberId	= PotentialCouples.ReceivingMemberId ,
	CreationDateTime	= DATEADD (SECOND , 5 , RequestingSessions.LoginDateTime) ,
	StatusId			= 1 ,	-- Sent
	ResponseDateTime	= NULL
FROM
	@tblPotentialCouples AS PotentialCouples
CROSS APPLY
	(
		SELECT TOP (1)
			MemberSessions.Id ,
			MemberSessions.LoginDateTime
		FROM
			Operation.MemberSessions AS MemberSessions
		WHERE
			MemberSessions.MemberId = PotentialCouples.RequestingMemberId
		ORDER BY
			MemberSessions.LoginDateTime DESC
	)
	AS
		RequestingSessions;
GO


CREATE PROCEDURE
	Operation.usp_CloseInvitations
AS

DECLARE
	@MemberId		AS INT ,
	@MemberGenderId	AS TINYINT ,
	@SessionId		AS INT;

DECLARE
	csrMembers
CURSOR
	LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
	SELECT
		MemberId		= Id ,
		MemberGenderId	= GenderId
	FROM
		Operation.Members
	ORDER BY
		MemberId ASC;

OPEN csrMembers;

FETCH NEXT FROM
	csrMembers
INTO
	@MemberId ,
	@MemberGenderId;

WHILE
	@@FETCH_STATUS = 0
BEGIN

	DECLARE
		csrMemberSessions
	CURSOR
		LOCAL STATIC READ_ONLY FORWARD_ONLY
	FOR
		SELECT
			SessionId = Id
		FROM
			Operation.MemberSessions
		WHERE
			MemberId = @MemberId
		AND
			LoginDateTime < DATEADD (YEAR , -2 , SYSDATETIME ())
		ORDER BY
			SessionId ASC;

	OPEN csrMemberSessions;

	FETCH NEXT FROM
		csrMemberSessions
	INTO
		@SessionId;

	WHILE
		@@FETCH_STATUS = 0
	BEGIN

		CREATE TABLE
			#Invitations
		(
			InvitationId		INT				NOT NULL ,
			ReceivingMemberId	INT				NOT NULL ,
			CreationDateTime	DATETIME2(0)	NOT NULL
		);

		INSERT INTO
			#Invitations
		(
			InvitationId ,
			ReceivingMemberId ,
			CreationDateTime
		)
		EXECUTE Operation.usp_GetOpenInvitationsPerRequestingSession
			@inSessionId = @SessionId;

		IF
			@MemberGenderId = 1	-- Male
		BEGIN

			UPDATE
				Operation.Invitations
			SET
				StatusId			= 3 ,	-- Denied
				ResponseDateTime	= SYSDATETIME ()
			WHERE
				Id IN
					(
						SELECT
							InvitationId
						FROM
							#Invitations
					);

		END;

		IF
			@MemberGenderId = 2	-- Female
		BEGIN

			UPDATE
				Operation.Invitations
			SET
				StatusId			= 2 ,	-- Accepted
				ResponseDateTime	= SYSDATETIME ()
			WHERE
				Id IN
					(
						SELECT
							InvitationId
						FROM
							#Invitations
					);

		END;

		DROP TABLE
			#Invitations;

		FETCH NEXT FROM
			csrMemberSessions
		INTO
			@SessionId;

	END;

	CLOSE csrMemberSessions;

	DEALLOCATE csrMemberSessions;

	FETCH NEXT FROM
		csrMembers
	INTO
		@MemberId ,
		@MemberGenderId;

END;

CLOSE csrMembers;

DEALLOCATE csrMembers;
GO


CREATE PROCEDURE
	Billing.usp_GetPaymentsByMemberId
(
	@inMemberId AS NVARCHAR(20)
)
AS

SELECT
	Id ,
	Amount ,
	DateAndTime
FROM
	Billing.Payments
WHERE
	MemberId = @inMemberId;
GO


CREATE PROCEDURE
	Operation.usp_GetSessionsBetweenDates
(
	@inFromDateTime	AS DATETIME2(0)	= NULL ,
	@inToDateTime	AS DATETIME2(0)	= NULL
)
AS

DECLARE
	@FromDateTime	AS DATETIME2(0)	= ISNULL (@inFromDateTime , DATEADD (HOUR , -5 , SYSDATETIME ())) ,
	@ToDateTime		AS DATETIME2(0)	= ISNULL (@inToDateTime , SYSDATETIME ());

SELECT
	SessionId		= Id ,
	MemberId		= MemberId ,
	LoginDateTime	= LoginDateTime ,
	EndDateTime		= EndDateTime
FROM
	Operation.MemberSessions
WHERE
	LoginDateTime >= @FromDateTime
AND
	LoginDateTime < @ToDateTime;
GO


CREATE PROCEDURE Operation.usp_GetReferredMembers
(
	@inReferringMemberId	AS INT ,
	@inReferralLevel		AS INT
)
AS

DECLARE
	@ReferredMemberId	AS INT ,
	@NextReferralLevel	AS INT	= @inReferralLevel + 1;

DECLARE
	csrReferredMembers
CURSOR
	LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
	SELECT
		Id
	FROM
		Operation.Members
	WHERE
		ReferringMemberId = @inReferringMemberId

OPEN csrReferredMembers;

FETCH NEXT FROM
	csrReferredMembers
INTO
	@ReferredMemberId;

WHILE
	@@FETCH_STATUS = 0
BEGIN

	INSERT INTO
		#ReferredMembers
	(
		MemberId ,
		ReferralLevel
	)
	VALUES
	(
		@ReferredMemberId ,
		@NextReferralLevel
	);
	
	EXECUTE Operation.usp_GetReferredMembers
		@inReferringMemberId	= @ReferredMemberId ,
		@inReferralLevel		= @NextReferralLevel;

	FETCH NEXT FROM
		csrReferredMembers
	INTO
		@ReferredMemberId;

END;

CLOSE csrReferredMembers;

DEALLOCATE csrReferredMembers;
GO


CREATE PROCEDURE Operation.usp_GetReferralTree
(
	@inMemberId AS INT
)
AS

CREATE TABLE
	#ReferredMembers
(
	MemberId		INT	NOT NULL ,
	ReferralLevel	INT	NOT NULL
);

INSERT INTO
	#ReferredMembers
(
	MemberId ,
	ReferralLevel
)
VALUES
(
	@inMemberId ,
	0
);

EXECUTE Operation.usp_GetReferredMembers
	@inReferringMemberId	= @inMemberId ,
	@inReferralLevel		= 0;

SELECT
	MemberId ,
	ReferralLevel
FROM
	#ReferredMembers
ORDER BY
	ReferralLevel	ASC ,
	MemberId		ASC;

DROP TABLE
	#ReferredMembers;
GO


CREATE TRIGGER
	Operation.trg_Members_a_i_CreateFolderForMember
ON
	Operation.Members
AFTER
	INSERT
AS
BEGIN

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


-- Create and populate the "Web.ReferenceCodes" table

CREATE SCHEMA
	Web;
GO


CREATE TABLE
	Web.ReferenceCodes
(
	ReferenceCode	BIGINT	NOT NULL ,
	CustomerId		BIGINT	NOT NULL ,
	CampaignId		BIGINT	NULL ,
	CreationDate	DATE	NOT NULL ,
	ExpirationDate	DATE	NULL ,

	CONSTRAINT
		pk_ReferenceCodes_c_ReferenceCode
	PRIMARY KEY CLUSTERED
		(ReferenceCode ASC)
);
GO


INSERT INTO
	Web.ReferenceCodes WITH (TABLOCK)
(
	ReferenceCode ,
	CustomerId ,
	CampaignId ,
	CreationDate ,
	ExpirationDate
)
SELECT TOP (1000000)
	ReferenceCode	= ROW_NUMBER () OVER (ORDER BY (SELECT NULL) ASC) ,
	CustomerId		= ABS (CHECKSUM (NEWID ())) % 100000 + 1 ,
	CampaignId		=
		CASE
			WHEN ABS (CHECKSUM (NEWID ())) % 10 <= 1
				THEN NULL
			ELSE
				ABS (CHECKSUM (NEWID ())) % 10000 + 1
		END ,
	CreationDate	= DATEADD (DAY , - (ABS (CHECKSUM (NEWID ())) % (365 * 2)) , SYSDATETIME ()) ,
	ExpirationDate	=
		CASE
			WHEN ABS (CHECKSUM (NEWID ())) % 10 = 0
				THEN NULL
			ELSE
				DATEADD (DAY , ABS (CHECKSUM (NEWID ())) % 365 , SYSDATETIME ())
		END
FROM
	sys.all_objects AS T1
CROSS JOIN
	sys.columns AS T2;
GO


-- Create a partition function and a partition scheme with 184 daily partitions (last 180 days + 4 days into the future)

DECLARE
	@DatesTable TABLE
(
	DateValue DATETIME2(7) NOT NULL
);

INSERT INTO
	@DatesTable
(
	DateValue
)
SELECT TOP 183
	DateValue = CAST (DATEADD (DAY , 4 - (ROW_NUMBER () OVER (ORDER BY (SELECT NULL))) , SYSDATETIME ()) AS DATETIME2(7))
FROM
	sys.all_columns;

DECLARE 
	@Statement AS NVARCHAR(MAX) =
		N'
			CREATE PARTITION FUNCTION
				pf_EveryDay (DATETIME2(7))
			AS RANGE
				RIGHT
			FOR VALUES
				(
					';

SELECT
	@Statement += N'''' + CONVERT (NCHAR(8) , DateValue , 112) + N''' ,
					'
FROM
	@DatesTable
ORDER BY
	DateValue ASC;

SET
	@Statement = LEFT (@Statement , LEN (@Statement) - 9) + N'
				);
		';

EXECUTE sys.sp_executesql
	@statement = @Statement;
GO


CREATE PARTITION SCHEME
	ps_EveryDay
AS
	PARTITION pf_EveryDay
ALL TO
	([PRIMARY]);
GO


-- Create the "Web.PageViews" partitioned table including a dedicated sequence object

CREATE SEQUENCE
	Web.PageViewIDs
AS
	BIGINT
START WITH
	1
INCREMENT BY
	1
MINVALUE
	1
NO MAXVALUE
CACHE
	10000;
GO


CREATE TABLE
	Web.PageViews
(
	Id				BIGINT			NOT NULL ,
	URL				NVARCHAR(100)	NOT NULL ,
	ReferenceCode	BIGINT			NULL ,
	SessionId		BIGINT			NOT NULL ,
	DateAndTime		DATETIME2(7)	NOT NULL ,

	CONSTRAINT
		pk_PageViews_c_DateAndTime#Id
	PRIMARY KEY CLUSTERED
		(
			DateAndTime	ASC ,
			Id			ASC
		) ,

	CONSTRAINT
		fk_PageViews_ReferenceCode_ReferenceCodes
	FOREIGN KEY
		(ReferenceCode)
	REFERENCES
		Web.ReferenceCodes (ReferenceCode)
)
ON
	ps_EveryDay (DateAndTime);
GO


ALTER TABLE
	Web.PageViews
ADD CONSTRAINT
	df_PageViews_Id
DEFAULT
	NEXT VALUE FOR Web.PageViewIDs
FOR
	Id;
GO


-- Create and populate the "Web.RandomDateTimeValues" table as a preparation for loading the "Web.PageViews" table

CREATE TABLE
	Web.RandomDateTimeValues
(
	RandomDateTime DATETIME2(7) NOT NULL
);
GO


INSERT INTO
	Web.RandomDateTimeValues
(
	RandomDateTime
)
SELECT TOP (5000000)
	RandomDateTime = DATEADD (MILLISECOND , ABS (CHECKSUM (NEWID ())) % (24 * 60 * 60 * 1000) , DATEADD (DAY , - (ABS (CHECKSUM (NEWID ())) % (6 * 30)) , CAST (CAST (SYSDATETIME () AS DATE) AS DATETIME2(7))))
FROM
	sys.all_objects AS T1
CROSS JOIN
	sys.all_objects AS T2;
GO


DELETE FROM
	Web.RandomDateTimeValues
WHERE
	RandomDateTime > SYSDATETIME ();
GO


-- Populate the "Web.PageViews" table with data up until last week

INSERT INTO
	Web.PageViews WITH (TABLOCK)
(
	URL ,
	ReferenceCode ,
	SessionId ,
	DateAndTime
)
SELECT
	URL				= N'www.' + REPLICATE (N'x' , ABS (CHECKSUM (NEWID ())) % 90) + N'.com' ,
	ReferenceCode	= ABS (CHECKSUM (NEWID ())) % 1000000 + 1 ,
	SessionId		= ABS (CHECKSUM (NEWID ())) % 1000000 + 1 ,
	DateAndTime		= RandomDateTime
FROM
	Web.RandomDateTimeValues
WHERE
	RandomDateTime < DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	RandomDateTime ASC;
GO


-- Update statistics on the "Web.PageViews" table with a full scan

UPDATE STATISTICS
	Web.PageViews
WITH
	FULLSCAN;
GO


-- Insert data for the last week into the "Web.PageViews" table
-- This will not trigger the automatic statistics update, so according to statistics there are still no rows in the last week

INSERT INTO
	Web.PageViews WITH (TABLOCK)
(
	URL ,
	ReferenceCode ,
	SessionId ,
	DateAndTime
)
SELECT
	URL				= N'www.' + REPLICATE (N'x' , ABS (CHECKSUM (NEWID ())) % 90) + N'.com' ,
	ReferenceCode	= ABS (CHECKSUM (NEWID ())) % 1000000 + 1 ,
	SessionId		= ABS (CHECKSUM (NEWID ())) % 1000000 + 1 ,
	DateAndTime		= RandomDateTime
FROM
	Web.RandomDateTimeValues
WHERE
	RandomDateTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
ORDER BY
	RandomDateTime ASC;
GO
