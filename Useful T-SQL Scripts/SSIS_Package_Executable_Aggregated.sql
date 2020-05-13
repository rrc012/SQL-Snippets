/*
 ===============================================================================
 Author:	     Unknown
 Source:       https://blueskybi.wordpress.com/2014/03/18/querying-ssis-packages-from-sql/
 Article Name: Querying SSIS Packages from SQL
 Create Date:  18-MAR-2014
 Description:  This query returns the list of Executables used inside a SSIS package
               and which is deployed on msdb database.
 Revision History:
 15-MAR-2020 - RAGHUNANDAN CUMBAKONAM
               Changed CROSS APPLY to OUTER APPLY
			Formatted the code.
			Added the history.
 Usage:		N/A			   
 ===============================================================================
*/

USE msdb
GO

SET NOCOUNT ON;

;WITH xmlnamespaces ('www.microsoft.com/SqlServer/Dts' AS DTS),
Base
AS
(
SELECT [name] AS PackageName, 
       packagedata = CAST(CAST(packagedata AS VARBINARY(MAX)) AS XML) 
  FROM msdb.dbo.sysssispackages
),
Recurse
AS
(
SELECT PackageName,
       ex.e.query('.') AS subxml,
       ex.e.value('(./@DTS:Description)[1]','VARCHAR(250)') AS ExecutableType,
       ex.e.value('(./@DTS:ObjectName)[1]','VARCHAR(250)') AS ExecutableName,
       COALESCE(ex.e.value('(./@DTS:Disabled)[1]','VARCHAR(5)'), 'False') AS IsDisabled,
	  0 AS ExecutableLevel
  FROM Base AS p
       CROSS APPLY PackageData.nodes('/DTS:Executable/DTS:Executables/DTS:Executable') AS ex(e)
 UNION ALL
SELECT PackageName,
       subex.e.query('.') AS subxml,
       subex.e.value('(./@DTS:Description)[1]','VARCHAR(250)') AS ExecutableType,
       subex.e.value('(./@DTS:ObjectName)[1]','VARCHAR(250)') AS ExecutableName,
       COALESCE(subex.e.value('(./@DTS:Disabled)[1]','VARCHAR(5)'), 'False') AS IsDisabled,
	  ExecutableLevel + 1
  FROM Recurse
       CROSS APPLY subxml.nodes('/DTS:Executable/DTS:Executables/DTS:Executable') AS subex(e)
)
SELECT PackageName,
	  ExecutableLevel,
       ExecutableType,
       IsDisabled,
       COUNT(*) AS ExecutableCount
  FROM recurse
 WHERE 1 = 1
   AND PackageName = ''
   --AND IsDisabled = 'False'
 GROUP BY PackageName, ExecutableLevel, ExecutableType, IsDisabled
 ORDER BY PackageName, ExecutableLevel, ExecutableType;