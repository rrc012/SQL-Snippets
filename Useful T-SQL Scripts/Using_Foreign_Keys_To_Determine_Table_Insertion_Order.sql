/*
SOURCE: http://www.sqlservercentral.com/blogs/sqltact/2013/02/17/using-foreign-keys-to-determine-table-insertion-order/
Article Name: Using Foreign Keys to Determine Table Insertion Order
*/

WITH cteFK (pktable, fktable) 
AS
(
SELECT pktable = CT.name,
       fktable = ISNULL(PT.name, '')
  FROM sys.objects AS CT
       LEFT JOIN sys.foreign_key_columns AS FK ON CT.object_id = FK.parent_object_id
       LEFT JOIN sys.objects AS PT ON PT.object_id = FK.referenced_object_id
 WHERE CT.type = 'U'
   AND CT.name NOT IN ('dtproperties', 'sysdiagrams')
 GROUP BY CT.name, ISNULL(PT.name, '')
),
cteRec (tablename, fkcount) 
AS
  (SELECT tablename = pktable,
          fkcount = 0
     FROM cteFK
    UNION ALL 
   SELECT tablename = pktable,
          fkcount = 1
     FROM cteFK 
          CROSS APPLY cteRec
    WHERE cteFK.fktable = cteRec.tablename),
x
AS
  (SELECT tablename = fktable,
          fkcount = 0
     FROM cteFK
    GROUP BY fktable
    UNION ALL 
   SELECT tablename = tablename,
          fkcount = SUM(ISNULL(fkcount,0))
     FROM cteRec
    GROUP BY tablename)
SELECT TableName,
       InsertOrder = DENSE_RANK() OVER (ORDER BY MAX(fkcount) ASC)
  FROM x
 WHERE x.tablename <> ''
 GROUP BY tablename
 ORDER BY 2, 1 ASC;