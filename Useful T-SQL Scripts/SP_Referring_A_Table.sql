WITH SRC
  AS
(
SELECT SO.object_id,
       SI.type_desc,
	  CA.Row_Count
  FROM sys.indexes AS SI
       INNER JOIN sys.objects AS SO ON SI.object_id = SO.object_id
	  CROSS APPLY (SELECT SUM(row_count) AS Row_Count FROM sys.dm_db_partition_stats AS SP WHERE SO.object_id = SP.object_id AND SP.index_id < 2) CA
 WHERE 1 = 1
   AND SO.type = 'U'
),
--NUMBER OF INDEXES ON EACH TABLE
IDX
AS
(
SELECT *, [CLUSTERED] + [NONCLUSTERED] AS 'No. of Indexes'
  FROM SRC
 PIVOT (COUNT(type_desc) FOR type_desc IN ([Clustered], [Nonclustered])) PVT
)
--LIST OF TABLES BEING REFERRED BY A SP
SELECT DISTINCT SCHEMA_NAME(SP.schema_id) AS PrSch_Name,
       SP.name AS Proc_Name,
       SCHEMA_NAME(SO.schema_id) AS TblSch_Name,
       SD.referenced_entity_name AS Table_Name,
	  Row_Count,
	  [Clustered] AS Clustered_Idx_Count,
	  [Nonclustered] AS NonClustered_Idx_Count,
	  [No. of Indexes]
  FROM sys.objects SO
       INNER JOIN sys.sql_expression_dependencies SD ON SO.object_id = SD.referenced_id
	  RIGHT JOIN sys.procedures SP ON SD.referencing_id = SP.object_id
	  LEFT JOIN IDX ON SO.object_id = IDX.object_id 
 WHERE 1 = 1
   AND SO.type = 'U'
   --AND SCHEMA_NAME(SP.schema_id) = ''
   --AND SP.name = ''
 ORDER BY 1, 2, 3, 4;