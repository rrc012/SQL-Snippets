/*
 ===============================================================================
 Author:	     RAGHUNANDAN CUMBAKONAM
 Create Date:  09-APR-2020
 Description:  This query returns the input-output column mapping details inside
               a DFT in a SSIS package and which is deployed on msdb database.
 To Fine Tune:
               1. Try to capture 3 part name for the "Destination" column.
               2. Extend the logic for all kinds of Destination in DFT.
 Revision History:
 
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
       COALESCE(ex.e.value('(./@DTS:Disabled)[1]','VARCHAR(5)'), 'False') AS IsDisabled
  FROM Base AS p
       CROSS APPLY PackageData.nodes('/DTS:Executable/DTS:Executables/DTS:Executable') AS ex(e)
 UNION ALL
SELECT PackageName,
       subex.e.query('.') AS subxml,
       subex.e.value('(./@DTS:Description)[1]','VARCHAR(250)') AS ExecutableType,
       subex.e.value('(./@DTS:ObjectName)[1]','VARCHAR(250)') AS ExecutableName,
       COALESCE(subex.e.value('(./@DTS:Disabled)[1]','VARCHAR(5)'), 'False') AS IsDisabled
  FROM Recurse
       CROSS APPLY subxml.nodes('/DTS:Executable/DTS:Executables/DTS:Executable') AS subex(e)
)
SELECT PackageName,
	  ExecutableName AS DFTName,
	  ComponentName,
       CASE WHEN ComponentType = 'Microsoft.OLEDBSource' THEN OledbSrcCode
            WHEN ComponentType IN ('Microsoft.OLEDBCommand', 'Microsoft.OLEDBDestination') THEN OledbTgtCode
            WHEN ComponentType = 'Microsoft.Lookup' THEN OledbTgtCode
            WHEN ComponentType LIKE '%FlatFile%' THEN FlatFileCode
            ELSE ComponentCode
       END AS DestinationName,
       InputColumn,
       OutputColumn
  FROM recurse
       --Navigate to Data Flow Task
       OUTER APPLY subxml.nodes('/DTS:Executable/DTS:ObjectData/pipeline/components/component') AS subex(e)
       --Navigate to Oledb inside Data Flow Task
       OUTER APPLY subex.e.nodes('./properties') AS oledb(e)
       --Navigate to Oledb Destination inside Data Flow Task
       OUTER APPLY subex.e.nodes('./inputs/input/inputColumns/inputColumn') AS oledbdst(e)
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
       --Parse OLEDB Destination Input-Output Mappings
       CROSS APPLY (SELECT --Extract the value of the Attribute; The input column for OLEDB Destination
                           oledbdst.e.value('(./@cachedName)[1]','VARCHAR(100)') AS InputColumn,
                           --Extract the value of the Attribute; The output column for OLEDB Destination
                           REVERSE(oledbdst.e.value('(./@externalMetadataColumnId)[1]','VARCHAR(1000)')) AS ExternalColumn
                   ) AS SrcTgtMapping
       /*
       Extract the Output Column from the External Column obtained in the above step.
	  The External Column obtained is of the format
       ===============================================================================================================================================================================
       Package\Foreach Loop Container - AllocationCycleId For InvestorAllocation\Load pre-stage to Stage\OLE DB Destination.Inputs[OLE DB Destination Input].ExternalColumns[AuditKey]
       ===============================================================================================================================================================================
       */
       CROSS APPLY (SELECT REVERSE(SUBSTRING(ExternalColumn, 2, CHARINDEX('[', ExternalColumn)-2)) AS OutputColumn) AS CA
 WHERE 1 = 1
   AND PackageName = ''
   AND ExecutableName = ''
   AND IsDisabled = 'False'
   AND ExecutableType = 'Data Flow Task'
   AND ComponentType LIKE '%Destination'
 ORDER BY PackageName, ExecutableName, ComponentName;