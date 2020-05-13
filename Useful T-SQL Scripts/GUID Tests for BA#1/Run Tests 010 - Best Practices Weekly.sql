/**********************************************************************************************************************
 Purpose:
 This is a test script.
 Defrag Weekly per "Best Practice": Test for whether to defrag or not is executed weekly.
        "Best Practice" runs based on Reorg at 10% fragmentation and Rebuild at 30%.
        Covers Fill Factors of 100, 90, 80, and 70
        Also does the Baseline and NoDefrag runs.
-----------------------------------------------------------------------------------------------------------------------
 Operator Notes:
 1. It takes this code approximately xx:xx:xx (hh:mm:ss) to execute on my laptop running SQL Server 2008 
    Developer's Edition.
 2. Note that after each run is completed, the "GuidTest" table is renamed to match the test. This prevents the need 
    for a lot of Dynamic SQL.  If the rename target already exists, it will be dropped with great predjudice.
 3. The run results are stored in the dbo.IxPageStats created in script 010.
 4. The run results are displayed and the end of the run and are suitable for copy'n'paste to a spreadsheet from the
    grid mode of SSMS.
----------------------------------------------------------------------------------------------------------------------- 
 Revision History:
 Rev 00 - 12 Nov 2017 - Jeff Moden
        - Initial creation and use.
 Rev 01 - 29 May 2018 - Jeff Moden
        - Modify the code for easy use by others.
        - Add more documentation to the code for easy use by others.
 Rev 02 - 31 Dec 2018 - Jeff Moden
        - Modify the Flower-Box header to augment understanding by others.
**********************************************************************************************************************/
--=====================================================================================================================
--      Presets
--=====================================================================================================================
--===== Local Variables
DECLARE  @TestDays           INT
        ,@HoursPerDay        INT
        ,@RowsPerHour        INT
        ,@TestType           CHAR(10)     
        ,@FluffSize          INT
        ,@DF_StartPageCount  INT
        ,@DF_ReorgPercent    INT  
        ,@DF_RebuildPercent  INT 
        ,@DF_Days            INT
;
--===== Constants: These settings affect ALL tests the same way
 SELECT  @TestDays          = 365
        ,@HoursPerDay       = 10
        ,@RowsPerHour       = 1000
        ,@FluffSize         = 100  --Fixed number of bytes to simulates extra columns
        ,@DF_StartPageCount = 1000
        ,@DF_ReorgPercent   = 10   
        ,@DF_RebuildPercent = 30  
        ,@DF_Days           = 7    --Number of days to skip between defrags (7 is "Weekly")
;
--=====================================================================================================================
--      BASELINE: Inputs in sorted "ever increasing" order so NO FRAGMENTATION.  Only "Good" page splits.
--                Uses the dbo.GuidSourceSorted table.
--=====================================================================================================================
        CHECKPOINT;
   DBCC FREEPROCCACHE;
   EXEC dbo.PopulateGuidTestAdaptive
         @pTestName         = 'BaseLine'
        ,@pTestDays         = @TestDays     
        ,@pHoursPerDay      = @HoursPerDay  
        ,@pRowsPerHour      = @RowsPerHour  
        ,@pFillFactor       = 100  
        ,@pFluffSize        = @FluffSize  
        ,@pDF_StartPageCount= @DF_StartPageCount
        ,@pDF_ReorgPercent  = @DF_ReorgPercent   
        ,@pDF_RebuildPercent= @DF_RebuildPercent   
        ,@pDF_Days          = @DF_Days
;
--===== Rename the table to keep it for later experiments
     IF OBJECT_ID('dbo.BaseLine','U') IS NOT NULL
        DROP TABLE dbo.BaseLine
;
   EXEC sp_rename 'dbo.GuidTest','BaseLine'
;
--=====================================================================================================================
--      NoDefrag: Brent's method for index maintenance. Low page splits but massive logical fragmentation.
--                All tests from here-on use the dbo.GuidSource table, which contains random GUIDs.
--=====================================================================================================================    
        CHECKPOINT;
   DBCC FREEPROCCACHE;
   EXEC dbo.PopulateGuidTestAdaptive
         @pTestName         = 'NoDefrag'
        ,@pTestDays         = @TestDays     
        ,@pHoursPerDay      = @HoursPerDay  
        ,@pRowsPerHour      = @RowsPerHour  
        ,@pFillFactor       = 100  
        ,@pFluffSize        = @FluffSize  
        ,@pDF_StartPageCount= @DF_StartPageCount
        ,@pDF_ReorgPercent  = 0  --Don't ever do a reorg
        ,@pDF_RebuildPercent= 0  --Don't ever do a rebuild
        ,@pDF_Days          = @DF_Days
;
--===== Rename the table to keep it for later experiments
     IF OBJECT_ID('dbo.NoDefrag','U') IS NOT NULL
        DROP TABLE dbo.NoDefrag
;
   EXEC sp_rename 'dbo.GuidTest','NoDefrag'
;
--=====================================================================================================================
--      "Best Practice" runs based on Reorg at 10% fragmentation and Rebuild at 30%.
--      Covers Fill Factors of 100, 90, 80, and 70
--=====================================================================================================================    
--===== Best Practice w/Fill Factor = 100
        CHECKPOINT;
   DBCC FREEPROCCACHE;
   EXEC dbo.PopulateGuidTestAdaptive
         @pTestName         = 'BPWK_FF100'
        ,@pTestDays         = @TestDays     
        ,@pHoursPerDay      = @HoursPerDay  
        ,@pRowsPerHour      = @RowsPerHour  
        ,@pFillFactor       = 100  
        ,@pFluffSize        = @FluffSize  
        ,@pDF_StartPageCount= @DF_StartPageCount
        ,@pDF_ReorgPercent  = @DF_ReorgPercent   
        ,@pDF_RebuildPercent= @DF_RebuildPercent   
        ,@pDF_Days          = @DF_Days
;
--===== Rename the table to keep it for later experiments
     IF OBJECT_ID('dbo.BPWK_FF100','U') IS NOT NULL
        DROP TABLE dbo.BPWK_FF100
;
   EXEC sp_rename 'dbo.GuidTest','BPWK_FF100'
;
-----------------------------------------------------------------------------------------------------------------------
--===== Best Practice w/Fill Factor = 90
        CHECKPOINT;
   DBCC FREEPROCCACHE;
   EXEC dbo.PopulateGuidTestAdaptive
         @pTestName         = 'BPWK_FF090'
        ,@pTestDays         = @TestDays     
        ,@pHoursPerDay      = @HoursPerDay  
        ,@pRowsPerHour      = @RowsPerHour  
        ,@pFillFactor       = 90   
        ,@pFluffSize        = @FluffSize  
        ,@pDF_StartPageCount= @DF_StartPageCount
        ,@pDF_ReorgPercent  = @DF_ReorgPercent   
        ,@pDF_RebuildPercent= @DF_RebuildPercent   
        ,@pDF_Days          = @DF_Days
;
--===== Rename the table to keep it for later experiments
     IF OBJECT_ID('dbo.BPWK_FF090','U') IS NOT NULL
        DROP TABLE dbo.BPWK_FF090
;
   EXEC sp_rename 'dbo.GuidTest','BPWK_FF090'
;
-----------------------------------------------------------------------------------------------------------------------
--===== Best Practice w/Fill Factor = 80
        CHECKPOINT;
   DBCC FREEPROCCACHE;
   EXEC dbo.PopulateGuidTestAdaptive
         @pTestName         = 'BPWK_FF080'
        ,@pTestDays         = @TestDays     
        ,@pHoursPerDay      = @HoursPerDay  
        ,@pRowsPerHour      = @RowsPerHour  
        ,@pFillFactor       = 80   
        ,@pFluffSize        = @FluffSize  
        ,@pDF_StartPageCount= @DF_StartPageCount
        ,@pDF_ReorgPercent  = @DF_ReorgPercent   
        ,@pDF_RebuildPercent= @DF_RebuildPercent   
        ,@pDF_Days          = @DF_Days
;
--===== Rename the table to keep it for later experiments
     IF OBJECT_ID('dbo.BPWK_FF080','U') IS NOT NULL
        DROP TABLE dbo.BPWK_FF080
;
   EXEC sp_rename 'dbo.GuidTest','BPWK_FF080'
;
-----------------------------------------------------------------------------------------------------------------------
--===== Best Practice w/Fill Factor = 70
        CHECKPOINT;
   DBCC FREEPROCCACHE;
   EXEC dbo.PopulateGuidTestAdaptive
         @pTestName         = 'BPWK_FF070'
        ,@pTestDays         = @TestDays     
        ,@pHoursPerDay      = @HoursPerDay  
        ,@pRowsPerHour      = @RowsPerHour  
        ,@pFillFactor       = 70   
        ,@pFluffSize        = @FluffSize  
        ,@pDF_StartPageCount= @DF_StartPageCount
        ,@pDF_ReorgPercent  = @DF_ReorgPercent   
        ,@pDF_RebuildPercent= @DF_RebuildPercent   
        ,@pDF_Days          = @DF_Days
;
--===== Rename the table to keep it for later experiments
     IF OBJECT_ID('dbo.BPWK_FF070','U') IS NOT NULL
        DROP TABLE dbo.BPWK_FF070
;
   EXEC sp_rename 'dbo.GuidTest','BPWK_FF070'
;
-----------------------------------------------------------------------------------------------------------------------
--=====================================================================================================================
--      Create the chart-set output for the spreadsheet.
--===================================================================================================================== 
 SELECT  [DayHour]
        ,[Baseline] = MAX(CASE WHEN TestName = 'Baseline' THEN PageCount ELSE 0 END)
        ,[B]        = ''
        ,[NoDefrag] = MAX(CASE WHEN TestName = 'NoDefrag' THEN PageCount ELSE 0 END)
        ,[N]        = ''
        ,[FF=100]   = MAX(CASE WHEN TestName LIKE '%100'  THEN PageCount ELSE 0 END)
        ,[100]      = ''
        ,[FF=90]    = MAX(CASE WHEN TestName LIKE '%090'  THEN PageCount ELSE 0 END)
        ,[90]       = ''
        ,[FF=80]    = MAX(CASE WHEN TestName LIKE '%080'  THEN PageCount ELSE 0 END)
        ,[80]       = ''
        ,[FF=70]    = MAX(CASE WHEN TestName LIKE '%070'  THEN PageCount ELSE 0 END)
        ,[70]       = ''
   FROM dbo.IxPageStats
  WHERE TestName LIKE 'BPWK%'
     OR TestName IN  ('Baseline','NoDefrag')
  GROUP BY DayHour
  ORDER BY DayHour
;
--=====================================================================================================================
--      Run Complete
--=====================================================================================================================    
        CHECKPOINT;
  PRINT '***** Run Complete *****'
;
GO