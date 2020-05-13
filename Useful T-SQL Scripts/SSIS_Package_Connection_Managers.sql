/*
 ===============================================================================
 Author:	     Alan Burstein
 Source:       https://www.sqlservercentral.com/forums/topic/query-msdb-for-ssis-packages-connection-managers
 Article Name: Query MSDB for SSIS Package Connection Managers
 Create Date:  20-NOV-2015
 Description:  This will extract the SSIS data as XML and the XML can be formatted
               to get the connection manager information.
 Revision History:
 10-OCT-2019 - RAGHUNANDAN CUMBAKONAM
               Changed CROSS APPLY to OUTER APPLY
			Formatted the code.
			Added the history.
 Usage:		N/A			   
 ===============================================================================
*/

USE msdb
GO

SET NOCOUNT ON;

;WITH xmlnamespaces ('www.microsoft.com/SqlServer/Dts' AS p1,'www.microsoft.com/SqlServer/Dts' AS DTS),
base
AS
( 
SELECT [name] AS PackageName, 
       ssisxml = CAST(CAST(packagedata AS VARBINARY(MAX)) AS XML) 
  FROM msdb.dbo.sysssispackages
)
SELECT PackageName,
       DTS_ID = n.value('(@DTS:DTSID)[1]','VARCHAR(1000)'), 
       ConnDesc = n.value('(@DTS:Description)[1]','VARCHAR(1000)'),
       RefId = n.value('(@DTS:refId)[1]','VARCHAR(1000)'),
       CreationName = n.value('(@DTS:CreationName)[1]','VARCHAR(100)'), 
       ObjectName = n.value('(@DTS:ObjectName)[1]','VARCHAR(100)'), 
       PropertyExpression = n.value('(DTS:PropertyExpression/text())[1]','VARCHAR(1000)'), 
       PropertyExpression = pe.value('(@DTS:Name)[1]','VARCHAR(1000)') +':  ' + pe.value('(text())[1]','VARCHAR(1000)'), 
       ConnectionString = ISNULL('Retain: ' + n.value('@DTS:Retain','VARCHAR(20)'),'') + n.value ('(DTS:ObjectData/DTS:ConnectionManager/@DTS:ConnectionString)[1]','VARCHAR(2000)') 
  FROM base AS b 
       OUTER APPLY ssisxml.nodes('DTS:Executable/DTS:ConnectionManagers/DTS:ConnectionManager') ssis(n)
       OUTER APPLY n.nodes('DTS:PropertyExpression') p(pe)
 WHERE 1 = 1
   --AND PackageName = ''
 ORDER BY 1;