
/**********************************************************************************************************************
 Purpose:
 This code produces the output portrayed in the table-charts that compare the performance of SELECTs.
-----------------------------------------------------------------------------------------------------------------------
 Operator Notes:
 1. It takes this code approximately xx:xx:xx (hh:mm:ss) to execute on my laptop running SQL Server 2008 
    Developer's Edition.
 2. Prior to each group of 5 tests, the Proc Cache and the Buffer Cache is cleared.  This allows us to examine 2 things:
        What the metrics are when Read-Aheads occur on the first run.
        What the metrics are when the data is alread present in memory and Read-Aheads are not necessary.
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
--=====================================================================================================================
--      Retreive 100,000 rows each from Baseline, Daily defragged, and NoDefrag
--      All produce MERGE Joins and SCANs
--=====================================================================================================================
PRINT REPLICATE('=',120);
PRINT '========== Baseline =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME,IO ON;
 SELECT tt.* 
   FROM dbo.Baseline tt
   JOIN dbo.GuidSourceSorted gss
     ON tt.Guid = gss.Guid
  WHERE gss.RowNum BETWEEN 1000000 AND 1099999
SET STATISTICS TIME,IO OFF;
GO 5
PRINT REPLICATE('=',120);
PRINT '========== BPDD_FF100 =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME,IO ON; 
 SELECT tt.*
   FROM dbo.BPDD_FF100 tt
   JOIN dbo.GuidSourceSorted gss
     ON tt.Guid = gss.Guid
  WHERE gss.RowNum BETWEEN 1000000 AND 1099999
SET STATISTICS TIME,IO OFF;
GO 5
PRINT REPLICATE('=',120);
PRINT '========== BPDD_FF090 =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME,IO ON; 
 SELECT tt.*
   FROM dbo.BPDD_FF090 tt
   JOIN dbo.GuidSourceSorted gss
     ON tt.Guid = gss.Guid
  WHERE gss.RowNum BETWEEN 1000000 AND 1099999
SET STATISTICS TIME,IO OFF;
GO 5
PRINT REPLICATE('=',120);
PRINT '========== BPDD_FF080 =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME,IO ON; 
 SELECT tt.*
   FROM dbo.BPDD_FF080 tt
   JOIN dbo.GuidSourceSorted gss
     ON tt.Guid = gss.Guid
  WHERE gss.RowNum BETWEEN 1000000 AND 1099999
SET STATISTICS TIME,IO OFF;
GO 5
PRINT REPLICATE('=',120);
PRINT '========== BPDD_FF070 =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME,IO ON; 
 SELECT tt.*
   FROM dbo.BPDD_FF070 tt
   JOIN dbo.GuidSourceSorted gss
     ON tt.Guid = gss.Guid
  WHERE gss.RowNum BETWEEN 1000000 AND 1099999
SET STATISTICS TIME,IO OFF;
GO 5
PRINT REPLICATE('=',120);
PRINT '========== NoDefrag =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME,IO ON;
 SELECT tt.GUID,tt.Fluff
   FROM dbo.NoDefrag tt
   JOIN dbo.GuidSourceSorted gss
     ON tt.Guid = gss.Guid
  WHERE gss.RowNum BETWEEN 1000000 AND 1099999
SET STATISTICS TIME,IO OFF;
GO 5
--=====================================================================================================================
--      Retreive 10,000 rows each from Baseline, Daily defragged, and NoDefrag
--      All produce LOOP Joins and SEEKS
--=====================================================================================================================
PRINT REPLICATE('=',120);
PRINT '========== Baseline =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME,IO ON;
 SELECT tt.* 
   FROM dbo.Baseline tt
   JOIN dbo.GuidSourceSorted gss
     ON tt.Guid = gss.Guid
  WHERE gss.RowNum BETWEEN 1000000 AND 1009999
SET STATISTICS TIME,IO OFF;
GO 5
PRINT REPLICATE('=',120);
PRINT '========== BPDD_FF100 =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME,IO ON; 
 SELECT tt.*
   FROM dbo.BPDD_FF100 tt
   JOIN dbo.GuidSourceSorted gss
     ON tt.Guid = gss.Guid
  WHERE gss.RowNum BETWEEN 1000000 AND 1009999
SET STATISTICS TIME,IO OFF;
GO 5
PRINT REPLICATE('=',120);
PRINT '========== BPDD_FF090 =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME,IO ON; 
 SELECT tt.*
   FROM dbo.BPDD_FF090 tt
   JOIN dbo.GuidSourceSorted gss
     ON tt.Guid = gss.Guid
  WHERE gss.RowNum BETWEEN 1000000 AND 1009999
SET STATISTICS TIME,IO OFF;
GO 5
PRINT REPLICATE('=',120);
PRINT '========== BPDD_FF080 =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME,IO ON; 
 SELECT tt.*
   FROM dbo.BPDD_FF080 tt
   JOIN dbo.GuidSourceSorted gss
     ON tt.Guid = gss.Guid
  WHERE gss.RowNum BETWEEN 1000000 AND 1009999
SET STATISTICS TIME,IO OFF;
GO 5
PRINT REPLICATE('=',120);
PRINT '========== BPDD_FF070 =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME,IO ON; 
 SELECT tt.*
   FROM dbo.BPDD_FF070 tt
   JOIN dbo.GuidSourceSorted gss
     ON tt.Guid = gss.Guid
  WHERE gss.RowNum BETWEEN 1000000 AND 1009999
SET STATISTICS TIME,IO OFF;
GO 5
PRINT REPLICATE('=',120);
PRINT '========== NoDefrag =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME,IO ON;
 SELECT tt.GUID,tt.Fluff
   FROM dbo.NoDefrag tt
   JOIN dbo.GuidSourceSorted gss
     ON tt.Guid = gss.Guid
  WHERE gss.RowNum BETWEEN 1000000 AND 1009999
SET STATISTICS TIME,IO OFF;
GO 5
--=====================================================================================================================
--      Retreive 10,000 rows each from Baseline, Daily defragged, and NoDefrag
--      All produce a simple Seek and Range Scan for the SELECT being measured.
--=====================================================================================================================
PRINT REPLICATE('=',120);
PRINT '========== Baseline =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
DECLARE  @LoGuid UNIQUEIDENTIFIER = (SELECT [Guid] FROM dbo.GuidSourceSorted WHERE RowNum = 1000000)
        ,@HiGuid UNIQUEIDENTIFIER = (SELECT [Guid] FROM dbo.GuidSourceSorted WHERE RowNum = 1099999)
;
    SET STATISTICS TIME,IO ON;
 SELECT tst.*
   FROM dbo.Baseline tst
  WHERE GUID BETWEEN @LoGuid AND @HiGuid;
    SET STATISTICS TIME,IO OFF;
GO 5
PRINT REPLICATE('=',120);
PRINT '========== BPDD_FF100 =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
DECLARE  @LoGuid UNIQUEIDENTIFIER = (SELECT [Guid] FROM dbo.GuidSourceSorted WHERE RowNum = 1000000)
        ,@HiGuid UNIQUEIDENTIFIER = (SELECT [Guid] FROM dbo.GuidSourceSorted WHERE RowNum = 1099999)
;
    SET STATISTICS TIME,IO ON;
 SELECT tst.*
   FROM dbo.BPDD_FF100 tst
  WHERE GUID BETWEEN @LoGuid AND @HiGuid;
    SET STATISTICS TIME,IO OFF;
GO 5
PRINT REPLICATE('=',120);
PRINT '========== BPDD_FF090 =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
DECLARE  @LoGuid UNIQUEIDENTIFIER = (SELECT [Guid] FROM dbo.GuidSourceSorted WHERE RowNum = 1000000)
        ,@HiGuid UNIQUEIDENTIFIER = (SELECT [Guid] FROM dbo.GuidSourceSorted WHERE RowNum = 1099999)
;
    SET STATISTICS TIME,IO ON;
 SELECT tst.*
   FROM dbo.BPDD_FF090 tst
  WHERE GUID BETWEEN @LoGuid AND @HiGuid;
    SET STATISTICS TIME,IO OFF;
GO 5
PRINT REPLICATE('=',120);
PRINT '========== BPDD_FF080 =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
DECLARE  @LoGuid UNIQUEIDENTIFIER = (SELECT [Guid] FROM dbo.GuidSourceSorted WHERE RowNum = 1000000)
        ,@HiGuid UNIQUEIDENTIFIER = (SELECT [Guid] FROM dbo.GuidSourceSorted WHERE RowNum = 1099999)
;
    SET STATISTICS TIME,IO ON;
 SELECT tst.*
   FROM dbo.BPDD_FF080 tst
  WHERE GUID BETWEEN @LoGuid AND @HiGuid;
    SET STATISTICS TIME,IO OFF;
GO 5
PRINT REPLICATE('=',120);
PRINT '========== BPDD_FF070 =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
DECLARE  @LoGuid UNIQUEIDENTIFIER = (SELECT [Guid] FROM dbo.GuidSourceSorted WHERE RowNum = 1000000)
        ,@HiGuid UNIQUEIDENTIFIER = (SELECT [Guid] FROM dbo.GuidSourceSorted WHERE RowNum = 1099999)
;
    SET STATISTICS TIME,IO ON;
 SELECT tst.*
   FROM dbo.BPDD_FF070 tst
  WHERE GUID BETWEEN @LoGuid AND @HiGuid;
    SET STATISTICS TIME,IO OFF;
GO 5
PRINT REPLICATE('=',120);
PRINT '========== NoDefrag =========='
DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
DECLARE  @LoGuid UNIQUEIDENTIFIER = (SELECT [Guid] FROM dbo.GuidSourceSorted WHERE RowNum = 1000000)
        ,@HiGuid UNIQUEIDENTIFIER = (SELECT [Guid] FROM dbo.GuidSourceSorted WHERE RowNum = 1099999)
;
    SET STATISTICS TIME,IO ON;
 SELECT tst.*
   FROM dbo.NoDefrag tst
  WHERE GUID BETWEEN @LoGuid AND @HiGuid;
    SET STATISTICS TIME,IO OFF;
GO 5
