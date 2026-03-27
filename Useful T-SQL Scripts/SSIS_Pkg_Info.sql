SET NOCOUNT ON;

/*
CREATE TABLE dbo.SSIS_Packages
(
    PackageID  INT IDENTITY(1,1) PRIMARY KEY,
    FileName   NVARCHAR(500),
    PackageXML XML,
    LoadDate   DATETIME DEFAULT GETDATE()
);

CREATE PRIMARY XML INDEX IX_SSIS_PackageXML ON dbo.SSIS_Packages (PackageXML);
--*/

/********************
 SEARCH FOR A STRING
********************/
;WITH XMLNAMESPACES 
('www.microsoft.com/SqlServer/Dts' AS DTS)
SELECT *
  FROM dbo.SSIS_Packages
 WHERE 1 = 1
   --AND [FileName] = 'ABC.dtsx'
   --AND PackageXML.exist('//*[contains(text()[1], "SomeText")]') = 1
 ORDER BY [Filename];

/*****************************
 GET PACKAGE LEVEL PROPERTIES
*****************************/
;WITH xmlnamespaces 
('www.microsoft.com/SqlServer/Dts' AS DTS),
Base
AS
(
SELECT [FileName], 
       PackageXML as packagedata
  FROM dbo.SSIS_Packages
)
SELECT p.[FileName],
       -- Core Package Properties
       ex.e.[value]('@DTS:ObjectName','nvarchar(255)')          AS [PackageName],
       ex.e.[value]('@DTS:DTSID','nvarchar(255)')               AS [PackageID],
       ex.e.[value]('@DTS:CreationDate','datetime')             AS CreationDate,
       ex.e.[value]('@DTS:CreatorName','nvarchar(255)')         AS CreatorName,
       ex.e.[value]('@DTS:CreatorComputerName','nvarchar(255)') AS CreatorComputerName,
       ex.e.[value]('@DTS:VersionBuild','int')                  AS VersionBuild,
       ex.e.[value]('@DTS:VersionGUID','uniqueidentifier')      AS VersionGUID,
       -- DelayValidation
       ex.e.[value]('@DTS:DelayValidation','nvarchar(10)')      AS DelayValidation,
       -- Transactions
       -- Default values are NOT stored; Only modified properties are serialized
       ISNULL(ex.e.[value]('@DTS:IsolationLevel','nvarchar(50)'), 'Serializable') AS IsolationLevel,
       ISNULL(ex.e.[value]('@DTS:TransactionOption','nvarchar(50)'), 'Supported') AS TransactionOption,
       -- Protection Level (mapped)
       CASE ISNULL(ex.e.[value]('@DTS:ProtectionLevel','int'),1)
            WHEN 0 THEN 'DontSaveSensitive'
            WHEN 1 THEN 'EncryptSensitiveWithUserKey'
            WHEN 2 THEN 'EncryptSensitiveWithPassword'
            WHEN 3 THEN 'EncryptAllWithPassword'
            WHEN 4 THEN 'EncryptAllWithUserKey'
            WHEN 5 THEN 'ServerStorage'
            ELSE 'Unknown'
        END AS ProtectionLevel
  FROM Base p
 CROSS APPLY PackageData.nodes('/DTS:Executable') AS ex(e)
 ORDER BY p.[FileName];

/****************************
 GET PACKAGE PARAMETERS INFO
****************************/
;WITH xmlnamespaces 
('www.microsoft.com/SqlServer/Dts' AS DTS),
Base
AS
(
SELECT [FileName] AS PackageName, 
       PackageXML as packagedata
  FROM dbo.SSIS_Packages
)
SELECT p.PackageName,
       ex.e.[value]('@DTS:ObjectName','varchar(200)') AS ParameterName,
       ex.e.[value]('@DTS:Required','varchar(10)') AS IsRequired,
       ex.e.[value]('@DTS:Sensitive','varchar(10)') AS IsSensitive,
       ex.e.[value]('(DTS:Property[@DTS:Name="ParameterValue"]/text())[1]','varchar(max)') AS ParameterValue,
       CASE ex.e.[value]('@DTS:DataType','int')
            WHEN 2  THEN 'Int16'
            WHEN 3  THEN 'Int32'
            WHEN 4  THEN 'Single'
            WHEN 5  THEN 'Double'
            WHEN 7  THEN 'DateTime'
            WHEN 8  THEN 'String'
            WHEN 11 THEN 'Boolean'
            WHEN 14 THEN 'Decimal'
            WHEN 20 THEN 'Int64'
            ELSE 'Other'
        END AS DataType
  FROM Base AS p
       CROSS APPLY PackageData.nodes('/DTS:Executable/DTS:PackageParameters/DTS:PackageParameter') AS ex(e)
 WHERE 1 = 1
   --AND PackageName = 'ABC.dtsx'
 ORDER BY PackageName, DataType, ParameterName;

/*******************
 GET VARIABLES INFO
*******************/
;WITH xmlnamespaces 
('www.microsoft.com/SqlServer/Dts' AS DTS),
Base
AS
(
SELECT [FileName] AS PackageName, 
       PackageXML as packagedata
  FROM dbo.SSIS_Packages
)
-- Extract variables from each scope
SELECT p.PackageName,
       ex.e.[value]('(./@DTS:Namespace)[1]','VARCHAR(100)') AS [Namespace],
       ex.e.[value]('(./@DTS:ObjectName)[1]','VARCHAR(100)') AS VariableName,
	   CASE CADT.DataType
            WHEN 0  THEN 'DBNull'
            WHEN 2  THEN 'Int16'
            WHEN 3  THEN 'Int32'
            WHEN 4  THEN 'Single'
            WHEN 5  THEN 'Double'
            WHEN 7  THEN 'DateTime'
            WHEN 8  THEN 'String'
            WHEN 11 THEN 'Boolean'
            WHEN 13 THEN 'Object'
            WHEN 14 THEN 'Decimal'
            WHEN 16 THEN 'Sbyte'
            WHEN 17 THEN 'Byte'
            WHEN 18 THEN 'Char'
            WHEN 19 THEN 'UInt32'
            WHEN 20 THEN 'Int64'
            WHEN 21 THEN 'UInt64'
            ELSE CONCAT(DataType, ' - Google "DTS:DataType ', DataType, '" for the corresponding DataType')    
        END AS DataType,
       ex.e.[value]('DTS:VariableValue[1]','VARCHAR(100)') AS VariableValue,
       ex.e.[value]('@DTS:Expression', 'varchar(max)') AS VariableExpression,        
       ex.e.[value]('@DTS:EvaluateAsExpression', 'varchar(10)') AS EvaluateAsExpression
  FROM Base AS p
       CROSS APPLY PackageData.nodes('/DTS:Executable/DTS:Variables/DTS:Variable') AS ex(e)
       CROSS APPLY (SELECT ex.e.[value]('(./DTS:VariableValue/@DTS:DataType)[1]','VARCHAR(50)') AS DataType) AS CADT
 WHERE 1 = 1
   --AND PackageName = 'ABC.dtsx'
 ORDER BY PackageName, [Namespace], DataType, VariableName;

/************************************
 GET BATCH SIZE FOR MS ORACLE SOURCE
************************************/
SELECT P.[FileName] AS PackageName,
       C.[value]('@name', 'nvarchar(200)') AS ComponentName,
       Prop.[value]('.', 'int')  AS [BatchSize]
  FROM dbo.SSIS_Packages P
       CROSS APPLY P.PackageXML.nodes('//*[local-name()="component"] [@componentClassID="Microsoft.SSISOracleSrc"]') AS X(C)
       OUTER APPLY C.nodes('.//*[local-name()="property"] [@name="BatchSize"]') AS Y(Prop)
 ORDER BY [BatchSize] DESC, PackageName;

/*******************************************
 GET DATA ACCESS MODE FOR OLDEB DESTINATION
*******************************************/
SELECT P.[FileName] AS PackageName,
       C.[value]('@name', 'nvarchar(200)') AS ComponentName,
       CASE Prop.[value]('.', 'int')
              WHEN 0 THEN 'Table or view'
              WHEN 1 THEN 'Table name or view name variable'
              WHEN 2 THEN 'SQL Command'
              WHEN 3 THEN 'Table or view - fast load'
              WHEN 4 THEN 'Table name or view name variable - fast load'
              ELSE 'Unknown'
        END AS DataAccessMode
  FROM dbo.SSIS_Packages P
       CROSS APPLY P.PackageXML.nodes('//*[local-name()="component"] [@componentClassID="Microsoft.OLEDBDestination"]') AS X(C)
       OUTER APPLY C.nodes('./*[local-name()="properties"] /*[local-name()="property"][@name="AccessMode"]') AS Y(Prop)
 ORDER BY PackageName, DataAccessMode;

/*******************
 EXEC SQL TASK INFO
*******************/
;WITH XMLNAMESPACES 
(
 'www.microsoft.com/SqlServer/Dts' AS DTS,
 'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS SQLTask
),
Base AS
(
SELECT [FileName] AS PackageName,
       PackageXML AS PackageData
  FROM dbo.SSIS_Packages
),
VAR_INFO AS
(
-- Parameter bindings
SELECT p.PackageName,
       ex.[value]('@DTS:ObjectName','varchar(200)') AS TaskName,
       pb.[value]('@SQLTask:DtsVariableName','varchar(200)') AS VariableName,
       pb.[value]('@SQLTask:ParameterName','varchar(200)') AS OrdinalPosition,
       pb.[value]('@SQLTask:ParameterDirection','varchar(50)') AS Direction,
       'Parameter' AS BindingType,
       ISNULL(ex.[value]('(DTS:ObjectData/SQLTask:SqlTaskData/@SQLTask:SqlStmtSourceType)[1]','varchar(50)'), 'DirectInput') AS SqlSourceType,
       ex.[value]('(DTS:ObjectData/SQLTask:SqlTaskData/@SQLTask:SqlStatementSource)[1]','varchar(max)') AS SqlSource
  FROM Base p
       CROSS APPLY PackageData.nodes('//DTS:Executable[@DTS:ExecutableType="Microsoft.ExecuteSQLTask"]') t(ex)
       CROSS APPLY ex.nodes('.//SQLTask:ParameterBinding') b(pb)
 UNION ALL
-- Result bindings
SELECT p.PackageName,
       ex.[value]('@DTS:ObjectName','varchar(200)') AS TaskName,
       rb.[value]('@SQLTask:DtsVariableName','varchar(200)') AS VariableName,
       rb.[value]('@SQLTask:ResultName','varchar(200)') AS OrdinalPosition,
       'Output' AS Direction,
       'Result' AS BindingType,
       ISNULL(ex.[value]('(DTS:ObjectData/SQLTask:SqlTaskData/@SQLTask:SqlStmtSourceType)[1]','varchar(50)'), 'DirectInput') AS SqlSourceType,
       ex.[value]('(DTS:ObjectData/SQLTask:SqlTaskData/@SQLTask:SqlStatementSource)[1]','varchar(max)') AS SqlSource
  FROM Base p
       CROSS APPLY PackageData.nodes('//DTS:Executable[@DTS:ExecutableType="Microsoft.ExecuteSQLTask"]') t(ex)
       CROSS APPLY ex.nodes('.//SQLTask:ResultBinding') r(rb)
)
SELECT *
  FROM VAR_INFO
 WHERE 1 = 1
   --AND PackageName = 'ABC.dtsx'
 ORDER BY TaskName, OrdinalPosition;

/***************
 DERIVED COLUMN
***************/
;WITH xmlnamespaces 
('www.microsoft.com/SqlServer/Dts' AS DTS, 'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS SQLTask),
Base
AS
(
SELECT [FileName] AS PackageName, 
       PackageXML as PackageData
  FROM dbo.SSIS_Packages
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
  FROM Recurse
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
   --AND PackageName = ''
   --AND DerivedColumn = 'BatchID'
 ORDER BY PackageName, ExecutableType, ExecutableName, ComponentName;

/*******************
 EXECUTABLE DETAILS
*******************/
;WITH xmlnamespaces 
('www.microsoft.com/SqlServer/Dts' AS DTS, 'www.microsoft.com/sqlserver/dts/tasks/sqltask' AS SQLTask),
Base
AS
(
SELECT [FileName] AS PackageName, 
       PackageXML as packagedata
  FROM dbo.SSIS_Packages
),
Recurse
AS
(
/* CONTROL FLOW EXECUTABLES */
SELECT PackageName,
       ex.e.query('.') AS subxml,
       ex.e.[value]('(./@DTS:Description)[1]','VARCHAR(250)') AS ExecutableType,
       ex.e.[value]('(./@DTS:ObjectName)[1]','VARCHAR(250)') AS ExecutableName,
       ex.e.[value]('(./@DTS:refId)[1]','VARCHAR(1000)') AS Hierarchy,
       COALESCE(ex.e.[value]('(./@DTS:Disabled)[1]','VARCHAR(5)'), 'False') AS IsDisabled,
	   0 AS ExecutableLevel,
       'CONTROL_FLOW' AS ExecutableGroup,
       NULL AS EventName
  FROM Base AS p
       CROSS APPLY PackageData.nodes('/DTS:Executable/DTS:Executables/DTS:Executable') AS ex(e)
 UNION ALL
/* EVENT HANDLER EXECUTABLES */
SELECT PackageName,
       ev.e.query('.') AS subxml,
       ev.e.[value]('(./@DTS:Description)[1]','VARCHAR(250)') AS ExecutableType,
       ev.e.[value]('(./@DTS:ObjectName)[1]','VARCHAR(250)') AS ExecutableName,
       ev.e.[value]('(./@DTS:refId)[1]','VARCHAR(1000)') AS Hierarchy,
       COALESCE(ev.e.[value]('(./@DTS:Disabled)[1]','VARCHAR(5)'), 'False') AS IsDisabled,
       0 AS ExecutableLevel,
       'EVENT_HANDLER' AS ExecutableGroup,
       eh.ehnode.[value]('(./@DTS:EventName)[1]','VARCHAR(100)') AS EventName
  FROM Base AS p
       CROSS APPLY PackageData.nodes('/DTS:Executable/DTS:EventHandlers/DTS:EventHandler') AS eh(ehnode)
       CROSS APPLY ehnode.nodes('./DTS:Executables/DTS:Executable') AS ev(e)
 UNION ALL
/* RECURSION */
SELECT PackageName,
       subex.e.query('.') AS subxml,
       subex.e.[value]('(./@DTS:Description)[1]','VARCHAR(250)') AS ExecutableType,
       subex.e.[value]('(./@DTS:ObjectName)[1]','VARCHAR(250)') AS ExecutableName,
       subex.e.[value]('(./@DTS:refId)[1]','VARCHAR(1000)') AS Hierarchy,
       COALESCE(subex.e.[value]('(./@DTS:Disabled)[1]','VARCHAR(5)'), 'False') AS IsDisabled,
	   ExecutableLevel + 1,
       ExecutableGroup,
       EventName
  FROM Recurse
       CROSS APPLY subxml.nodes('/DTS:Executable/DTS:Executables/DTS:Executable') AS subex(e)
),
Exec_Info
AS
(
SELECT PackageName,
       ExecutableLevel,
       ExecutableGroup,
       EventName,
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
                WHEN 'Execute Package Task' THEN pkg.code.[value]('PackageName[1]','VARCHAR(100)')
                WHEN 'Execute SQL Task' THEN exe.code.[value]('(./@SQLTask:SqlStatementSource)[1]','VARCHAR(MAX)')
                WHEN 'Script Task' THEN scr.code.[value]('ProjectItem[4]','VARCHAR(MAX)')
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
                           subex.e.[value]('(./@name)[1]','VARCHAR(250)') AS ComponentName,
                           --Extract the value of the Attribute
                           subex.e.[value]('(./@componentClassID)[1]','VARCHAR(250)') AS ComponentType,
                           --Extract the value of the Element
                           subex.e.[value]('properties[1]','VARCHAR(MAX)') AS ComponentCode,
                           --Extract the value of the Element for OLEDB Source
                           oledb.e.[value]('property[4]','VARCHAR(MAX)') AS OledbSrcCode,
                           --Extract the value of the Element for OLEDB Command & Destination
                           oledb.e.[value]('property[2]','VARCHAR(100)') AS OledbTgtCode,
                           --Extract the value of the Attribute for Flat File Source & Destination
                           subex.e.[value]('(./connections/connection/@connectionManagerID)[1]','VARCHAR(250)') AS FlatFileCode
                   ) AS SubComponents
)
SELECT *
  FROM Exec_Info
 WHERE 1 = 1
   AND PackageName = 'ingestSM_CAS_DLR_DMS_INTGN_MDL_ASC.dtsx'
   --AND IsDisabled = 'False'
   --AND ExecutableType = ''
   --AND ComponentType = 'Microsoft.SSISOracleSrc'
   --AND Code LIKE '%Test%'
 ORDER BY PackageName,
          IIF(ExecutableGroup = 'CONTROL_FLOW', 1 , 2),
          ExecutableLevel,
          ExecutableType,
          ExecutableName,
          ComponentName;

/****************************************************
 GET FULL TRANSACTION & ISOLATION AUDIT (ALL LEVELS)
****************************************************/
;WITH xmlnamespaces 
('www.microsoft.com/SqlServer/Dts' AS DTS),
Base
AS
(
SELECT [FileName] AS PackageName, 
       PackageXML AS packagedata
  FROM dbo.SSIS_Packages
)
SELECT p.PackageName,
       -- Executable Details
       ex.e.[value]('(./@DTS:ObjectName)[1]','VARCHAR(250)') AS ExecutableName,
       ex.e.[value]('(./@DTS:Description)[1]','VARCHAR(250)') AS ExecutableType,
       -- Isolation Level (default = Serializable)
       ISNULL(ex.e.[value]('@DTS:IsolationLevel','nvarchar(50)'), 'Serializable') AS IsolationLevel,
       -- Transaction Option (default = Supported)
       ISNULL(ex.e.[value]('@DTS:TransactionOption','nvarchar(50)'), 'Supported') AS TransactionOption
  FROM Base p
       CROSS APPLY PackageData.nodes('/DTS:Executable/DTS:Executables/DTS:Executable') AS ex(e)
 WHERE 1 = 1
   -- Shows only explicitly configured nodes or non Defaults
   -- AND (ex.e.exist('@DTS:TransactionOption') = 1 OR ex.e.exist('@DTS:IsolationLevel') = 1)
 ORDER BY p.PackageName;