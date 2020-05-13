--===== These will become parameters in the eventual stored procedure.
     -- If both are null, all indexes within the constraints of the final WHERE clause will be returned.
     -- If the @pObjectID is provided and the @pIndexID is null, the output will be additionally limited only to the 
     -- indexes of that object.
     -- If @pIndexID is provided, then @pObjectID must be provided. 
DECLARE  @pObjectID INT = NULL 
        ,@pIndexID  INT = NULL
;
/**********************************************************************************************************************
 Purpose:
 This is an expanded version of sys.dm_db_index_physical_stats that returns important columns such as fill factor, 
 the RowModCtr column, information about the leading column of index keys and the defaults for that leading column.
 It also returns "what if" estimates for how much it would cost(-) or save if the index were rebuilt using 4 common
 fill factors plus a calculation that identifies the average number of rows per page that an index will have based
 on the average size of the row in bytes (note that 8060 is NOT the proper constant to use here).

 To make experimentation easier and quicker, the name of the various objects and indexes are also returned.
 To that same end, the code also builds the ALTER INDEX REBUILD and the sp_IndexDNA commands for the given index
 support various experiments without getting bogged down in typing or modifying code.

 Also note that the NCIExpansiveCnt (a count of the number of potentially "ExpAnsive" columns that are a part of the
 Non-Clustered Index) will always be "0" for Clustered Indexes.  Use the "Trigger Method" in a separate stored
 procedure (sp_CreateExpansiveUpdateTrigger) to find and evaluate "ExpAnsive" columns much more accurately than a 
 simple count.

 Because this code is for experimental purposes, it is currently hard coded to "the need", which indludes only the
 "Sampled" level of detail and only information for "IN ROW DATA". 

 Programming Notes
 1. Search for NOTE 1 when using with SQL Server 2012 or better and returning RowModCntr is desired.
    Uncomment the code in those two places to enable returning RowModCntr.

 Usage Notes.
 1. Note that this code is "Proof-of-Concept" code and is not supported by the author of the code.
 2. This code can take a substantial period of time to execute depending on the number and size of the indexes.
 3. Don't forget to make changes in the final WHERE clause if you want to see more returns.

 Revision History:
 Rev 00 - 25 Nov 2017 - Jeff Moden
        - Initial creation of Proof-of-Concept code and test.
 Rev 01 - 23 Sep 2018 - Jeff Moden
        - Remove various "what if" experiments from the code so that others may use it without distraction or taking
          the results of a "failed" experiment as being useful.
**********************************************************************************************************************/
WITH cte AS
(
 SELECT  DBName         = DB_NAME(stats.database_ID)
        ,SchemaName     = OBJECT_SCHEMA_NAME(stats.object_id)
        ,ObjectName     = OBJECT_NAME(stats.object_id)
        ,IndexName      = idx.name
        ,ObjectID       = stats.object_id
        ,IndexID        = stats.index_id
        ,PartitionNum   = stats.partition_number
        ,PageTypeDesc   = stats.alloc_unit_type_desc
        ,FragPct        = stats.avg_fragmentation_in_percent
        ,FragSizePages  = stats.avg_fragment_size_in_pages
        ,FragCnt        = Stats.fragment_count
        ,PageCnt        = stats.page_count
        ,RowCnt         = stats.record_count
        ,PageDensity    = stats.avg_page_space_used_in_percent
        ,[FillFactor]   = idx.fill_factor
        ,CurSizeMB      = (stats.page_count/128.0)
        ,EstSavMBFFCur  = (stats.page_count/128.0) 
                        - (stats.avg_page_space_used_in_percent/ISNULL(NULLIF(idx.fill_factor,0),100)*(stats.page_count/128.0))
        ,EstSavMBFF72   = (stats.page_count/128.0) - (stats.avg_page_space_used_in_percent/ 72*(stats.page_count/128.0))
        ,EstSavMBFF82   = (stats.page_count/128.0) - (stats.avg_page_space_used_in_percent/ 82*(stats.page_count/128.0))
        ,EstSavMBFF92   = (stats.page_count/128.0) - (stats.avg_page_space_used_in_percent/ 92*(stats.page_count/128.0))
        ,EstSavMBFF97   = (stats.page_count/128.0) - (stats.avg_page_space_used_in_percent/ 97*(stats.page_count/128.0))
        ,EstSavMBFF98   = (stats.page_count/128.0) - (stats.avg_page_space_used_in_percent/ 98*(stats.page_count/128.0))
        ,EstSavMBFF99   = (stats.page_count/128.0) - (stats.avg_page_space_used_in_percent/ 99*(stats.page_count/128.0))
        ,AvgRowsPerPage = CONVERT(INT,8096/NULLIF(stats.avg_record_size_in_bytes,0))
        ,MinRowSize     = stats.min_record_size_in_bytes
        ,AvgRowSize     = stats.avg_record_size_in_bytes
        ,MaxRowSize     = stats.max_record_size_in_bytes
        ,IsUnique       = idx.is_unique
        ,IsPK           = idx.is_primary_key 
        ,IsFiltered     = idx.has_filter
        ,IsDisabled     = idx.is_disabled
        ,FwdRows        = stats.forwarded_record_count
      --,RowModCnt      = statsprop.modification_counter --See Note 1
        ,DBID           = stats.database_id
   FROM sys.dm_db_index_physical_stats(DB_ID(),@pObjectID,@pIndexID,NULL,'SAMPLED') stats
   LEFT JOIN sys.indexes idx
          ON idx.object_id = stats.object_id
         AND idx.index_id  = stats.index_id
  --CROSS APPLY sys.dm_db_stats_properties(stats.object_id,stats.index_id) statsprop --See Note 1
  WHERE stats.index_level           = 0
    AND idx.is_hypothetical         = 0
    AND stats.alloc_unit_type_desc  = 'IN_ROW_DATA'
    AND OBJECT_SCHEMA_NAME(stats.object_id) NOT IN ('Arch','Scratch','IMPLD') --Tables I don't want to check
)
 SELECT cte.*
        ,leadcol.*
        ,IndexRebuildCmd = 'ALTER INDEX '+QUOTENAME(cte.IndexName)
                         + ' ON '+QUOTENAME(cte.SchemaName)+'.'+QUOTENAME(cte.ObjectName)
                         + ' REBUILD WITH (FILLFACTOR='+CONVERT(CHAR(3),cte.[FillFactor])+',ONLINE = OFF);' 
        ,IndexDnaCmd     = 'EXEC sp_IndexDNA ' 
                         + CONVERT(VARCHAR(10),cte.ObjectID) + ','
                         + CONVERT(VARCHAR(10),cte.IndexID) + ';'
--If you want to store the results in a table, change this comment into an "INTO tablename" clause.
   FROM cte
  OUTER APPLY
        (--===== Information about the lead column in the key and how many expansive columns are in the index key(s).
              -- This includes columns found in the INCLUDE clause of NCIs but not the leaf level of CIs.
              -- We have other code for the study of CIs.
         SELECT  LeadColumnDataType = MAX(CASE WHEN coltyp.key_ordinal = 1 THEN systyp.name ELSE '' END)
                ,LeadColumnDefault  = MAX(CASE WHEN coltyp.key_ordinal = 1 THEN sysdflt.definition ELSE '' END)
                ,IsIdentity         = MAX(CONVERT(TINYINT,coltyp.is_identity))
                ,IndexColumnCnt     = COUNT(*)
                ,NCIExpansiveCnt    = SUM(CASE WHEN systyp.system_type_id IN (98,165,167,231,240,241) THEN 1 ELSE 0 END)
           FROM (
                 SELECT  idxcol.object_id
                        ,idxcol.index_id
                        ,idxcol.key_ordinal
                        ,idxcol.column_id
                        ,objcol.system_type_id
                        ,objcol.is_identity
                   FROM      sys.index_columns  idxcol 
                   LEFT JOIN sys.columns        objcol ON objcol.object_id = idxcol.object_id 
                                                      AND objcol.column_id = idxcol.column_id
                  WHERE idxcol.object_id    = cte.ObjectID
                    AND idxcol.index_id     = cte.IndexID
                ) coltyp
           LEFT JOIN sys.types systyp ON systyp.system_type_id = coltyp.system_type_id
           LEFT JOIN sys.default_constraints sysdflt ON sysdflt.parent_object_id = coltyp.object_id
                                                    AND sysdflt.parent_column_id = coltyp.column_id
          GROUP BY coltyp.object_id, coltyp.index_id
        ) leadcol
  WHERE PageCnt > 1024 --This equates to 8MB at the Leaf Level
    AND IndexID > 0
     -- You can add other filters here if desired
  ORDER BY PageCnt DESC --EstSavMBFF80 ASC
;