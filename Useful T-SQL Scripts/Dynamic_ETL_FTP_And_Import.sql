USE [DATABASE_NAME]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

/*
 ===============================================================
 Author:       SARAH DORISS
 Source:       http://www.sqlservercentral.com/articles/ETL/71210/
 Create Date:  03-MAY-2013
 Article:      Dynamic ETL with SSIS
 Description:  This article is about how to dynamically load 
			   flat files using SSIS as a shell for basic 
			   extraction functionality while all transformations 
			   and business logic run in the database.
 Revision History:
 03-MAY-2013 - SARAH DORISS
 07-MAY-2013 - RAGHUNANDAN CUMBAKONAM 
			   Formatted the code.
			   Added the function udf_Get_NextWeekDay.
			   Added the usage and history.
 Usage:        N/A
 ===============================================================
*/

/****************************************
  DDL for creating Tables - BEGIN
****************************************/

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ETL_ZipFiles' AND type = 'U')
BEGIN
	 DROP TABLE dbo.ETL_ZipFiles
END
GO
CREATE TABLE [dbo].[ETL_ZipFiles] 
(
	 [ETLFileId] [INT] IDENTITY(1, 1) NOT NULL
	,[FileCode] [CHAR](2) NOT NULL
	,[FilePrefix] [VARCHAR](100) NULL
	,[FileDescription] [VARCHAR](500) NULL
	,[ServerLocation] [VARCHAR](500) NULL
	,[FolderNamePrefix] [VARCHAR](100) NULL
	,[RunOrder] [INT] NULL
	,[Active] [BIT] NULL
	,[FTPLocation] [VARCHAR](200) NULL
	) ON [PRIMARY]
GO
/************************************************************************************/
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ETL_ImportFiles' AND type = 'U')
BEGIN
	 DROP TABLE dbo.ETL_ImportFiles
END
GO
CREATE TABLE [dbo].[ETL_ImportFiles] 
(
	 [ETLImportFileId] [INT] IDENTITY(1, 1) NOT NULL
	,[ETLFileId] [INT] NOT NULL
	,[FileCode] [CHAR](2) NOT NULL
	,[ImportFileName] [VARCHAR](100) NULL
	,[LoadTableName] [VARCHAR](100) NULL
	,[DestTableName] [VARCHAR](100) NULL
	,[Delimited] [BIT] NOT NULL
	,[Delimiter] [CHAR](1) NULL
	,[DestFieldToIndex] [VARCHAR](100) NULL
	) ON [PRIMARY]
GO
/************************************************************************************/
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ETL_ImportDictionary' AND type = 'U')
BEGIN
	 DROP TABLE dbo.ETL_ImportDictionary
END
GO
CREATE TABLE [dbo].[ETL_ImportDictionary] 
(
	 [ETLImportDictionaryId] [INT] IDENTITY(1, 1) NOT NULL
	,[ETLImportFileId] [INT] NOT NULL
	,[FileCode] [CHAR](2) NOT NULL
	,[FieldName] [VARCHAR](200) NULL
	,[ParseStartPoint] [INT] NULL
	,[ParseEndPoint] [INT] NULL
	,[DataTypeDescription] [VARCHAR](100) NULL
	,[FieldsOrder] [INT] NULL
	) ON [PRIMARY]
GO
/************************************************************************************/
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ETL_Run' AND type = 'U')
BEGIN
	 DROP TABLE dbo.ETL_Run
END
GO
CREATE TABLE [dbo].[ETL_Run] 
(
	 [ETLRunId] [INT] IDENTITY(1, 1) NOT NULL
	,[ETLFileId] [INT] NOT NULL
	,[FileCode] [CHAR](2) NOT NULL
	,[FileName] [VARCHAR](200) NOT NULL
	,[FolderName] [VARCHAR](100) NULL
	,[FileLocation] [VARCHAR](500) NULL
	,[RunStart] [SMALLDATETIME] NULL
	,[RunEnd] [SMALLDATETIME] NULL
	,[Completed] [BIT] NOT NULL
	,[ContainsErrors] [BIT] NOT NULL
	,[Duration] [INT] NULL
	,[Imported] [BIT] NOT NULL
	,[FileDate] [SMALLDATETIME] NULL
	) ON [PRIMARY]
GO

/****************************************
  DDL for creating Tables - END
****************************************/

/****************************************
  DDL for creating Stored Procs - BEGIN
****************************************/
--This udf is missing from the article
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'udf_Get_NextWeekDay' AND xtype = 'FN')
BEGIN
	 DROP FUNCTION dbo.udf_Get_NextWeekDay
END
GO

CREATE FUNCTION dbo.udf_Get_NextWeekDay 
     (
	 @aDate DATETIME
	,@dayofweek TINYINT
	/*
      @dw - day of the week
      1 - Monday
      2 - Tuesday
      3 - Wednesday
      4 - Thursday
      5 - Friday
      6 - Saturday
      7 - Sunday
    */
	)
RETURNS DATETIME
AS
/*
  SELECT dbo.udf_Get_NextWeekDay(GETDATE(), 6)
  SELECT dbo.udf_Get_NextWeekDay('2011-08-08', 1)
*/
BEGIN
	RETURN DATEADD(DAY, (@dayofweek + 8 - DATEPART(dw, @aDate) - @@DATEFIRST) % 7, @aDate)
END
GO
/*****************************************************************************************/
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'Package_QueueRun' AND xtype = 'P')
BEGIN
	 DROP PROC dbo.Package_QueueRun
END
GO
CREATE PROCEDURE [dbo].[Package_QueueRun] 
	@RunDate SMALLDATETIME = NULL
AS
BEGIN
SET NOCOUNT ON

DECLARE @FileDate VARCHAR(8)
	   ,@LastRunDate SMALLDATETIME

--if run date not passed in - get the next dated file
IF @RunDate IS NULL
BEGIN
	SELECT @LastRunDate = DATEADD(DAY, 1, MAX(FileDate))
	FROM dbo.ETL_Run

	SELECT @FileDate = dbo.udf_Get_NextWeekDay(@LastRunDate, 3)
END

IF @FileDate IS NULL
BEGIN
	SELECT @FileDate = dbo.udf_Get_NextWeekDay(@RunDate, 3)
END

INSERT INTO [dbo].[ETL_Run] 
(
	 [FileCode]
	,[ETLFileId]
	,[FileName]
	,[FolderName]
	,[FileLocation]
	,[RunStart]
	,FileDate
	)
SELECT FileCode
	  ,ETLFileId
	  ,FilePrefix + @FileDate
	  ,FolderNamePrefix + @FileDate
	  ,ServerLocation + FolderNamePrefix + @FileDate + '\'
	  ,GETDATE()
	  ,CAST(@FileDate AS SMALLDATETIME)
FROM dbo.ETL_ZipFiles
WHERE Active = 1

SET NOCOUNT OFF
END
/*****************************************************************************************/
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'Package_QueueRun' AND xtype = 'P')
BEGIN
	 DROP PROC dbo.Package_QueueRun
END
GO

CREATE PROCEDURE [dbo].[Package_CreateLoadTables]
AS
BEGIN
SET NOCOUNT ON

DECLARE @SQL NVARCHAR(MAX)
	   ,@DropSQL NVARCHAR(MAX)

SET @SQL = ''
SET @DropSQL = ''

--Create DROP TABLE SQL
SELECT @DropSQL = @DropSQL + 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N' + QUOTENAME('[dbo].' + QUOTENAME(LoadTableName), '''') + ') AND type in (N' + QUOTENAME('U', '''') + '))DROP TABLE [dbo].' + QUOTENAME(LoadTableName) + '; '
FROM dbo.[ETL_ImportFiles] mi
INNER JOIN dbo.ETL_zipfiles mz ON mi.FileCode = mz.FileCode
INNER JOIN dbo.ETL_Run r ON r.Filecode = mi.FileCode
WHERE mz.Active = 1
	AND Completed = 0
	AND ContainsErrors = 0

--Add Select and Primary Key Constraint
SELECT @SQL = @SQL + 'CREATE TABLE ' + QUOTENAME('dbo') + '.' + QUOTENAME(LoadTableName) + '( ' + QUOTENAME('Id') + ' int NOT NULL Identity(1,1), EverythingElse varchar(500)' + ' CONSTRAINT [PK_' + LoadTableName + '] PRIMARY KEY CLUSTERED' + '(

 [Id' + '] ASC

 ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

 ) ON [PRIMARY]; '
FROM dbo.[ETL_ImportFiles] mi
INNER JOIN dbo.ETL_zipfiles mz ON mi.FileCode = mz.FileCode
WHERE mz.Active = 1

--SELECT @DropSQL
--SELECT @SQL
EXEC sp_executeSQL @DropSQL

EXEC sp_executeSQL @SQL

SET NOCOUNT OFF
END
/*****************************************************************************************/
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'Package_RunInfo' AND xtype = 'P')
BEGIN
	 DROP PROC dbo.Package_RunInfo
END
GO

CREATE PROCEDURE [dbo].[Package_RunInfo]
AS
BEGIN
	SET NOCOUNT ON;

	SELECT ETLRunId
		  ,mr.FileCode
		  ,mr.FileName
		  ,mr.FolderName
		  ,mr.FileLocation AS ZipLocation
		  ,mr.FileLocation + 'ExtractFiles\' AS FileLocation
		  ,mr.RunStart
		  ,mr.RunEnd
		  ,mr.Completed
		  ,mr.ContainsErrors
		  ,mr.Duration
		  ,md.FTPLocation
	FROM [dbo].[ETL_Run] mr
		INNER JOIN dbo.ETL_ZipFiles md ON md.FileCode = mr.FileCode
	WHERE Completed = 0 --Finds all runs that haven't been run yet
		AND ContainsErrors = 0
		AND md.Active = 1

	SET NOCOUNT OFF;
END
/*****************************************************************************************/
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'Package_GetLoadTable' AND xtype = 'P')
BEGIN
	 DROP PROC dbo.Package_GetLoadTable
END
GO

CREATE PROCEDURE [dbo].[Package_GetLoadTable] @FileCode CHAR(2)
AS
SET NOCOUNT ON

BEGIN
	SELECT LoadTableName
		  ,ImportFileName
	FROM dbo.[ETL_ImportFiles] mi
		INNER JOIN dbo.ETL_zipfiles mz ON mi.FileCode = mz.FileCode
	WHERE mi.FileCode = @FileCode
		AND mz.Active = 1

SET NOCOUNT OFF
END
/*****************************************************************************************/
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'GetConcatenatedFieldsWithType' AND xtype = 'FN')
BEGIN
	 DROP FUNCTION dbo.GetConcatenatedFieldsWithType
END
GO

CREATE FUNCTION [dbo].[GetConcatenatedFieldsWithType] (@ETLImportFileId INT)
RETURNS NVARCHAR(2000)
AS
BEGIN
	DECLARE @Fields NVARCHAR(2000)

	SET @Fields = ''

	SELECT @Fields = @Fields + '[' + FieldName + '] ' + DataTypeDescription + ' NULL, '
	FROM ETL_ImportDictionary id
	WHERE id.ETLImportFileId = @ETLImportFileId

	RETURN @Fields
END
/*****************************************************************************************/
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'Package_CreateDestinationTables' AND xtype = 'P')
BEGIN
	 DROP PROC dbo.Package_CreateDestinationTables
END
GO

CREATE PROCEDURE [dbo].[Package_CreateDestinationTables]
AS
SET NOCOUNT ON

BEGIN
	
	DECLARE @SQL NVARCHAR(MAX)
		   ,@DropSQL NVARCHAR(MAX)
	
	DECLARE @DestTableCreate TABLE 
	    (
		 ETLImportFileId INT
		,BeginString NVARCHAR(2000)
		,FieldString NVARCHAR(2000)
		,EndString NVARCHAR(2000)
		,TotalString NVARCHAR(MAX)
		)

	SET @SQL = ''
	SET @DropSQL = ''

	SELECT @DropSQL = @DropSQL + 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N' + QUOTENAME('[dbo].' + QUOTENAME(DestTableName), '''') + ') AND type in (N' + QUOTENAME('U', '''') + '))DROP TABLE [dbo].' + QUOTENAME(DestTableName) + '; '
	FROM dbo.[ETL_ImportFiles] mi
		INNER JOIN dbo.ETL_zipfiles mz ON mi.FileCode = mz.FileCode
		INNER JOIN dbo.ETL_Run r ON r.Filecode = mi.FileCode
	WHERE mz.Active = 1
		AND Completed = 0
		AND ContainsErrors = 0

	--CREATE TABLE STRING
	INSERT INTO @DestTableCreate (
		ETLImportFileId
		,BeginString
		)
	SELECT ETLImportFileId
		,'CREATE TABLE ' + QUOTENAME('dbo') + '.' + QUOTENAME(DestTableName) + '( ' + QUOTENAME(DestTableName + 'Id') + ' INT NOT NULL IDENTITY(1,1), '
	FROM dbo.[ETL_ImportFiles] mi
		INNER JOIN dbo.ETL_zipfiles mz ON mi.FileCode = mz.FileCode
		INNER JOIN dbo.ETL_Run r ON r.Filecode = mi.FileCode
	WHERE mz.Active = 1
		AND Completed = 0
		AND ContainsErrors = 0
		AND EXISTS (
			SELECT 1
			FROM ETL_ImportDictionary md --Actually contains fields
			WHERE md.ETLImportFileId = mi.ETLImportFileId
			)

	--Concatenate Field Names and Types 
	UPDATE d
	SET FieldString = dbo.[GetConcatenatedFieldsWithType](d.ETLImportFileId)
	FROM @DestTableCreate d

	UPDATE d
	SET EndString = ' CONSTRAINT ' + QUOTENAME('PK_' + DestTableName) + ' PRIMARY KEY CLUSTERED 

(

 ' + QUOTENAME(DestTableName + 'Id') + ' ASC

)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

) ON [PRIMARY]; '
	FROM @DestTableCreate d
		INNER JOIN dbo.[ETL_ImportFiles] mi ON mi.ETLImportFileId = d.ETLImportFileId
		INNER JOIN dbo.ETL_zipfiles mz ON mi.FileCode = mz.FileCode
		INNER JOIN dbo.ETL_Run r ON r.Filecode = mi.FileCode
	WHERE mz.Active = 1
		AND Completed = 0
		AND ContainsErrors = 0
		AND EXISTS (
			SELECT 1
			FROM ETL_ImportDictionary md
			WHERE md.ETLImportFileId = mi.ETLImportFileId
			)

	UPDATE d
	SET TotalString = BeginString + FieldString + EndString
	FROM @DestTableCreate d

	SELECT @SQL = @SQL + TotalString
	FROM @DestTableCreate

	--SELECT @DropSQL
	--SELECT @SQL
	EXEC sp_executeSQL @DropSQL

	EXEC sp_executeSQL @SQL

SET NOCOUNT OFF
END
/*****************************************************************************************/
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'Package_CreateIndexes' AND xtype = 'P')
BEGIN
	 DROP PROC dbo.Package_CreateIndexes
END
GO

CREATE PROCEDURE [dbo].[Package_CreateIndexes]
AS
SET NOCOUNT ON

BEGIN
	DECLARE @IndexSQL NVARCHAR(MAX)

	SET @IndexSQL = ''

	--Create DROP TABLE SQL
	SELECT @IndexSQL = @IndexSQL + 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N' + QUOTENAME('[dbo].' + QUOTENAME(DestTableName), '''') + ') AND type in (N' + QUOTENAME('U', '''') + '))CREATE INDEX IX_' + DestTableName + '_' + CONVERT(VARCHAR(255), REPLACE(NEWID(), '-', '')) + ' ON [dbo].' + QUOTENAME(DestTableName) + ' (' + DestFieldToIndex + ')' + '; '
	FROM dbo.[ETL_ImportFiles] mi
		INNER JOIN dbo.ETL_zipfiles mz ON mi.FileCode = mz.FileCode
		INNER JOIN dbo.ETL_Run r ON r.Filecode = mi.FileCode
	WHERE mz.Active = 1
		AND Completed = 0
		AND ContainsErrors = 0
		AND r.Imported = 1
		AND mi.DestFieldToIndex IS NOT NULL

	--SELECT @IndexSQL
	EXEC sp_executeSQL @IndexSQL

SET NOCOUNT OFF
END
/*****************************************************************************************/
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'CreateDelimitedTableString' AND xtype = 'FN')
BEGIN
	 DROP FUNCTION dbo.CreateDelimitedTableString
END
GO

CREATE FUNCTION [dbo].[CreateDelimitedTableString] (@ETLImportFileId INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @DestTableName VARCHAR(100)
		   ,@LoadTableName VARCHAR(100)
		   ,@FieldNames VARCHAR(2000)
		   ,@Select VARCHAR(5000)
		   ,@SQL VARCHAR(MAX)
		   ,@FieldNumbers VARCHAR(300)
		   ,@Delimiter CHAR(1)

	SET @DestTableName = ''
	SET @LoadTableName = ''
	SET @FieldNames = ''
	SET @Select = ''
	SET @SQL = ''
	SET @FieldNumbers = ''

	IF EXISTS (
			SELECT 1
			FROM ETL_ImportDictionary
			WHERE ETLImportFileId = @ETLImportFileId
			)
	BEGIN
		SELECT @DestTableName = DestTableName
			  ,@LoadTableName = LoadTableName
			  ,@Delimiter = mi.Delimiter
		FROM dbo.[ETL_ImportFiles] mi
			INNER JOIN dbo.ETL_zipfiles mz ON mi.FileCode = mz.FileCode
			INNER JOIN dbo.ETL_Run r ON r.Filecode = mi.FileCode
		WHERE mi.ETLImportFileId = @ETLImportFileId
			AND mz.Active = 1
			AND Completed = 0
			AND ContainsErrors = 0

		SELECT @FieldNames = @FieldNames + QUOTENAME(FieldName) + ', '
		FROM ETL_ImportDictionary id
		WHERE id.ETLImportFileId = @ETLImportFileId

		SELECT @FieldNames = SUBSTRING(@FieldNames, 1, LEN(@FieldNames) - 1)

		SELECT @FieldNumbers = @FieldNumbers + QUOTENAME(CAST(FieldsOrder AS VARCHAR)) + ','
		FROM dbo.ETL_ImportDictionary
		WHERE ETLImportFileId = @ETLImportFileId

		SELECT @FieldNumbers = SUBSTRING(@FieldNumbers, 1, LEN(@FieldNumbers) - 1)

		SELECT @SELECT = 'INSERT INTO ' + QUOTENAME(@DestTableName) + '(' + @FieldNames + ') SELECT '

		SELECT @SQL = @SELECT + @FieldNumbers + ' FROM (SELECT d.Id, WordNumber, Word ' + 'FROM dbo.' + QUOTENAME(@LoadTableName) + ' d CROSS APPLY dbo.DelimitedItem(d.EverythingElse,' + QUOTENAME(@Delimiter, '''') + ')' + ') p PIVOT (MAX([Word]) FOR WordNumber in (' + @FieldNumbers + ')) as pvt; '
	END

	RETURN @SQL
END
/*****************************************************************************************/
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'CreateParsedTableString' AND xtype = 'FN')
BEGIN
	 DROP FUNCTION dbo.CreateParsedTableString
END
GO

CREATE FUNCTION [dbo].[CreateParsedTableString] (@ETLImportFileId INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @DestTableName VARCHAR(100)
		   ,@LoadTableName VARCHAR(100)
		   ,@FieldNames VARCHAR(2000)
		   ,@Select VARCHAR(5000)
		   ,@Substring VARCHAR(5000)
		   ,@SQL VARCHAR(MAX)

	SET @DestTableName = ''
	SET @LoadTableName = ''
	SET @FieldNames = ''
	SET @Select = ''
	SET @SQL = ''
	SET @Substring = ''

	IF EXISTS (
			SELECT 1
			FROM ETL_ImportDictionary
			WHERE ETLImportFileId = @ETLImportFileId
			)
	BEGIN
		SELECT @DestTableName = DestTableName
			  ,@LoadTableName = LoadTableName
		FROM dbo.[ETL_ImportFiles] mi
			INNER JOIN dbo.ETL_zipfiles mz ON mi.FileCode = mz.FileCode
			INNER JOIN dbo.ETL_Run r ON r.Filecode = mi.FileCode
		WHERE mi.ETLImportFileId = @ETLImportFileId
			AND mz.Active = 1
			AND Completed = 0
			AND ContainsErrors = 0

		SELECT @FieldNames = @FieldNames + QUOTENAME(FieldName) + ', '
		FROM ETL_ImportDictionary id
		WHERE id.ETLImportFileId = @ETLImportFileId

		SELECT @FieldNames = SUBSTRING(@FieldNames, 1, LEN(@FieldNames) - 1)

		SELECT @SELECT = 'INSERT INTO ' + QUOTENAME(@DestTableName) + '(' + @FieldNames + ') SELECT '

		SELECT @Substring = @Substring + 'SUBSTRING(EverythingElse, ' + CAST(ParseStartPoint AS VARCHAR) + ', ' + CAST((ParseEndPoint - ParseStartPoint + 1) AS VARCHAR) + ') AS ' + FieldName + ' , '
		FROM ETL_ImportDictionary id
		WHERE id.ETLImportFileId = @ETLImportFileId

		SELECT @Substring = SUBSTRING(@Substring, 1, LEN(@Substring) - 1)

		SELECT @SQL = @SELECT + @Substring + ' FROM dbo.' + QUOTENAME(@LoadTableName) + '; '
	END

	RETURN @SQL
END
/*****************************************************************************************/
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'Package_PopulateDestination' AND xtype = 'P')
BEGIN
	 DROP PROC dbo.Package_PopulateDestination
END
GO

--WARNING! ERRORS ENCOUNTERED DURING SQL PARSING!
CREATE PROCEDURE [dbo].[Package_PopulateDestination]
AS
SET NOCOUNT ON

BEGIN
	DECLARE @SQL NVARCHAR(MAX)

	SET @SQL = ''

	IF EXISTS (
			SELECT 1
			FROM dbo.[ETL_ImportFiles] mi
				INNER JOIN dbo.ETL_zipfiles mz ON mi.FileCode = mz.FileCode
				INNER JOIN dbo.ETL_Run r ON r.Filecode = mi.FileCode
			WHERE mz.Active = 1
				AND Completed = 0
				AND ContainsErrors = 0
				AND mi.Delimited = 1
			)
	BEGIN
		SELECT @SQL = @SQL + dbo.CreateDelimitedTableString(mi.ETLFileId)
		FROM dbo.[ETL_ImportFiles] mi
			INNER JOIN dbo.ETL_zipfiles mz ON mi.FileCode = mz.FileCode
			INNER JOIN dbo.ETL_Run r ON r.Filecode = mi.FileCode
		WHERE mz.Active = 1
			AND Completed = 0
			AND ContainsErrors = 0
			AND mi.Delimited = 1
	END

	IF EXISTS (
			SELECT 1
			FROM dbo.[ETL_ImportFiles] mi
				INNER JOIN dbo.ETL_zipfiles mz ON mi.FileCode = mz.FileCode
				INNER JOIN dbo.ETL_Run r ON r.Filecode = mi.FileCode
			WHERE mz.Active = 1
				AND Completed = 0
				AND ContainsErrors = 0
				AND mi.Delimited = 0
			)
	BEGIN
		SELECT @SQL = @SQL + dbo.CreateParsedTableString(mi.ETLFileId)
		FROM dbo.[ETL_ImportFiles] mi
			INNER JOIN dbo.ETL_zipfiles mz ON mi.FileCode = mz.FileCode
			INNER JOIN dbo.ETL_Run r ON r.Filecode = mi.FileCode
		WHERE mz.Active = 1
			AND Completed = 0
			AND ContainsErrors = 0
			AND mi.Delimited = 0
	END

	--SELECT @SQL
	EXEC sp_executeSQL @SQL

	UPDATE r
	SET Imported = 1
	FROM dbo.[ETL_ImportFiles] mi
		INNER JOIN dbo.ETL_zipfiles mz ON mi.FileCode = mz.FileCode
		INNER JOIN dbo.ETL_Run r ON r.Filecode = mi.FileCode
	WHERE mz.Active = 1
		AND Completed = 0
		AND ContainsErrors = 0

SET NOCOUNT OFF
END
/*****************************************************************************************/
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'DelimitedItem' AND xtype = 'TF')
BEGIN
	 DROP FUNCTION dbo.DelimitedItem
END
GO

CREATE FUNCTION [dbo].[DelimitedItem] 
    (
	-- Add the parameters for the function here
	 @String VARCHAR(8000)
	,@Delimiter CHAR(1)
	)
RETURNS @ListTable TABLE 
    (
	-- Add the column definitions for the TABLE variable here
	 WordNumber INT
	,StartPoint INT
	,EndingPoint INT
	,Word VARCHAR(500)
	)
AS
BEGIN
	WITH csvtbl 
	   (
		 WordNumber
		,StartPoint
		,EndingPoint
		,Word
		)
	AS (
		SELECT WordNumber = 1
			  ,StartPoint = 1
			  ,EndingPoint = CHARINDEX(@Delimiter, @String + @Delimiter)
			  ,Word = SUBSTRING(@String, 1, CHARINDEX(@Delimiter, @String + @Delimiter) - 1)
		 
		UNION ALL
		
		SELECT WordNumber = WordNumber + 1
			  ,StartPoint = EndingPoint + 1
			  ,EndingPoint = CHARINDEX(@Delimiter, @String + @Delimiter, EndingPoint + 1)
			  ,Word = SUBSTRING(@String, EndingPoint + 1, CHARINDEX(@Delimiter, @String + @Delimiter, EndingPoint + 1) - (EndingPoint + 1))
		FROM csvtbl
		WHERE CHARINDEX(@Delimiter, @String + @Delimiter, EndingPoint + 1) <> 0
		)
	INSERT INTO @ListTable (
		 WordNumber
		,StartPoint
		,EndingPoint
		,Word
		)
	SELECT WordNumber
		  ,StartPoint
		  ,EndingPoint
		  ,Word
	FROM csvtbl

	RETURN
END
/*****************************************************************************************/
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'Package_TruncateLoadTables' AND xtype = 'P')
BEGIN
	 DROP PROC dbo.Package_TruncateLoadTables
END
GO

CREATE PROCEDURE [dbo].[Package_TruncateLoadTables]
AS
SET NOCOUNT ON

BEGIN
	DECLARE @DropSQL NVARCHAR(MAX)

	SET @DropSQL = ''

	--Create DROP TABLE SQL
	SELECT @DropSQL = @DropSQL + 'IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N' + QUOTENAME('[dbo].' + QUOTENAME(LoadTableName), '''') + ') AND type in (N' + QUOTENAME('U', '''') + '))TRUNCATE TABLE [dbo].' + QUOTENAME(LoadTableName) + '; '
	FROM dbo.[ETL_ImportFiles] mi
		INNER JOIN dbo.ETL_zipfiles mz ON mi.FileCode = mz.FileCode
		INNER JOIN dbo.ETL_Run r ON r.Filecode = mi.FileCode
	WHERE mz.Active = 1
		AND Completed = 0
		AND ContainsErrors = 0
		AND r.Imported = 1

	--SELECT @DropSQL
	EXEC sp_executeSQL @DropSQL

SET NOCOUNT OFF
END
/*****************************************************************************************/
IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'Package_SetRunCompletion' AND xtype = 'P')
BEGIN
	 DROP PROC dbo.Package_SetRunCompletion
END
GO

CREATE PROCEDURE [dbo].[Package_SetRunCompletion] 
@FileCode CHAR(2)
AS
SET NOCOUNT ON

BEGIN

UPDATE m
   SET RunEnd = GETDATE(),
       Completed = 1,
       Duration = DATEDIFF(MINUTE, m.RunStart, GETDATE())
  FROM ETL_Run m
 WHERE m.Completed = 0
	AND ContainsErrors = 0
	AND FileCode = @FileCode

SET NOCOUNT OFF
END
/*****************************************************************************************/

SET ANSI_PADDING OFF
GO

/****************************************
  DDL for creating Stored Procs - END
****************************************/