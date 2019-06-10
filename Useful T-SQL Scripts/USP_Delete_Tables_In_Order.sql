/*
***************************************************************************
Database    : HPG_EDV
Name        : dbo.USP_DELETE_TABLES_IN_ORDER
Purpose     : This is a procedure to delete data in all the tables without 
              throwing FK error. 
Used By     : It will be used in all the FUNCTIONALITY STORED PROCEDURES.
Author      : Raghunandan Cumbakonam
Created     : 2016-03-15
Usage       : EXEC dbo.USP_DELETE_TABLES_IN_ORDER 1, 1, 'ORG';
***************************************************************************
Change History
***************************************************************************
Name               Date               Reason for modification
---------------    -----------        -----------------------
AUTHOR             YYYY-MM-DD  
**************************************************************************/

CREATE PROCEDURE dbo.USP_DELETE_TABLES_IN_ORDER
@bPurgeAll   BIT, --IF 0, SKIP TABLES WITH NO DATA
@bDebug      BIT, --IF 1, PRINT THE DELETE STATEMENTS
@sSchemaName VARCHAR(100) = NULL

AS 

SET NOCOUNT ON;

--DECLARE VARIABLES
DECLARE @iMin        SMALLINT,
	   @iMax        SMALLINT,
	   @iMinLevel   SMALLINT,
	   @iMaxLevel   SMALLINT,
	   @iRowCount   INT,
	   @sTableName  VARCHAR(200),
        @sDynamicSQL NVARCHAR(MAX);

--CREATE TEMP TABLE
IF object_id('tempdb..#Delete_Order', 'U') IS NOT NULL DROP TABLE #Delete_Order;
CREATE TABLE #Delete_Order 
(
 Id         SMALLINT IDENTITY(1,1) NOT NULL,
 SchemaName VARCHAR(100)           NOT NULL,
 TableName  VARCHAR(100)           NOT NULL,
 Level      SMALLINT               NOT NULL,
 DML        NVARCHAR(500)          NOT NULL,
 [RowCount] INT                    NOT NULL,
 CONSTRAINT PK_Delete_Order_H PRIMARY KEY CLUSTERED (Id ASC),
);
CREATE NONCLUSTERED INDEX IX_Delete_Order_Level ON #Delete_Order (Level);

BEGIN TRY
     /********************************************************
      LOAD TEMP TABLE WITH TABLE NAMES THAT NEED TO BE PURGED
     ********************************************************/
     WITH FK_TABLES
     AS 
     (
     SELECT SCHEMA_NAME(CT.schema_id) AS Child_Schema,
            CT.Name AS Child_Table,
     	  CASP.Row_Count,
            SCHEMA_NAME(PT.schema_id) AS Parent_Schema,
            PT.Name AS Parent_Table,
     	  CT.schema_id
       FROM sys.foreign_keys AS FK
            INNER JOIN sys.tables AS CT ON FK.parent_object_id = CT.object_id
            INNER JOIN sys.tables AS PT ON FK.referenced_object_id = PT.object_id
     	  CROSS APPLY (SELECT SUM(SP.row_count) AS Row_Count FROM sys.dm_db_partition_stats AS SP WHERE CT.object_id = SP.object_id AND SP.index_id < 2) CASP  
     /*For the purposes of finding dependency hierarchy we're not worried about self-referencing tables*/
      WHERE 1 = 1
        AND CT.name NOT IN ('dtproperties', 'sysdiagrams')
        AND CT.name != PT.name
     ),
     ORDERED_TABLES
     AS
     (
     SELECT SCHEMA_NAME(ST.schema_id) AS Schema_Nm,
            ST.name AS Table_Name,
     	  CASP.Row_Count,
            0 AS Level
       FROM sys.tables AS ST
            LEFT JOIN FK_TABLES AS FK ON ST.schema_id = FK.schema_id
                                     AND ST.name = FK.Child_Table
            CROSS APPLY (SELECT SUM(SP.row_count) AS Row_Count FROM sys.dm_db_partition_stats AS SP WHERE ST.object_id = SP.object_id AND SP.index_id < 2) CASP 
      WHERE FK.Child_Schema IS NULL
        AND ST.name NOT IN ('dtproperties', 'sysdiagrams')
      UNION ALL
     SELECT FK.Child_Schema,
            FK.Child_Table,
     	  FK.Row_Count,
            OT.Level + 1
       FROM fk_tables AS FK
            INNER JOIN ORDERED_TABLES AS OT ON FK.Parent_Schema = OT.Schema_Nm
                                           AND FK.Parent_Table = OT.Table_Name
     ),
     PURGE_ORDER
     AS
     (
     SELECT DISTINCT
            Schema_Nm,
            Table_Name,
            MAX(Level) OVER (PARTITION BY Schema_Nm, Table_Name) AS Level,
     	  CONCAT('DELETE ', Schema_Nm, '.', Table_Name, ';') AS DML,
     	  Row_Count
       FROM ORDERED_TABLES
      WHERE 1 = 1
        AND Row_Count > IIF(@bPurgeAll = 1, -1, 0)
        AND Schema_Nm = COALESCE(@sSchemaName, Schema_Nm)
     )
     INSERT INTO #Delete_Order
     (SchemaName, TableName, Level, DML, [RowCount])
     SELECT Schema_Nm,
            Table_Name,
            Level,
     	  DML,
     	  Row_Count
       FROM PURGE_ORDER
      ORDER BY Level DESC, Schema_Nm, Table_Name
     OPTION (MAXRECURSION 0);
     
     /**************************
      PURGE TABLES SEQUENTIALLY
     **************************/
     --ASSIGN MIN & MAX LEVEL
     SELECT @iMinLevel = MIN(Level),
            @iMaxLevel = MAX(Level)
       FROM #Delete_Order;
     
     WHILE (@iMaxLevel >= @iMinLevel)
     BEGIN    
         --ASSIGN MIN & MAX ID's BY THE LEVEL
         SELECT @iMin = MIN(Id),
                @iMax = MAX(Id)
           FROM #Delete_Order 
          WHERE Level = @iMaxLevel;
     
         --INNER WHILE LOOP TO PURGE THE TABLES BY LEVEL BY ID
         WHILE (@iMin <= @iMax)
         BEGIN
             SELECT @sDynamicSQL = DML,
     	          @sTableName = CONCAT(SchemaName, '.', TableName),
     			@iRowCount = [RowCount]
     	     FROM #Delete_Order
     	    WHERE Id = @iMin;
             IF @bDebug = 1
         	       PRINT CONCAT(@sDynamicSQL, '--', @iRowCount, ' rows');
             ELSE
     	       BEGIN
         	           EXECUTE sp_executesql @sDynamicSQL;
     			 PRINT CONCAT('Deleted ', @@ROWCOUNT, ' rows from ', DB_NAME(), '.', @sTableName);
     		  END;
             SET @iMin += 1;
         END; --INNER WHILE LOOP
     
         SET @iMaxLevel -= 1;
     END; --OUTER WHILE LOOP
     
     /****************
      DROP TEMP TABLE
     ****************/
     IF object_id('tempdb..#Delete_Order', 'U') IS NOT NULL DROP TABLE #Delete_Order;

END TRY

BEGIN CATCH
 
     THROW;

END CATCH