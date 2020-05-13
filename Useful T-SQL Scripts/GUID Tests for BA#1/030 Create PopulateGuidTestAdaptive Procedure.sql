   USE FragTest
-- DROP PROCEDURE dbo.PopulateGuidTestAdaptive
GO
 CREATE PROCEDURE dbo.PopulateGuidTestAdaptive
/**********************************************************************************************************************
 Purpose:
 This stored procedure will run one fragmentation test depending on the parameters that are provided.  
-----------------------------------------------------------------------------------------------------------------------
 Operator Notes:
 1. The GuidTest table is dropped and recreated as a target for each test.  This prevents the need for a lot of
    Dynamic SQL.
 2. The test table consists of two columns
        The GUID column itself and will always be the Clustered Index.
        The Fluff column, which contains a fixed CHAR() datatype to simulate a multitude of other columns to simulate
            a realistic row length. The size of the Fluff column is variable by parameter.
        To simulate a narrow non-clustered index, set the size of the Fluff column to something like 1.  It cannot be
            zero.
 3. This code is part of a test harness. There is little that's been done to protect the operatore from mistakes in 
    the parameters.
 4. This code will not work without the GuidSource and GuidSourceSorted tables that are created and populate by
    script 010 of this collection of scripts.
-----------------------------------------------------------------------------------------------------------------------
 Revision History:
 Rev 00 - 12 Nov 2017 - Jeff Moden
        - Initial creation and use.
 Rev 01 - 29 May 2018 - Jeff Moden
        - Modify the code for easy use by others.
        - Add more documentation to the code for easy use by others.
 Rev 02 - 31 Dec 2018 - Jeff Moden
        - Add Flower-Box header to augment understanding by others.
**********************************************************************************************************************/
--===== Parameters
         @pTestName             VARCHAR(50) -- Name of the test (NOT checked for duplicates)
        ,@pTestDays             INT         -- Number of simulated test days (365 used for my tests) 
        ,@pHoursPerDay          INT         -- Number of simulated hours per day (10 used for my tests
        ,@pRowsPerHour          INT         -- Number of separated inserts to do per hour (1000 used for my tests)
        ,@pFillFactor           INT         -- Fill Factor to test with
        ,@pFluffSize            INT         -- Size of "additional columns" to add bulk to each row.
        ,@pDF_StartPageCount    INT         -- Minimum number of pages before any defragging will occur.
        ,@pDF_ReorgPercent      FLOAT       -- Min % Of fragmentation to do a REORG at. 0 means "No Reorg".
        ,@pDF_RebuildPercent    FLOAT       -- Min % Of fragmentation to do a REBUILD at. 0 means "No Rebuild".
        ,@pDF_Days              INT         -- 1 means test for defrag "EveryDay", 7 means once per week (for example).
        ,@pDF_IsAdaptive        BIT = 0     -- Future Use.
        ,@pDF_AdaptivePercent   INT = 10    -- Future Use.
     AS
--=====================================================================================================================
--      Presets
--=====================================================================================================================
--===== Environment Settings
    SET NOCOUNT ON
;
        RAISERROR('Running %s',0,0,@pTestName) WITH NOWAIT;
;
--===== Local Variables
DECLARE  @BatchDT           DATETIME = GETDATE()
        ,@BitBucket         UNIQUEIDENTIFIER
        ,@CumeRunDur        INT --
        ,@DayCounter        INT      --
        ,@DefragStartDT     DATETIME --
        ,@DefragDur         INT = 0
        ,@DefragType        CHAR(7) = ''
        ,@AdaptFillFactor   VARCHAR(3)
        ,@FragPercent       DECIMAL(9,2)
        ,@GuidRowNum        INT      --
        ,@HourCounter       INT      --
        ,@HourRunDur        INT
        ,@HourStartDt       DATETIME
        ,@NeedsDefrag       INT
        ,@PageCount         BIGINT
        ,@RowCounter        INT
        ,@SQL               VARCHAR(8000)
;
--===== Start with the first GUID from the source table (sorted or unsorted table)
 SELECT @GuidRowNum = 1
;
--=====================================================================================================================
--      Create or Recreate the TestTable
--=====================================================================================================================
--===== If the test table exists, drop it to make reruns in SSMS easier.
     IF OBJECT_ID('dbo.GuidTest','U') IS NOT NULL
  BEGIN
           DROP TABLE dbo.GuidTest; 
    END
;
--===== Create the test table. We'll alter it in a minute to change the fluff size.
 CREATE TABLE dbo.GuidTest
        (
         GUID  UNIQUEIDENTIFIER NOT NULL
        )
;
--===== Alter the table to have the correct fluff size using dynamic SQL.
 SELECT @SQL = '
  ALTER TABLE dbo.GuidTest 
    ADD Fluff CHAR('+ CONVERT(VARCHAR(10),@pFluffSize) + ')  NOT NULL DEFAULT ''X'';'
;
   EXEC (@SQL)
;
--===== Create the primary key with the desired FILL FACTOR using dynamic SQL.
 SELECT @SQL  = '
--===== Add the PK as an index so we can control the FILL FACTOR
 CREATE UNIQUE CLUSTERED INDEX PK_GuidTest
     ON dbo.GuidTest (GUID) WITH (FILLFACTOR = ' + CONVERT(VARCHAR(10),@pFillFactor) + ');'
;
   EXEC (@SQL)
;
--=====================================================================================================================
--      Do the Test Run
--      3 Loops... 1 Loop per @pTestDays, @pHoursPerDay hour loops per day, @pRowsPerHour row loops per hour.
--      We'll only include the hour loops in the @CumeRunDur because the rest of the code is for measurements.
--=====================================================================================================================
--===== Day Counter Loop
 SELECT  @DayCounter  = 1
        ,@HourCounter = 0
;
--===== For each day, measure the starting and hourly fragmentation as we build data.
  WHILE @DayCounter <= @pTestDays
  BEGIN 
        --===== Measure the fragmentation at the start of the day and do other counts at the end of the hour.
             -- This marks H00. H00 is the starting mark for each day.
             -- Indications of the previous day defrag type will appear here, if a defrag was done.
         INSERT INTO dbo.IxPageStats
                (
                 TestName
                ,BatchDT             
                ,DayNumber                     
                ,HourNumber                    
                ,IndexID                     
                ,IndexLevel                   
                ,AvgFragPct  
                ,PageCount                    
                ,AvgSpaceUsedPct
                ,Rows                  
                ,AvgRowSize     
                ,DefragType
                ,DefragDur
                )
         SELECT  TestName       = @pTestName
                ,BatchDT        = @BatchDT
                ,DayNumber      = @DayCounter
                ,HourNumber     = @HourCounter
                ,IndexID        = index_id                      
                ,IndexLevels    = index_level                   
                ,AvgFragPct     = avg_fragmentation_in_percent  
                ,PageCount      = page_count                    
                ,AvgSpaceUsedPct= avg_page_space_used_in_percent
                ,Rows           = record_count                  
                ,AvgRowSize     = avg_record_size_in_bytes
                ,DefragType     = @DefragType
                ,DefragDur      = @DefragDur
           FROM sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID('dbo.GuidTest'),NULL,NULL,'DETAILED')
          WHERE index_level = 0
        ;
        ---------------------------------------------------------------------------------------------------------------
        --===== Hour Counter Loop
         SELECT @HourCounter = 1
        ;
          WHILE @HourCounter <= @pHoursPerDay
          BEGIN
        --===== Start the duration timer for this hour
         SELECT @HourStartDt = GETDATE()
        ;
                -------------------------------------------------------------------------------------------------------
                --===== Row Counter Loop
                 SELECT @RowCounter =  1;
                  WHILE @RowCounter <= @pRowsPerHour
                  BEGIN
                        --===== Copy the next guid from the GuidSource table into the test table.
                             -- The source table is in sorted order for the baseline test.
                             -- All other tests are in random order.
                             IF @pTestName NOT LIKE '%Baseline%'
                                 INSERT INTO dbo.GuidTest
                                        (GUID)
                                 SELECT Guid
                                   FROM dbo.GuidSource       --Guids are in random order so SPLITS POSSIBLE.
                                  WHERE RowNum = @GuidRowNum;
                           ELSE --Test name contains the word "Baseline"
                                 INSERT INTO dbo.GuidTest
                                        (GUID)
                                 SELECT Guid
                                   FROM dbo.GuidSourceSorted --Guids are in sorted ordere so NO SPLITS POSSIBLE.
                                  WHERE RowNum = @GuidRowNum
                        ;
                        --===== Bump the Guid Counter
                         SELECT @GuidRowNum = @GuidRowNum + 1
                        ;
                --===== Bump the Row Counter
                 SELECT @RowCounter = @RowCounter + 1
                ;
                END     --This is the end of the row counter loop.
                ;
                -------------------------------------------------------------------------------------------------------
        --===== Remember the time this hour took to run.
         SELECT @HourRunDur = DATEDIFF(ms,@HourStartDt,GETDATE())
        ;
        --===== Measure the fragmentation at the end of each hour and record counts/neasurements.
         INSERT INTO dbo.IxPageStats  
                (
                 TestName
                ,BatchDT
                ,DayNumber                     
                ,HourNumber
                ,HourRunDur
                ,IndexID                      
                ,IndexLevel                   
                ,AvgFragPct  
                ,PageCount                    
                ,AvgSpaceUsedPct
                ,Rows                  
                ,AvgRowSize      
                )
         SELECT  TestName       = @pTestName
                ,BatchDT        = @BatchDT
                ,DayNumber      = @DayCounter
                ,HourNumber     = @HourCounter
                ,HourRunDur     = @HourRunDur
                ,IndexID        = index_id                      
                ,IndexLevels    = index_level                   
                ,AvgFragPct     = avg_fragmentation_in_percent  
                ,PageCount      = page_count                    
                ,AvgSpaceUsedPct= avg_page_space_used_in_percent
                ,Rows           = record_count                  
                ,AvgRowSize     = avg_record_size_in_bytes
           FROM sys.dm_db_index_physical_stats(DB_ID(),OBJECT_ID('dbo.GuidTest'),NULL,NULL,'DETAILED')
          WHERE index_level = 0
        ;
        --===== Bump the Hour Counter
         SELECT @HourCounter = @HourCounter + 1
        ;
        END     --This is the end of the hour counter loop.
        ;
        ---------------------------------------------------------------------------------------------------------------
--===== We're back in the day counter loop here.

--===== Local end-of-day presets
 SELECT  @DefragType = '' --Will be reported at H00 at the begining of the next day.
        ,@DefragDur  = 0  --Will be reported at H00 at the begining of the next day.
;
--===== See if the parameters and conditions match to even consider defragging.
     -- If they match up, then do the defrag check and if that says we need a defrag,
     -- then do the type of defrag according to the parameters and conditions.
     IF @pDF_StartPageCount         > 0  
    AND (@pDF_ReorgPercent          > 0 OR @pDF_RebuildPercent > 0) --and we want some form of defrag
    AND (@DayCounter-1) % @pDF_Days = 0 --and today is a day we want to defrag on (every @pDF_Days)
  BEGIN
        --===== Start the defrag timer.
         SELECT @DefragStartDT = GETDATE()
        ;
        --===== Check fragmentation and the current page count.
             -- Note that @pDF_AdaptivePercent should never be zero but won't come into play later unless
             -- @pDF_IsAdaptive is a positive non-zero value.  You could default it to 1 as a non-adaptive indicator.
         SELECT  @FragPercent       = FragPct
                ,@PageCount         = PageCnt
                ,@AdaptFillFactor   = AdaptFillFactor
           FROM dbo.FragmentationInfo(OBJECT_ID('dbo.GuidTest'),NULL,@pDF_AdaptivePercent)
        ;
        --===== Determine if we need to defrag and the kind of defrag we're going to do.
             -- An emptry string means that we won't be doing a defrag for this iteration.
         SELECT @DefragType = CASE --Will be reported at H00 at the begining of the next day.
                              WHEN @PageCount          < @pDF_StartPageCount                       THEN ''
                              WHEN @pDF_IsAdaptive     > 0
                               AND @pDF_RebuildPercent > 0 AND @FragPercent >= @pDF_RebuildPercent THEN 'Adapt'
                              WHEN @pDF_RebuildPercent > 0 AND @FragPercent >= @pDF_RebuildPercent THEN 'Rebuild'
                              WHEN @pDF_ReorgPercent   > 0 AND @FragPercent >= @pDF_ReorgPercent   THEN 'Reorg'
                              ELSE ''
                              END
        ;
        --===== Defrag only if we need to and do the right kind of defrag as determined above.
             -- Remember that if @DefragType is an empty string, none of these qualify and we won't do a defrag
             -- for this iteration.  These are all mutually exclusive, as well.
             IF @DefragType = 'Rebuild' ALTER INDEX PK_GuidTest ON dbo.GuidTest REBUILD;
             IF @DefragType = 'Reorg'   ALTER INDEX PK_GuidTest ON dbo.GuidTest REORGANIZE
             IF @DefragType = 'Adapt'   
                EXEC ('ALTER INDEX PK_GuidTest ON dbo.GuidTest REBUILD WITH (FILLFACTOR = '+@AdaptFillFactor+');')
        ;
        --===== Remember the defrag run time.
             -- Will be reported at H00 at the begining of the next day.
         SELECT @DefragDur = DATEDIFF(ms,@DefragStartDT,GETDATE()) 
        ;              
    END
;
--===== Bump the Day Counter and Reset the Hour Counter
 SELECT  @DayCounter  = @DayCounter + 1
        ,@HourCounter = 0
END -- This is the end of the day counter loop
;
-----------------------------------------------------------------------------------------------------------------------
        RAISERROR('RUN COMPLETE',0,0) WITH NOWAIT
;
GO