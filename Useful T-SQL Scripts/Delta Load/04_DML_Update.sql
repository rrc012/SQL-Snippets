USE Sandbox;
GO

SET NOCOUNT ON;

TRUNCATE TABLE Sandbox.dbo.CompanyPhone;

INSERT INTO Sandbox.dbo.CompanyPhone (CompanyId, Phone)
VALUES (1, '697-555-0142'),
       (2, '819-555-0175'),
       (3, '212-555-0187'),
       (4, '612-555-0100'), --This record will get updated.
       (5, '849-555-0139');

TRUNCATE TABLE Sandbox.dbo.CompanyPhoneRaw;

INSERT INTO Sandbox.dbo.CompanyPhoneRaw (CompanyId, Phone)
VALUES (1, '697-555-0142'),
       (2, '819-555-0175'),
       (3, '212-555-0187'),
       (4, '612-555-0110'), --Data modified in the source.
       (5, '849-555-0139');

/*
EXEC Sandbox.dbo.CompanyPhoneWorkoff;

SELECT * FROM Sandbox.dbo.CompanyPhoneRaw;
SELECT * FROM Sandbox.dbo.CompanyPhone;
--*/