USE [master]
--This script contains code at the end of the script to convert the new stored procedure into a system stored procedure.
GO
 CREATE PROCEDURE [dbo].[sp_AnalyzeExpansiveUpdates]
/**********************************************************************************************************************
 Purpose:
 This stored procedure produces and aggregated result set to aid in the analysis of "ExpAnsive" updates in tables
 and the related indexes.
-----------------------------------------------------------------------------------------------------------------------
 Example Usage:
   EXEC sp_AnalyzeExpansiveUpdates
;
-----------------------------------------------------------------------------------------------------------------------
 Dependencies:
 1. The dbo.DBA_ExpansiveUpdateLog table, which is created by the separate sp_CreateExpansiveUpdateTrigger stored
    procedure must exist in the "current" database and the related triggers must be actively populating the table for
    results to be returned.
-----------------------------------------------------------------------------------------------------------------------
 Programmer Notes:
 1. This code is easiest to use when it lives in the master database as a "system stored procedure".  That allows it
    to be used from any database just by calling it from the database where the target table lives.

    If you do create the stored procedure in the master database, then make the stored procedure a "system" stored
    procedure by executing the following code:

    USE MASTER;  
--===== Reclassify the stored procedure as a system stored procedure.
   EXEC sp_ms_marksystemobject 'sp_AnalyzeExpansiveUpdates'
;  
--===== If the following code returns a 1 for "is_ms_shipped", then it worked.
 SELECT name, is_ms_shipped   
   FROM sys.objects  
  WHERE name = 'sp_AnalyzeExpansiveUpdates'  
;
-----------------------------------------------------------------------------------------------------------------------
 Revision History:
 Rev 00 - 19 Jan 2019 - Jeff Moden
        - Conversion and unit test of "Proof-of-Principle" code to fully documented code.
**********************************************************************************************************************/
--===== Parameters for this proc
     -- (This procedure takes no parameters)
     AS
   WITH cte AS
(--==== Find by table/column and column size that have been updated and count them
 SELECT TableFullName, ColumnName, MaxNewLen, TotalUpdateCnt = SUM(UpdateCnt) 
   FROM dbo.DBA_ExpansiveUpdateLog 
  WHERE UpdateCnt > 0 AND IsExpansive = 1
  GROUP BY TableFullName, ColumnName, MaxNewLen
)--==== Produce the list by table/column name/MaxNewLen with the percentage that each length represents as a part of
     -- all the updates for the given column to help identify what a possible max default length should be to keep
     -- columns from being "ExpAnsive".  This will also help determine which columns might be converted to LOBs
     -- so that they can be moved to "Out of Row" to increase the performance of other queries while preventing
     -- "ExpAnsive" updates in the process.
 SELECT *
		,RunTotalPct = CONVERT(DECIMAL(9,1)
                           ,SUM(TotalUpdateCnt) OVER (PARTITION BY TableFullName,ColumnName ORDER BY MaxNewLen)
                           * 100.0 / SUM(TotalUpdateCnt) OVER (PARTITION BY TableFullName,ColumnName)
                       )
		,RunTotal = SUM(TotalUpdateCnt) OVER (PARTITION BY TableFullName,ColumnName ORDER BY MaxNewLen)
   FROM cte
  ORDER BY TableFullName, ColumnName, MaxNewLen
;
GO
--=====================================================================================================================
--      Change the stored procedure that we just created into a "System Stored Procedure" so that we can execute it
--      from any "current" database.
--=====================================================================================================================
    USE MASTER;  
--===== Reclassify the stored procedure as a system stored procedure.
   EXEC sp_ms_marksystemobject 'sp_AnalyzeExpansiveUpdates'
;  
--===== If the following code returns a 1 for "is_ms_shipped", then it worked.
 SELECT name, is_ms_shipped   
   FROM sys.objects  
  WHERE name = 'sp_AnalyzeExpansiveUpdates'  
;
GO