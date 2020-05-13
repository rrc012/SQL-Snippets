USE msdb
GO

SET NOCOUNT ON;

DECLARE @ssisPkg SYSNAME = 'SSIS_DSS_FINANCE_EDW_To_Stg_Data_Load',
        @execName VARCHAR(100) = 'DFT_LU_Contract_Earning_Cycle';

IF OBJECT_ID('tempdb..#DFT_Info', 'U') IS NOT NULL DROP TABLE #DFT_Info;
CREATE TABLE #DFT_Info
(
 PackageName     VARCHAR(100)  NOT NULL,
 PackageData     XML           NULL,
 Subxml          XML           NULL,
 ExecutableType  VARCHAR(100)  NOT NULL,
 ExecutableName  VARCHAR(100)  NOT NULL,
 Hierarchy       VARCHAR(1000) NOT NULL,
 IsDisabled      VARCHAR(5)    NOT NULL
);

IF OBJECT_ID('tempdb..#Column_Mapping', 'U') IS NOT NULL DROP TABLE #Column_Mapping;
CREATE TABLE #Column_Mapping
(
 PackageName     VARCHAR(100)  NOT NULL,
 ExecutableType  VARCHAR(100)  NOT NULL,
 ExecutableName  VARCHAR(100)  NOT NULL,
 IsDisabled      VARCHAR(5)    NOT NULL,
 ComponentType   VARCHAR(100)  NOT NULL,
 ComponentName   VARCHAR(100)  NOT NULL,
 Hierarchy       VARCHAR(1000) NOT NULL,
 InputColumn     VARCHAR(100)  NULL,
 OutputColumn    VARCHAR(100)  NOT NULL
);

;WITH xmlnamespaces 
('www.microsoft.com/SqlServer/Dts' AS DTS, 'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS SQLTask),
Base
AS
(
SELECT [name] AS PackageName, 
       PackageData = CAST(CAST(packagedata AS VARBINARY(MAX)) AS XML) 
  FROM msdb.dbo.sysssispackages
 WHERE [name] = @ssisPkg
),
Recurse
AS
(
SELECT PackageName,
       PackageData,
       ex.e.query('.') AS subxml,
       ex.e.value('(./@DTS:Description)[1]','VARCHAR(100)') AS ExecutableType,
       ex.e.value('(./@DTS:ObjectName)[1]','VARCHAR(100)') AS ExecutableName,
       ex.e.value('(./@DTS:refId)[1]','VARCHAR(1000)') AS Hierarchy,
       COALESCE(ex.e.value('(./@DTS:Disabled)[1]','VARCHAR(5)'), 'False') AS IsDisabled
  FROM Base AS p
       CROSS APPLY PackageData.nodes('/DTS:Executable/DTS:Executables/DTS:Executable') AS ex(e)
 UNION ALL
SELECT PackageName,
       PackageData,
       subex.e.query('.') AS subxml,
       subex.e.value('(./@DTS:Description)[1]','VARCHAR(100)') AS ExecutableType,
       subex.e.value('(./@DTS:ObjectName)[1]','VARCHAR(100)') AS ExecutableName,
       subex.e.value('(./@DTS:refId)[1]','VARCHAR(1000)') AS Hierarchy,
       COALESCE(subex.e.value('(./@DTS:Disabled)[1]','VARCHAR(5)'), 'False') AS IsDisabled
  FROM Recurse
       CROSS APPLY subxml.nodes('/DTS:Executable/DTS:Executables/DTS:Executable') AS subex(e)
)
INSERT INTO #DFT_Info
SELECT PackageName,
       PackageData,
       Subxml,
       ExecutableType,      
       ExecutableName,
       Hierarchy,
       IsDisabled
  FROM recurse;

--SELECT * FROM #DFT_Info WITH (NOLOCK);

/*************
 OLEDB SOURCE
*************/
;WITH xmlnamespaces 
('www.microsoft.com/SqlServer/Dts' AS DTS, 'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS SQLTask)
SELECT PackageName,
       ExecutableType,
	  ExecutableName,
       IsDisabled,
	  ComponentType,
       ComponentName,
       Hierarchy,
       OutputColumn,
       CONCAT(DataType, ColumnLength) AS DataType
  FROM #DFT_Info
       OUTER APPLY subxml.nodes('/DTS:Executable/DTS:ObjectData/pipeline/components/component') AS subex(e)
       --Navigate to the DFT to extract the Source Column Info
       OUTER APPLY subex.e.nodes('./outputs/output/externalMetadataColumns/externalMetadataColumn') AS col(e)
       --Parse OLEDB/Other Source Components inside Data Flow Task Components
       CROSS APPLY (SELECT --Extract the value of the Attribute
                           subex.e.value('(./@name)[1]','VARCHAR(100)') AS ComponentName,
                           --Extract the value of the Attribute
                           subex.e.value('(./@componentClassID)[1]','VARCHAR(100)') AS ComponentType,
                           --Extract the value of the Attribute
                           col.e.value('(./@name)[1]','VARCHAR(100)') AS OutputColumn,
                           --Extract the value of the Attribute
                           col.e.value('(./@dataType)[1]','VARCHAR(100)') AS DataType,
                           --Extract the value of the Attribute
                           '(' + col.e.value('(./@length)[1]','VARCHAR(100)') + ')' AS ColumnLength
                   ) AS SubComponents
 WHERE 1 = 1
   AND IsDisabled = 'False'
   AND ExecutableType = 'Data Flow Task'
   AND ComponentType LIKE '%Source'
   AND ExecutableName = @execName
   --AND ComponentName = 'Add columns for Logging error records'
 ORDER BY PackageName, ExecutableType, ExecutableName, ComponentName;

/***************
 DERIVED COLUMN
***************/
;WITH xmlnamespaces 
('www.microsoft.com/SqlServer/Dts' AS DTS, 'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS SQLTask)
SELECT PackageName,
       ExecutableType,
	  ExecutableName,
       IsDisabled,
	  ComponentType,
       ComponentName,
       Hierarchy,
       DerivedColumn,
       DataType,
       Expression
  FROM #DFT_Info
       OUTER APPLY subxml.nodes('/DTS:Executable/DTS:ObjectData/pipeline/components/component') AS subex(e)
       --Navigate inside Derived Column to extract the Column Name
       OUTER APPLY subex.e.nodes('./outputs/output/outputColumns/outputColumn') AS derc(e)
       --Navigate inside Derived Column to extract the Expression
       CROSS APPLY derc.e.nodes('./properties') AS dere(e)
       --Parse Derived Column from Data Flow Task Components
       CROSS APPLY (SELECT --Extract the value of the Attribute
                           subex.e.value('(./@name)[1]','VARCHAR(100)') AS ComponentName,
                           --Extract the value of the Attribute
                           subex.e.value('(./@componentClassID)[1]','VARCHAR(100)') AS ComponentType,
                           --Extract the value of the Attribute
                           derc.e.value('(./@name)[1]','VARCHAR(100)') AS DerivedColumn,
                           --Extract the value of the Attribute
                           derc.e.value('(./@dataType)[1]','VARCHAR(100)') AS DataType,
                           --Extract the value of the Element
                           dere.e.value('property[1]','VARCHAR(MAX)') AS Expression
                   ) AS SubComponents
 WHERE 1 = 1
   AND IsDisabled = 'False'
   AND ComponentType = 'Microsoft.DerivedColumn'
   AND ExecutableName = @execName
   --AND ComponentName = 'Add columns for Logging error records'
 ORDER BY PackageName, ExecutableType, ExecutableName, ComponentName;

/******************
 OLEDB DESTINATION
******************/
--Extract Columns that are Mapped
;WITH xmlnamespaces 
('www.microsoft.com/SqlServer/Dts' AS DTS, 'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS SQLTask)
INSERT INTO #Column_Mapping(PackageName, ExecutableType, ExecutableName, IsDisabled, ComponentType, ComponentName, Hierarchy, InputColumn, OutputColumn)
SELECT PackageName,
       ExecutableType,
	  ExecutableName,
       IsDisabled,
	  ComponentType,
       ComponentName,
       Hierarchy,
       InputColumn,
       OutputColumn
  FROM #DFT_Info
       OUTER APPLY subxml.nodes('/DTS:Executable/DTS:ObjectData/pipeline/components/component') AS subex(e)
       --Navigate to the OLEDB Destination iniside the DFT to extract the Source-Destination Column Mapping
       OUTER APPLY subex.e.nodes('./inputs/input/inputColumns/inputColumn') AS oledb(e)
       --Parse OLEDB/Other Destination Components inside Data Flow Task Components
       CROSS APPLY (SELECT --Extract the value of the Attribute
                           subex.e.value('(./@name)[1]','VARCHAR(100)') AS ComponentName,
                           --Extract the value of the Attribute
                           subex.e.value('(./@componentClassID)[1]','VARCHAR(100)') AS ComponentType,
                           --Extract the value of the Attribute
                           REVERSE(oledb.e.value('(./@refId)[1]','VARCHAR(1000)')) AS RefId,
                           --Extract the value of the Attribute
                           REVERSE(oledb.e.value('(./@externalMetadataColumnId)[1]','VARCHAR(1000)')) AS ExternalMetadataColumnId
                   ) AS SubComponents
       --Format the Input & Output Clumns obtained from the above CROSS APPLY step
       CROSS APPLY (SELECT --Format & Extract the name of the Input Column
                           REVERSE(SUBSTRING(RefId, 2, CHARINDEX('[', RefId)-2)) AS InputColumn,
                           --Format & Extract the name of the Output Column
                           REVERSE(SUBSTRING(ExternalMetadataColumnId, 2, CHARINDEX('[', ExternalMetadataColumnId)-2)) AS OutputColumn
                   ) AS ColumnMapping
 WHERE 1 = 1
   AND IsDisabled = 'False'
   AND ExecutableType = 'Data Flow Task'
   AND ComponentType LIKE '%Destination'
   AND ExecutableName = @execName
   --AND ComponentName = 'Add columns for Logging error records'

--Extract Columns that are Unmapped
;WITH xmlnamespaces 
('www.microsoft.com/SqlServer/Dts' AS DTS, 'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS SQLTask)
INSERT INTO #Column_Mapping(PackageName, ExecutableType, ExecutableName, IsDisabled, ComponentType, ComponentName, Hierarchy, InputColumn, OutputColumn)
SELECT Src.PackageName,
       Src.ExecutableType,
	  Src.ExecutableName,
       Src.IsDisabled,
	  SubComponents.ComponentType,
       SubComponents.ComponentName,
       Src.Hierarchy,
       NULL AS InputColumn,
       UnmappedColumn
  FROM #DFT_Info AS Src
       OUTER APPLY subxml.nodes('/DTS:Executable/DTS:ObjectData/pipeline/components/component') AS subex(e)
       --Navigate to the OLEDB Destination iniside the DFT to extract the Source-Destination Column Mapping
       OUTER APPLY subex.e.nodes('./inputs/input/externalMetadataColumns/externalMetadataColumn') AS oledb(e)
       --Parse OLEDB/Other Destination Components inside Data Flow Task Components
       CROSS APPLY (SELECT --Extract the value of the Attribute
                           subex.e.value('(./@name)[1]','VARCHAR(100)') AS ComponentName,
                           --Extract the value of the Attribute
                           subex.e.value('(./@componentClassID)[1]','VARCHAR(100)') AS ComponentType,
                           --Extract the value of the Attribute
                           REVERSE(oledb.e.value('(./@refId)[1]','VARCHAR(1000)')) AS RefId,
                           --Extract the value of the Attribute
                           oledb.e.value('(./@name)[1]','VARCHAR(100)') AS UnmappedColumn
                   ) AS SubComponents
 WHERE 1 = 1
   AND NOT EXISTS (SELECT 1 FROM #Column_Mapping AS Tgt WHERE Src.Hierarchy = Tgt.Hierarchy AND UnmappedColumn = Tgt.OutputColumn)
   AND Src.IsDisabled = 'False'
   AND Src.ExecutableType = 'Data Flow Task'
   AND SubComponents.ComponentType LIKE '%Destination'
   AND ExecutableName = @execName
   --AND ComponentName = 'Add columns for Logging error records'

SELECT * FROM #Column_Mapping ORDER BY Hierarchy, ComponentName;