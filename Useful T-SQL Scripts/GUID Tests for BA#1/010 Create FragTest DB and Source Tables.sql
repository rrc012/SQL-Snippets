/**********************************************************************************************************************
 Purpose:
 1. Create the "FragTest" database.
 2. Create the unsorted "GuidSource" table used for repeatable testing across multiple Fill Factors.
 3. Create the sorted "GuidSourceSorted" table to be used for the "Append Only Baseline" testing.
 4. Create the "IxPageStats" table where all durations and page counts from every test will be stored.
-----------------------------------------------------------------------------------------------------------------------
 Operator Notes:
 1. It takes this code approximately 00:04:06 (hh:mm:ss) to execute on my laptop running SQL Server 2008 
    Developer's Edition.
 2. The final size of the database this code creates is 15GB.
        The MDF file is 12GB.
        The LDF file is  3GB.
        Both files are created in the directories specified by the instance default file settings.
        If that's not satisfactory, review the code and make the appropriate changes before execution.
 3. The owner of the database will be whomever runs this code.
 4. the database is set to the SIMPLE Recovery Model.
 5. The name of the database is "FragTest"
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
--===== Notify the operator of where they can monitor progress of the code.
    SET NOCOUNT ON;
 SELECT Information = 'See messages tab for progress';
    SET NOCOUNT OFF
;
RAISERROR('
--=====================================================================================================================
--      Drop and create the "FragTest" Database
--=====================================================================================================================
',0,0) WITH NOWAIT
;
--===== Change to a safe place so we don't drop our own connection.
    USE tempdb
;
--===== If the database exists, drop it.
     -- Commented out for safety purposes. Uncomment if you need to do this (destroys ALL collected data, too!)
  --   IF DB_ID('FragTest') IS NOT NULL
  --BEGIN 
  --      RAISERROR('Dropping existing database...',0,0) WITH NOWAIT
  --      ;
  --      --===== Kick everyone and everything out of the database.
  --        ALTER DATABASE FragTest SET SINGLE_USER WITH ROLLBACK IMMEDIATE
  --      ;
  --      --===== Drop the database
  --         DROP DATABASE FragTest
  --      ;
  --  END
  -- ELSE RAISERROR('Database did not exist.',0,0) WITH NOWAIT
;
--===== Create the database using only the defaults and set to the SIMPLE Recovery Model.
RAISERROR('Creating the database...',0,0) WITH NOWAIT
;
 CREATE DATABASE FragTest;
  ALTER DATABASE FragTest SET RECOVERY SIMPLE WITH NO_WAIT
;
--===== PreSize the database so we don't have to wait for growths.
     -- This is only large enough to accomodate the test data that we'll generate in other scripts.
RAISERROR('Presizing the database...',0,0) WITH NOWAIT
;
  ALTER DATABASE FragTest MODIFY FILE (NAME = N'FragTest'    , SIZE = 12000MB, FILEGROWTH = 100MB);
  ALTER DATABASE FragTest MODIFY FILE (NAME = N'FragTest_log', SIZE =  3000MB, FILEGROWTH = 100MB)
;
GO
RAISERROR('
--=====================================================================================================================
--      Create the two source tables (3,650,000 GUIDs each)
--=====================================================================================================================
',0,0) WITH NOWAIT
;
--===== Identify the database to do this in.
    USE FragTest
;
-----------------------------------------------------------------------------------------------------------------------
RAISERROR('Creating the GuidSource table...',0,0) WITH NOWAIT
;
--===== If the test table exists, drop it to make reruns in SSMS easier
     IF OBJECT_ID('dbo.GuidSource','U') IS NOT NULL
   DROP TABLE dbo.GuidSource
;
--===== Create the table with a row number for easy access to each GUID.
 CREATE TABLE dbo.GuidSource
        (
         RowNum INT IDENTITY(1,1) PRIMARY KEY CLUSTERED
        ,Guid UNIQUEIDENTIFIER
        )
;
--===== Populate the table with millions of Guids. 
     -- THESE WILL BE IN RANDOM ORDER and are used for all tests except BASELINEs.
RAISERROR('Populating the GuidSource table...',0,0) WITH NOWAIT;
RAISERROR('(Contains randomized GUIDs)',0,0) WITH NOWAIT
;
 INSERT INTO dbo.GuidSource WITH(TABLOCK)
        (Guid)
 SELECT TOP 3650000
        Guid = NEWID()
   FROM      sys.all_columns ac1
  CROSS JOIN sys.all_columns ac2
;
-----------------------------------------------------------------------------------------------------------------------
    PRINT REPLICATE('-',119);
RAISERROR('Creating the GuidSourceSorted table...',0,0) WITH NOWAIT
;
--===== If the test table exists, drop it to make reruns in SSMS easier
     IF OBJECT_ID('dbo.GuidSourceSorted','U') IS NOT NULL
   DROP TABLE dbo.GuidSourceSorted
;
--===== Create the table with a row number for easy access to each GUID.
 CREATE TABLE dbo.GuidSourceSorted
        (
         RowNum INT IDENTITY(1,1) PRIMARY KEY CLUSTERED
        ,Guid UNIQUEIDENTIFIER
        )
;
--===== Populate the table with millions of Guids. 
     -- THESE WILL BE IN SORTED ORDER and are used only for BASELINEs.
RAISERROR('Populating the GuidSourceSorted table...',0,0) WITH NOWAIT;
RAISERROR('(Contains same GUIDs but sorted)',0,0) WITH NOWAIT
;
 INSERT INTO dbo.GuidSourceSorted WITH(TABLOCK)
        (Guid)
 SELECT Guid
   FROM GuidSource
  ORDER BY Guid
;
GO
CHECKPOINT
GO
RAISERROR('
--=====================================================================================================================
--      Create the Test Support Table where we accumulate hourly index information and durations.
--=====================================================================================================================
',0,0) WITH NOWAIT
;
--drop table IxPageStats
--===== Create the table that will contain the output of sys.dm_db_index_physical_stats
RAISERROR('Creating the IxPageStats table...',0,0) WITH NOWAIT
;
     IF OBJECT_ID('dbo.IxPageStats','U') IS NULL 
 CREATE TABLE dbo.IxPageStats  
        (
         IxPageStatsID      INT             IDENTITY(1,1)
        ,TestName           VARCHAR(50)     NOT NULL
        ,BatchDT            DATETIME        NOT NULL
        ,DayNumber          SMALLINT        NOT NULL
        ,HourNumber         TINYINT         NOT NULL
        ,HourRunDur         INT             NOT NULL DEFAULT 0
        ,IndexID            TINYINT         NOT NULL
        ,IndexLevel         TINYINT         NOT NULL
        ,AvgFragPct         FLOAT           NOT NULL
        ,DayHour AS ((('D'+RIGHT(DayNumber+(1000),(3)))+' H')+RIGHT(HourNumber+(100),(2))) PERSISTED
        ,PageCount          BIGINT          NOT NULL
        ,AvgSpaceUsedPct    FLOAT           NOT NULL
        ,Rows               BIGINT          NOT NULL
        ,AvgRowSize         FLOAT           NOT NULL
        ,DefragType         CHAR(7)         NOT NULL DEFAULT ''
        ,DefragDur          INT             NULL
        )
;
RAISERROR('
--=====================================================================================================================
--      Run complete.
--=====================================================================================================================
',0,0) WITH NOWAIT
;
GO