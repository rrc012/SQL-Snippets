/*
 ===============================================================================
 Author:	     Unknown
 Source:       https://blueskybi.wordpress.com/2014/03/18/querying-ssis-packages-from-sql/
 Article Name: Querying SSIS Packages from SQL
 Create Date:  18-MAR-2014
 Description:  This query returns the list of Executable details used inside a SSIS package
               and which is deployed on msdb database.
 Revision History:
 15-MAR-2020 - RAGHUNANDAN CUMBAKONAM
               Added logic to check if a Control Flow Task is Enabled/Disabled.
               Added logic to derive the code inside the Executables (Control Flow).
               Added logic to derive the code inside the Components (Data Flow).
               Formatted the code.
               Added the history.
 Usage:		N/A			   
 ===============================================================================
*/

USE msdb
GO

SET NOCOUNT ON;

;WITH xmlnamespaces 
('www.microsoft.com/SqlServer/Dts' AS DTS, 'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS SQLTask),
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
       ex.e.value('(./@DTS:refId)[1]','VARCHAR(1000)') AS Hierarchy,
       COALESCE(ex.e.value('(./@DTS:Disabled)[1]','VARCHAR(5)'), 'False') AS IsDisabled,
	  0 AS ExecutableLevel
  FROM Base AS p
       CROSS APPLY PackageData.nodes('/DTS:Executable/DTS:Executables/DTS:Executable') AS ex(e)
 UNION ALL
SELECT PackageName,
       subex.e.query('.') AS subxml,
       subex.e.value('(./@DTS:Description)[1]','VARCHAR(250)') AS ExecutableType,
       subex.e.value('(./@DTS:ObjectName)[1]','VARCHAR(250)') AS ExecutableName,
       subex.e.value('(./@DTS:refId)[1]','VARCHAR(1000)') AS Hierarchy,
       COALESCE(subex.e.value('(./@DTS:Disabled)[1]','VARCHAR(5)'), 'False') AS IsDisabled,
	  ExecutableLevel + 1
  FROM Recurse
       CROSS APPLY subxml.nodes('/DTS:Executable/DTS:Executables/DTS:Executable') AS subex(e)
)
SELECT PackageName,
	  ExecutableLevel,
       ExecutableType,
       IsDisabled,
	  ExecutableName,
	  ComponentType,
       ComponentName,
       Hierarchy,
       IIF(ComponentType > '', --Component Type is NULL for Control Flow Tasks
           --Fetch the code inside the components in a Data Flow Task
           CASE WHEN ComponentType = 'Microsoft.OLEDBSource' THEN OledbSrcCode
                WHEN ComponentType IN ('Microsoft.OLEDBCommand', 'Microsoft.OLEDBDestination') THEN OledbTgtCode
                WHEN ComponentType = 'Microsoft.Lookup' THEN OledbTgtCode
                WHEN ComponentType LIKE '%FlatFile%' THEN FlatFileCode
                ELSE ComponentCode
           END,
           CASE ExecutableType --For Control Flow Executables like Exec SQL Task/Script Task, fetch the corresponding code
                WHEN 'Execute Package Task' THEN pkg.code.value('PackageName[1]','VARCHAR(100)')
                WHEN 'Execute SQL Task' THEN exe.code.value('(./@SQLTask:SqlStatementSource)[1]','VARCHAR(MAX)')
                WHEN 'Script Task' THEN scr.code.value('ProjectItem[4]','VARCHAR(MAX)')
           END
          ) AS Code
  FROM recurse
       --Navigate to Exec Pkg Task
       OUTER APPLY subxml.nodes('/DTS:Executable/DTS:ObjectData/ExecutePackageTask') AS pkg(code)
       --Navigate to Exec SQL Task
       OUTER APPLY subxml.nodes('/DTS:Executable/DTS:ObjectData/SQLTask:SqlTaskData') AS exe(code)
       --Navigate to Script Task
       OUTER APPLY subxml.nodes('/DTS:Executable/DTS:ObjectData/ScriptProject') AS scr(code)
       --Navigate to Data Flow Task
       OUTER APPLY subxml.nodes('/DTS:Executable/DTS:ObjectData/pipeline/components/component') AS subex(e)
       --Navigate to Oledb inside Data Flow Task
       OUTER APPLY subex.e.nodes('./properties') AS oledb(e)
       --Parse Data Flow Task Components
       CROSS APPLY (SELECT --Extract the value of the Attribute
                           subex.e.value('(./@name)[1]','VARCHAR(250)') AS ComponentName,
                           --Extract the value of the Attribute
                           subex.e.value('(./@componentClassID)[1]','VARCHAR(250)') AS ComponentType,
                           --Extract the value of the Element
                           subex.e.value('properties[1]','VARCHAR(MAX)') AS ComponentCode,
                           --Extract the value of the Element for OLEDB Source
                           oledb.e.value('property[4]','VARCHAR(MAX)') AS OledbSrcCode,
                           --Extract the value of the Element for OLEDB Command & Destination
                           oledb.e.value('property[2]','VARCHAR(100)') AS OledbTgtCode,
                           --Extract the value of the Attribute for Flat File Source & Destination
                           subex.e.value('(./connections/connection/@connectionManagerID)[1]','VARCHAR(250)') AS FlatFileCode
                   ) AS SubComponents
 WHERE 1 = 1
   AND PackageName = ''
   --AND IsDisabled = 'False'
   --AND ExecutableType = ''
   --AND ComponentType = ''
 ORDER BY PackageName, ExecutableLevel, ExecutableType, ExecutableName, ComponentName;