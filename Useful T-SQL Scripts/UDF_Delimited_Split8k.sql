IF EXISTS (SELECT * FROM sys.sysobjects WHERE name = 'udf_DelimitedSplit8K' AND xtype = 'IF')
BEGIN
	 DROP FUNCTION dbo.udf_DelimitedSplit8K;
END
GO

CREATE FUNCTION dbo.udf_DelimitedSplit8K
--===== Define I/O parameters
        (@pString VARCHAR(8000), @pDelimiter CHAR(1))
--WARNING!!! DO NOT USE MAX DATA-TYPES HERE!  IT WILL KILL PERFORMANCE!
RETURNS TABLE WITH SCHEMABINDING AS
 RETURN

/*
 ======================================================================
 Author:	     Jeff Moden
 Source:       http://www.sqlservercentral.com/articles/Tally+Table/72993/
 Create Date:  28-DEC-2012
 Description:  This user-defined function splits a csv list of values
			into individual elements
 Revision History:
 14-JAN-2013 - RAGHUNANDAN CUMBAKONAM 
			Formatted the code.
			Renamed the function.
			Added the usage and history.
 Usage:		
 
 IF OBJECT_ID('tempdb..#JBMTest') IS NOT NULL DROP TABLE #JBMTest;
 SELECT *
   INTO #JBMTest
   FROM (                                               --# & type of Return Row(s)
         SELECT  0, NULL                      UNION ALL --1 NULL
         SELECT  1, SPACE(0)                  UNION ALL --1 b (Empty String)
         SELECT  2, SPACE(1)                  UNION ALL --1 b (1 space)
         SELECT  3, SPACE(5)                  UNION ALL --1 b (5 spaces)
         SELECT  4, ','                       UNION ALL --2 b b (both are empty strings)
         SELECT  5, '55555'                   UNION ALL --1 E
         SELECT  6, ',55555'                  UNION ALL --2 b E
         SELECT  7, ',55555,'                 UNION ALL --3 b E b
         SELECT  8, '55555,'                  UNION ALL --2 b B
         SELECT  9, '55555,1'                 UNION ALL --2 E E
         SELECT 10, '1,55555'                 UNION ALL --2 E E
         SELECT 11, '55555,4444,333,22,1'     UNION ALL --5 E E E E E 
         SELECT 12, '55555,4444,,333,22,1'    UNION ALL --6 E E b E E E
         SELECT 13, ',55555,4444,,333,22,1,'  UNION ALL --8 b E E b E E E b
         SELECT 14, ',55555,4444,,,333,22,1,' UNION ALL --9 b E E b b E E E b
         SELECT 15, ' 4444,55555 '            UNION ALL --2 E (w/Leading Space) E (w/Trailing Space)
         SELECT 16, 'This,is,a,test.'                   --E E E E
        ) d (SomeID, SomeValue);

--===== Split the CSV column for the whole table using CROSS APPLY (this is the solution)
 SELECT test.SomeID, test.SomeValue, split.ItemNumber, Item = QUOTENAME(split.Item,'"')
   FROM #JBMTest test
  CROSS APPLY dbo.udf_DelimitedSplit8k(test.SomeValue,',') split;
 ======================================================================
*/

--===== "Inline" CTE Driven "Tally Table" produces values from 1 up to 10,000...
     -- enough to cover VARCHAR(8000)
  WITH E1(N) AS (
                 SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL
                 SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL
                 SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
                ),                          --10E+1 or 10 rows
       E2(N) AS (SELECT 1 FROM E1 a, E1 b), --10E+2 or 100 rows
       E4(N) AS (SELECT 1 FROM E2 a, E2 b), --10E+4 or 10,000 rows max
 cteTally(N) AS (--==== This provides the "base" CTE and limits the number of rows right up front
                     -- for both a performance gain and prevention of accidental "overruns"
                 SELECT TOP (ISNULL(DATALENGTH(@pString),0)) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM E4
                ),
cteStart(N1) AS (--==== This returns N+1 (starting position of each "element" just once for each delimiter)
                 SELECT 1 UNION ALL
                 SELECT t.N+1 FROM cteTally t WHERE SUBSTRING(@pString,t.N,1) = @pDelimiter
                ),
cteLen(N1,L1) AS(--==== Return start and length (for use in substring)
                 SELECT s.N1,
                        ISNULL(NULLIF(CHARINDEX(@pDelimiter,@pString,s.N1),0)-s.N1,8000)
                   FROM cteStart s
                )
--===== Do the actual split. The ISNULL/NULLIF combo handles the length for the final element when no delimiter is found.
 SELECT ItemNumber = ROW_NUMBER() OVER(ORDER BY l.N1),
        Item       = SUBSTRING(@pString, l.N1, l.L1)
   FROM cteLen l;