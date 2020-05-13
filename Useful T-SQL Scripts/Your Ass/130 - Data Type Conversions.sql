USE
	YourAss;
GO


SET STATISTICS IO ON;
GO


SELECT
	MemberId			= Members.Id ,
	MemberFirstName		= Members.FirstName ,
	MemberLastName		= Members.LastName ,
	PaymentAmount		= Payments.Amount ,
	PaymentDateTime		= Payments.DateAndTime
FROM
	Operation.Members AS Members
INNER JOIN
	Billing.Payments AS Payments
ON
	Members.Id = Payments.MemberId
WHERE
	Members.RegistrationDateTime >= '2012-01-01'
AND
	Members.RegistrationDateTime < '2012-01-02'
AND
	Payments.Amount <= 10.00
ORDER BY
	MemberId		ASC ,
	PaymentDateTime	ASC;
GO


-- Create a non-clustered index on the "MemberId" column in the "Billing.Payments" table

CREATE NONCLUSTERED INDEX
	ix_Payments_nc_nu_MemberId
ON
	Billing.Payments (MemberId ASC);
GO


SELECT
	MemberId			= Members.Id ,
	MemberFirstName		= Members.FirstName ,
	MemberLastName		= Members.LastName ,
	PaymentAmount		= Payments.Amount ,
	PaymentDateTime		= Payments.DateAndTime
FROM
	Operation.Members AS Members
INNER JOIN
	Billing.Payments AS Payments
ON
	Members.Id = Payments.MemberId
WHERE
	Members.RegistrationDateTime >= '2012-01-01'
AND
	Members.RegistrationDateTime < '2012-01-02'
AND
	Payments.Amount <= 10.00
ORDER BY
	MemberId		ASC ,
	PaymentDateTime	ASC;
GO


-- Force the optimizer to use the "ix_Payments_nc_nu_MemberId" index

SELECT
	MemberId			= Members.Id ,
	MemberFirstName		= Members.FirstName ,
	MemberLastName		= Members.LastName ,
	PaymentAmount		= Payments.Amount ,
	PaymentDateTime		= Payments.DateAndTime
FROM
	Operation.Members AS Members
INNER JOIN
	Billing.Payments AS Payments WITH (INDEX = ix_Payments_nc_nu_MemberId)
ON
	Members.Id = Payments.MemberId
WHERE
	Members.RegistrationDateTime >= '2012-01-01'
AND
	Members.RegistrationDateTime < '2012-01-02'
AND
	Payments.Amount <= 10.00
ORDER BY
	MemberId		ASC ,
	PaymentDateTime	ASC;
GO


-- Explicitly convert the values in the "Id" column in the "Operation.Members" table to NVARCHAR(20)

SELECT
	MemberId			= Members.Id ,
	MemberFirstName		= Members.FirstName ,
	MemberLastName		= Members.LastName ,
	PaymentAmount		= Payments.Amount ,
	PaymentDateTime		= Payments.DateAndTime
FROM
	Operation.Members AS Members
INNER JOIN
	Billing.Payments AS Payments
ON
	CAST (Members.Id AS NVARCHAR(20)) = Payments.MemberId
WHERE
	Members.RegistrationDateTime >= '2012-01-01'
AND
	Members.RegistrationDateTime < '2012-01-02'
AND
	Payments.Amount <= 10.00
ORDER BY
	MemberId		ASC ,
	PaymentDateTime	ASC;
GO


-- Check the execution plan of the following query

SELECT
	Id ,
	MemberId ,
	Amount ,
	DateAndTime
FROM
	Billing.Payments
WHERE
	MemberId = 54321;
GO


-- Check the execution plan of the following query

SELECT
	Id ,
	MemberId ,
	Amount ,
	DateAndTime
FROM
	Billing.Payments
WHERE
	MemberId = N'54321';
GO
