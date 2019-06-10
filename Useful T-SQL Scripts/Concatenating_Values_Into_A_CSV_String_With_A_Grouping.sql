/*
 ======================================================================
 Author:	     SQLZealot
 Source:       http://beyondrelational.com/blogs/sqlzealot/archive/2012/01/02/tsql-script-generating-concatenating-values-into-a-comma-separated-string-with-a-grouping.aspx
 Create Date:  02-JAN-2012
 Description:  This script generates/concatenates values into a 
			comma separated string with a grouping.	
 Revision History:
 01-AUG-2012 - RAGHUNANDAN CUMBAKONAM 
			Formatted the code.
			Added semicolon after each statement.
			Added the history.
 Usage:		N/A			   
 ======================================================================
*/

DECLARE @Reviewers TABLE(Request_ID INT, Approver_Name VARCHAR(50));

INSERT INTO @Reviewers
(Request_ID, Approver_Name)
SELECT 1, 'A' UNION ALL
SELECT 2, 'D' UNION ALL
SELECT 2, 'C' UNION ALL
SELECT 3, 'E' UNION ALL
SELECT 3, 'H' UNION ALL
SELECT 3, 'G';

--Method1
;WITH Rid
AS
(
SELECT Request_ID
  FROM @Reviewers
 GROUP BY Request_ID
)
SELECT Rid.Request_ID,
       STUFF(g.y, 1, 1, '') AS Names_List
  FROM Rid 
       CROSS APPLY (SELECT DISTINCT ', ' + Approver_Name
	                 FROM @Reviewers AS s
	                WHERE s.Request_ID = Rid .Request_ID
	                ORDER BY ', ' + Approver_Name
	              FOR XML PATH('')
			    ) AS g(y);

--Method2
SELECT NameTbl.Request_ID,
       STUFF(
             (SELECT ', ' + nt.Approver_Name
                FROM @Reviewers nt
               WHERE nt.Request_ID = NameTbl.Request_ID
               ORDER BY nt.Approver_Name
              FOR XML PATH('')
		   ), 1, 1, ''
		  ) AS Names_List
  FROM @Reviewers NameTbl
 GROUP BY NameTbl.Request_ID;

--Method3
;WITH cte (Request_ID,combined,rn)
AS
(
SELECT Request_ID,
       Approver_Name,
       rn = ROW_NUMBER() OVER (PARTITION BY Request_ID ORDER BY Approver_Name)
 FROM @Reviewers),
cte2 (outputid,finalstatus,rn) 
AS
(
SELECT Request_ID,
       CONVERT(VARCHAR(MAX),combined),
       1
  FROM cte
 WHERE rn = 1
 UNION ALL 
SELECT cte2.outputid,
       CONVERT(VARCHAR(MAX), cte2.finalstatus + ', ' + cte.combined),
       cte2.rn+1
  FROM cte2
       INNER JOIN cte ON cte.Request_ID = cte2.outputid
              AND cte.rn = cte2.rn+1
)
SELECT outputid AS Request_ID,
       MAX(finalstatus) AS Names_List
  FROM cte2
 GROUP BY outputid;