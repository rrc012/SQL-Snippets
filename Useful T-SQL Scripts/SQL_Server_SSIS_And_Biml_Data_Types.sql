/*
 ===============================================================================
 Author:	     Clint Huijbers
 Source:       https://clinthuijbers.wordpress.com/2017/06/16/sql-tablecte-for-sql-server-ssis-and-biml-data-types/
 Article Name: Finding The Needle In The Haystack
 Create Date:  16-JUN-2017
 Description:  The following script provides an easy lookup table/cte for the
               data types within SQL Server, SSIS and Biml.
 Revision History:
 20-JUL-2017 - RAGHUNANDAN CUMBAKONAM
			Formatted the code.
			Added the history.
			Replaced the VALUES with SELECT..UNION ALL
 Usage:		N/A			   
 ===============================================================================
*/

USE master
GO

SET NOCOUNT ON;

WITH DataTypeMatrix 
(DataType_SQL, DataType_SSIS, DataType_Biml)
AS
( 
SELECT 'bigint','DT_I8','Int64' UNION ALL
SELECT 'binary','DT_BYTES','Binary' UNION ALL
SELECT 'bit','DT_BOOL','Boolean' UNION ALL
SELECT 'char','DT_STR','AnsiStringFixedLength' UNION ALL
SELECT 'date','DT_DBDATE','Date' UNION ALL
SELECT 'datetime','DT_DBTIMESTAMP','DateTime' UNION ALL
SELECT 'datetime2','DT_DBTIMESTAMP2','DateTime2' UNION ALL
SELECT 'datetimeoffset','DT_DBTIMESTAMPOFFSET','DateTimeOffset' UNION ALL
SELECT 'decimal','DT_NUMERIC','Decimal' UNION ALL
SELECT 'float','DT_R8','Double' UNION ALL
SELECT 'geography','DT_IMAGE','Object' UNION ALL
SELECT 'geometry','DT_IMAGE','Object' UNION ALL
SELECT 'hierarchyid','DT_BYTES','Object' UNION ALL
SELECT 'image','DT_IMAGE','Binary' UNION ALL
SELECT 'int','DT_I4','Int32' UNION ALL
SELECT 'money','DT_CY','Currency' UNION ALL
SELECT 'nchar','DT_WSTR','StringFixedLength' UNION ALL
SELECT 'ntext','DT_NTEXT','String' UNION ALL
SELECT 'numeric','DT_NUMERIC','Decimal' UNION ALL
SELECT 'nvarchar','DT_WSTR','String' UNION ALL
SELECT 'real','DT_R4','Single' UNION ALL
SELECT 'rowversion','DT_BYTES','Binary' UNION ALL
SELECT 'smalldatetime','DT_DBTIMESTAMP','DateTime' UNION ALL
SELECT 'smallint','DT_I2','Int16' UNION ALL
SELECT 'smallmoney','DT_CY','Currency' UNION ALL
SELECT 'sql_variant','DT_WSTR','Object' UNION ALL
SELECT 'text','DT_TEXT','AnsiString' UNION ALL
SELECT 'time','DT_DBTIME2','Time' UNION ALL
SELECT 'timestamp','DT_BYTES','Binary' UNION ALL
SELECT 'tinyint','DT_UI1','Byte' UNION ALL
SELECT 'uniqueidentifier','DT_GUID','Guid' UNION ALL
SELECT 'varbinary','DT_BYTES','Binary' UNION ALL
SELECT 'varchar','DT_STR','AnsiString' UNION ALL
SELECT 'xml','DT_NTEXT','Xml'
)
SELECT *
  FROM DataTypeMatrix;