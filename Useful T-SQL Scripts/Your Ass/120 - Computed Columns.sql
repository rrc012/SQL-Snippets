USE
	YourAss;
GO


SET STATISTICS IO ON;
GO


SELECT
	MemberId			= Members.Id ,
	MemberFirstName		= Members.FirstName ,
	MemberLastName		= Members.LastName ,
	MemberPhoneNumber	= Members.PhoneNumber
FROM
	Operation.Members AS Members
WHERE
	Members.PhoneNumber LIKE N'%000'
ORDER BY
	MemberId ASC;
GO


-- Create a non-clustered index on the "PhoneNumber" column in the "Operation.Members" table

CREATE NONCLUSTERED INDEX
	ix_MemberSessions_nc_nu_PhoneNumber
ON
	Operation.Members (PhoneNumber ASC);
GO


SELECT
	MemberId			= Members.Id ,
	MemberFirstName		= Members.FirstName ,
	MemberLastName		= Members.LastName ,
	MemberPhoneNumber	= Members.PhoneNumber
FROM
	Operation.Members AS Members
WHERE
	Members.PhoneNumber LIKE N'%000'
ORDER BY
	MemberId ASC;
GO


-- Create a computed column on the reverse of "PhoneNumber"

ALTER TABLE
	Operation.Members
ADD
	ReversePhoneNumber AS REVERSE (PhoneNumber);
GO


SELECT
	MemberId			= Members.Id ,
	MemberFirstName		= Members.FirstName ,
	MemberLastName		= Members.LastName ,
	MemberPhoneNumber	= Members.PhoneNumber
FROM
	Operation.Members AS Members
WHERE
	Members.PhoneNumber LIKE N'%000'
ORDER BY
	MemberId ASC;
GO


-- Rewrite the search argument to use the computed column

SELECT
	MemberId			= Members.Id ,
	MemberFirstName		= Members.FirstName ,
	MemberLastName		= Members.LastName ,
	MemberPhoneNumber	= Members.PhoneNumber
FROM
	Operation.Members AS Members
WHERE
	Members.ReversePhoneNumber LIKE N'000%'
ORDER BY
	MemberId ASC;
GO


-- Make the computed column "ReversePhoneNumber" persisted

ALTER TABLE
	Operation.Members
DROP COLUMN
	ReversePhoneNumber;
GO


ALTER TABLE
	Operation.Members
ADD
	ReversePhoneNumber AS REVERSE (PhoneNumber) PERSISTED;
GO


SELECT
	MemberId			= Members.Id ,
	MemberFirstName		= Members.FirstName ,
	MemberLastName		= Members.LastName ,
	MemberPhoneNumber	= Members.PhoneNumber
FROM
	Operation.Members AS Members
WHERE
	Members.ReversePhoneNumber LIKE N'000%'
ORDER BY
	MemberId ASC;
GO


-- Create a non-clustered index on the "ReversePhoneNumber" column in the "Operation.Members" table

CREATE NONCLUSTERED INDEX
	ix_MemberSessions_nc_nu_ReversePhoneNumber
ON
	Operation.Members (ReversePhoneNumber ASC);
GO


SELECT
	MemberId			= Members.Id ,
	MemberFirstName		= Members.FirstName ,
	MemberLastName		= Members.LastName ,
	MemberPhoneNumber	= Members.PhoneNumber
FROM
	Operation.Members AS Members
WHERE
	Members.ReversePhoneNumber LIKE N'000%'
ORDER BY
	MemberId ASC;
GO
