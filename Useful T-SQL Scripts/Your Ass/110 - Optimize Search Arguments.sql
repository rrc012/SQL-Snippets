USE
	YourAss;
GO


SET STATISTICS IO ON;
GO


SELECT
	MemberId		= Members.Id ,
	MemberFirstName	= Members.FirstName ,
	MemberLastName	= Members.LastName ,
	LoginDateTime	= MemberSessions.LoginDateTime ,
	EndDateTime		= MemberSessions.EndDateTime ,
	EndReason		= SessionEndReasons.Name
FROM
	Operation.Members AS Members
INNER JOIN
	Operation.MemberSessions AS MemberSessions
ON
	Members.Id = MemberSessions.MemberId
INNER JOIN
	Lists.SessionEndReasons AS SessionEndReasons
ON
	MemberSessions.EndReasonId = SessionEndReasons.Id
WHERE
	YEAR (MemberSessions.LoginDateTime) = 2014
AND
	MONTH (MemberSessions.LoginDateTime) = 2
AND
	DAY (MemberSessions.LoginDateTime) = 15
ORDER BY
	MemberId		ASC ,
	LoginDateTime	ASC;
GO


-- Rewrite the search argument

SELECT
	MemberId		= Members.Id ,
	MemberFirstName	= Members.FirstName ,
	MemberLastName	= Members.LastName ,
	LoginDateTime	= MemberSessions.LoginDateTime ,
	EndDateTime		= MemberSessions.EndDateTime ,
	EndReason		= SessionEndReasons.Name
FROM
	Operation.Members AS Members
INNER JOIN
	Operation.MemberSessions AS MemberSessions
ON
	Members.Id = MemberSessions.MemberId
INNER JOIN
	Lists.SessionEndReasons AS SessionEndReasons
ON
	MemberSessions.EndReasonId = SessionEndReasons.Id
WHERE
	DATEADD (DAY , DATEDIFF (DAY , '1900-01-01' , MemberSessions.LoginDateTime) , '1900-01-01') = '2014-02-15'
ORDER BY
	MemberId		ASC ,
	LoginDateTime	ASC;
GO


-- Add more predicates and watch the estimated number of rows

SELECT
	MemberId		= Members.Id ,
	MemberFirstName	= Members.FirstName ,
	MemberLastName	= Members.LastName ,
	LoginDateTime	= MemberSessions.LoginDateTime ,
	EndDateTime		= MemberSessions.EndDateTime ,
	EndReason		= SessionEndReasons.Name
FROM
	Operation.Members AS Members
INNER JOIN
	Operation.MemberSessions AS MemberSessions
ON
	Members.Id = MemberSessions.MemberId
INNER JOIN
	Lists.SessionEndReasons AS SessionEndReasons
ON
	MemberSessions.EndReasonId = SessionEndReasons.Id
WHERE
	DATEADD (DAY , DATEDIFF (DAY , '1900-01-01' , MemberSessions.LoginDateTime) , '1900-01-01') = '2014-02-15'
AND
	DATEADD (DAY , DATEDIFF (DAY , '1901-01-01' , MemberSessions.LoginDateTime) , '1901-01-01') = '2014-02-15'
AND
	DATEADD (DAY , DATEDIFF (DAY , '1902-01-01' , MemberSessions.LoginDateTime) , '1902-01-01') = '2014-02-15'
ORDER BY
	MemberId		ASC ,
	LoginDateTime	ASC;
GO


-- Rewrite the search argument again

SELECT
	MemberId		= Members.Id ,
	MemberFirstName	= Members.FirstName ,
	MemberLastName	= Members.LastName ,
	LoginDateTime	= MemberSessions.LoginDateTime ,
	EndDateTime		= MemberSessions.EndDateTime ,
	EndReason		= SessionEndReasons.Name
FROM
	Operation.Members AS Members
INNER JOIN
	Operation.MemberSessions AS MemberSessions
ON
	Members.Id = MemberSessions.MemberId
INNER JOIN
	Lists.SessionEndReasons AS SessionEndReasons
ON
	MemberSessions.EndReasonId = SessionEndReasons.Id
WHERE
	CAST (MemberSessions.LoginDateTime AS DATE) = '2014-02-15'
ORDER BY
	MemberId		ASC ,
	LoginDateTime	ASC;
GO


-- Rewrite the search argument again

SELECT
	MemberId		= Members.Id ,
	MemberFirstName	= Members.FirstName ,
	MemberLastName	= Members.LastName ,
	LoginDateTime	= MemberSessions.LoginDateTime ,
	EndDateTime		= MemberSessions.EndDateTime ,
	EndReason		= SessionEndReasons.Name
FROM
	Operation.Members AS Members
INNER JOIN
	Operation.MemberSessions AS MemberSessions
ON
	Members.Id = MemberSessions.MemberId
INNER JOIN
	Lists.SessionEndReasons AS SessionEndReasons
ON
	MemberSessions.EndReasonId = SessionEndReasons.Id
WHERE
	MemberSessions.LoginDateTime >= '2014-02-15'
AND
	MemberSessions.LoginDateTime < '2014-02-16'
ORDER BY
	MemberId		ASC ,
	LoginDateTime	ASC;
GO
