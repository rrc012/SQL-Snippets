USE
	YourAss;
GO


SET STATISTICS IO ON;
GO


EXECUTE Operation.usp_SendFakeInvitations;
GO


-- Replace the table variable with a temporary table

ALTER PROCEDURE
	Operation.usp_SendFakeInvitations
AS

CREATE TABLE
	#PotentialCouples
(
	RequestingMemberId	INT	NOT NULL ,
	ReceivingMemberId	INT	NOT NULL
);

INSERT INTO
	#PotentialCouples
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
	#PotentialCouples AS PotentialCouples
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

DROP TABLE
	#PotentialCouples;
GO


EXECUTE Operation.usp_SendFakeInvitations;
GO


-- Add a clustered index on the "RequestingMemberId" column in the temporary table

ALTER PROCEDURE
	Operation.usp_SendFakeInvitations
AS

CREATE TABLE
	#PotentialCouples
(
	RequestingMemberId	INT	NOT NULL ,
	ReceivingMemberId	INT	NOT NULL
);

INSERT INTO
	#PotentialCouples
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

CREATE CLUSTERED INDEX
	ix_PotentialCouples_c_RequestingMemberId
ON
	#PotentialCouples (RequestingMemberId ASC);

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
	#PotentialCouples AS PotentialCouples
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

DROP TABLE
	#PotentialCouples;
GO


EXECUTE Operation.usp_SendFakeInvitations;
GO
