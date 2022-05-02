USE Sandbox;
GO

SET QUOTED_IDENTIFIER ON;
GO
SET ANSI_NULLS ON;
GO

/*******************************************************************************************************
*   Sandbox.dbo.CompanyPhone
*
*   Creator:        Shane Gebs
*   Date:           02/08/2022
*
*   Notes:          Dummy data used for workoff presentation  
*   

	SELECT TOP 1000 *
      FROM Sandbox.dbo.CompanyPhone with (nolock);
 
*   Modifications   
*   Developer Name      Date        Brief description
*   ------------------- ----------- ------------------------------------------------------------
*   
*******************************************************************************************************/
IF OBJECT_ID('dbo.CompanyPhone', 'U') IS NULL
BEGIN
     CREATE TABLE dbo.CompanyPhone
     (
      CompanyId INT NOT NULL,
      Phone VARCHAR(12) NOT NULL,
      InsertDate SMALLDATETIME NOT NULL CONSTRAINT DF__CompanyPhone__InsertDate DEFAULT GETDATE(),
      UpdateDate SMALLDATETIME NULL
     );
END;

/* all tables should have a unique clustered index, probably implemented as a clustered primary key */
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE [name] = 'PKC__CompanyPhone__CompanyId' AND parent_object_id = object_id('dbo.CompanyPhone', 'U'))
BEGIN
     ALTER TABLE [dbo].[CompanyPhone] ADD CONSTRAINT [PKC__CompanyPhone__CompanyId] PRIMARY KEY CLUSTERED 
     (
     	[CompanyId] ASC
     )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY];
END;