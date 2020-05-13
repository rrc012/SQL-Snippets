/******************
  DATABASE SEARCH
******************/
SELECT *
  FROM dbc.DatabasesV
 WHERE 1 = 1
   --AND DatabaseName LIKE '%%'
 ORDER BY DatabaseName;
 
/********************
  TABLE/VIEW SEARCH
********************/
SELECT *
  FROM dbc.tablesv
 WHERE 1 = 1
   AND DatabaseName = 'HTGPO_Views'
   --AND TableKind = 'T'
 ORDER BY DatabaseName, TableName;

/****************
  COLUMN SEARCH
****************/
SELECT *
  FROM DBC.ColumnsV
 WHERE 1 = 1
   AND DatabaseName = 'HTGPO_Views'
   AND TableName = 'Item_Package'
   --AND ColumnName LIKE '%%'
 ORDER BY ColumnName, DatabaseName, TableName;

/**************
  SAMPLE DATA
**************/
SELECT TOP 10
     *
  FROM HTGPO_Views.Item
 WHERE 1 = 1