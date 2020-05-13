USE
	YourAss;
GO


SET STATISTICS IO ON;
GO


EXECUTE Operation.usp_CloseInvitations;
GO


-- Replace the cursors and the inner stored procedure with a single UPDATE statement

UPDATE
	Invitations
SET
	StatusId			=
		CASE Members.GenderId
			WHEN 1	THEN 3	-- Denied
			WHEN 2	THEN 2	-- Accedpted
		END ,
	ResponseDateTime	= SYSDATETIME ()
FROM
	Operation.Invitations AS Invitations
INNER JOIN
	Operation.MemberSessions AS MemberSessions
ON
	Invitations.RequestingSessionId = MemberSessions.Id
INNER JOIN
	Operation.Members AS Members
ON
	MemberSessions.MemberId = Members.Id
WHERE
	MemberSessions.LoginDateTime < DATEADD (YEAR , -2 , SYSDATETIME ())
AND
	Invitations.StatusId = 1;	-- Sent
GO
