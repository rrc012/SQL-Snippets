SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#Numbers', 'U') IS NOT NULL DROP TABLE #Numbers;
GO

SELECT TOP (10) ROW_NUMBER() OVER (ORDER BY(SELECT 1)) AS Nbrs
  INTO #Numbers
  FROM sys.all_columns ac1 
       CROSS JOIN sys.all_columns ac2;

WITH RecursiveCTE AS (
SELECT Nbrs,
       CAST('R0' AS VARCHAR(20)) AS RunningSumExpr,
       Nbrs AS RunningSum,
       CAST('R0' AS VARCHAR(20)) AS RunningPrdExpr,
       Nbrs AS RunningPrd
  FROM #Numbers
 WHERE Nbrs = 1
 UNION ALL
SELECT C0.Nbrs,
       CAST(CONCAT('R', C1.Nbrs, ' ---> ', C0.Nbrs, '+', C1.RunningSum) AS VARCHAR(20)),
       C0.Nbrs + C1.RunningSum,
       CAST(CONCAT('R', C1.Nbrs, ' ---> ', C0.Nbrs, '*', C1.RunningPrd) AS VARCHAR(20)),
       C0.Nbrs * C1.RunningPrd
  FROM #Numbers AS C0
       INNER JOIN RecursiveCTE AS C1 ON C0.Nbrs = C1.Nbrs+1
)
SELECT *
  FROM RecursiveCTE;

/*
Step 0: Execute the anchor part and get the result R0.
Step 1: Execute the recursive member using R0 as input and generate R1.
Step 2: Execute the recursive member using R1 as input and generate R2.
Step 3: Recursion continues till the recursive member ouput becomes NULL.
Step 4: Finally apply the UNION ALL on all the resultsets obtained to generate the output.

R0 - 1, 1
R1 - 2, 2*1
R2 - 3, 3*2*1
R3 - 4, 4*3*2*1
--*/

IF OBJECT_ID('tempdb..#Numbers', 'U') IS NOT NULL DROP TABLE #Numbers;
GO