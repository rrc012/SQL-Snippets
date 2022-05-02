--chk
;WITH LIST_CHECK_CONSTRAINTS
 AS
(
SELECT IIF(SO.type = 'TT', SCHEMA_NAME(STT.schema_id), SCHEMA_NAME(SO.schema_id)) AS Sch_Name,
       IIF(SO.type = 'TT', STT.name, OBJECT_NAME(CC.parent_object_id)) AS ObjectName,
       SO.type_desc AS Object_Type,
       CC.name AS Check_Constraint_Name,
	  CC.definition AS Check_Value,
	  SC.name AS Column_Name,
 	  SD.name AS Data_Type,
 	  SC.max_length AS Max_Length,
 	  SC.precision AS Precision,
 	  SC.scale AS Scale,
 	  IIF(SC.is_nullable = 1, 'YES', 'NO') AS Is_Nullable,
	  IIF(CC.is_system_named = 1, 'YES', 'NO') AS Is_System_Named
  FROM sys.check_constraints AS CC
       LEFT JOIN sys.objects AS SO ON CC.parent_object_id = SO.object_id
       LEFT JOIN sys.columns AS SC ON CC.parent_object_id = SC.object_id
	        AND CC.parent_column_id = SC.column_id
	  LEFT JOIN sys.types AS SD ON SC.system_type_id = SD.system_type_id
 	        AND SC.user_type_id = SD.user_type_id
       LEFT JOIN sys.table_types AS STT ON CC.parent_object_id = STT.type_table_object_id
)
SELECT *
  FROM LIST_CHECK_CONSTRAINTS
 WHERE 1 = 1
   --AND Sch_Name = ''
   --AND Object_Type = ''
   --AND ObjectName = ''
   --AND Check_Constraint_Name = ''
   --AND Is_System_Named = 'NO'
 ORDER BY 1, 3, 2
;

--citf
CREATE FUNCTION --(owner_name.)function_name
  --(@parameter_name AS scalar_data_type ( = default_value ), ...)
RETURNS TABLE
--WITH ENCRYPTION|SCHEMABINDING, ...
AS
RETURN ( SELECT /* query specification */ )
GO

--cnt
SELECT [rows] AS TotalRows
  FROM sys.sysindexes
 WHERE id = OBJECT_ID('')
   AND indid < 2
;

--col
SELECT COLUMN_NAME,
       COLUMN_DEFAULT,
       IS_NULLABLE,
       DATA_TYPE,
       CHARACTER_MAXIMUM_LENGTH,
       NUMERIC_PRECISION,
       NUMERIC_SCALE
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE 1 = 1
   --AND TABLE_SCHEMA = ''
   --AND TABLE_NAME = ''
 ORDER BY ORDINAL_POSITION;

--colinfo
;WITH LIST_COLUMNS
 AS
(
SELECT IIF(SO.type = 'TT', SCHEMA_NAME(STT.schema_id), SCHEMA_NAME(SO.schema_id)) AS Sch_Name,
       IIF(SO.type = 'TT', STT.name, SO.name) AS ObjectName,
 	  SO.type_desc AS Object_Type,
 	  SC.name AS Column_Name,
	  SCHEMA_NAME(SD.schema_id) AS Data_Type_Schema,
 	  SD.name AS Data_Type,
 	  SC.max_length AS Max_Length,
 	  SC.precision AS Precision,
 	  SC.scale AS Scale,
 	  IIF(SC.is_nullable = 1, 'YES', 'NO') AS Is_Nullable,
 	  IIF(SC.is_identity = 1, 'YES', 'NO') AS Is_Identity,
 	  IIF(SC.is_computed = 1, 'YES', 'NO') AS Is_Computed,
       IIF(SD.is_user_defined = 1, 'YES', 'NO') AS Is_User_Defined,
       IIF(SD.is_assembly_type =1, 'YES', 'NO') AS Is_Assembly_Type,
	  ISNULL(CC.Definition, '-') AS Computed_Value,
	  IIF(DC.object_id IS NOT NULL, 'YES', 'NO') AS Is_Default,
	  ISNULL(DC.name, '-') AS Default_Constraint_Name,
	  ISNULL(DC.definition, '-') AS Default_Value,
       ISNULL(CKC.name, '-') AS Check_Constraint_Name,
	  ISNULL(CKC.definition, '-') AS Check_Value,
       EP.[value] AS Comments
  FROM sys.columns AS SC
       LEFT JOIN sys.check_constraints AS CKC ON SC.object_id = CKC.parent_object_id
	        AND SC.column_id = CKC.parent_column_id
	  LEFT JOIN sys.computed_columns AS CC ON SC.object_id = CC.object_id
	        AND SC.column_id = CC.column_id
		   AND CC.is_computed = 1
	  LEFT JOIN sys.default_constraints AS DC ON SC.default_object_id = DC.object_id
       LEFT JOIN sys.objects AS SO ON SC.object_id = SO.object_id
 	  LEFT JOIN sys.table_types AS STT ON SC.object_id = STT.type_table_object_id
       LEFT JOIN sys.types AS SD ON SC.system_type_id = SD.system_type_id
	        AND SC.user_type_id = SD.user_type_id
       LEFT JOIN sys.extended_properties AS EP ON SC.object_id = EP.major_id
             AND SC.column_id = EP.minor_id
             AND EP.name = 'MS_Description'
             AND EP.class_desc = 'OBJECT_OR_COLUMN'
)
SELECT *
  FROM LIST_COLUMNS
 WHERE 1 = 1
   --AND Sch_Name = ''
   --AND Object_Type = ''
   --AND ObjectName = ''
   --AND Column_Name = ''
 ORDER BY 1, 3, 2;

--colnames
DECLARE @i VARCHAR(MAX) 
SELECT @i = COALESCE(@i + ', ','') + COLUMN_NAME
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE 1 = 1
   AND TABLE_SCHEMA = ''
   AND TABLE_NAME = '' 
-- ORDER BY COLUMN_NAME
SELECT @i;

--comp
;WITH LIST_COMPUTED_COLUMNS
 AS
(
SELECT IIF(SO.type = 'TT', SCHEMA_NAME(STT.schema_id), SCHEMA_NAME(SO.schema_id)) AS Sch_Name,
       IIF(SO.type = 'TT', STT.name, SO.name) AS ObjectName,
	  SO.Type_Desc AS Object_Type,
       CC.name AS Column_Name,
	  CC.Definition,
       ST.name AS Datatype,
	  CC.Max_Length,
       CC.Precision,
       CC.Scale,
       IIF(CC.is_nullable = 1, 'YES', 'NO') AS Is_Nullable,
	  IIF(CC.is_persisted = 1, 'YES', 'NO') AS Is_Persisted
  FROM sys.computed_columns AS CC
       LEFT JOIN sys.types AS ST ON CC.system_type_id = ST.system_type_id
	        AND CC.user_type_id = ST.user_type_id	   
	  LEFT JOIN sys.objects AS SO ON CC.object_id = SO.object_id
	  LEFT JOIN sys.table_types AS STT ON CC.object_id = STT.type_table_object_id
)
SELECT *
  FROM LIST_COMPUTED_COLUMNS
 WHERE 1 = 1
   --AND Sch_Name = ''
   --AND Object_Type = ''
   --AND ObjectName = ''
   --AND Column_Name = ''
 ORDER BY 1, 3, 2
;

--csf
CREATE FUNCTION --(owner_name.)function_name
  --(@parameter_name AS scalar_data_type ( = default_value ), ...)
RETURNS --scalar_data_type
--WITH ENCRYPTION|SCHEMABINDING, ...
AS
BEGIN
  -- Function body here
  RETURN --scalar_expression
END
GO

--ctf
CREATE FUNCTION --(owner_name.)function_name
  --(@parameter_name AS scalar_data_type ( = default_value ), ...)
RETURNS @return_variable TABLE --table type definition
--WITH ENCRYPTION|SCHEMABINDING, ...
AS
BEGIN
  -- Function body here
  RETURN
END
GO

--dd
USE MASTER
GO
ALTER DATABASE MyDBName
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE MyDBName
GO

--dft
;WITH LIST_DEFAULTS
 AS
(
SELECT IIF(SO.type = 'TT', SCHEMA_NAME(STT.schema_id), SCHEMA_NAME(SO.schema_id)) AS Sch_Name,
       IIF(SO.type = 'TT', STT.name, OBJECT_NAME(DC.parent_object_id)) AS ObjectName,
       SO.type_desc AS Object_Type,
       DC.name AS Default_Constraint_Name,
	  DC.definition AS Default_Value,
	  SC.name AS Column_Name,
 	  SD.name AS Data_Type,
 	  SC.max_length AS Max_Length, 
 	  SC.precision AS Precision, 
 	  SC.scale AS Scale, 
 	  IIF(SC.is_nullable = 1, 'YES', 'NO') AS Is_Nullable,
	  IIF(DC.is_system_named = 1, 'YES', 'NO') AS Is_System_Named
  FROM sys.default_constraints AS DC
       LEFT JOIN sys.objects AS SO ON DC.parent_object_id = SO.object_id
       LEFT JOIN sys.columns AS SC ON SC.default_object_id = DC.object_id
	  LEFT JOIN sys.types AS SD ON SC.system_type_id = SD.system_type_id
 	        AND SC.user_type_id = SD.user_type_id
       LEFT JOIN sys.table_types AS STT ON DC.parent_object_id = STT.type_table_object_id
)
SELECT *
  FROM LIST_DEFAULTS
 WHERE 1 = 1
   --AND Sch_Name = ''
   --AND Object_Type = ''
   --AND ObjectName = ''
   --AND Default_Constraint_Name = ''
   --AND Is_System_Named = 'NO'
 ORDER BY 1, 3, 2
;

--fkcolref
;WITH LIST_FOREIGN_KEY_COLUMNS
AS
(
SELECT referencing_column.name AS Foreign_Key_Column,
       TYPE_NAME(referencing_column.user_type_id) AS Parent_Column_Type,
       referencing_column.max_length AS Parent_Column_Length,
	  referencing_column.precision AS Parent_Column_Precision,
	  referencing_column.scale AS Parent_Column_Scale,
       referenced_column.name AS Referenced_Column,
	  TYPE_NAME(referenced_column.user_type_id) AS Referenced_Column_Type,
       referenced_column.max_length AS Referenced_Column_Length,
	  referenced_column.precision AS Referenced_Column_Precision,
	  referenced_column.scale AS Referenced_Column_Scale,
	  SO.object_id AS Ref_Id,
	  FKC.constraint_column_id AS FK_Col_Order
  FROM sys.foreign_key_columns AS FKC
       INNER JOIN sys.objects AS SO ON SO.object_id = FKC.constraint_object_id
       INNER JOIN sys.tables AS parent_table ON FKC.parent_object_id = parent_table.object_id
       INNER JOIN sys.schemas AS parent_schema ON parent_schema.schema_id = parent_table.schema_id
       INNER JOIN sys.columns AS referencing_column ON FKC.parent_object_id = referencing_column.object_id
                                                   AND FKC.parent_column_id = referencing_column.column_id
       INNER JOIN sys.tables AS referenced_table ON referenced_table.object_id = FKC.referenced_object_id
       INNER JOIN sys.schemas AS referenced_schema ON referenced_schema.schema_id = referenced_table.schema_id
       INNER JOIN sys.columns AS referenced_column ON FKC.referenced_object_id = referenced_column.object_id
                                                  AND FKC.referenced_column_id = referenced_column.column_id       
)
SELECT parent_schema.name AS Parent_Schema,
       parent_table.name AS Parent_Table,
       IIF(FK.is_disabled = 0, 'ENABLED', 'DISABLED') AS FK_Status,
       IIF(COUNT(*) OVER (PARTITION BY fk.name) > 1, 'Y', 'N') AS Complex_FK,
       FK.name AS Foreign_Key_Name,
	  Foreign_Key_Column,
       FK_Col_Order,
       referenced_schema.name AS Referenced_Schema,
       referenced_table.name AS Referenced_Table,
	  Referenced_Column,    	  
	  Parent_Column_Type,
	  Parent_Column_Length,
	  Parent_Column_Precision,
	  Parent_Column_Scale,	  
	  Referenced_Column_Type,
	  Referenced_Column_Length,
	  Referenced_Column_Precision,
	  Referenced_Column_Scale
  FROM sys.foreign_keys AS FK
       INNER JOIN sys.tables AS parent_table ON FK.parent_object_id = parent_table.object_id
       INNER JOIN sys.schemas AS parent_schema ON parent_schema.schema_id = parent_table.schema_id	  
       INNER JOIN sys.tables AS referenced_table ON FK.referenced_object_id = referenced_table.object_id
       INNER JOIN sys.schemas AS referenced_schema ON referenced_schema.schema_id = referenced_table.schema_id
	  INNER JOIN LIST_FOREIGN_KEY_COLUMNS ON FK.object_id = Ref_Id
 WHERE 1 = 1
 ORDER BY Parent_Schema, Parent_Table, Referenced_Schema, Referenced_Table, FK_Col_Order;

--fktblref
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
       0 AS Level,
	  CAST('-' AS sysname) AS Parent_Schema_Nm,
	  CAST('-' AS sysname) AS Parent_Table_Name
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
       OT.Level + 1,
	  FK.Parent_Schema,
	  FK.Parent_Table
  FROM fk_tables AS FK
       INNER JOIN ORDERED_TABLES AS OT ON FK.Parent_Schema = OT.Schema_Nm
                                      AND FK.Parent_Table = OT.Table_Name
),
HIERARCHICAL_PATH
AS
(
SELECT DISTINCT
       Schema_Nm,
       Table_Name,
       MAX(Level) OVER (PARTITION BY Schema_Nm, Table_Name) AS Level,	  
	  Row_Count,
	  Parent_Schema_Nm,
	  Parent_Table_Name
  FROM ORDERED_TABLES
),
UNIQUE_SET
AS
(
SELECT Schema_Nm, Table_Name, Level, Parent_Schema_Nm, Parent_Table_Name,
	  ROW_NUMBER() OVER(PARTITION BY Schema_Nm, Table_Name ORDER BY Schema_Nm, Table_Name) AS RN,
	  ROW_NUMBER() OVER(PARTITION BY Parent_Schema_Nm, Parent_Table_Name ORDER BY Parent_Schema_Nm, Parent_Table_Name) AS RN1       
  FROM HIERARCHICAL_PATH
),
FK_REFERENCES
AS
(
SELECT Schema_Nm,
       Table_Name,
       MAX(Level) OVER (PARTITION BY Schema_Nm, Table_Name) AS Level,
	  Row_Count,
	  Parent_Schema_Nm,
	  Parent_Table_Name,
	  COALESCE(Parent_Level, '-') As Parent_Level
  FROM HIERARCHICAL_PATH AS C1
       OUTER APPLY (SELECT CAST(MAX(T1.Level) OVER (PARTITION BY T1.Schema_Nm, T1.Table_Name) AS VARCHAR(5)) AS Parent_Level
	                 FROM UNIQUE_SET AS T1
				       INNER JOIN UNIQUE_SET AS T2 ON T1.Schema_Nm = T2.Parent_Schema_Nm
					                             AND T1.Table_Name = T2.Parent_Table_Name
										    AND T1.RN = T2.RN1
										    AND T1.RN = 1
				 WHERE C1.Parent_Schema_Nm = T2.Parent_Schema_Nm
				   AND C1.Parent_Table_Name = T2.Parent_Table_Name
			    ) OA
)
SELECT *
  FROM FK_REFERENCES
 WHERE 1 = 1
   --AND Schema_Nm = ''
   --AND Table_Name = ''
   --AND Level = 0
   --AND Parent_Schema_Nm = ''
   --AND Parent_Table_Name = ''
   --AND Parent_Level = 0
 ORDER BY 3, 1, 2;

--idx
;WITH LIST_INDEXES
 AS
(
SELECT CASE SO.type
	       WHEN 'TT' THEN SCHEMA_NAME(STT.schema_id)
		  WHEN 'U' THEN SCHEMA_NAME(SO.schema_id)
	  END AS Sch_Name,
       CASE SO.type
	       WHEN 'TT' THEN STT.name
		  WHEN 'U' THEN SO.name
	  END AS ObjectName,
	  SO.type_desc AS Object_Type,
       SI.type_desc,
	  CACC.Column_Count,
	  CARC.Row_Count
  FROM sys.indexes AS SI
       INNER JOIN sys.objects AS SO ON SI.object_id = SO.object_id
	  INNER JOIN sys.schemas AS SS ON SO.schema_id = SS.schema_id
	  LEFT JOIN sys.table_types AS STT ON SO.object_id = STT.type_table_object_id
	  CROSS APPLY (SELECT SUM(row_count) AS Row_Count FROM sys.dm_db_partition_stats AS SP WHERE SO.object_id = SP.object_id AND SP.index_id < 2) CARC
	  CROSS APPLY (SELECT COUNT(1) AS Column_Count FROM sys.columns AS SC WHERE SO.object_id = SC.object_id) CACC
 WHERE 1 = 1
   AND SO.type IN ('TT', 'U')
   --AND SI.type > 0 --0 INDICATES HEAP. UNCOMMENT THIS TO REMOVE THE LIST OF TABLES/TABLE_TYPES HAVING NO INDEXES.  
)
SELECT CONCAT(Sch_Name, '.', ObjectName) AS ObjectName, 
       Object_Type, 
	  Column_Count, 
	  Row_Count, 
	  [Clustered] AS Clustered_Idx_Count, 
	  [Nonclustered] AS NonClustered_Idx_Count, 
	  [CLUSTERED] + [NONCLUSTERED] AS 'No. of Indexes'
  FROM LIST_INDEXES
 PIVOT (COUNT (type_desc) FOR type_desc IN ([Clustered], [Nonclustered])) PVT
 WHERE 1 = 1
   --AND Sch_Name = ''
 ORDER BY Sch_Name, Object_Type DESC, ObjectName
;

--idxDDL
;WITH CREATE_INDEX
AS
(
SELECT DB_NAME() AS database_name,
       sc.name AS [schema_name],
	  t.name AS table_name,
       (SELECT MAX(user_reads) 
          FROM (VALUES (last_user_seek), (last_user_scan), (last_user_lookup)) AS value(user_reads)
	  ) AS last_user_read,
       last_user_update,
	  si.type_desc,
       CASE si.index_id 
	       WHEN 0 THEN N'/* No create statement (Heap) */'
            ELSE CASE is_primary_key 
		            WHEN 1 THEN N'ALTER TABLE ' + QUOTENAME(sc.name) + N'.' + QUOTENAME(t.name) + CHAR(13) + N'ADD CONSTRAINT ' + QUOTENAME(si.name) + N' PRIMARY KEY ' + IIF(si.index_id > 1, N'NON', N'') + N'CLUSTERED '
                      ELSE N'CREATE ' + IIF(si.is_unique = 1, N'UNIQUE ', N'') + IIF(si.index_id > 1, N'NON', N'') + N'CLUSTERED ' + N'INDEX ' + QUOTENAME(si.name) + N' ON ' + QUOTENAME(sc.name) + N'.' + QUOTENAME(t.name) + N' '
                 END
                +
                 /* key def */ N'(' + key_definition + N')' +
                 /* includes */ IIF(include_definition IS NOT NULL, CHAR(13) + N'INCLUDE (' + include_definition + N')', N'') +
                 /* filters */ IIF(filter_definition IS NOT NULL, CHAR(13) + N'WHERE ' + filter_definition, N'') +
                 /* with clause - compression goes here */
                 CASE WHEN row_compression_partition_list IS NOT NULL OR page_compression_partition_list IS NOT NULL 
                      THEN N' WITH (' + CASE WHEN row_compression_partition_list IS NOT NULL
		 	       				     THEN N'DATA_COMPRESSION  =  ROW ' + IIF(psc.name IS NULL, N'', + N' ON PARTITIONS (' + row_compression_partition_list + N')')
		 	       				     ELSE N''
		 	       				END
		 	       			   + IIF(row_compression_partition_list IS NOT NULL AND page_compression_partition_list IS NOT NULL, N', ', N'')
		 	       			   + CASE WHEN page_compression_partition_list IS NOT NULL
		 	       			          THEN N'DATA_COMPRESSION  =  PAGE ' + IIF(psc.name IS NULL, N'', + N' ON PARTITIONS (' + page_compression_partition_list + N')')
                                             ELSE N''
                                        END
                                      + N')'
                      ELSE N''
                 END
                +
                 /* ON where? filegroup? partition scheme? */
                 CHAR(13) + 'ON ' + IIF(psc.name IS NULL, COALESCE(QUOTENAME(fg.name), N''), psc.name + N' (' + partitioning_column.column_name + N')')
                + N';'
       END AS index_create_statement,
       si.index_id,
       si.name AS index_name,
       si.is_unique,
	  si.has_filter,
	  IIF(include_definition IS NOT NULL, 1, 0) AS is_included,
       partition_sums.reserved_in_row_GB,
       partition_sums.reserved_LOB_GB,
       partition_sums.row_count,
       stat.user_seeks,
       stat.user_scans,
       stat.user_lookups,
       user_updates AS queries_that_modified,
       partition_sums.partition_count,
       si.allow_page_locks,
       si.allow_row_locks,
       si.is_hypothetical,       
       si.fill_factor,
       COALESCE(pf.name, '/* Not partitioned */') AS partition_function,
       COALESCE(psc.name, fg.name) AS partition_scheme_or_filegroup,
       t.create_date AS table_created_date,
       t.modify_date AS table_modify_date
  FROM sys.indexes AS si
       INNER JOIN sys.tables AS t ON si.object_id = t.object_id
       INNER JOIN sys.schemas AS sc ON t.schema_id = sc.schema_id
       LEFT JOIN sys.dm_db_index_usage_stats AS stat ON stat.database_id  =  DB_ID() 
             AND si.object_id = stat.object_id 
             AND si.index_id = stat.index_id
       LEFT JOIN sys.partition_schemes AS psc ON si.data_space_id = psc.data_space_id
       LEFT JOIN sys.partition_functions AS pf ON psc.function_id = pf.function_id
       LEFT JOIN sys.filegroups AS fg ON si.data_space_id = fg.data_space_id
       /* Key list */
	  OUTER APPLY (SELECT STUFF (
                                  (SELECT N', ' + QUOTENAME(c.name) +
                                          CASE ic.is_descending_key WHEN 1 THEN N' DESC' ELSE N'' END
                                     FROM sys.index_columns AS ic 
                                          INNER JOIN sys.columns AS c ON ic.column_id = c.column_id  
                                                 AND ic.object_id = c.object_id
                                    WHERE ic.object_id  =  si.object_id
                                      AND ic.index_id = si.index_id
                                      AND ic.key_ordinal > 0
                                    ORDER BY ic.key_ordinal FOR XML PATH(''), TYPE
                                  ).value('.', 'NVARCHAR(MAX)'),
                                  1, 2, ''
                                 ) AS key_definition
                   ) AS keys
	  /* Partitioning Ordinal */
	  OUTER APPLY (SELECT MAX(QUOTENAME(c.name)) AS column_name
                      FROM sys.index_columns AS ic 
                           INNER JOIN sys.columns AS c ON ic.column_id = c.column_id  
                                  AND ic.object_id = c.object_id
                     WHERE ic.object_id  =  si.object_id
                       AND ic.index_id = si.index_id
                       AND ic.partition_ordinal = 1
			    ) AS partitioning_column
	  /* Include list */
       OUTER APPLY (SELECT STUFF (
                                  (SELECT N', ' + QUOTENAME(c.name)
                                     FROM sys.index_columns AS ic 
                                          INNER JOIN sys.columns AS c ON ic.column_id = c.column_id  
                                                 AND ic.object_id = c.object_id
                                    WHERE ic.object_id  =  si.object_id
                                      AND ic.index_id = si.index_id
                                      AND ic.is_included_column  =  1
                                    ORDER BY c.name FOR XML PATH(''), TYPE
                                  ).value('.', 'NVARCHAR(MAX)'),
						    1, 2, ''
                                 ) AS include_definition
                   ) AS includes
	  /* Partitions */
	  OUTER APPLY (SELECT COUNT(*) AS partition_count,
                           CAST(SUM(ps.in_row_reserved_page_count)*8./1024./1024. AS NUMERIC(32,1)) AS reserved_in_row_GB,
                           CAST(SUM(ps.lob_reserved_page_count)*8./1024./1024. AS NUMERIC(32,1)) AS reserved_LOB_GB,
                           SUM(ps.row_count) AS row_count
                      FROM sys.partitions AS p
                           INNER JOIN sys.dm_db_partition_stats AS ps ON p.partition_id = ps.partition_id
                     WHERE p.object_id = si.object_id
                       AND p.index_id = si.index_id
                   ) AS partition_sums
	  /* row compression list by partition */
	  OUTER APPLY (SELECT STUFF (
                                  (SELECT N', ' + CAST(p.partition_number AS VARCHAR(32))
                                     FROM sys.partitions AS p
                                    WHERE p.object_id = si.object_id
                                      AND p.index_id = si.index_id
                                      AND p.data_compression = 1
                                    ORDER BY p.partition_number FOR XML PATH(''), TYPE
                                  ).value('.', 'NVARCHAR(MAX)'),
                                  1, 2, ''
                                 ) AS row_compression_partition_list
                   ) AS row_compression_clause
	  /* data compression list by partition */
	  OUTER APPLY (SELECT STUFF (
                                  (SELECT N', ' + CAST(p.partition_number AS VARCHAR(32))
                                     FROM sys.partitions AS p
                                    WHERE p.object_id  =  si.object_id
                                      AND p.index_id = si.index_id
                                      AND p.data_compression = 2
                                    ORDER BY p.partition_number FOR XML PATH(''), TYPE
                                  ).value('.', 'NVARCHAR(MAX)'),
                                  1, 2, ''
                                 ) AS page_compression_partition_list
                   ) AS page_compression_clause
 WHERE 1 = 1
   AND si.type IN (0, 1, 2) /* heap, clustered, nonclustered */
)
SELECT *
  FROM CREATE_INDEX 
 WHERE 1 = 1
   --AND [schema_name] = 'IMSWeb'
   AND table_name  =  ''
   --AND is_unique = 0
   --AND has_filter = 1
   --AND is_included = 1
 ORDER BY table_name, index_id
OPTION (RECOMPILE);

--idxnames
;WITH IDX_COLUMNS
 AS
(
SELECT CASE SO.type
	       WHEN 'TT' THEN SCHEMA_NAME(STT.schema_id)
		  WHEN 'U' THEN SCHEMA_NAME(SO.schema_id)
	  END AS Sch_Name,
       CASE SO.type
	       WHEN 'TT' THEN STT.name
		  WHEN 'U' THEN SO.name
	  END AS ObjectName,
	  SO.type_desc AS Object_Type,
	  SI.name AS Idx_Name,
	  SI.type_desc AS Idx_Type,
	  IIF(SI.is_unique = 1, 'YES', 'NO') AS Is_Unique,
	  IIF(SI.is_disabled = 1, 'YES', 'NO') AS Is_Disabled,	  
	  IIF(SI.is_primary_key = 1, 'YES', 'NO') AS Is_Primary_Key,
	  IIF(SI.is_unique_constraint = 1, 'YES', 'NO') AS Is_Unique_Constraint,
	  IIF(SC.is_identity = 1, 'YES', 'NO') AS Is_Identity,
	  IIF(IC.is_included_column = 1, 'YES', 'NO') AS Is_Included_Column,
	  COL_NAME(IC.object_id, IC.column_id) AS Column_Name,
	  IC.index_column_id AS Index_Column_ID,	  
	  ST.name AS Data_Type,
	  SC.max_length AS Max_Length, 
	  SC.precision AS Precision, 
	  SC.scale AS Scale, 
	  CASE WHEN SC.is_nullable = 1 THEN 'YES' ELSE 'NO' END AS Is_Nullable,
	  CA.Row_Cnt
  FROM sys.indexes AS SI
       INNER JOIN sys.objects AS SO ON SI.object_id = SO.object_id	   
	  INNER JOIN sys.index_columns AS IC ON SI.index_id = IC.index_id
	         AND SO.object_id = IC.object_id
	  INNER JOIN sys.columns AS SC ON SO.object_id = SC.object_id
	         AND IC.column_id = SC.column_id
	  INNER JOIN sys.types AS ST ON SC.system_type_id = ST.system_type_id
	         AND SC.user_type_id = ST.user_type_id
       LEFT JOIN sys.table_types AS STT ON SC.object_id = STT.type_table_object_id
	  CROSS APPLY (SELECT ISNULL(SUM(row_count), 0) AS Row_Cnt FROM sys.dm_db_partition_stats AS SP WHERE SO.object_id = SP.object_id AND SP.index_id < 2) CA
 WHERE 1 = 1
   AND SO.type IN ('TT', 'U')
   --AND SI.type = ; 4 = Spatial; 5 = Clustered columnstore index; 6 = Nonclustered columnstore index; 7 = Nonclustered hash index)
)
SELECT * 
  FROM IDX_COLUMNS
 WHERE 1 = 1
   --AND Sch_Name = ''
   --AND ObjectName = ''
 ORDER BY Sch_Name, Object_Type DESC, ObjectName, Idx_Type, Idx_Name, Index_Column_ID
;

--inc
SELECT CASE WHEN DATA_TYPE LIKE '%CHAR' THEN ',CASE WHEN S.' + COLUMN_NAME + ' > '''' THEN S.' + COLUMN_NAME + ' ELSE ''-'' END AS ' + COLUMN_NAME
            WHEN DATA_TYPE LIKE '%INT' THEN ',CASE WHEN S.' + COLUMN_NAME + ' IS NOT NULL THEN S.' + COLUMN_NAME + ' ELSE 0 END AS ' + COLUMN_NAME
            WHEN DATA_TYPE = 'DECIMAL' THEN ',CASE WHEN S.' + COLUMN_NAME + ' IS NOT NULL THEN S.' + COLUMN_NAME + ' ELSE 0 END AS ' + COLUMN_NAME
            WHEN DATA_TYPE = 'NUMERIC' THEN ',CASE WHEN S.' + COLUMN_NAME + ' IS NOT NULL THEN S.' + COLUMN_NAME + ' ELSE 0 END AS ' + COLUMN_NAME
            WHEN DATA_TYPE = 'DATETIME' THEN ',CASE WHEN S.' + COLUMN_NAME + ' > '''' THEN S.' + COLUMN_NAME + ' ELSE ''1900-01-01 00:00:00.001'' END AS ' + COLUMN_NAME
            ELSE ',S.' + COLUMN_NAME 
	   END
  FROM INFORMATION_SCHEMA.COLUMNS 
 WHERE TABLE_NAME = '' 
;

--jobhelp
EXEC msdb..sp_help_job @job_name = '',
                       @job_aspect = 'JOB';

--jobpx
SELECT j.name AS 'job_name',
       js.step_id,
       js.step_name,
       js.subsystem,
       js.last_run_date,
       js.proxy_id,
       px.name AS 'proxy_name'
  FROM msdb.dbo.sysjobsteps AS js
       LEFT JOIN msdb.dbo.sysproxies AS px ON js.proxy_id = px.proxy_id
       LEFT JOIN msdb.dbo.sysjobs AS j ON js.job_id = j.job_id
 WHERE 1 = 1
   AND js.proxy_id > 0
   --AND j.name = ''
   --AND px.name = ''
 ORDER BY 1, 2;

--jobrun
USE msdb
GO

SET NOCOUNT ON;

DECLARE @iJEH          TINYINT = 1, --Indicates number of runs for a job based on the date
        @iStepID       TINYINT, --If NULL, retrieves all the steps for a given job
        @iRunStatus    TINYINT, --If NULL, retrieves all the statuses for a given job
        @iCharPosition TINYINT,
        @dtJEHDate     DATE,
        @sJobsNameList VARCHAR(1000) = ''; --Enter a comma-separated list of job names        

--Used to hold list of SQL Agent Job names to process
IF OBJECT_ID('tempdb..#JobsNameList') IS NOT NULL DROP TABLE tempdb..#JobsNameList;
CREATE TABLE #JobsNameList 
(
 job_name VARCHAR(128),
 run_date DATE
);

--Process list
SET @sJobsNameList = @sJobsNameList + ',';

WHILE CHARINDEX(',', @sJobsNameList) > 0
BEGIN
	SET @iCharPosition = CHARINDEX(',', @sJobsNameList)
	INSERT INTO #JobsNameList (job_name)
	SELECT LTRIM(RTRIM(LEFT(@sJobsNameList, @iCharPosition - 1)));
	SET @sJobsNameList = STUFF(@sJobsNameList, 1, @iCharPosition, '');
END  -- While loop

;WITH JEH
AS
(
SELECT j.name AS job_name,
       ROW_NUMBER() OVER(PARTITION BY j.name ORDER BY j.name, CA.run_date DESC) AS [nRun(s)],
       CA.run_date
  FROM dbo.sysjobhistory AS h
       INNER JOIN dbo.sysjobs AS j ON h.job_id = j.job_id
       INNER JOIN #JobsNameList AS jnl ON j.name = jnl.job_name
       CROSS APPLY (SELECT CAST(CONVERT(VARCHAR(10), h.run_date, 101) AS DATE) AS run_date) CA
 GROUP BY j.name, CA.run_date
),
LastRun
AS
(
SELECT JEH.job_name, MIN(JEH.run_date) AS Earliest_Run_Date
  FROM JEH
 WHERE [nRun(s)] = IIF(@iJEH > [nRun(s)], [nRun(s)], @iJEH)
 GROUP BY JEH.job_name
)
UPDATE JNL
   SET run_date = Earliest_Run_Date
  FROM LastRun AS LR
       INNER JOIN #JobsNameList AS JNL ON LR.job_name = JNL.job_name

--SELECT * FROM #JobsNameList;

SELECT j.name AS JobName,
       --j.description AS JobDescription,
       h.step_id AS StepID,
       h.step_name AS StepName,
       js.subsystem,
       SD.StartDate,
       STUFF(STUFF(RIGHT('000000' + CAST (h.run_time AS VARCHAR(6)),6),5,0,':'),3,0,':') StartTime,
       TRY_CONVERT(TIME(0), STR(FLOOR(h.run_duration / 10000), 2, 0)
                          + ':' + RIGHT(STR(FLOOR(h.run_duration / 100), 6, 0), 2)
                          + ':' + RIGHT(STR(h.run_duration), 2)) AS [ExecutionTime (HH:MM:SS)],
       CASE h.run_status
            WHEN 0 THEN 'Failed'
            WHEN 1 THEN 'Succeeded'
            WHEN 2 THEN 'Retry'
            WHEN 3 THEN 'Cancelled'
            WHEN 4 THEN 'In Progress'
       END AS ExecutionStatus,
       js.command,
       js.database_name,
       js.output_file_name,
       h.message MessageGenerated
  FROM dbo.sysjobhistory AS h
       INNER JOIN dbo.sysjobs AS j ON h.job_id = j.job_id
       INNER JOIN dbo.sysjobsteps AS js ON j.job_id = js.job_id
              AND h.step_id = js.step_id
       INNER JOIN #JobsNameList AS jnl ON j.name = jnl.job_name
	  CROSS APPLY (SELECT TRY_CAST(STR(h.run_date,8, 0) AS DATE) AS StartDate) AS SD
 WHERE 1 = 1
   AND h.step_id = COALESCE(@iStepID, h.step_id)
   AND h.run_status = COALESCE(@iRunStatus, h.run_status)
   AND SD.StartDate >= jnl.run_date
 ORDER BY JobName, SD.StartDate DESC, StartTime DESC, StepID;

--jobs
USE msdb;
GO

SET NOCOUNT ON;

DECLARE @iStepID       TINYINT = NULL,     --IF NULL FETCH ALL THE STEPS ASSOCIATED WITH A JOB, ELSE FETCH THE SPECIFIED STEP DETAILS TIED TO A JOB.
        @iProxyID      TINYINT = NULL,     --IF 0 FETCH ONLY THOSE JOBS THAT HAVE PROXIES ASSOCIATED WITH IT.
        @sFreqType     VARCHAR(10) = NULL, --DAILY/WEEKLY/MONTHLY etc
        @sSubSystem    VARCHAR(10) = NULL, --TSQL/SSIS/CmdExec/PowerShell etc
        @sJobsNameList VARCHAR(1000) = '', --IF BLANK FETCH ALL JOBS, ELSE FETCH THE SPECIFIED JOB DETAILS. ENTER A COMMA-SEPARATED LIST OF JOB NAMES.
        @iCharPosition TINYINT;

--Used to hold list of SQL Agent Job names to process
IF OBJECT_ID('tempdb..#JobsNamesList') IS NOT NULL DROP TABLE tempdb..#JobsNamesList;
CREATE TABLE #JobsNamesList 
(
 job_name VARCHAR(128)
);

--Process list
SET @sJobsNameList += ',';

WHILE CHARINDEX(',', @sJobsNameList) > 0
BEGIN
	SET @iCharPosition = CHARINDEX(',', @sJobsNameList)
	INSERT INTO #JobsNamesList (job_name)
	SELECT LTRIM(RTRIM(LEFT(@sJobsNameList, @iCharPosition - 1)));
	SET @sJobsNameList = STUFF(@sJobsNameList, 1, @iCharPosition, '');
END  -- While loop

--SELECT * FROM #JobsNamesList;

SELECT j.name AS job_name,
       px.name AS proxy_name,
       j.description AS job_description,
	  j.start_step_id,
       js.step_id,
       js.step_name,
	  ss.name AS schedule_name,
       ft.freq_type,
       fi.freq_interval,
	  fst.freq_subday_type,
/*       
       ss.freq_subday_interval,
       ss.freq_relative_interval,
       ss.freq_recurrence_factor,
       ss.active_start_date,
       ss.active_end_date,
       ss.active_start_time,
       ss.active_end_time,
--*/
       js.subsystem,
       js.command,
       pkg.ssis_package_path,
       js.database_name,
       js.output_file_name,
       j.date_created AS job_created_on,
       j.date_modified AS job_modified_on,
       j.version_number AS job_version_number,
       ss.date_created AS schedule_created_on,
       ss.date_modified AS schedule_modified_on,
       ss.version_number AS schedule_version_number
  FROM dbo.sysjobs AS j
       INNER JOIN #JobsNamesList AS jnl ON j.name LIKE COALESCE(CONCAT('%', jnl.job_name, '%'), j.name)
       LEFT JOIN dbo.sysjobsteps AS js ON j.job_id = js.job_id
       LEFT JOIN dbo.sysjobschedules AS jss ON j.job_id = jss.job_id
       LEFT JOIN dbo.sysschedules AS ss ON jss.schedule_id = ss.schedule_id
       LEFT JOIN dbo.sysproxies AS px ON js.proxy_id = px.proxy_id
       --Removing all the characters in CMD starting from CMD'" /SERVER "*" /CHECKPOINTING OFF /REPORTING E' in the cmd to extract the anme of the SSIS package which is called by a step in a SQL Job
       OUTER APPLY (SELECT STUFF(js.command, CHARINDEX('" /SERVER', js.command), LEN(js.command), '') AS cleanup1) AS p1
       --Removing all instances of '"\' & '/SQL ' & '\"' from cleanup1 to extract the name of the SSIS Package and the Folder under which it is present
       OUTER APPLY (SELECT '\' + REPLACE(REPLACE(REPLACE(REPLACE(p1.cleanup1, '"\', ''), '/SQL ', ''), '\"', ''), '"', '') AS ssis_package_path) AS pkg
	  OUTER APPLY (SELECT CASE ss.freq_relative_interval
                                WHEN 1  THEN 'first'
                                WHEN 2  THEN 'second'
                                WHEN 4  THEN 'third'
                                WHEN 8  THEN 'fourth'
                                WHEN 16 THEN 'last'
                           END AS freq_relative_interval
                   ) AS fri
       OUTER APPLY (SELECT CASE ss.freq_type
                                WHEN 1   THEN 'Once'
                                WHEN 4   THEN 'Daily'
                                WHEN 8   THEN 'Weekly'
                                WHEN 16  THEN 'Monthly'
                                WHEN 32  THEN 'Monthly, Relative'
                                WHEN 64  THEN 'Starts when SQL Server Agent service starts'
                                WHEN 128 THEN 'Runs when computer is idle'
                           END AS freq_type
                   ) AS ft
        OUTER APPLY (SELECT CASE WHEN ss.freq_type IN (1, 64, 128) THEN 'Unused'
                                 --Daily
                                 WHEN ss.freq_type = 4 THEN CONCAT('Every ', freq_interval, ' day(s)')
                                 --Weekly
                                 WHEN ss.freq_type = 8 THEN CASE ss.freq_interval
                                                                 WHEN 1  THEN 'Every Sunday of the week'
                                                                 WHEN 2  THEN 'Every Monday of the week'
                                                                 WHEN 4  THEN 'Every Tuesday of the week'
                                                                 WHEN 8  THEN 'Every Wednesday of the week'
                                                                 WHEN 16 THEN 'Every Thursday of the week'
                                                                 WHEN 32 THEN 'Every Friday of the week'
                                                                 WHEN 64 THEN 'Every Saturday of the week'
                                                                 ELSE 'Multiple days in a week'
                                                                 /*
                                                                 WHEN 3 (1+2) THEN Every Sunday, Monday of the week
													WHEN 9 (1+4+8) THEN Every Sunday, Tuesday, Wednesday of the week
													WHEN 62 (2+4+8+16+32) THEN Every Sunday, Monday, Tuesday, Wednesday, Thursday & Friday of the week
													....so on and so forth
                                                                 */
                                                            END
                                 --Monthly
                                 WHEN ss.freq_type = 16 THEN CONCAT('On the ',
                                                                    ss.freq_interval,
                                                                    CASE ss.freq_interval
                                                                         WHEN 1  THEN 'st'
                                                                         WHEN 21 THEN 'st'
                                                                         WHEN 31 THEN 'st'
                                                                         WHEN 2  THEN 'nd'
                                                                         WHEN 22 THEN 'nd'
                                                                         WHEN 3  THEN 'rd'
                                                                         WHEN 23 THEN 'rd'
                                                                         ELSE 'th'
                                                                    END,
                                                                    ' day of the month')
                                 --Monthly, relative (also uses freq_relative_interval)
                                 WHEN ss.freq_type = 32 THEN  CONCAT('On the ',
                                                                     fri.freq_relative_interval,
                                                                     SPACE(1),
                                                                     CASE ss.freq_interval
                                                                          WHEN 1  THEN 'Sunday'
                                                                          WHEN 2  THEN 'Monday'
                                                                          WHEN 3  THEN 'Tuesday'
                                                                          WHEN 4  THEN 'Wednesday'
                                                                          WHEN 5  THEN 'Thursday'
                                                                          WHEN 6  THEN 'Friday'
                                                                          WHEN 7  THEN 'Saturday'
                                                                          WHEN 8  THEN 'day'
                                                                          WHEN 9  THEN 'weekday'
                                                                          WHEN 10 THEN 'weekend day'
                                                                     END,
                                                                     ' of the month'
                                                                    )
                            END AS freq_interval
                   ) AS fi
        OUTER APPLY (SELECT STUFF(STUFF(RIGHT(REPLICATE('0', 6) + CAST(ss.active_start_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS active_start_time) AS ast
        OUTER APPLY (SELECT CASE WHEN ss.freq_subday_type = 2 THEN CONCAT(' every ', freq_subday_interval, ' seconds starting at ', ast.active_start_time)
                                 WHEN ss.freq_subday_type = 4 THEN CONCAT(' every ', freq_subday_interval, ' minutes starting at ', ast.active_start_time)
                                 WHEN ss.freq_subday_type = 8 THEN CONCAT(' every ', freq_subday_interval, ' hours starting at ',   ast.active_start_time)
                                 ELSE ' starting at ' + ast.active_start_time
                            END AS freq_subday_type
                    ) AS fst
 WHERE 1 = 1
   AND js.step_id >= COALESCE(@iStepID, js.step_id)
   AND COALESCE(ft.freq_type, '') LIKE COALESCE(CONCAT('%', @sFreqType, '%'), ft.freq_type)
   AND js.subsystem LIKE COALESCE(CONCAT('%', @sSubSystem, '%'), js.subsystem)
   AND COALESCE(px.proxy_id, 0) > COALESCE(@iProxyID, -1)
 ORDER BY j.name, js.step_id;

--jobstatus
SET NOCOUNT ON;
/*
DECLARE @job_id UNIQUEIDENTIFIER = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = '');    
EXEC master.dbo.xp_sqlagent_enum_jobs 1, 'sa', @job_id;
--*/
SELECT j.NAME AS job_name, 
       ISNULL(ja.last_executed_step_id, 0) + 1 AS current_executed_step_id, 
       js.step_name,
	  js.subsystem,
	  js.command,
	  ja.start_execution_date,
	  DATEDIFF(mi, ja.start_execution_date, GETDATE()) AS [Execution_Time (Mins)]
  FROM msdb.dbo.sysjobactivity AS ja 
       LEFT JOIN msdb.dbo.sysjobhistory AS jh ON ja.job_history_id = jh.instance_id 
       INNER JOIN msdb.dbo.sysjobs AS j ON ja.job_id = j.job_id 
       INNER JOIN msdb.dbo.sysjobsteps AS js ON ja.job_id = js.job_id 
              AND ISNULL(ja.last_executed_step_id, 0) + 1 = js.step_id 
 WHERE ja.session_id = (SELECT TOP 1 session_id
                          FROM msdb.dbo.syssessions 
                         ORDER BY agent_start_date DESC) 
   AND ja.start_execution_date IS NOT NULL 
   AND ja.stop_execution_date IS NULL
   --AND j.NAME LIKE '%%'
 ORDER BY job_name;

--lac
;WITH SUS
AS
(
SELECT last_user_seek,
       last_user_scan,
       last_user_lookup,
       [object_id],
       database_id,
       last_user_update, COALESCE(last_user_seek, last_user_scan, last_user_lookup,0) AS null_indicator
  FROM sys.dm_db_index_usage_stats
 WHERE database_id = DB_ID()
),
CTE
AS
(
SELECT MAX(up.last_user_read) AS 'last_read',
       MAX(up.last_user_update) AS 'last_write',
       UP.[object_id]
  FROM SUS 
       UNPIVOT (last_user_read FOR read_date IN (last_user_seek, last_user_scan, last_user_lookup, null_indicator)) AS UP
 GROUP BY UP.[object_id]
)
SELECT DISTINCT OBJECT_SCHEMA_NAME(t.[object_id]) AS 'Schema',
       OBJECT_NAME(t.[object_id]) AS 'Table/View Name',
       CASE WHEN rw.last_read > 0 THEN rw.last_read END AS last_read,
       rw.last_write,
       t.[object_id]
 FROM sys.tables AS t
      LEFT JOIN CTE AS rw ON rw.[object_id] = t.[object_id]
WHERE OBJECT_SCHEMA_NAME(t.[object_id]) = 'AUDIT'
ORDER BY last_read, last_write, [Table/View Name];

--nbr
SELECT TOP (65536) ROW_NUMBER() OVER (ORDER BY(SELECT 1)) AS Nbrs
  FROM sys.all_columns ac1 
       CROSS JOIN sys.all_columns ac2
;

--PkgInfo
SELECT Name, CONVERT(XML,PkgData) AS PackageSource
  FROM msdb.dbo.sysssispackages
       CROSS APPLY (SELECT CONVERT(VARBINARY(MAX),PackageData) AS PkgData) AS CA
 WHERE 1 = 1
   --AND PkgData LIKE '%your_object_name%'
   --AND name = ''
 ORDER BY 1;

--proc
SELECT OBJECT_SCHEMA_NAME(OBJECT_ID) AS Schema_Nm,
       name AS Proc_Nm,
       OBJECT_DEFINITION(OBJECT_ID) AS Proc_Definition,
	  create_date AS Created_Date, 
	  modify_date AS Modified_Date
  FROM sys.procedures
 WHERE 1 = 1
   --AND OBJECT_SCHEMA_NAME(OBJECT_ID) IN ('')
   --AND name LIKE '%%'
 ORDER BY 1, 2
;

--param
;WITH LIST_PARAMETERS
AS
(
SELECT OBJECT_SCHEMA_NAME(SO.object_id) AS SchemaName,
       SO.name AS ObjectName,
	  SO.type_desc AS Object_Type,
	  SPA.name AS Parameter_Name,
	  SPA.parameter_id AS Parameter_Order,
	  TYPE_NAME(SPA.user_type_id) AS Data_Type,
	  IIF(SPA.name IS NULL, NULL, IIF(SPA.system_type_id = SPA.user_type_id, 'NO', 'YES')) AS Is_User_Defined,
	  SPA.Max_Length,
	  SPA.Precision,
	  SPA.Scale,
	  IIF(SPA.name IS NULL, NULL, IIF(SPA.is_nullable = 1, 'YES', 'NO')) AS Is_Nullable,
	  IIF(SPA.name IS NULL, NULL, IIF(SPA.is_output = 1, 'YES', 'NO')) AS Is_Output,
	  IIF(SPA.name IS NULL, NULL, IIF(SPA.is_readonly = 1, 'YES', 'NO')) AS Is_Readonly,
	  IIF(SPA.name IS NULL, NULL, IIF(SPA.has_default_value = 1, 'YES', 'NO')) AS Is_Default,
	  IIF(SPA.name IS NULL, NULL, ISNULL(SPA.default_value, '-')) AS Default_Value
  FROM sys.objects AS SO
       INNER JOIN sys.parameters AS SPA ON SO.object_id = SPA.object_id
 WHERE SO.type IN ('P','FN','TF', 'IF', 'IS', 'AF','PC', 'FS', 'FT')
)
SELECT *
  FROM LIST_PARAMETERS
 WHERE 1 = 1
   AND SchemaName = ''
   AND ObjectName IN ('')
 ORDER BY 1, 2, 4;

--procref
SELECT CONCAT(RFG.Referenced_Schema_Name, '.', RFG.Referenced_Entity_Name) AS Referenced_Object_Name,
	  COALESCE(SOG.type_desc, RFG.referenced_class_desc) AS Referenced_Object_Type,
	  CONCAT(OBJECT_SCHEMA_NAME(RFD.referencing_id), '.', OBJECT_NAME(RFD.referencing_id)) AS Referencing_Object_Name,
	  COALESCE(SOD.type_desc, RFD.referenced_class_desc) AS Referencing_Object_Type
  FROM sys.procedures AS SP
       LEFT JOIN sys.sql_expression_dependencies AS RFG ON SP.object_id = RFG.referencing_id
       LEFT JOIN sys.objects AS SOG ON RFG.referenced_id = SOG.object_id
	  LEFT JOIN sys.sql_expression_dependencies AS RFD ON SP.object_id = RFD.referenced_id
	  LEFT JOIN sys.objects AS SOD ON RFD.referencing_id = SOD.object_id
 WHERE 1 = 1
   AND OBJECT_SCHEMA_NAME(SP.OBJECT_ID) IN ('')
   AND SP.name LIKE '%%'
 ORDER BY 2, 1, 4, 3
;

--procref1
;WITH PROC_REF
AS
(
SELECT OBJECT_SCHEMA_NAME(SP.OBJECT_ID) AS Proc_Schema_Name,
       SP.name AS Proc_Name,
	  CONCAT(OBJECT_SCHEMA_NAME(SP.OBJECT_ID), '.', SP.name, ' is calling') AS Proc_Dependencies,
       CONCAT(RFG.Referenced_Schema_Name, '.', RFG.Referenced_Entity_Name) AS ObjectName,
	  COALESCE(SOG.type_desc, RFG.referenced_class_desc) AS Object_Type
  FROM sys.procedures AS SP
       LEFT JOIN sys.sql_expression_dependencies AS RFG ON SP.object_id = RFG.referencing_id
       LEFT JOIN sys.objects AS SOG ON RFG.referenced_id = SOG.object_id 
 UNION
SELECT OBJECT_SCHEMA_NAME(SP.OBJECT_ID) AS Proc_Schema_Name,
       SP.name AS Proc_Name,
	  CONCAT(OBJECT_SCHEMA_NAME(SP.OBJECT_ID), '.', SP.name, ' is called by') AS Proc_Dependencies,
	  CONCAT(OBJECT_SCHEMA_NAME(RFD.referencing_id), '.', OBJECT_NAME(RFD.referencing_id)) AS ObjectName,
	  COALESCE(SOD.type_desc, RFD.referenced_class_desc) AS Object_Type
  FROM sys.procedures AS SP
	  LEFT JOIN sys.sql_expression_dependencies AS RFD ON SP.object_id = RFD.referenced_id
	  LEFT JOIN sys.objects AS SOD ON RFD.referencing_id = SOD.object_id
)
SELECT Proc_Dependencies,
       ObjectName,
       Object_Type
  FROM PROC_REF
 WHERE 1 = 1
   AND Proc_Schema_Name IN ('')
   AND Proc_Name LIKE '%%'
 ORDER BY 1, 3, 2
;

--ref
SELECT DMV.referencing_schema_name, 
       DMV.referencing_entity_name, 
	  SO.type_desc
  FROM sys.dm_sql_referencing_entities('schema_name.referenced_entity_name', 'referenced_class') AS DMV
       INNER JOIN sys.objects AS SO ON DMV.referencing_id = SO.object_id
--<referenced_class> ::= {OBJECT | TYPE | XML_SCHEMA_COLLECTION | PARTITION_FUNCTION}
;

--rowcnt
;WITH Total_Rows
AS
(
SELECT SS.name AS Sch_Name,
       ST.name AS Table_Name, 
       SUM(SP.row_count) AS Row_Count
  FROM sys.tables AS ST
	  INNER JOIN sys.schemas AS SS ON ST.schema_id = SS.schema_id
	  LEFT JOIN sys.dm_db_partition_stats AS SP ON ST.object_id = SP.object_id AND SP.index_id < 2
 WHERE 1 = 1
   --AND SS.name = ''
   --AND ST.name IN ('')
 GROUP BY SS.name, ST.name
)
SELECT * 
  FROM Total_Rows
 WHERE 1 = 1
   --AND Row_Count > 0
 ORDER BY 1, 2;

--schedule
EXEC msdb..sp_help_jobschedule @job_name = '';

--sendmail
USE msdb
GO
SET NOCOUNT ON;
SELECT p.[name] AS Profile_Name,
       p.[description] AS [Description],
       a.[name] AS Account_Name,
       a.[description] AS Account_Description,
       a.[Email_Address],
       a.[Display_Name],
       a.[Replyto_Address],
       s.[Servertype],
       s.[Servername],
       s.[Port],
       s.[Username],
       s.[Credential_ID],
       s.[Use_Default_Credentials],
       s.[Enable_SSL],
       s.[Flags],
       s.[Timeout],
       s.[Last_Mod_User]
  FROM dbo.sysmail_profile AS p 
       INNER JOIN dbo.sysmail_profileaccount AS pa on p.profile_id = pa.profile_id 
       INNER JOIN dbo.sysmail_account AS a on pa.account_id = a.account_id 
       INNER JOIN dbo.sysmail_server AS s on a.account_id = s.account_id
 WHERE 1 = 1
   --AND p.[name] LIKE '%%'
 ORDER BY 1;

--sis
/*
This is an easy way to look through the sources of all objects in the database
if you need to find particular string. This script can be used, for example,
to find references of some specific object by other objects. Depending on the
size of your database you might want to limit the search scope to particular 
object type. Just comment unneeded object types in WHERE statement.
Enter search string between %% marks in @SearchPattern initialisation statement.
When you get the results you can copy object name from "FullName" column and
use SSMSBoost to quickly locate it in the object explorer, or you can continue
searching in results using "Find in ResultsGrid" function.
This script is provided to you by SSMSBoost as is. Improvements and comments are welcome.
Redistribution with reference to SSMSBoost project website is welcome.
SSMSBoost team, 2014
*/
DECLARE @SearchPattern NVARCHAR(128) = '%%';
SELECT SCHEMA_NAME(o.schema_id) + '.' + o.[name] AS FullName,
	  o.[type],
	  OBJECT_DEFINITION(object_id) AS [Source]
  FROM sys.objects AS o
 WHERE LOWER(OBJECT_DEFINITION(o.object_id)) LIKE LOWER(@SearchPattern)
   AND o.[type] IN (
		'C', --- = Check constraint
		'D', --- = Default (constraint or stand-alone)
		'P', --- = SQL stored procedure
		'FN',--- = SQL scalar function
		'R', --- = Rule
		'RF',--- = Replication filter procedure
		'TR',--- = SQL trigger (schema-scoped DML trigger, or DDL trigger at either the database or server scope)
		'IF',--- = SQL inline table-valued function
		'TF',--- = SQL table-valued function
		'V') --- = View
 ORDER BY FullName;

--ssis
SELECT J.name AS JobName,
       JS.step_id AS Step,
       JS.command AS SSISLocation,
       CASE JS.last_run_outcome
            WHEN 0 THEN 'Failed'
            WHEN 1 THEN 'Succeeded'
            WHEN 2 THEN 'Retry'
            WHEN 3 THEN 'Canceled'
            WHEN 5 THEN 'Unknown' -- In Progress
	  END AS LastRunStatus,
	  STUFF(STUFF(RIGHT('000000' + CAST(JS.last_run_duration AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS Run_Time
  FROM msdb.dbo.sysjobs AS J
       INNER JOIN msdb.dbo.sysjobsteps AS JS ON J.job_id = JS.job_id
 WHERE 1 = 1
   AND JS.subsystem = 'SSIS'
 ORDER BY 1
;

--ssisjob
SELECT J.name AS job_name,
       JS.step_name,
       JS.subsystem,
       JS.database_name,
       JA.Start_execution_date AS start_time,
       DATEDIFF(ss, JA.Start_execution_date, GETDATE()) as [Has_been_running (in sec)]
  FROM msdb.dbo.sysjobactivity JA
       INNER JOIN msdb.dbo.sysjobs J ON J.job_id = JA.job_id
       INNER JOIN msdb.dbo.sysjobsteps JS ON JA.job_id = JS.job_id
 WHERE job_history_id IS NULL
   AND start_execution_date IS NOT NULL
   --AND J.name = ''
 ORDER BY start_execution_date;

--ssispkg
WITH FOLDERS 
  AS
(
--Capture root node
SELECT CAST(PF.foldername AS VARCHAR(MAX)) AS FolderPath,
	  PF.folderid,
	  PF.parentfolderid,
	  PF.foldername
  FROM msdb.dbo.sysssispackagefolders PF
 WHERE PF.parentfolderid IS NULL
--Build recursive hierarchy
 UNION ALL
SELECT CAST(F.FolderPath + '\' + PF.foldername AS VARCHAR(MAX)) AS FolderPath,
	  PF.folderid,
	  PF.parentfolderid,
	  PF.foldername
  FROM msdb.dbo.sysssispackagefolders PF
       INNER JOIN FOLDERS F ON F.folderid = PF.parentfolderid
),
PACKAGES AS
(
--Pull information about stored SSIS packages
SELECT P.name AS PackageName,
	  P.createdate,
       P.id AS PackageId,
       P.description as PackageDescription,
       P.folderid,
       P.packageFormat,
       P.packageType,
       P.vermajor,
       P.verminor,
       P.verbuild,
       suser_sname(P.ownersid) AS ownername
  FROM msdb.dbo.sysssispackages P
)
SELECT P.PackageName,
	  F.FolderPath,
       P.CreateDate,
       P.PackageFormat,
       CASE P.packageType
	       WHEN 1 THEN 'SQL Server Import and Export Wizard'
		  WHEN 3 THEN 'SQL Server Replication'
		  WHEN 5 THEN 'SSIS Designer'
		  WHEN 6 THEN 'Maintenance Plan Designer or Wizard'
		  ELSE 'Default'
	  END AS PackageType,
       P.Vermajor,
       P.Verminor,
       P.Verbuild,
       P.OwnerName,
       P.PackageId
  FROM FOLDERS F
       INNER JOIN PACKAGES P ON P.folderid = F.folderid
 WHERE 1 = 1
 --Uncomment this if you want to filter out the native Data Collector packages
   AND F.FolderPath <> '\Data Collector'
   AND PackageName = ''
 ORDER BY 1;

--start
USE msdb;
GO
 
SET NOCOUNT ON;
 
/*
SELECT j.name, js.step_id, js.step_name, js.subsystem 
  FROM dbo.sysjobs AS j
       INNER JOIN dbo.sysjobsteps AS js on j.job_id = js.job_id
 WHERE 1 = 1
 ORDER BY 1, 2;
--*/
 
EXEC dbo.sp_start_job @job_name = N'',
                      @step_name = NULL;

--stats
SELECT name AS IndexName,
       STATS_DATE(object_id, stats_id) AS LastStatisticsUpdate
  FROM sys.stats
 WHERE object_id = OBJECT_ID('TABLENAME')
   AND name = 'INDEXNAME';

--stop
USE msdb;
GO
SET NOCOUNT ON;
/*
SELECT * 
  FROM dbo.sysjobs
 WHERE 1 = 1
 ORDER BY 3;
--*/
EXEC dbo.sp_stop_job N'';

--syn
SELECT Name, 
       COALESCE(PARSENAME(base_object_name, 4), @@servername) AS ServerName, 
       COALESCE(PARSENAME(base_object_name, 3), DB_NAME(DB_ID())) AS DBName, 
       COALESCE(PARSENAME(base_object_name, 2), SCHEMA_NAME(SCHEMA_ID())) AS SchemaName, 
       PARSENAME(base_object_name, 1) AS objectName 
  FROM sys.synonyms
 WHERE 1 = 1
   AND name = ''
 ORDER BY 1, 2, 3, 4, 5;

--tblinfo
;WITH LIST_TABLES
AS
(
SELECT CONCAT(SCHEMA_NAME(ST.SCHEMA_ID), '.', ST.name) AS Table_Name,
	  CASP.Row_Count,
	  ST.max_column_id_used AS Column_Count,
	  OACC.Computed_Column_Count,
	  OADC.Default_Constraint_Count,
	  IIF(OBJECTPROPERTY(ST.object_id, 'TableHasPrimaryKey') = 1, 'YES', 'NO') AS Primary_Key_Exists,
	  IIF(OBJECTPROPERTY(ST.object_id, 'TableHasClustIndex') = 1, 1, 0) AS Clustered_Idx_Count,
	  OAIX.NonClustered_Idx_Count,
	  IIF(OBJECTPROPERTY(ST.object_id, 'TableHasIdentity') = 1, 'YES', 'NO') AS Identity_Column_Exists,
	  IIF(IC.object_id IS NOT NULL, last_value, 'N/A') AS Last_Value,
	  COALESCE(OAFK.Table_is_referenced_by_Foreign_Key, '-') AS Table_is_referenced_by_Foreign_Key,
	  COALESCE(OAFK.Foreign_Key_References_Count, 0) AS Foreign_Key_References_Count,
	  COALESCE(OAREF.Referencing_Entity_Name, 'N/A') AS Referencing_Entity_Name,
	  COALESCE(OAREF.Referencing_Entity_Type, 'SQL_STORED_PROCEDURE') AS Referencing_Entity_Type,
	  COALESCE(OAREF.Referencing_Entities_Count, 0) AS Referencing_Entities_Count,
	  ST.create_date AS Table_Created_Date,
	  ST.modify_date AS Table_Modified_Date,
	  EP.[value] AS Comments
  FROM sys.tables AS ST
       LEFT JOIN sys.identity_columns AS IC ON ST.object_id = IC.object_id
       LEFT JOIN sys.extended_properties AS EP ON ST.object_id = EP.major_id
             AND EP.name = 'MS_Description'
             AND EP.minor_id = 0
             AND EP.class_desc = 'OBJECT_OR_COLUMN'
	  CROSS APPLY (SELECT SUM(SP.row_count) AS Row_Count FROM sys.dm_db_partition_stats AS SP WHERE ST.object_id = SP.object_id AND SP.index_id < 2) CASP
	  OUTER APPLY (SELECT COUNT(1) AS NonClustered_Idx_Count FROM sys.indexes AS IDX WHERE ST.object_id = IDX.object_id AND IDX.type_desc = 'NONCLUSTERED') OAIX
	  OUTER APPLY (SELECT COUNT(1) AS Default_Constraint_Count FROM sys.default_constraints AS DC WHERE ST.object_id = DC.parent_object_id) OADC
	  OUTER APPLY (SELECT COUNT(1) AS Computed_Column_Count FROM sys.computed_columns AS CC WHERE ST.object_id = CC.object_id) OACC
	  OUTER APPLY (SELECT CONCAT(SCHEMA_NAME(FK.schema_id), '.', OBJECT_NAME(FK.parent_object_id), ' - ', COL_NAME(FK.parent_object_id, FKC.parent_column_id)) AS Table_is_referenced_by_Foreign_Key,
	                      COUNT(ST.object_id) OVER (PARTITION BY ST.object_id) AS Foreign_Key_References_Count
				  FROM sys.foreign_keys AS FK
					  INNER JOIN sys.foreign_key_columns AS FKC ON FK.object_id = FKC.constraint_object_id
				 WHERE FK.referenced_object_id = ST.object_id
			    ) OAFK
	  OUTER APPLY (SELECT CONCAT(referencing_schema_name, '.', referencing_entity_name) AS Referencing_Entity_Name,
					  SO.type_desc AS Referencing_Entity_Type,
					  COUNT(SO.type_desc) OVER (PARTITION BY ST.object_id, SO.type_desc) AS Referencing_Entities_Count				  
				  FROM sys.dm_sql_referencing_entities (SCHEMA_NAME(ST.schema_id) + '.' + ST.name, 'OBJECT') AS REF
					  INNER JOIN sys.objects AS SO ON REF.referencing_id = SO.object_id
			    ) OAREF
 WHERE 1 = 1
   AND ST.type = 'U'
   --AND SCHEMA_NAME(ST.SCHEMA_ID) IN ('')
   --AND ST.name LIKE '%%'
),
APPEND_REF
AS
(
SELECT DISTINCT T1.Table_Name,
       T1.Row_Count,
       T1.Column_Count,
       T1.Computed_Column_Count,
       T1.Default_Constraint_Count,
       T1.Clustered_Idx_Count,
       T1.NonClustered_Idx_Count,
       T1.Primary_Key_Exists,
       T1.Identity_Column_Exists,
       T1.Last_Value,
       OAFKREF.Table_is_referenced_by_Foreign_Key,
	  T1.Foreign_Key_References_Count,
	  OAREF.Referencing_Entity_Name,
	  T1.Referencing_Entity_Type,
       T1.Table_Created_Date,
       T1.Table_Modified_Date,
	  T1.Comments
  FROM LIST_TABLES AS T1
	  OUTER APPLY (SELECT (STUFF(
						    (SELECT CONCAT(CHAR(10), FK.Table_is_referenced_by_Foreign_Key)
							  FROM LIST_TABLES AS FK
							 WHERE T1.Table_Name = FK.Table_Name
							 GROUP BY CONCAT(CHAR(10), FK.Table_is_referenced_by_Foreign_Key)							   
							 ORDER BY 1      
							   FOR XML PATH ('')
						    ), 1, 1, ''
						   )
	                      ) AS Table_is_referenced_by_Foreign_Key
			    ) OAFKREF
	  OUTER APPLY (SELECT (STUFF(
						    (SELECT CONCAT(CHAR(10), REF.Referencing_Entity_Name)
							  FROM LIST_TABLES AS REF
							 WHERE T1.Table_Name = REF.Table_Name
							   AND T1.Referencing_Entity_Type = REF.Referencing_Entity_Type
							 GROUP BY CONCAT(CHAR(10), REF.Referencing_Entity_Name)							   
							 ORDER BY 1      
							   FOR XML PATH ('')
						    ), 1, 1, ''
						   )
	                      ) AS Referencing_Entity_Name
			    ) OAREF
)
SELECT Table_Name,
       Row_Count,
       Column_Count,
       Computed_Column_Count,
       Default_Constraint_Count,
       Clustered_Idx_Count,
       NonClustered_Idx_Count,
       Primary_Key_Exists,
       Identity_Column_Exists,
       Last_Value,
       Table_is_referenced_by_Foreign_Key,
       Foreign_Key_References_Count,
	  ISNULL(SQL_STORED_PROCEDURE, 'N/A') AS Referencing_Stored_Procs,
       ISNULL(LEN(SQL_STORED_PROCEDURE) - LEN(REPLACE(SQL_STORED_PROCEDURE, CHAR(10), '')) + 1, 0) AS Referencing_Procs_Count,
	  ISNULL(SQL_TRIGGER, 'N/A') AS Referencing_Triggers,
       ISNULL(LEN(SQL_TRIGGER) - LEN(REPLACE(SQL_TRIGGER, CHAR(10), '')) + 1, 0) AS Referencing_Triggers_Count,
	  ISNULL([VIEW], 'N/A') AS Referencing_Views,
       ISNULL(LEN([VIEW]) - LEN(REPLACE([VIEW], CHAR(10), '')) + 1, 0) AS Referencing_Views_Count,
       Table_Created_Date,
       Table_Modified_Date,
	  Comments
  FROM APPEND_REF
 PIVOT (MAX(Referencing_Entity_Name) FOR Referencing_Entity_Type IN ([SQL_STORED_PROCEDURE], [SQL_TRIGGER], [VIEW])) PVT
 ORDER BY 1;

--tlog
SELECT Name, 
       Physical_Name, 
       size / 128 AS Size_MB 
  FROM sys.database_files 
 WHERE 1 = 1
   AND type = 1;

--trg
;WITH LIST_TRIGGERS
AS
(
SELECT OBJECT_SCHEMA_NAME(ST.object_id) AS Trigger_Schema_Name,
       ST.name AS Trigger_Name,
	  CASE WHEN ST.parent_class = 0 THEN 'DDL' ELSE 'DML' END AS [DDL/DML Type],
	  TE.type_desc AS Trigger_Event_Type,
       OBJECT_SCHEMA_NAME(ST.parent_id) AS Parent_Schema_Name,
       OBJECT_NAME(ST.parent_id) AS Parent_Name,
	  SO.type_desc AS Parent_Type,
	  ISNULL(OBJECT_DEFINITION(ST.parent_id), 'N/A') AS Parent_Definition,
	  OBJECT_DEFINITION(ST.object_id) AS Triger_Definition,
	  ST.type_desc AS Trigger_Type,
	  ST.create_date AS Trigger_Create_Date,
	  ST.modify_date AS Trigger_Modify_Date,
	  ST.is_ms_shipped,
	  ST.is_disabled,
	  ST.is_not_for_replication,
	  ST.is_instead_of_trigger
  FROM sys.triggers AS ST       
       INNER JOIN sys.objects AS SO ON ST.parent_id = SO.object_id
	  LEFT JOIN sys.trigger_events AS TE ON ST.object_id = TE.object_id
)
SELECT * 
  FROM LIST_TRIGGERS
 WHERE 1 = 1
   AND Trigger_Schema_Name IN ('')
 ORDER BY Trigger_Schema_Name,
          Trigger_Name,
          Parent_Schema_Name,
          Parent_Name
;

--udt
;WITH UDT_INFO
 AS
(
SELECT CONCAT(SCHEMA_NAME(STT.schema_id), '.', STT.name) AS Table_Type_Name,
       SO.Create_Date,
	  SO.Modify_Date,
	  IIF(OBJECTPROPERTY(STT.type_table_object_id, 'TableHasPrimaryKey') = 1, 'YES', 'NO') AS Primary_Key_Exists,
	  IIF(OBJECTPROPERTY(STT.type_table_object_id, 'TableHasIdentity') = 1, 'YES', 'NO') AS Identity_Column_Exists,
	  IIF(OBJECTPROPERTY(STT.type_table_object_id, 'TableHasClustIndex') = 1, 1, 0) AS Clustered_Idx_Count,
	  OAIX.NonClustered_Idx_Count,
	  CAC.Column_Count,
	  OACC.Computed_Column_Count,
	  OADC.Default_Constraint_Count,
	  COALESCE(OAREF.Referencing_Entity_Name, 'N/A') AS Referencing_Entity_Name,
	  COALESCE(OAREF.Referencing_Entity_Type, 'SQL_STORED_PROCEDURE') AS Referencing_Entity_Type,
	  COALESCE(OAREF.Referencing_Entities_Count, 0) AS Referencing_Entities_Count
  FROM sys.table_types AS STT
	  OUTER APPLY (SELECT COUNT(1) AS NonClustered_Idx_Count FROM sys.indexes AS IDX WHERE STT.type_table_object_id = IDX.object_id AND IDX.type_desc = 'NONCLUSTERED') OAIX
	  CROSS APPLY (SELECT COUNT(1) AS Column_Count FROM sys.columns AS SC WHERE STT.type_table_object_id = SC.object_id) CAC
	  OUTER APPLY (SELECT COUNT(1) AS Default_Constraint_Count FROM sys.default_constraints AS DC WHERE STT.type_table_object_id = DC.parent_object_id) OADC
	  OUTER APPLY (SELECT COUNT(1) AS Computed_Column_Count FROM sys.computed_columns AS CC WHERE STT.type_table_object_id = CC.object_id) OACC
	  OUTER APPLY (SELECT CONCAT(referencing_schema_name, '.', referencing_entity_name) AS Referencing_Entity_Name,
					  SO.type_desc AS Referencing_Entity_Type,
					  COUNT(SO.type_desc) OVER (PARTITION BY STT.type_table_object_id, SO.type_desc) AS Referencing_Entities_Count				  
				  FROM sys.dm_sql_referencing_entities (SCHEMA_NAME(STT.schema_id) + '.' + STT.name, 'TYPE') AS REF
					  INNER JOIN sys.objects AS SO ON REF.referencing_id = SO.object_id
			    ) OAREF
       INNER JOIN sys.objects AS SO ON STT.type_table_object_id = SO.object_id
 WHERE 1 = 1
   AND STT.is_user_defined = 1
   AND STT.is_table_type = 1
   --AND SCHEMA_NAME(STT.schema_id) IN ('')
   --AND STT.name LIKE '%%'
   --AND IDX.type > 0 --0 INDICATES HEAP. UNCOMMENT THIS TO ELIMINATE THE LIST OF TABLE_TYPES HAVING NO INDEXES.
),
LIST_UDTS
AS
(
SELECT T1.Table_Type_Name,
       T1.Create_Date,
	  T1.Modify_Date,
	  T1.Column_Count,
       T1.Primary_Key_Exists,
	  T1.Identity_Column_Exists,	  
	  T1.Computed_Column_Count,
	  T1.Default_Constraint_Count,
       T1.Clustered_Idx_Count,
       T1.NonClustered_Idx_Count,
       T1.Clustered_Idx_Count + T1.NonClustered_Idx_Count AS 'No. of Indexes',       	  
	  ISNULL(SP.Referencing_Entities_Count, 0) AS Referencing_Procs_Count,
	  ISNULL(TRG.Referencing_Entities_Count, 0) AS Referencing_Triggers_Count,
	  T1.Referencing_Entity_Type,
	  OAFK.Referencing_Entity_Name
  FROM UDT_INFO AS T1
	  OUTER APPLY (SELECT (STUFF(
						    (SELECT CONCAT(CHAR(10), Referencing_Entity_Name)
							  FROM UDT_INFO AS T2
							 WHERE T1.Table_Type_Name = T2.Table_Type_Name
							   AND T1.Referencing_Entity_Type = T2.Referencing_Entity_Type
							 ORDER BY 1      
							   FOR XML PATH ('')
						    ), 1, 1, ''
						   )
	                      ) AS Referencing_Entity_Name
			    ) OAFK
       LEFT JOIN UDT_INFO AS SP ON T1.Table_Type_Name = SP.Table_Type_Name
	        AND SP.Referencing_Entity_Type = 'SQL_STORED_PROCEDURE'
       LEFT JOIN UDT_INFO AS TRG ON T1.Table_Type_Name = TRG.Table_Type_Name
	        AND TRG.Referencing_Entity_Type = 'SQL_TRIGGER'
)
SELECT Table_Type_Name,
       Create_Date,
	  Modify_Date,
       Column_Count,
       Primary_Key_Exists,
       Identity_Column_Exists,
       Computed_Column_Count,
       Default_Constraint_Count,
       Clustered_Idx_Count,
       NonClustered_Idx_Count,
       [No. of Indexes],
	  ISNULL(SQL_STORED_PROCEDURE, 'N/A') AS Referencing_Stored_Procs,
	  Referencing_Procs_Count,
	  ISNULL(SQL_TRIGGER, 'N/A') AS Referencing_Triggers,
	  Referencing_Triggers_Count
  FROM LIST_UDTS
 PIVOT (MAX(Referencing_Entity_Name) FOR Referencing_Entity_Type IN ([SQL_STORED_PROCEDURE], [SQL_TRIGGER])) PVT;

--udtcolnames
DECLARE @sColList VARCHAR(MAX), 
        @iColCount TINYINT;
SELECT @sColList = COALESCE(@sColList + ', ','') + SC.name,
       @iColCount = COUNT(column_id) OVER(PARTITION BY STT.type_table_object_id)
  FROM sys.columns AS SC
	  INNER JOIN sys.table_types AS STT ON SC.OBJECT_ID = STT.type_table_object_id
 WHERE 1 = 1
   AND SCHEMA_NAME(STT.schema_id) IN ('')
   AND STT.name IN ('');
SELECT @sColList AS Column_List, @iColCount AS Column_Count

--vw
SELECT CONCAT(OBJECT_SCHEMA_NAME(SV.object_id), '.', SV.name) AS View_Nm,
	  OBJECT_DEFINITION(SV.object_id) AS View_Definition, 
	  CC.Column_Count,
	  SV.Create_Date, 
	  SV.Modify_Date,
	  EP.[value] AS Comments
  FROM sys.views AS SV
       LEFT JOIN sys.extended_properties AS EP ON SV.object_id = EP.major_id
             AND EP.name = 'MS_Description'
             AND EP.minor_id = 0
             AND EP.class_desc = 'OBJECT_OR_COLUMN'
       CROSS APPLY (SELECT MAX(column_id) AS Column_Count FROM sys.columns AS SC WHERE SV.object_id = SC.object_id) AS CC
 WHERE 1 = 1
   --AND OBJECT_SCHEMA_NAME(SV.object_id) IN ('')
   --AND SV.name LIKE '%%'
 ORDER BY 1;

--vwcol
SELECT SC.name AS Column_Name, 
	  TYPE_NAME(SC.user_type_id) AS Data_Type, 
	  SC.max_length AS Max_Length, 
	  SC.precision AS Precision, 
	  SC.scale AS Scale,
	  IIF(SC.is_nullable = 1, 'YES', 'NO') AS Is_Nullable,
       IIF(SC.is_identity = 1, 'YES', 'NO') AS Is_Identity,
	  IIF(SC.is_computed = 1, 'YES', 'NO') AS Is_Computed,
	  IIF(SC.default_object_id != 0, 'YES', 'NO') AS Is_Default,
	  Create_Date, 
	  Modify_Date,
	  EP.[value] AS Comments
  FROM sys.views AS SV
       INNER JOIN sys.columns AS SC ON SV.object_id = SC.object_id
       LEFT JOIN sys.extended_properties AS EP ON SV.object_id = EP.major_id
             AND SC.column_id = EP.minor_id
             AND EP.name = 'MS_Description'             
             AND EP.class_desc = 'OBJECT_OR_COLUMN'
 WHERE 1 = 1
   AND OBJECT_SCHEMA_NAME(SV.object_id) IN ('')
   AND SV.name = ''
 ORDER BY SV.object_id, SC.column_id;

--vwcolref
SELECT OBJECT_SCHEMA_NAME(SV.object_id) AS View_Schema,
       SV.name AS View_Name,
	  OBJECT_SCHEMA_NAME(SO.object_id) AS Base_Object_Schema,
	  SO.name AS Base_Object_Name,
	  SO.type_desc AS Base_Object_Type,
       OC.name AS Column_Name,
	  TYPE_NAME(OC.user_type_id) AS Data_Type,
	  OC.max_length AS Max_Length,
	  OC.precision AS Precision,
	  OC.scale AS Scale,
	  IIF(OC.is_nullable = 1, 'YES', 'NO') AS Is_Nullable,
       IIF(OC.is_identity = 1, 'YES', 'NO') AS Is_Identity,
	  IIF(OC.is_computed = 1, 'YES', 'NO') AS Is_Computed,
	  IIF(OC.default_object_id != 0, 'YES', 'NO') AS Is_Default,
	  SO.Create_Date AS Base_Object_Created_Date,
	  SO.Modify_Date AS Base_Object_Modified_Date
  FROM sys.views AS SV
       INNER JOIN sys.sql_expression_dependencies AS SD ON SV.object_id = SD.referencing_id
	  INNER JOIN sys.objects AS SO ON SD.referenced_id = SO.object_id
       INNER JOIN sys.columns AS OC ON OC.object_id = SD.referenced_id
	         AND OC.column_id = SD.referenced_minor_id
 WHERE 1 = 1
   AND OBJECT_SCHEMA_NAME(SV.object_id) IN ('')
   AND SV.name = ''
 ORDER BY 1, 2, 3, 4, OC.column_id
;

--vwref
SELECT DISTINCT CONCAT(OBJECT_SCHEMA_NAME(SV.object_id), '.', SV.name) AS View_Name,
       CONCAT(REF.referenced_schema_name, '.', REF.referenced_entity_name) AS Base_Object_Name,
       SO.type_desc AS Base_Object_Type,
	  COUNT(SO.object_id) OVER (PARTITION BY SV.object_id, SO.object_id) AS Columns_In_The_View_From_The_Base_Object,
	  CACC.Base_Column_Count,
	  CARC.Base_Row_Count,
	  SO.Create_Date AS Base_Object_Created_Date,
	  SO.Modify_Date AS Base_Object_Modified_Date
  FROM sys.views AS SV
	  LEFT JOIN sys.sql_expression_dependencies AS REF ON SV.object_id = REF.referencing_id
       LEFT JOIN sys.objects AS SO ON REF.referenced_id = SO.object_id
	  INNER JOIN sys.columns AS OC ON OC.object_id = REF.referenced_id
	         AND OC.column_id = REF.referenced_minor_id
	  OUTER APPLY (SELECT SUM(row_count) AS Base_Row_Count FROM sys.dm_db_partition_stats AS SP WHERE SO.object_id = SP.object_id AND SP.index_id < 2) CARC
	  OUTER APPLY (SELECT COUNT(1) AS Base_Column_Count FROM sys.columns AS SC WHERE SO.object_id = SC.object_id) CACC
 WHERE 1 = 1
   AND OBJECT_SCHEMA_NAME(SV.object_id) = ''
   AND SV.name = ''
 ORDER BY 1, 2;

--wis
EXEC dbo.sp_whoisactive
/*
@filter_type = 'session',
@filter = 136,
@get_full_inner_text = 1
--*/
;

--xpfd
EXEC master..xp_fixeddrives