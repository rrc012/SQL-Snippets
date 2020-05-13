USE
	YourAss;
GO


SET STATISTICS IO ON;
GO


CREATE TABLE
	#MembersWithLastSessions
(
	MemberId		INT				NOT NULL ,
	MemberName		NVARCHAR(100)	NOT NULL ,
	SessionId		INT				NOT NULL ,
	LoginDateTime	DATETIME2(0)	NOT NULL ,
	EndDateTime		DATETIME2(0)	NULL ,
	EndReasonId		TINYINT			NULL
);

DECLARE
	@MemberId	AS INT ,
	@MemberName	AS NVARCHAR(100);

DECLARE
	csrMembers
CURSOR
	LOCAL STATIC READ_ONLY FORWARD_ONLY
FOR
	SELECT
		MemberId	= Id ,
		MemberName	= FirstName + N' ' + LastName
	FROM
		Operation.Members
	WHERE
		CountryId = 4;	-- France

OPEN csrMembers;

FETCH NEXT FROM
	csrMembers
INTO
	@MemberId ,
	@MemberName;

WHILE
	@@FETCH_STATUS = 0
BEGIN

	INSERT INTO
		#MembersWithLastSessions
	(
		MemberId ,
		MemberName ,
		SessionId ,
		LoginDateTime ,
		EndDateTime ,
		EndReasonId
	)
	SELECT TOP (3)
		MemberId		= @MemberId ,
		MemberName		= @MemberName ,
		SessionId		= Id ,
		LoginDateTime	= LoginDateTime ,
		EndDateTime		= EndDateTime ,
		EndReasonId		= EndReasonId
	FROM
		Operation.MemberSessions
	WHERE
		MemberId = @MemberId
	ORDER BY
		LoginDateTime DESC;

	FETCH NEXT FROM
		csrMembers
	INTO
		@MemberId ,
		@MemberName;

END;

CLOSE csrMembers;

DEALLOCATE csrMembers;

SELECT
		MemberId ,
		MemberName ,
		SessionId ,
		LoginDateTime ,
		EndDateTime ,
		EndReasonId
FROM
	#MembersWithLastSessions
ORDER BY
	MemberId		ASC ,
	LoginDateTime	DESC;

DROP TABLE
	#MembersWithLastSessions;
GO


-- Solution #1: Use a correlated sub-query with CROSS APPLY

SELECT
	MemberId		= Members.Id ,
	MemberName		= Members.FirstName + N' ' + Members.LastName ,
	SessionId		= MemberLastSessions.Id ,
	LoginDateTime	= MemberLastSessions.LoginDateTime ,
	EndDateTime		= MemberLastSessions.EndDateTime ,
	EndReasonId		= MemberLastSessions.EndReasonId
FROM
	Operation.Members AS Members
CROSS APPLY
	(
		SELECT TOP (3)
			MemberSessions.Id ,
			MemberSessions.LoginDateTime ,
			MemberSessions.EndDateTime ,
			MemberSessions.EndReasonId
		FROM
			Operation.MemberSessions AS MemberSessions
		WHERE
			MemberSessions.MemberId = Members.Id
		ORDER BY
			MemberSessions.LoginDateTime DESC
	)
	AS
		MemberLastSessions
WHERE
	Members.CountryId = 4	-- France
ORDER BY
	MemberId		ASC ,
	LoginDateTime	DESC;
GO


-- Solution #2: Use the ROW_NUMBER function

SELECT
	MemberId ,
	MemberName ,
	SessionId ,
	LoginDateTime ,
	EndDateTime ,
	EndReasonId
FROM
	(
		SELECT
			MemberId		= Members.Id ,
			MemberName		= Members.FirstName + N' ' + Members.LastName ,
			SessionId		= MemberSessions.Id ,
			LoginDateTime	= MemberSessions.LoginDateTime ,
			EndDateTime		= MemberSessions.EndDateTime ,
			EndReasonId		= MemberSessions.EndReasonId ,
			RowNumber		= ROW_NUMBER () OVER (PARTITION BY Members.Id ORDER BY MemberSessions.LoginDateTime DESC)
		FROM
			Operation.Members AS Members
		INNER JOIN
			Operation.MemberSessions AS MemberSessions
		ON
			Members.Id = MemberSessions.MemberId
		WHERE
			Members.CountryId = 4	-- France
	)
	AS
		MembersWithLastSessions
WHERE
	RowNumber <= 3
ORDER BY
	MemberId		ASC ,
	LoginDateTime	DESC;
GO
