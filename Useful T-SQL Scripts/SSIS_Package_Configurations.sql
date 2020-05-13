/*
 ===============================================================================
 Author:	    RAGHUNANDAN CUMBAKONAM
 Reference:   http://sqlblog.com/blogs/peter_debetta/archive/2006/07/13/Using-XML-Data-Type-Methods-to-query-SSIS-Packages.aspx
 Create Date: 19-MAR-2014
 Description: This query returns the configurations used inside a SSIS package
              and which is deployed on msdb database. This is applicable only
              for "Package Mode" deployment.
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
       PackageData = CAST(CAST(packagedata AS VARBINARY(MAX)) AS XML) 
  FROM msdb.dbo.sysssispackages
)
SELECT PackageName,
       ConfigurationType,
       CASE CAST(ConfigurationType AS INT)
            WHEN 0 THEN 'Parent Package'
            WHEN 1 THEN 'XML File'
            WHEN 2 THEN 'Environmental Variable'
            WHEN 3 THEN 'Registry Entry'
            WHEN 4 THEN 'Parent Package via Environmental Variable'
            WHEN 5 THEN 'XML File via Environmental Variable'
            WHEN 6 THEN 'Registry Entry via Environmental Variable'
            WHEN 7 THEN 'SQL Server'
       END AS ConfigurationTypeDesc,
       V.Vars.value('(./@DTS:ConfigurationVariable)[1]', 'varchar(100)') AS ConfigurationVariable,
       V.Vars.value('(./@DTS:ObjectName)[1]', 'varchar(100)') AS ConfigurationName,
       V.Vars.value('(./@DTS:ConfigurationString)[1]', 'varchar(100)') AS ConfigurationString
  FROM Base
       CROSS APPLY Base.PackageData.nodes('/DTS:Executable/DTS:Configurations/DTS:Configuration') AS V(Vars)
       CROSS APPLY (SELECT V.Vars.value('(./@DTS:ConfigurationType)[1]', 'varchar(100)') AS ConfigurationType) AS CT