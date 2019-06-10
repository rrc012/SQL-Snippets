/*
 ======================================================================
 Author:	     VISAKH MURUKESAN
 Source:       http://visakhm.blogspot.in/search/label/foreign%20keys%20in%20a%20table
 Create Date:  09-NOV-2011
 Description:  This code will help us in finding out recursively the 
               object relationships and then delete from tables the 
		     dependent records.
 Revision History:
 16-MAR-2015 - RAGHUNANDAN CUMBAKONAM
			Formatted the code.
			Added the history.
 Usage:		N/A
 ======================================================================
*/
WITH object_cte (tblid, schname, tblname, rtblid, rtblname, level)
AS 
(
 SELECT DISTINCT o.object_id AS tblid,
        SCHEMA_NAME(o.schema_id) AS schname,
        OBJECT_NAME(o.object_id) AS tblname,
        CAST(NULL AS INT),
        CAST(NULL AS sysname),
        0 AS level
   FROM sys.objects o
        INNER JOIN sys.foreign_keys f ON f.parent_object_id = o.object_id
  WHERE o.is_ms_shipped = 0
    AND o.type = 'u'
  UNION ALL
 SELECT t.object_id AS tblid,
	   SCHEMA_NAME(t.schema_id) AS schname,
        OBJECT_NAME(t.object_id) AS tblname,
        o.tblid,
        o.tblname,
        o.level + 1
   FROM object_cte o
        INNER JOIN sys.foreign_keys f ON f.parent_object_id = o.tblid
        INNER JOIN sys.objects t ON t.object_id = f.referenced_object_id
  WHERE t.is_ms_shipped = 0
    AND t.type = 'u'
    )
SELECT *
  FROM (SELECT ROW_NUMBER() OVER (PARTITION BY object_cte.tblname ORDER BY object_cte.level) AS rn, * FROM object_cte)t
 WHERE t.rn = 1
 ORDER BY t.level
;