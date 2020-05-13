USE
	YourAss;
GO


SET STATISTICS IO ON;
GO


SELECT
	RequestingMemberId				= RequestingMembers.Id ,
	RequestingMemberName			= RequestingMembers.FirstName + N' ' + RequestingMembers.LastName ,
	ReuestingMemberGenderId			= RequestingMembers.GenderId ,
	ReuestingMemberCountryId		= RequestingMembers.CountryId ,
	ReuestingMemberBirthDate		= RequestingMembers.BirthDate ,
	ReuestingMemberMaritalStatusId	= RequestingMembers.MaritalStatusId ,
	ReuestingMemberPicture			= RequestingMembers.Picture ,
	RequestingSessionLoginDateTime	= MemberSessions.LoginDateTime ,
	RequestingSessionLoginDateTime	= MemberSessions.EndDateTime ,
	InvitationCreationDateTime		= Invitations.CreationDateTime ,
	InvitationResponseDateTime		= Invitations.ResponseDateTime
FROM
	Operation.Members AS RequestingMembers
INNER JOIN
	Operation.MemberSessions AS MemberSessions
ON
	RequestingMembers.Id = MemberSessions.MemberId
INNER JOIN
	Operation.Invitations AS Invitations
ON
	MemberSessions.Id = Invitations.RequestingSessionId
WHERE
	RequestingMembers.BirthDate < DATEADD (YEAR , -20 , SYSDATETIME ())
AND
	DATEDIFF (YEAR , RequestingMembers.BirthDate , RequestingMembers.RegistrationDateTime) > 20
AND
	RequestingMembers.Password LIKE N'%' + LEFT (RequestingMembers.PhoneNumber , 1) + N'%'
AND
	RequestingMembers.Password LIKE N'%' + RIGHT (RequestingMembers.PhoneNumber , 1) + N'%'
AND
	DATEDIFF (MINUTE , MemberSessions.LoginDateTime , MemberSessions.EndDateTime) > 5
AND
	CAST (MemberSessions.LoginDateTime AS DATE) = CAST (MemberSessions.EndDateTime AS DATE);
GO


-- Store partial results in temporary tables - Take I

CREATE TABLE
	#RequestingMembers
(
	RequestingMemberId				INT				NOT NULL ,
	RequestingMemberName			NVARCHAR(41)	NOT NULL ,
	RequestingMemberGenderId		TINYINT			NOT NULL ,
	RequestingMemberCountryId		TINYINT			NOT NULL ,
	RequestingMemberBirthDate		DATE			NOT NULL ,
	RequestingMemberMaritalStatusId	TINYINT			NULL ,
	RequestingMemberPicture			VARBINARY(MAX)	NULL
);

INSERT INTO
	#RequestingMembers
(
	RequestingMemberId ,
	RequestingMemberName ,
	RequestingMemberGenderId ,
	RequestingMemberCountryId ,
	RequestingMemberBirthDate ,
	RequestingMemberMaritalStatusId ,
	RequestingMemberPicture
)
SELECT
	RequestingMemberId				= Id ,
	RequestingMemberName			= FirstName + N' ' + LastName ,
	RequestingMemberGenderId		= GenderId ,
	RequestingMemberCountryId		= CountryId ,
	RequestingMemberBirthDate		= BirthDate ,
	RequestingMemberMaritalStatusId	= MaritalStatusId ,
	RequestingMemberPicture			= Picture
FROM
	Operation.Members
WHERE
	BirthDate < DATEADD (YEAR , -20 , SYSDATETIME ())
AND
	DATEDIFF (YEAR , BirthDate , RegistrationDateTime) > 20
AND
	Password LIKE N'%' + LEFT (PhoneNumber , 1) + N'%'
AND
	Password LIKE N'%' + RIGHT (PhoneNumber , 1) + N'%';

SELECT
	RequestingMemberId				= RequestingMembers.RequestingMemberId ,
	RequestingMemberName			= RequestingMembers.RequestingMemberName ,
	RequestingMemberGenderId		= RequestingMembers.RequestingMemberGenderId ,
	RequestingMemberCountryId		= RequestingMembers.RequestingMemberCountryId ,
	RequestingMemberBirthDate		= RequestingMembers.RequestingMemberBirthDate ,
	RequestingMemberMaritalStatusId	= RequestingMembers.RequestingMemberMaritalStatusId ,
	RequestingMemberPicture			= RequestingMembers.RequestingMemberPicture ,
	RequestingSessionLoginDateTime	= MemberSessions.LoginDateTime ,
	RequestingSessionEndDateTime	= MemberSessions.EndDateTime ,
	InvitationCreationDateTime		= Invitations.CreationDateTime ,
	InvitationResponseDateTime		= Invitations.ResponseDateTime
FROM
	#RequestingMembers AS RequestingMembers
INNER JOIN
	Operation.MemberSessions AS MemberSessions
ON
	RequestingMembers.RequestingMemberId = MemberSessions.MemberId
INNER JOIN
	Operation.Invitations AS Invitations
ON
	MemberSessions.Id = Invitations.RequestingSessionId
WHERE
	DATEDIFF (MINUTE , MemberSessions.LoginDateTime , MemberSessions.EndDateTime) > 5
AND
	CAST (MemberSessions.LoginDateTime AS DATE) = CAST (MemberSessions.EndDateTime AS DATE);

DROP TABLE
	#RequestingMembers;
GO


-- Store partial results in temporary tables - Take II

CREATE TABLE
	#RequestingMembersAndSessions
(
	RequestingMemberId				INT				NOT NULL ,
	RequestingMemberName			NVARCHAR(41)	NOT NULL ,
	RequestingMemberGenderId		TINYINT			NOT NULL ,
	RequestingMemberCountryId		TINYINT			NOT NULL ,
	RequestingMemberBirthDate		DATE			NOT NULL ,
	RequestingMemberMaritalStatusId	TINYINT			NULL ,
	RequestingMemberPicture			VARBINARY(MAX)	NULL ,
	RequestingSessionId				INT				NOT NULL ,
	RequestingSessionLoginDateTime	DATETIME2(0)	NOT NULL ,
	RequestingSessionEndDateTime	DATETIME2(0)	NULL ,
);

INSERT INTO
	#RequestingMembersAndSessions
(
	RequestingMemberId ,
	RequestingMemberName ,
	RequestingMemberGenderId ,
	RequestingMemberCountryId ,
	RequestingMemberBirthDate ,
	RequestingMemberMaritalStatusId ,
	RequestingMemberPicture ,
	RequestingSessionId ,
	RequestingSessionLoginDateTime ,
	RequestingSessionEndDateTime
)
SELECT
	RequestingMemberId				= RequestingMembers.Id ,
	RequestingMemberName			= RequestingMembers.FirstName + N' ' + RequestingMembers.LastName ,
	RequestingMemberGenderId		= RequestingMembers.GenderId ,
	RequestingMemberCountryId		= RequestingMembers.CountryId ,
	RequestingMemberBirthDate		= RequestingMembers.BirthDate ,
	RequestingMemberMaritalStatusId	= RequestingMembers.MaritalStatusId ,
	RequestingMemberPicture			= RequestingMembers.Picture ,
	RequestingSessionId				= MemberSessions.Id ,
	RequestingSessionLoginDateTime	= MemberSessions.LoginDateTime ,
	RequestingSessionEndDateTime	= MemberSessions.EndDateTime
FROM
	Operation.Members AS RequestingMembers
INNER JOIN
	Operation.MemberSessions AS MemberSessions
ON
	RequestingMembers.Id = MemberSessions.MemberId
WHERE
	RequestingMembers.BirthDate < DATEADD (YEAR , -20 , SYSDATETIME ())
AND
	DATEDIFF (YEAR , RequestingMembers.BirthDate , RequestingMembers.RegistrationDateTime) > 20
AND
	RequestingMembers.Password LIKE N'%' + LEFT (RequestingMembers.PhoneNumber , 1) + N'%'
AND
	RequestingMembers.Password LIKE N'%' + RIGHT (RequestingMembers.PhoneNumber , 1) + N'%'
AND
	DATEDIFF (MINUTE , MemberSessions.LoginDateTime , MemberSessions.EndDateTime) > 5
AND
	CAST (MemberSessions.LoginDateTime AS DATE) = CAST (MemberSessions.EndDateTime AS DATE);

SELECT
	RequestingMemberId				= RequestingMembersAndSessions.RequestingMemberId ,
	RequestingMemberName			= RequestingMembersAndSessions.RequestingMemberName ,
	RequestingMemberGenderId		= RequestingMembersAndSessions.RequestingMemberGenderId ,
	RequestingMemberCountryId		= RequestingMembersAndSessions.RequestingMemberCountryId ,
	RequestingMemberBirthDate		= RequestingMembersAndSessions.RequestingMemberBirthDate ,
	RequestingMemberMaritalStatusId	= RequestingMembersAndSessions.RequestingMemberMaritalStatusId ,
	RequestingMemberPicture			= RequestingMembersAndSessions.RequestingMemberPicture ,
	RequestingSessionLoginDateTime	= RequestingMembersAndSessions.RequestingSessionLoginDateTime ,
	RequestingSessionEndDateTime	= RequestingMembersAndSessions.RequestingSessionEndDateTime ,
	InvitationCreationDateTime		= Invitations.CreationDateTime ,
	InvitationResponseDateTime		= Invitations.ResponseDateTime
FROM
	#RequestingMembersAndSessions AS RequestingMembersAndSessions
INNER JOIN
	Operation.Invitations AS Invitations
ON
	RequestingMembersAndSessions.RequestingSessionId = Invitations.RequestingSessionId

DROP TABLE
	#RequestingMembersAndSessions;
GO


-- Store partial results in temporary tables - Take III

CREATE TABLE
	#RequestingMembers
(
	RequestingMemberId				INT				NOT NULL ,
	RequestingMemberName			NVARCHAR(41)	NOT NULL ,
	RequestingMemberGenderId		TINYINT			NOT NULL ,
	RequestingMemberCountryId		TINYINT			NOT NULL ,
	RequestingMemberBirthDate		DATE			NOT NULL ,
	RequestingMemberMaritalStatusId	TINYINT			NULL ,
	RequestingMemberPicture			VARBINARY(MAX)	NULL
);

CREATE TABLE
	#RequestingMembersAndSessions
(
	RequestingMemberId				INT				NOT NULL ,
	RequestingMemberName			NVARCHAR(41)	NOT NULL ,
	RequestingMemberGenderId		TINYINT			NOT NULL ,
	RequestingMemberCountryId		TINYINT			NOT NULL ,
	RequestingMemberBirthDate		DATE			NOT NULL ,
	RequestingMemberMaritalStatusId	TINYINT			NULL ,
	RequestingMemberPicture			VARBINARY(MAX)	NULL ,
	RequestingSessionId				INT				NOT NULL ,
	RequestingSessionLoginDateTime	DATETIME2(0)	NOT NULL ,
	RequestingSessionEndDateTime	DATETIME2(0)	NULL ,
);

INSERT INTO
	#RequestingMembers
(
	RequestingMemberId ,
	RequestingMemberName ,
	RequestingMemberGenderId ,
	RequestingMemberCountryId ,
	RequestingMemberBirthDate ,
	RequestingMemberMaritalStatusId ,
	RequestingMemberPicture
)
SELECT
	RequestingMemberId				= Id ,
	RequestingMemberName			= FirstName + N' ' + LastName ,
	RequestingMemberGenderId		= GenderId ,
	RequestingMemberCountryId		= CountryId ,
	RequestingMemberBirthDate		= BirthDate ,
	RequestingMemberMaritalStatusId	= MaritalStatusId ,
	RequestingMemberPicture			= Picture
FROM
	Operation.Members
WHERE
	BirthDate < DATEADD (YEAR , -20 , SYSDATETIME ())
AND
	DATEDIFF (YEAR , BirthDate , RegistrationDateTime) > 20
AND
	Password LIKE N'%' + LEFT (PhoneNumber , 1) + N'%'
AND
	Password LIKE N'%' + RIGHT (PhoneNumber , 1) + N'%';

INSERT INTO
	#RequestingMembersAndSessions
(
	RequestingMemberId ,
	RequestingMemberName ,
	RequestingMemberGenderId ,
	RequestingMemberCountryId ,
	RequestingMemberBirthDate ,
	RequestingMemberMaritalStatusId ,
	RequestingMemberPicture ,
	RequestingSessionId ,
	RequestingSessionLoginDateTime ,
	RequestingSessionEndDateTime
)
SELECT
	RequestingMemberId				= RequestingMembers.RequestingMemberId ,
	RequestingMemberName			= RequestingMembers.RequestingMemberName ,
	RequestingMemberGenderId		= RequestingMembers.RequestingMemberGenderId ,
	RequestingMemberCountryId		= RequestingMembers.RequestingMemberCountryId ,
	RequestingMemberBirthDate		= RequestingMembers.RequestingMemberBirthDate ,
	RequestingMemberMaritalStatusId	= RequestingMembers.RequestingMemberMaritalStatusId ,
	RequestingMemberPicture			= RequestingMembers.RequestingMemberPicture ,
	RequestingSessionId				= MemberSessions.Id ,
	RequestingSessionLoginDateTime	= MemberSessions.LoginDateTime ,
	RequestingSessionEndDateTime	= MemberSessions.EndDateTime
FROM
	#RequestingMembers AS RequestingMembers
INNER JOIN
	Operation.MemberSessions AS MemberSessions
ON
	RequestingMembers.RequestingMemberId = MemberSessions.MemberId
WHERE
	DATEDIFF (MINUTE , MemberSessions.LoginDateTime , MemberSessions.EndDateTime) > 5
AND
	CAST (MemberSessions.LoginDateTime AS DATE) = CAST (MemberSessions.EndDateTime AS DATE);

SELECT
	RequestingMemberId				= RequestingMembersAndSessions.RequestingMemberId ,
	RequestingMemberName			= RequestingMembersAndSessions.RequestingMemberName ,
	RequestingMemberGenderId		= RequestingMembersAndSessions.RequestingMemberGenderId ,
	RequestingMemberCountryId		= RequestingMembersAndSessions.RequestingMemberCountryId ,
	RequestingMemberBirthDate		= RequestingMembersAndSessions.RequestingMemberBirthDate ,
	RequestingMemberMaritalStatusId	= RequestingMembersAndSessions.RequestingMemberMaritalStatusId ,
	RequestingMemberPicture			= RequestingMembersAndSessions.RequestingMemberPicture ,
	RequestingSessionLoginDateTime	= RequestingMembersAndSessions.RequestingSessionLoginDateTime ,
	RequestingSessionEndDateTime	= RequestingMembersAndSessions.RequestingSessionEndDateTime ,
	InvitationCreationDateTime		= Invitations.CreationDateTime ,
	InvitationResponseDateTime		= Invitations.ResponseDateTime
FROM
	#RequestingMembersAndSessions AS RequestingMembersAndSessions
INNER JOIN
	Operation.Invitations AS Invitations
ON
	RequestingMembersAndSessions.RequestingSessionId = Invitations.RequestingSessionId

DROP TABLE
	#RequestingMembersAndSessions;

DROP TABLE
	#RequestingMembers;
GO
