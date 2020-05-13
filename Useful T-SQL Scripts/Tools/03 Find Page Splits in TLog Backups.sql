/**********************************************************************************************************************
 Purpose:
 Find which objects, by partition and index, are experiencing page splits for the current database according to the 
 previous 24 hours of transaction log files for the current database.

      ***********************************************************************************************************
      ***** WARNING!!! ***** WARNING!!! ***** WARNING!!! ***** WARNING!!! ***** WARNING!!! ***** WARNING!!! ***** 
      *****       THERE ARE KNOWN SERIOUS ISSUES WITH USING THIS METHOD PRIOR TO SQL SERVER 2012 SP2!!!     *****
      *****          The following warnings are copies made from Paul's article without modification;       *****
      ***********************************************************************************************************
      ***** Edit 8/15/13: Beware – we just found out from a customer system that uses this extensively that *****
      *****               every time fn_dump_dblog is called, it creates a new hidden SQLOS scheduler and   *****
      *****               up to three threads, which will never go away and never be reused.                *****
      *****               Use with caution.                                                                 *****
      *****                                                                                                 *****
      ***** Edit 5/15/15: It’s fixed in SQL Server 2012 SP2+ and SQL Server 2014. The fix won’t be          *****
      *****               back-ported any earlier.                                                          *****
      ***** WARNING!!! ***** WARNING!!! ***** WARNING!!! ***** WARNING!!! ***** WARNING!!! ***** WARNING!!! ***** 
      ***********************************************************************************************************

 Usage Notes.
 1. Note that this code is "Proof-of-Concept" code and is not supported by the authors of the code.
 2. This code takes no parameters. It could be converted to a "system stored procedure", though.
    Feel free to add additional parameters as you see fit.
 3. This code can take a substantial period of time to execute depending on the size of the transaction log backups.
 4. This code uses fn_dump_dblog, which is undocumented and unsupported by Microsoft or the authors of this code.

 Revision History:
 Rev 00 - 07 Feb 2013 - Paul Randal
        - Original concept code, explanation, and warnings at the following URL:
          https://www.sqlskills.com/blogs/paul/tracking-page-splits-using-the-transaction-log/
 Rev 01 - 01 Sep 2018 - Jeff Moden
        - Formalize and modify the code to read all transaction log backups for the current database for the
          previous 24 hours.
**********************************************************************************************************************/
--=====================================================================================================================
--      Local Variables and presets
--=====================================================================================================================
--===== Local variables
DECLARE  @Counter       SMALLINT
        ,@FileCount     INT
        ,@FilePath      NVARCHAR(260)
        ,@FileSizeMB    VARCHAR(10)
;
--===== Presets (trying to keep things compatible back to 2005 but see warning in the header)
 SELECT  @Counter   = 1
        ,@FileCount = 0
;
--=====================================================================================================================
--      Temp Tables
--=====================================================================================================================
--===== If the working tables already exist, drop them to make reruns easier in SSMS.
     -- These drops may be commented out for production stored procedures
     IF OBJECT_ID('tempdb..#TLogInfo'  ,'U') IS NOT NULL DROP TABLE #TLogInfo;
     IF OBJECT_ID('tempdb..#PageSplits','U') IS NOT NULL DROP TABLE #PageSplits;

--===== Create the table to hold the transaction log file information.
     -- The SortOrder (PK) column is necessary because we need to use this as a control table for a loop.
 CREATE TABLE #TLogInfo
        (
         SortOrder              SMALLINT        IDENTITY(1,1) PRIMARY KEY CLUSTERED
        ,server_name            SYSNAME         NOT NULL --Future expansion
        ,database_name          SYSNAME         NOT NULL --Future expansion
        ,physical_device_name   NVARCHAR(260)   NOT NULL --Not my limit. SQL Server Limit
        ,backup_start_date      DATETIME        NOT NULL --Sanity check, otherwise, not used
        ,FileSizeMB             DECIMAL(9,1)    NOT NULL --Sanity check, otherwise, not used
        )
;
--===== Create the table to hold the number of splits by object and index.
     -- Once filled, this table will be fully scanned one time so no need for CI/NCIs
 CREATE TABLE #PageSplits
        (
         Schema_Name        SYSNAME
        ,Object_Name        SYSNAME
        ,Index_Name         SYSNAME
        ,fill_factor        TINYINT
        ,partition_id       BIGINT
        ,partition_number   INT
        ,schema_id          INT
        ,object_id          INT
        ,index_id           INT
        ,SplitType          CHAR(12)
        ,SplitCount         INT
        ,FilePath           NVARCHAR(260)
        )
;
--=====================================================================================================================
--      Get the transaction log file info we need from the msdb database.
--      Sorry... I don't use 3rd party backups and so I've only tested for native backups.
--=====================================================================================================================
--===== Save the full path of all backup files for the current database for the previous 24 hours.
 INSERT INTO #TLogInfo WITH (TABLOCK)
        (server_name,database_name,physical_device_name,backup_start_date,FileSizeMB)
 SELECT  bu.server_name
        ,bu.database_name
        ,mf.physical_device_name
        ,bu.backup_start_date
        ,FileSizeMB = CONVERT(DECIMAL(9,1),bu.backup_size/1048576)
   FROM msdb.dbo.backupset         bu
   JOIN msdb.dbo.backupmediafamily mf ON bu.media_set_id = mf.media_set_id
  WHERE bu.database_name   = DB_NAME() -- Remove this line for all the databases
    AND backup_start_date >= DATEADD(hh,-24,GETDATE()) --Always looks 24 hours back.  May take a while.
    AND [type]             = 'L'  --Transaction Log Backups
  ORDER BY backup_start_date
;
--===== Remember how many files there are.
 SELECT @FileCount = @@ROWCOUNT
;
--=====================================================================================================================
--      For each transaction file, get the objects and indexes by name that have page splits and the # of page splits
--      for each.
--=====================================================================================================================
  WHILE @Counter <= @FileCount
  BEGIN
        --===== Get the file path of the transaction log to examine for page splits
         SELECT  @FilePath   = physical_device_name
                ,@FileSizeMB = FileSizeMB
           FROM #TLogInfo
          WHERE SortOrder    = @Counter
        ;
        --===== Give the operator something to watch so they know it's working.
        RAISERROR('Working on file %u of %u (%sMB): %s',0,0,@Counter,@FileCount,@FileSizeMB,@FilePath) WITH NOWAIT
        ;
        --===== Get the page splits by object and index.
         INSERT INTO #PageSplits WITH (TABLOCK)
                (
                 Schema_Name
                ,Object_Name      
                ,Index_Name     
                ,fill_factor  
                ,partition_id    
                ,partition_number
                ,schema_id       
                ,object_id       
                ,index_id        
                ,SplitType       
                ,SplitCount 
                ,FilePath     
                )
         SELECT  Schema_Name   = s.name
                ,Object_Name   = o.name
                ,Index_Name    = i.name
                ,i.fill_factor
                ,p.partition_id
                ,p.partition_number
                ,s.schema_id
                ,o.object_id
                ,i.index_id
                ,f.SplitType  
                ,f.SplitCount 
                ,FilePath = @FilePath
           FROM (
                 SELECT  AllocUnitId
                        ,SplitType    = (
                                        CASE Context
                                        WHEN N'LCX_INDEX_LEAF' THEN N'Nonclustered'
                                        WHEN N'LCX_CLUSTERED'  THEN N'Clustered'
                                        ELSE N'Non-Leaf'
                                        END
                                        )
                        ,SplitCount   = COUNT(*)
                   FROM fn_dump_dblog   (-- Yeah... all the DEFAULT junk is absolutely necessary.
                                        NULL, NULL, N'DISK', 1
                                        ,@FilePath
                                        ,DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT
                                        ,DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT
                                        ,DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT
                                        ,DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT
                                        ,DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT
                                        ,DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT
                                        ,DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT
                                        ,DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT
                                        ,DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT
                                        )
                  WHERE Operation     = N'LOP_DELETE_SPLIT'
                  GROUP BY AllocUnitId, Context
                ) f
           JOIN sys.system_internals_allocation_units   
                               a ON a.allocation_unit_id = f.AllocUnitId
           JOIN sys.partitions p ON p.partition_id       = a.container_id
           JOIN sys.indexes    i ON i.object_id          = p.object_id AND i.index_id = p.index_id 
           JOIN sys.objects    o ON o.object_id          = p.object_id
           JOIN sys.schemas    s ON s.schema_id          = o.schema_id
        ;
        --===== Bump the counter to get the next file
         SELECT @Counter = @Counter + 1
        ;
    END
;
--=====================================================================================================================
--      Return the expected result set aggregated by object, parition, and index and sorted with the highest split
--      counts first.
--=====================================================================================================================
 SELECT  Schema_Name,Object_Name,Index_Name,SplitType,fill_factor,partition_number,object_id,index_id
        ,TotalSplitCount = SUM(SplitCount)
        ,IndexDnaCmd     = 'EXEC sp_IndexDNA ' 
                         + CONVERT(VARCHAR(10),object_id) + ','
                         + CONVERT(VARCHAR(10),index_id) + ';'
   FROM #PageSplits
  GROUP BY Schema_Name,Object_Name,Index_Name,SplitType,fill_factor,partition_number,object_id,index_id
  ORDER BY TotalSplitCount DESC
GO
