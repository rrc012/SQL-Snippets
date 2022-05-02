SET NOCOUNT ON;

--//////////////////////////////////////////////////////
--CONTROL CENTER - DECLARE AND CONFIGURE THE VARIABLES
--//////////////////////////////////////////////////////
DECLARE @sAliasSchemaName  VARCHAR(20)   = 'dbo',
        @sTargetSchemaName VARCHAR(20)   = 'dbo',
        @sAliasTableName   VARCHAR(100)  = 'SecuritiesAllSummaryScoresRaw',
        @sTargetTableName  VARCHAR(100)  = 'MSCIESGSecuritiesAllSummaryScoresRaw',
        @sColInfoSQL       NVARCHAR(MAX),
        @sParams           NVARCHAR(100) = N'@SchemaName VARCHAR(20), @TableName VARCHAR(100)';

IF OBJECT_ID('tempdb.dbo.#Alias') IS NOT NULL DROP TABLE tempdb.dbo.#Alias;
IF OBJECT_ID('tempdb.dbo.#Target') IS NOT NULL DROP TABLE tempdb.dbo.#Target;
IF OBJECT_ID('tempdb.dbo.#DataConversionResults') IS NOT NULL DROP TABLE tempdb.dbo.#DataConversionResults;

CREATE TABLE #Alias
(
 TableName      VARCHAR(100) NOT NULL,
 ColumnPosition INT          NOT NULL,
 ColumnName     VARCHAR(100) NOT NULL,
 DataType       VARCHAR(30)  NOT NULL
);

CREATE TABLE #Target
(
 TableName      VARCHAR(100) NOT NULL,
 ColumnPosition INT          NOT NULL,
 ColumnName     VARCHAR(100) NOT NULL,
 DataType       VARCHAR(30)  NOT NULL
);

SET @sColInfoSQL = N'
SELECT SS.[name] + ''.'' + SO.[name] AS TableName,
 	   SC.column_id AS ColumnPosition,
 	   SC.[name] AS ColumnName,
 	   CASE WHEN RIGHT(SD.[name], 4) = ''CHAR'' THEN CONCAT(SD.[name], ''('', SC.max_length, '')'')
            WHEN RIGHT(SD.[name], 3) IN (''BIT'', ''IME'', ''INT'') THEN SD.[name]
            WHEN LEFT(SD.[name], 4) IN (''DATE'') THEN SD.[name]
            WHEN SD.[name] IN (''DECIMAL'', ''NUMERIC'') THEN CONCAT(SD.[name], ''('', SC.[precision], '','', SC.scale, '')'')
       END AS DataType
  FROM sys.columns AS SC
       INNER JOIN sys.objects AS SO ON SC.object_id = SO.object_id
       INNER JOIN sys.schemas AS SS ON SO.schema_id = SS.schema_id
       LEFT JOIN sys.types AS SD ON SC.system_type_id = SD.system_type_id
             AND SC.user_type_id = SD.user_type_id
 WHERE 1 = 1
   AND SS.[name] = @SchemaName
   AND SO.[name] = @TableName
 ORDER BY ColumnPosition;'

INSERT INTO #Alias
(TableName, ColumnPosition, ColumnName, DataType)
EXEC sp_executesql @sColInfoSQL, @sParams, @SchemaName = @sAliasSchemaName, @TableName = @sAliasTableName;

INSERT INTO #Target
(TableName, ColumnPosition, ColumnName, DataType)
EXEC sp_executesql @sColInfoSQL, @sParams, @SchemaName = @sTargetSchemaName, @TableName = @sTargetTableName;

SELECT T.*, CONCAT('SELECT ', A.ColumnName, ' FROM ', A.TableName, ' WHERE ', A.ColumnName, ' != ''''', ' AND TRY_CAST(', A.ColumnName, ' AS ', T.DataType, ') IS NULL;')
  FROM #Alias AS A
       INNER JOIN #Target AS T ON REPLACE(A.ColumnName, '_', '') = T.ColumnName
              AND A.DataType != T.DataType
 ORDER BY A.ColumnPosition;

DROP TABLE tempdb.dbo.#Alias;
DROP TABLE tempdb.dbo.#Target;