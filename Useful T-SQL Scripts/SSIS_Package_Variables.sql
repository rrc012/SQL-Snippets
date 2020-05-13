/*
 ===============================================================================
 Author:	    RAGHUNANDAN CUMBAKONAM
 Reference:   https://docs.microsoft.com/en-us/dotnet/api/microsoft.sqlserver.dts.runtime.wrapper.datatype?view=sqlserver-2017
 Create Date: 19-MAR-2014
 Description: This query returns the list of variables used inside a SSIS package
              and which is deployed on msdb database.
 ===============================================================================
*/

USE msdb
GO

SET NOCOUNT ON;

;WITH xmlnamespaces 
('www.microsoft.com/SqlServer/Dts' AS DTS),
Base
AS
(
SELECT [name] AS PackageName, 
       packagedata = CAST(CAST(packagedata AS VARBINARY(MAX)) AS XML) 
  FROM msdb.dbo.sysssispackages
)
SELECT PackageName,
       ex.e.value('(./@DTS:Namespace)[1]','VARCHAR(100)') AS VariableSpace,
       ex.e.value('(./@DTS:ObjectName)[1]','VARCHAR(100)') AS VariableName,
       ex.e.value('DTS:VariableValue[1]','VARCHAR(100)') AS VariableValue,
	  CASE DataType
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
        END AS DataType
  FROM Base AS p
       CROSS APPLY PackageData.nodes('/DTS:Executable/DTS:Variables/DTS:Variable') AS ex(e)
       CROSS APPLY (SELECT ex.e.value('(./DTS:VariableValue/@DTS:DataType)[1]','VARCHAR(50)') AS DataType) AS CADT
 WHERE 1 = 1
   --AND PackageName = ''
 ORDER BY DataType, VariableName, Variablespace;