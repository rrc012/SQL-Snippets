USE Sandbox;
GO

SET NOCOUNT ON;

TRUNCATE TABLE Sandbox.dbo.CompanyPhone;

INSERT INTO Sandbox.dbo.CompanyPhone (CompanyId, Phone)
VALUES (7,  '497-555-0142'),
       (8,  '419-555-0175'),
       (9,  '412-555-0187'), --This record will get deleted.
       (10, '412-555-0100'), --This record will get updated.
       (11, '449-555-0139');

TRUNCATE TABLE Sandbox.dbo.CompanyPhoneRaw;

INSERT INTO Sandbox.dbo.CompanyPhoneRaw (CompanyId, Phone)
VALUES (7,  '797-555-0142'),
       (8,  '719-555-0175'),
       (10, '712-555-0110'), --Data modified in the source.
       (11, '749-555-0139'),
       (12, '725-555-0258'); --This record will get inserted.

/*
EXEC Sandbox.dbo.CompanyPhoneWorkoff @OverrideSizeCheck = 1;

SELECT * FROM Sandbox.dbo.CompanyPhoneRaw;
SELECT * FROM Sandbox.dbo.CompanyPhone;
--*/