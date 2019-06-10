USE [datamart]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'usp_InsertUnknownDimensionRow' AND xtype = 'P')
BEGIN
	 DROP PROC usp_InsertUnknownDimensionRow
END
GO

CREATE PROCEDURE [dbo].[usp_InsertUnknownDimensionRow](@TableName NVARCHAR(128))
AS
BEGIN

SET NOCOUNT ON

/*
 ======================================================================
 Author:	  Joost van Rossum
 Source:      http://microsoft-ssis.blogspot.com/2015/01/insert-unknown-dimension-record-for-all.html
 Create Date: 28-JAN-2015
 Description: This Stored Procedure inserts a record in the dimension table
              for unknown dimension values. It generates an insert statement
			  based on the column datatypes and executes it. The integer 
			  column with identity enabled gets the value -1 and all other 
			  columns get a default value based on their datatype. Columns 
			  with a default value are ignored.
 Usage:       EXEC usp_InsertUnknownDimensionRow 'tbl_d_policy'
 Revision History:
 12-FEB-2015 - RAGHUNANDAN CUMBAKONAM Renamed the SP
									  Formatted the code
                                      Added SET NOCOUNT
 ======================================================================
*/

/*
 Tweak the code for your own needs and standards. Optional extra check 
 if you don't want to truncate your dimensions: is there already a 
 default/unknown record available
*/
 -- Create temporary table for column specs of dimension table

DECLARE @TableSpecs TABLE 
        (
        COLUMN_ID                INT IDENTITY
       ,COLUMN_NAME              NVARCHAR(128)
       ,DATA_TYPE                NVARCHAR(128)
       ,CHARACTER_MAXIMUM_LENGTH INT
       ,COLUMN_IS_IDENTITY       BIT
        );

-- Use the information schema to get column info and insert it to the temporary table.
INSERT @TableSpecs
SELECT C.COLUMN_NAME
      ,C.DATA_TYPE
      ,C.CHARACTER_MAXIMUM_LENGTH
      ,COLUMNPROPERTY(OBJECT_ID(C.TABLE_SCHEMA + '.' + C.TABLE_NAME)
      ,C.COLUMN_NAME, 'IsIdentity') AS COLUMN_IS_IDENTITY
  FROM INFORMATION_SCHEMA.COLUMNS C
 WHERE QUOTENAME(C.TABLE_NAME) = QUOTENAME(@TableName)
   AND C.COLUMN_DEFAULT IS NULL
 ORDER BY C.ORDINAL_POSITION
;

-- Variables to keep track of the number of columns
DECLARE @ColumnId INT
	  ,@ColumnCount INT;

SET @ColumnId = -1
SET @ColumnCount = 0

-- Variables to create the insert query
DECLARE @INSERTSTATEMENT_START NVARCHAR(MAX)
	   ,@INSERTSTATEMENT_END NVARCHAR(MAX);

SET @INSERTSTATEMENT_START = 'INSERT INTO ' + QUOTENAME(@TableName) + ' ('
SET @INSERTSTATEMENT_END = 'VALUES ('

/*
 Variables to complete the insert query with extra enable and disable identity statements
 You could add an extra check in the loop to make sure there is an identity column in the
 table. Otherwise the SET IDENTITY_INSERT statement will fail.
*/
DECLARE @IDENITYSTATEMENT_ON NVARCHAR(255)
 	   ,@IDENITYSTATEMENT_OFF NVARCHAR(255);

SET @IDENITYSTATEMENT_ON = 'SET IDENTITY_INSERT ' + QUOTENAME(@TableName) + ' ON;'
SET @IDENITYSTATEMENT_OFF = 'SET IDENTITY_INSERT ' + QUOTENAME(@TableName) + ' OFF;'

-- Variables filled and use the WHILE loop
DECLARE @COLUMN_NAME VARCHAR(50)
	   ,@DATA_TYPE VARCHAR(50)
	   ,@CHARACTER_MAXIMUM_LENGTH INT
	   ,@COLUMN_IS_IDENTITY BIT;

-- WHILE loop to loop through all columns and create a insert query with the columns
WHILE @ColumnId IS NOT NULL
	BEGIN
	-- Keep track of the number of columns
	SELECT @ColumnId = MIN(COLUMN_ID)
		  ,@ColumnCount = @ColumnCount + 1
	  FROM @TableSpecs
	 WHERE COLUMN_ID > @ColumnCount;

	-- Check if there are any columns left
	IF @ColumnId IS NULL
		BEGIN
			-- No columns left, break loop
			BREAK
		END
	ELSE
		BEGIN
			-- Get info for column number x
			SELECT @COLUMN_NAME = COLUMN_NAME
				  ,@DATA_TYPE = DATA_TYPE
				  ,@CHARACTER_MAXIMUM_LENGTH = CHARACTER_MAXIMUM_LENGTH
				  ,@COLUMN_IS_IDENTITY = COLUMN_IS_IDENTITY
			  FROM @TableSpecs
			WHERE COLUMN_ID = @ColumnCount;
		END
       
	-- Start building the begin of the statement (same for each column)
	SET @INSERTSTATEMENT_START = @INSERTSTATEMENT_START + @COLUMN_NAME + ','

	-- Start building the end of the statement (the default values)
	IF @COLUMN_IS_IDENTITY = 1
		BEGIN
			-- Default value if the current column is the identity column
			SET @INSERTSTATEMENT_END = @INSERTSTATEMENT_END + '-1,'
		END
             
	IF @DATA_TYPE IN ('INT', 'NUMERIC', 'DECIMAL', 'MONEY', 'FLOAT', 'REAL', 'BIGINT', 'SMALLINT', 'TINYINT', 'SMALLMONEY') AND (@COLUMN_IS_IDENTITY = 0)
		BEGIN
			-- Default value if the current column is a numeric column,
			-- but not an identity: zero
			SET @INSERTSTATEMENT_END = @INSERTSTATEMENT_END + '0,'
		END

	IF @DATA_TYPE IN ('CHAR', 'NCHAR', 'VARCHAR', 'NVARCHAR')
		BEGIN
			-- Default value if the current column is a text column
			-- Part of the text "unknown" depending on the length
			SET @INSERTSTATEMENT_END = @INSERTSTATEMENT_END + '''' + LEFT('Unknown', @CHARACTER_MAXIMUM_LENGTH) + ''','
		END

	IF @DATA_TYPE IN ('DATETIME', 'DATE', 'TIMESTAMP', 'DATATIME2', 'DATETIMEOFFSET', 'SMALLDATETIME', 'TIME') 
		BEGIN
			-- Default value if the current column is a datetime column
			-- First of January 1900
			SET @INSERTSTATEMENT_END = @INSERTSTATEMENT_END + '''' + CONVERT(VARCHAR, CONVERT(DATE, 'Jan 1 1900')) + ''','
		END

	IF @DATA_TYPE = 'BIT' 
		BEGIN
			-- Default value if the current column is a boolean 
			SET @INSERTSTATEMENT_END = @INSERTSTATEMENT_END + '0,'
		END
	END --End of WHILE Block

-- Remove last comma from start and end part of the insert statement
SET @INSERTSTATEMENT_START = LEFT(@INSERTSTATEMENT_START, LEN(@INSERTSTATEMENT_START) - 1) + ')'
SET @INSERTSTATEMENT_END = LEFT(@INSERTSTATEMENT_END, LEN(@INSERTSTATEMENT_END) - 1) + ');'

-- Execute the complete statement
EXEC (@IDENITYSTATEMENT_ON + ' ' + @INSERTSTATEMENT_START + ' ' + @INSERTSTATEMENT_END + ' ' + @IDENITYSTATEMENT_OFF)

SET NOCOUNT OFF
      
END --End of SP Block

GO