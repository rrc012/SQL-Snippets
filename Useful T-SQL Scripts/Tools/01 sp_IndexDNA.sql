 CREATE PROCEDURE [dbo].[sp_IndexDNA] 
/**********************************************************************************************************************
 Purpose:
 Given an object_id (found in sys.objects) for a given table or other object that can have indexes applied to 
 them and the index_id (found in sys.indexes), return the enumerated sequence of pages and the percent of page fullness
 (PageDensity) for each page sampled.
-----------------------------------------------------------------------------------------------------------------------
 COPYRIGHT:
 Copyright© by Jeff Moden, 01 July 2018, All Rights Reserved.

 Authorized Usage:
 1. This product may be used freely in normal daily work or for purposes of experimentation provided that no 
    modifications are made to the code or the comments included in this stored procedure and that it is used/stored in
    it's entirety as is.
 2. This product may not be sold nor included in a sold package in whole or in part without specific written 
    authorization of the original author (Jeff Moden https://www.linkedin.com/in/jeff-moden-344b906/) of this code.

 Liability:
 1. Neither the original author of this product nor anyone that teaches its intact usage shall not be held responsible
    for nor assumes any liability for any use or abuse of this code in whole or in part in any way, shape, or form.

 **********************************************************************************************************************
 ***** NOTICE *****           THIS CODE IS CURRENTLY DESIGNED ONLY FOR EXPERIMENTAL USE              ***** NOTICE *****
 **********************************************************************************************************************
 1. It is a known fact that this code can cause extended periods of blocking on busy tables/systems, especially if the
    index it is being used against is large. Use with caution. If used in a production environment, check for blocking 
    on a regular basis and abort the run of this code if blocking or any other anomolies occur.
 **********************************************************************************************************************

 Usage Examples:
--===== Syntax example
   EXEC dbo.sp_IndexDNA @pObjectID, @pIndexID
;
--===== Practical example
    USE somedatabase
;
DECLARE  @pObjectID INT
        ,@pIndexID  INT
;
 SELECT  @pObjectID = OBJECT_ID('someschemaname.sometablename')
        ,@pIndexID  = 1
;
   EXEC dbo.sp_IndexDNA @pObjectID, @pIndexID --Both parameters are required and must be correct.
;
-----------------------------------------------------------------------------------------------------------------------
 Programmer's Notes:
 1. This stored procedure current works only with "In Row Data" on Row-Store indexes.  It does not work on LOBs and
    had not been tested on Column-Store or In-Memory tables. It has also NOT been tested for partitioned tables and
    is not setup to support them.
 2. This code uses a filtered index for performance. If needed, you can manually change the code to work on 2005.
    Do a search for '(Mod for 2005)' in the code and read the comments on how to do so. This is the only authorized
    change you may make to the code.
 3. Note that the sample size is automatically calculated so that no more than 100,000 plot points are ever returned 
    because of the amount of time it would take to 1) execute DBCC PAGE on more pages than that and 2) plot them on the
    related Excel spreadsheet.
 4. Note that the object name can be a one or two part name.
 5. After creating this stored procedure in the MASTER database, execute the following code to reclassify it as  a
    system stored procedure that can be called from any database.

    USE MASTER;  
--===== Reclassify the stored procedure as a system stored procedure.
   EXEC sp_ms_marksystemobject 'sp_IndexDNA'
;  
--===== If the following code returns a 1 for "is_ms_shipped", then it worked.
 SELECT name, is_ms_shipped   
   FROM sys.objects  
  WHERE name = 'sp_IndexDNA'  
;

 6. If you prefer not to install this code in the MASTER database, it will need to be deployed to whichever database
    it will be used from.
-----------------------------------------------------------------------------------------------------------------------
 Revision History:
 Rev 00 - 01 Jul 2018 - Jeff Moden
        - Proof of principle script.
 Rev 01 - 05 Aug 2018 - Jeff Moden
        - Convert to a stored procedure.
**********************************************************************************************************************/
--===== Declare the I/O for this stored procedure
         @pObjectID INT
        ,@pIndexID  INT
     AS
--=====================================================================================================================
--      Presets
--=====================================================================================================================
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; --Helps keep DBCC IND and DBCC PAGE from blocking.

--=====================================================================================================================
--      Local variables and presets
--=====================================================================================================================
DECLARE  @Counter       INT
        ,@LeafPageCount INT
        ,@MaxPageSort   INT
        ,@PageDensity   FLOAT
        ,@PageFreeBytes SMALLINT
        ,@PageRowCount  SMALLINT
        ,@PageUsedBytes SMALLINT
        ,@SampleSize    INT
        ,@SQL           VARCHAR(8000)
;
--=====================================================================================================================
--      Temp Tables and their indexes
--=====================================================================================================================
--===== Drop any existing Temp Tables that will be used.
     -- Comment this section out for production use. It's not needed in stored procedures.
     --IF OBJECT_ID('tempdb..#DBCCIND')           IS NOT NULL DROP TABLE #DBCCIND;
     --IF OBJECT_ID('tempdb..#IndexPageSpace')    IS NOT NULL DROP TABLE #IndexPageSpace;
     --IF OBJECT_ID('tempdb..#PageInfo')          IS NOT NULL DROP TABLE #PageInfo;

--===== Create a temp table to store the results of DBCC IND.
     -- Yes, we could use sys.dm_db_database_page_allocations here but it doesn't really buy us much and does not
     -- return page fullness for anything but LOBs at least up to SQL Server 2016.
     -- It also doesn't exist until SQL Server 2012 and we want this to work as far back as possible.
 CREATE TABLE #DBCCIND  
        (
         PageSortNum        BIGINT
        ,PageFID            INT
        ,PagePID            INT
        ,IAMFID             INT
        ,IAMPID             INT
        ,ObjectID           INT
        ,IndexID            INT
        ,PartitionNumber    SMALLINT
        ,ParitionID         BIGINT
        ,iam_chain_type     VARCHAR(50)
        ,PageType           TINYINT
        ,IndexLevel         TINYINT
        ,NextPageFID        INT
        ,NextPagePID        INT
        ,PrevPageFID        INT
        ,PrevPagePID        INT
        ,m_freeCnt          SMALLINT
        )
;
--===== Create the table that will hold the info from the DBCC Page command for each page we process. 
 CREATE TABLE #PageInfo
        (
         ParentObject   VARCHAR(255)
        ,Object         VARCHAR(255)
        ,Field          VARCHAR(255)
        ,Value          VARCHAR(255)
        )
;
--=====================================================================================================================
--      Return the 4 part naming for the given index for documentation purposes.
--=====================================================================================================================
 SELECT  ServerName = @@SERVERNAME
        ,DBName     = DB_NAME()
        ,SchemaName = OBJECT_SCHEMA_NAME(@pObjectID)
        ,ObjectName = OBJECT_NAME(@pObjectID)
        ,IndexName  = (SELECT name FROM sys.indexes WHERE object_id = @pObjectID AND index_id = @pIndexID)
;
--=====================================================================================================================
--      Get the page information we need for the given object and index parameters.
--=====================================================================================================================
--===== Create the DBCC IND command for this specfic Object and Index
     -- Parameters for DBCC IND are DB_ID of 0 is current database, ObjectID, Index_ID
 SELECT @SQL = 'DBCC IND (0,' 
             + CONVERT(VARCHAR(10),@pObjectID) + ','
             + CONVERT(VARCHAR(10),@pIndexID)  + ') WITH TABLERESULTS,NO_INFOMSGS'
;
 INSERT INTO #DBCCIND
        (
         PageFID        
        ,PagePID        
        ,IAMFID         
        ,IAMPID         
        ,ObjectID       
        ,IndexID        
        ,PartitionNumber
        ,ParitionID     
        ,iam_chain_type 
        ,PageType       
        ,IndexLevel     
        ,NextPageFID    
        ,NextPagePID    
        ,PrevPageFID    
        ,PrevPagePID     
        )
   EXEC (@SQL)
;
--===== Create a filtered index to support the hierarchy scan we'll need to do to determine the
     -- logical page order.
     -- Note that filtered indexes weren't available until 2008. 
     -- For 2005, you'll need to comment out the WHERE clause. (Mod for 2005)
 CREATE INDEX Traverse 
     ON #DBCCIND (PagePID,PageFID)
INCLUDE (PrevPageFID,PrevPagePID,NextPageFID,NextPagePID)
  WHERE IndexLevel      = 0
    AND iam_chain_type  = 'In-row data'
;
----===== Create a filtered index to support the hierarchy scan we'll need to do to determine the
--     -- logical page order of the BLOB data (if any). --Note: Future use
-- CREATE INDEX TraverseBlob
--     ON #DBCCIND (PagePID,PageFID)
--  WHERE IndexLevel      = 0 
--    AND iam_chain_type  = 'LOB data'
--;
--===== Calculate how to "sample" the pages because anything over 100,000 pages takes a very long time.
     -- This will sample every 1, 10, 100, 1000, etc depending on the number of pages in the index.
     -- No, having the variable on the left side of the "=" sign is NOT an error. It's immediate reuse of the variable.
 SELECT  @LeafPageCount = COUNT(*)
        ,@SampleSize     = POWER(10,CONVERT(INT,CEILING(LOG(@LeafPageCount)/LOG(10))-5))
        ,@SampleSize     = CASE WHEN @SampleSize > 0 THEN @SampleSize ELSE 1 END 
   FROM #DBCCIND
  WHERE iam_chain_type = 'In-row data'
;
--=====================================================================================================================
--      Determine the logical order of the pages according to the hierarchy created by the page ID and the next page ID.
--      Note that we also observe the page file ID for future enhancements for working with multiple file groups and,
--      possibly, partitioned tables, which I'm not concerned with at this time.
--=====================================================================================================================
   WITH cteEnumerate AS
(--==== The first logical page of an index will have a "0" for the PrevPageID for non-partitioned tables.
     -- That's the root of our hierarchy.
 SELECT  PageSort = 0
        ,PageFID
        ,PagePID
        ,PrevPageFID
        ,PrevPagePID
        ,NextPageFID
        ,NextPagePID
   FROM #DBCCIND
  WHERE PrevPagePID = 0                 --First logical page of index
    AND IndexLevel  = 0                 --Only want to use leaf-level pages
    AND iam_chain_type = 'In-row data'  --Only include leaf-level index pages
  UNION ALL
 --==== Recursive section walks through the pages in logical order according to the next page ID.
 SELECT  PageSort = cte.PageSort + 1
        ,tbl.PageFID
        ,tbl.PagePID
        ,tbl.PrevPageFID
        ,tbl.PrevPagePID
        ,tbl.NextPageFID
        ,tbl.NextPagePID
   FROM cteEnumerate cte
   JOIN #DBCCIND     tbl
     ON tbl.PageFID         = cte.NextPageFID
    AND tbl.PagePID         = cte.NextPagePID
  WHERE tbl.IndexLevel      = 0             --Only want to use leaf-level pages
    AND tbl.iam_chain_type  = 'In-row data' --Only include leaf-level index pages
)
--===== This returns and remembers only those rows that are evenly divisible by the sample size so that we don't go 
     -- over 100,000 rows.
 SELECT *
        ,PageRowCount   = CONVERT(SMALLINT,0)
        ,PageFreeBytes  = CONVERT(SMALLINT,0)
        ,PageUsedBytes  = CONVERT(SMALLINT,0)
        ,PageDensity    = CONVERT(FLOAT,0.0)
   INTO #IndexPageSpace 
   FROM cteEnumerate
  WHERE PageSort % @SampleSize = 0
 OPTION (MAXRECURSION 0, RECOMPILE)
;
--===== We need a good index on the table for the upcoming page information evaluations.
CREATE UNIQUE CLUSTERED INDEX PK_#IndexPageSpace ON #IndexPageSpace (PageSort)
;
--=====================================================================================================================
--      Read each page header using DBCC PAGE to capture the m_freeCnt value, which is used to calculate PageDensity.
--      Note that we do NOT need to set a Trace Flag for this because of the TABLERESULTS option.
--      And, yes, we're calculating some stuff we don't need right now. Those are for future enhancements.
--=====================================================================================================================
--===== Preset the loop control variables
 SELECT  @MaxPageSort   = MAX(PageSort) 
        ,@Counter       = 0 --Yeah... Necessary RBAR on Steroids comin' up!
  FROM #IndexPageSpace
;
--===== Run DBCC PAGE for each page we have stored in the #IndexTable and save the page density information.
  WHILE @Counter <= @MaxPageSort  --Yeah... I know... but the RBAR is unavoidable here.
  BEGIN
        --===== Empty the page info table for each iteration. 
        TRUNCATE TABLE #PageInfo
        ;
        --===== Create the dynamic SQL to read the page header for this current page.
         SELECT @SQL  = REPLACE(REPLACE(REPLACE(
                        'DBCC PAGE (<<DB_Name>>,<<PageFID>>,<<PagePID>>,0) WITH NO_INFOMSGS, TABLERESULTS;'
                        ,'<<DB_Name>>',DB_NAME())
                        ,'<<PageFID>>',CONVERT(VARCHAR(10),PageFID))
                        ,'<<PagePID>>',CONVERT(VARCHAR(10),PagePID))
           FROM #IndexPageSpace
          WHERE PageSort = @Counter
        ;
        --===== Capture the current page info and save it so we can filter it for what we need.
         INSERT INTO #PageInfo
                (ParentObject,Object,Field,Value)
           EXEC (@SQL)
        ;
        --===== Get the page row count and freespace in bytes. Use the freespace value to calculate PageDensity. 
         SELECT  @PageRowCount  = MAX(CASE WHEN Field = 'm_slotCnt' THEN VALUE ELSE 0 END)
                ,@PageFreeBytes = MAX(CASE WHEN Field = 'm_freeCnt' THEN VALUE ELSE 0 END)
                ,@PageUsedBytes = 8096-@PageFreeBytes --Yes, 8060 is NOT the correct number!!!
                ,@PageDensity   = @PageUsedBytes*100.0/8096.0
           FROM #PageInfo
        ;
        --===== Update the page info in the pagespace table.
             -- Again, we're capturing some things that we won't need until a future rev.
         UPDATE #IndexPageSpace
            SET  PageRowCount   = @PageRowCount
                ,PageFreeBytes  = @PageFreeBytes
                ,PageUsedBytes  = @PageUsedBytes
                ,PageDensity    = @PageDensity
          WHERE PageSort = @Counter
        ;
        --===== Bump the loop counter
         SELECT @Counter = @Counter + @SampleSize
        ;
    END
;
--===== Final rinse and filter to return the page densities in the correct order to we can see the pattern they form
     -- in the scatter chart in the Excel spreadsheet.
 SELECT PageSort, PageDensity
   FROM #IndexPageSpace 
  ORDER BY PageSort
;
