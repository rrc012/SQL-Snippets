USE HPG_EDV
GO

/**************************************************************************
Database    : HPG_EDV
Name        : SLR.USP_VALIDATE_ROW_COUNT_AND_DATA
Purpose     : Validates the test cases for a given table
Used By     : 
Author      : Raghunandan Cumbakonam
Created     : 2015-12-15
Usage       : EXEC SLR.USP_VALIDATE_ROW_COUNT_AND_DATA 'SLR', 'TEST_SELLER_MANUFACTURER_SAT', 'SLR', 'S_SELLER_MANUFACTURER', 'LOAD_DATE, LOAD_DATE_END', 1;
***************************************************************************
Change History
***************************************************************************
Name               Date               Reason for modification
---------------    -----------        -----------------------
AUTHOR             YYYY-MM-DD  
**************************************************************************/

IF EXISTS (SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'SLR.USP_VALIDATE_ROW_COUNT_AND_DATA') AND TYPE IN (N'P', N'PC'))
BEGIN
	 DROP PROC SLR.USP_VALIDATE_ROW_COUNT_AND_DATA;
END
GO

CREATE PROCEDURE SLR.USP_VALIDATE_ROW_COUNT_AND_DATA
	  @Chk_Schema_Name VARCHAR(20),
	  @Chk_Table_Name VARCHAR(100),
	  @Tgt_Schema_Name VARCHAR(20),
	  @Tgt_Table_Name VARCHAR(100),
	  @Ignore_Columns VARCHAR(1000) = NULL,
	  @Debug_Proc BIT = NULL
AS
BEGIN
SET NOCOUNT ON;

BEGIN TRY		
		DECLARE @xColumn_List XML,
		        @sError_Msg VARCHAR(500),
			   @iChk_Cnt TINYINT,
			   @iTgt_Cnt TINYINT,
			   @iJoin_Cnt TINYINT,
			   @sChk_SQL NVARCHAR(MAX),
			   @sTgt_SQL NVARCHAR(MAX),
			   @sJoin_SQL NVARCHAR(MAX),
		        @sColumn_SQL NVARCHAR(MAX),
			   --@sDynamic_SQL NVARCHAR(MAX),
			   @sParameter_Def NVARCHAR(500) = N'@Count TINYINT OUTPUT';

		--This table variable is used to hold the list of COLUMN names that are to be excluded in the JOIN condition
		DECLARE @Column TABLE
		(
		 Excluded_Columns VARCHAR(100)
		);
		
		--Raise an error if the check table is not present in the database
		SET @sError_Msg = CONCAT('The object ', @Chk_Schema_Name, '.', @Chk_Table_Name, ' does not exist in database ', DB_NAME(), ' or is invalid for this operation.');
		IF NOT EXISTS (SELECT 1
		                 FROM sys.tables
					 WHERE SCHEMA_NAME(schema_id) = @Chk_Schema_Name
					   AND name = @Chk_Table_Name)
		RAISERROR (@sError_Msg, 16, 1);

		--Raise an error if the target table is not present in the database
		SET @sError_Msg = CONCAT('The object ', @Tgt_Schema_Name, '.', @Tgt_Table_Name, ' does not exist in database ', DB_NAME(), ' or is invalid for this operation.');
		IF NOT EXISTS (SELECT 1
		                 FROM sys.tables
					 WHERE SCHEMA_NAME(schema_id) = @Tgt_Schema_Name
					   AND name = @Tgt_Table_Name)
		RAISERROR (@sError_Msg, 16, 1);

--/*
		--Raise an error if the check table is empty
		SET @sError_Msg = CONCAT('The object ', @Chk_Schema_Name, '.', @Chk_Table_Name, ' has 0 records and is invalid for this operation.');
		SET @sChk_SQL = CONCAT(N'IF NOT EXISTS (SELECT 1 FROM ', @Chk_Schema_Name, N'.', @Chk_Table_Name, N') SELECT @Count = 0')
		EXECUTE sp_executesql @sChk_SQL, @sParameter_Def, @Count = @iChk_Cnt OUTPUT;
		IF @iChk_Cnt = 0 RAISERROR (@sError_Msg, 16, 1);

		--Raise an error if the target table is empty
		SET @sError_Msg = CONCAT('The object ', @Tgt_Schema_Name, '.', @Tgt_Table_Name, ' has 0 records and is invalid for this operation.');
		SET @sTgt_SQL = CONCAT(N'IF NOT EXISTS (SELECT 1 FROM ', @Tgt_Schema_Name, N'.', @Tgt_Table_Name, N') SELECT @Count = 0')
		EXECUTE sp_executesql @sTgt_SQL, @sParameter_Def, @Count = @iTgt_Cnt OUTPUT;
		IF @iTgt_Cnt = 0 RAISERROR (@sError_Msg, 16, 1);
--*/
		--Split single comma separated row (Column list passed as i/p parameter to the SP) into multiple rows
		SET @xColumn_List = CAST('<i>' + REPLACE(@Ignore_Columns, ',', '</i><i>') + '</i>' AS XML);		
		
		INSERT INTO @Column
          SELECT LTRIM(RTRIM(x.i.value('.', 'VARCHAR(100)')))
            FROM @xColumn_List.nodes('i') x(i)
		 WHERE EXISTS (SELECT 1
		                 FROM INFORMATION_SCHEMA.COLUMNS
				      WHERE TABLE_SCHEMA = @Tgt_Schema_Name
					   AND TABLE_NAME = @Tgt_Table_Name
					   AND COLUMN_NAME = LTRIM(RTRIM(x.i.value('.', 'VARCHAR(100)')))
					  );
		
		--Print the columns that are excluded in the JOIN condition
		IF (@@ROWCOUNT > 0 AND @Debug_Proc = 1)
		BEGIN
			SELECT @Ignore_Columns = STUFF((SELECT ', ' + Excluded_Columns FROM @Column ORDER BY Excluded_Columns FOR XML PATH('')), 1, 2, '');
               PRINT CONCAT('Excluded the following columns in the JOIN condition', CHAR(10), @Ignore_Columns, CHAR(10));
		END;
		
		--Build the JOIN clause
		WITH JOIN_COLUMNS
		AS
		(
		SELECT CASE WHEN IS_NULLABLE = 'NO' THEN CONCAT('TGT.', COLUMN_NAME, ' = CHK.', COLUMN_NAME)
		            WHEN IS_NULLABLE = 'YES' THEN CASE WHEN RIGHT(DATA_TYPE, 3) = 'INT' THEN CONCAT('ISNULL(TGT.', COLUMN_NAME, ', 0) = ISNULL(CHK.', COLUMN_NAME, ', 0)')
                                                         WHEN DATA_TYPE IN ('BIT', 'DECIMAL', 'FLOAT', 'NUMERIC', 'REAL') THEN CONCAT('ISNULL(TGT.', COLUMN_NAME, ', 0) = ISNULL(CHK.', COLUMN_NAME, ', 0)')
											  WHEN RIGHT(DATA_TYPE, 5) = 'MONEY' THEN CONCAT('ISNULL(TGT.', COLUMN_NAME, ', 0) = ISNULL(CHK.', COLUMN_NAME, ', 0)')
											  WHEN RIGHT(DATA_TYPE, 4) = 'CHAR' THEN CONCAT('ISNULL(TGT.', COLUMN_NAME, ', ''-'') = ISNULL(CHK.', COLUMN_NAME, ', ''-'')')
											  WHEN RIGHT(DATA_TYPE, 4) = 'TEXT' THEN CONCAT('ISNULL(TGT.', COLUMN_NAME, ', ''-'') = ISNULL(CHK.', COLUMN_NAME, ', ''-'')')
											  WHEN RIGHT(DATA_TYPE, 6) = 'BINARY' THEN CONCAT('ISNULL(TGT.', COLUMN_NAME, ', ''-'') = ISNULL(CHK.', COLUMN_NAME, ', ''-'')')
											  WHEN DATA_TYPE LIKE '%DATE%' THEN CONCAT('ISNULL(TGT.', COLUMN_NAME, ', ''1900-01-01'') = ISNULL(CHK.', COLUMN_NAME, ', ''1900-01-01'')')
											  WHEN DATA_TYPE = 'TIME' THEN CONCAT('ISNULL(TGT.', COLUMN_NAME, ', ''12:59:59.9999'') = ISNULL(CHK.', COLUMN_NAME, ', ''12:59:59.9999'')')
											  ELSE 'Datatype not supported by the proc'
										  END
	            END AS Join_Clause
		  FROM INFORMATION_SCHEMA.COLUMNS
		 WHERE 1 = 1
		   AND TABLE_SCHEMA = @Tgt_Schema_Name
		   AND TABLE_NAME = @Tgt_Table_Name
		   AND COLUMN_NAME NOT IN (SELECT * FROM @Column)
		)
		SELECT @sColumn_SQL = COALESCE(@sColumn_SQL + CHAR(10) + SPACE(18) + N'AND ', N'') + Join_Clause 
		  FROM JOIN_COLUMNS;
        
		--Get the ROW COUNT from the Check Table
		SET @sChk_SQL = CONCAT(N'SELECT @Count = COUNT(*) FROM ', @Chk_Schema_Name, N'.', @Chk_Table_Name);
		EXECUTE sp_executesql @sChk_SQL, @sParameter_Def, @Count = @iChk_Cnt OUTPUT;
		IF @Debug_Proc = 1 PRINT CONCAT(@Chk_Schema_Name, '.', @Chk_Table_Name, ' Row_Count = ', @iChk_Cnt, CHAR(10));

		--Get the ROW COUNT from the Target Table
		SET @sTgt_SQL = CONCAT(N'SELECT @Count = COUNT(*) FROM ', @Tgt_Schema_Name, N'.', @Tgt_Table_Name);
		EXECUTE sp_executesql @sTgt_SQL, @sParameter_Def, @Count = @iTgt_Cnt OUTPUT;
		IF @Debug_Proc = 1 PRINT CONCAT(@Tgt_Schema_Name, '.', @Tgt_Table_Name, ' Row_Count = ', @iTgt_Cnt, CHAR(10));

		--Get the ROW COUNT from the JOIN condition
          SET @sJoin_SQL = CONCAT(N'SELECT @Count = COUNT(*)', CHAR(10), SPACE(6), N'FROM ', @Tgt_Schema_Name, N'.', @Tgt_Table_Name, N' AS TGT', CHAR(10), SPACE(11)) +
		                 CONCAT(N'INNER JOIN ', @Chk_Schema_Name, N'.', @Chk_Table_Name, N' AS CHK ON ', @sColumn_SQL);		
		EXECUTE sp_executesql @sJoin_SQL, @sParameter_Def, @Count = @iJoin_Cnt OUTPUT;
		IF @Debug_Proc = 1 PRINT CONCAT('Join_Row_Cnt = ', @iJoin_Cnt, CHAR(10));
		
		--Print the IF STATEMENT for debugging purposes
		IF @Debug_Proc = 1 
		PRINT REPLACE(CONCAT('IF (', @sJoin_SQL, ') = (', @sChk_SQL, ')', CHAR(10), 'AND (', @sTgt_SQL,') = (', @sChk_SQL, ')', CHAR(10), SPACE(5), 'SELECT 1 AS Is_Success', CHAR(10), 'ELSE', CHAR(10), SPACE(5), 'SELECT 0 AS Is_Success;') /*End of CONCAT*/, 
		              '@Count = ', '');

		--Compare the COUNTs to evaluate the SUCCESS of the Test Case 
		IF ((@iJoin_Cnt = @iChk_Cnt) AND (@iTgt_Cnt = @iChk_Cnt))
			SELECT 1 AS Is_Success
		ELSE
			SELECT 0 AS Is_Success;

/*
		--Build the IF statement to compare the COUNTs
		SET @sDynamic_SQL = CONCAT(N'IF (SELECT COUNT(*)', CHAR(10), SPACE(6), N'FROM ', @Tgt_Schema_Name, N'.', @Tgt_Table_Name, N' AS TGT', CHAR(10), SPACE(11)) +
		                    CONCAT(N'INNER JOIN ', @Chk_Schema_Name, N'.', @Chk_Table_Name, N' AS CHK ON ', @sColumn_SQL, N')') +
		                    CONCAT(N' = (SELECT COUNT(*) FROM ', @Chk_Schema_Name, N'.',@Chk_Table_Name, N')', CHAR(10)) +
						CONCAT(N'AND (SELECT COUNT(*) FROM ', @Tgt_Schema_Name, N'.', @Tgt_Table_Name, N')') +
						CONCAT(N' = (SELECT COUNT(*) FROM ', @Chk_Schema_Name, N'.', @Chk_Table_Name, N')', CHAR(10), SPACE(4), N'SELECT 1 AS Is_Success') +
			               CONCAT(CHAR(10), N'ELSE', CHAR(10), SPACE(4), N'SELECT 0 AS Is_Success;');

		IF @Debug_Proc = 1 PRINT @sDynamic_SQL;

		EXECUTE sp_executesql @sDynamic_SQL;
--*/

END TRY

BEGIN CATCH
	THROW
END CATCH

SET NOCOUNT OFF;

END