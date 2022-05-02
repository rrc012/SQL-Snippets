SET NOCOUNT ON

	DECLARE @TableName VARCHAR(500) = 'SantanderWealthGlobalCurrentTotalInvestments';

	IF OBJECT_ID('tempdb..#Temp_Index_Details', 'U') IS NOT NULL DROP TABLE #Temp_Index_Details;

	CREATE TABLE #Temp_Index_Details
     (
      [Object_Id]                BIGINT,
	  [Object_Name]              VARCHAR(100),
	  Index_Id                   INT,
	  Index_Name                 VARCHAR(200),
	  User_Seeks                 BIGINT,
	  User_Scans                 BIGINT,
	  User_Lookups               BIGINT,
	  Index_Rows                 BIGINT,
	  User_Updates               BIGINT,
	  Index_Lock_Attempt_Count   BIGINT,
	  Index_Lock_Promotion_Count BIGINT,
	  Page_Lock_Wait_Count       BIGINT,
	  Page_Lock_Wait_In_Ms       BIGINT,
	  [Fillfactor]               INT,
	  Constraint_Type            VARCHAR(100),
	  Partition_Number           BIGINT
     );

	INSERT INTO #Temp_Index_Details 
		   (
		    [OBJECT_ID],
		    [OBJECT_NAME],
		    Index_ID,
		    Index_Name,
		    User_Seeks,
		    User_Scans,
		    User_Lookups,
		    Index_Rows,
		    User_Updates,
		    [FILLFACTOR],
		    Constraint_Type	
		   )
	SELECT u.OBJECT_ID,
		   OBJECT_NAME(u.OBJECT_ID),
		   i.indid,
		   i.name,
		   u.user_seeks,
		   u.user_scans,
		   u.user_lookups,
		   i.rowcnt,
		   u.user_updates,
		   i.OrigFillFactor,
		   k.[type] AS [CONSTRAINT TYPE] 
	  FROM sys.sysindexes i
	       LEFT JOIN sys.dm_db_index_usage_stats u ON u.OBJECT_ID = i.id 
                 AND u.index_id = i.indid
	       LEFT JOIN sys.key_constraints k ON i.id = k.parent_OBJECT_ID 
                 AND i.indid = k.unique_index_id
	 WHERE u.database_id = DB_ID() 
       AND OBJECT_NAME(u.OBJECT_ID) = @TableName
	 ORDER BY OBJECT_NAME(u.OBJECT_ID), i.name, u.user_updates DESC;
		
	UPDATE B 
       SET B.Partition_Number = A.partition_number, 
	       B.Index_Lock_Attempt_Count = index_lock_promotion_attempt_count,
	       B.Index_Lock_Promotion_Count = A.index_lock_promotion_count ,
	       B.page_lock_wait_count = A.page_lock_wait_count, 
	       B.page_lock_wait_in_ms = A.page_lock_wait_in_ms
	  FROM sys.dm_db_index_operational_stats (DB_ID(DB_NAME()), OBJECT_ID(@TableName), NULL, NULL) A
           INNER JOIN #Temp_Index_Details B  ON A.OBJECT_ID = B.OBJECT_ID 
	              AND A.index_id = B.Index_ID;

	--Table Details
	SELECT @TableName 'TableName',
		   A.OBJECT_ID,
		   CASE WHEN A.index_id=0 THEN 'Heap' ELSE 'Clustered Table' END 'Table Type',
		   C.row_count
	  FROM sys.partitions A
	       LEFT JOIN sys.dm_db_partition_stats C ON A.OBJECT_ID = C.OBJECT_ID 
                 AND c.index_id IN (0,1)
	 WHERE A.index_id < 2 
       AND A.OBJECT_ID = OBJECT_ID(@TableName);
	
	--Column Details		
	SELECT Column_ID,
		   name AS Column_Name,
		   TYPE_NAME(user_type_id) Data_Type,
		   Max_Length,
		   Precision,
		   Scale,
		   Is_Identity,
		   CASE WHEN is_nullable = 1 THEN 'Yes' ELSE 'No' END Is_Nullable 
	  FROM sys.columns
	 WHERE OBJECT_ID = OBJECT_ID(@TableName);

	--Index Details
	SELECT A.name IndexName,
		   A.Index_ID,
		   c.name ColumnName,
		   CASE WHEN System_type_id = User_Type_id THEN TYPE_NAME(System_type_id) ELSE TYPE_NAME(User_Type_id) END Data_Type,
		   A.Type_Desc,
		   Is_Identity,
		   Is_Included_Column,
		   Is_Replicated,
		   Is_Unique,
		   Is_Primary_Key,
		   Is_Unique_Constraint,
		   Fill_factor,
		   Is_Padded,
		   Is_Replicated,
		   Is_Nullable,
		   Is_Computed
	  FROM sys.indexes A 
	       INNER JOIN sys.index_columns B ON A.OBJECT_ID = B.OBJECT_ID 
                  AND A.index_id = B.index_id
	       INNER JOIN sys.columns C ON c.OBJECT_ID = B.OBJECT_ID  
                  AND C.column_id = B.column_id
	 WHERE A.OBJECT_ID = OBJECT_ID(@TableName)
	 ORDER BY A.Index_id,Is_included_Column,Key_ordinal ASC;
	
	--Index Usage Details		
	SELECT [OBJECT_NAME],
		   Index_ID,
		   Index_Name,
		   User_Seeks,
		   User_Scans,
		   User_Lookups,
		   Index_Rows,
		   User_Updates,
		   Index_Lock_Attempt_Count,
		   Index_Lock_Promotion_Count,
		   page_lock_wait_count,
		   page_lock_wait_in_ms,
		   [FILLFACTOR],
		   Constraint_Type,
		   Partition_Number 
	  FROM #Temp_Index_Details;
			
	--Stats information
	SELECT A.OBJECT_ID,
		   A.name,
		   A.stats_id,
		   C.column_id,
		   C.name,
		   A.auto_created,
		   user_created,
		   has_filter,
		   STATS_DATE(A.OBJECT_ID,A.stats_id) 'Stats_Date'
	  FROM sys.stats A
	       INNER JOIN sys.stats_columns B ON A.OBJECT_ID = B.OBJECT_ID 
	              AND A.stats_id = B.stats_id
	       INNER JOIN sys.columns C ON B.column_id = C.column_id 
	              AND A.OBJECT_ID = C.OBJECT_ID
	 WHERE A.OBJECT_ID = OBJECT_ID(@Tablename);

	--Primary Key and Foreign Key information
	SELECT tc.TABLE_NAME AS PrimaryKeyTable,
		   tc.CONSTRAINT_NAME AS PrimaryKey,
		   COALESCE(rc1.CONSTRAINT_NAME,'N/A') AS ForeignKey ,
		   COALESCE(tc2.TABLE_NAME,'N/A') AS ForeignKeyTable
	  FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
	       LEFT JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc1 ON tc.CONSTRAINT_NAME = rc1.UNIQUE_CONSTRAINT_NAME
	       LEFT JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc2 ON tc2.CONSTRAINT_NAME = rc1.CONSTRAINT_NAME
	 WHERE TC.CONSTRAINT_TYPE = 'PRIMARY KEY' 
       AND OBJECT_ID(tc.TABLE_NAME) = OBJECT_ID(@Tablename)
	 ORDER BY tc.TABLE_NAME,tc.CONSTRAINT_NAME,rc1.CONSTRAINT_NAME;
	 
SET NOCOUNT OFF