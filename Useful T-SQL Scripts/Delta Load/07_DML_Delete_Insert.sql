USE Sandbox;
GO

SET NOCOUNT ON;

TRUNCATE TABLE Sandbox.dbo.CompanyPhone;

INSERT INTO Sandbox.dbo.CompanyPhone (CompanyId, Phone)
VALUES (1, '697-555-0142'),
       (2, '819-555-0175'),
       (3, '212-555-0187'), --This record will get deleted.
       (4, '612-555-0100'),
       (5, '849-555-0139');

TRUNCATE TABLE Sandbox.dbo.CompanyPhoneRaw;

INSERT INTO Sandbox.dbo.CompanyPhoneRaw (CompanyId, Phone)
VALUES (1, '697-555-0142'),
       (2, '819-555-0175'),
       (4, '612-555-0100'),
       (5, '849-555-0139'),
       (6, '225-555-0258'); --This record will get inserted.

/*
EXEC Sandbox.dbo.CompanyPhoneWorkoff;

SELECT * FROM Sandbox.dbo.CompanyPhoneRaw;
SELECT * FROM Sandbox.dbo.CompanyPhone;
--*/