USE Sandbox;
GO

SET QUOTED_IDENTIFIER ON;
GO
SET ANSI_NULLS ON;
GO

/*******************************************************************************************************
*   Sandbox.dbo.CompanyPhoneRaw
*
*   Creator:        Shane Gebs
*   Date:           02/08/2022
*
*   Notes:          Dummy data used for workoff presentation  
*   

	SELECT TOP 1000 *
      FROM Sandbox.dbo.CompanyPhoneRaw WITH (NOLOCK);
 
*   Modifications   
*   Developer Name      Date        Brief description
*   ------------------- ----------- ------------------------------------------------------------
*   
*******************************************************************************************************/
IF OBJECT_ID('dbo.CompanyPhoneRaw', 'U') IS NOT NULL DROP TABLE Sandbox.dbo.CompanyPhoneRaw;

CREATE TABLE dbo.CompanyPhoneRaw
(
 CompanyId INT NOT NULL,
 Phone VARCHAR(12) NOT NULL
);