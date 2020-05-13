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
   AND DatabaseName = ''
   --AND TableKind = 'T'
   --AND TableName LIKE '%%'
 ORDER BY DatabaseName, TableName;

/****************
  COLUMN SEARCH
****************/
SELECT *
  FROM DBC.ColumnsV
 WHERE 1 = 1
   AND DatabaseName = ''
   AND TableName = ''
   --AND ColumnName LIKE '%%'
 ORDER BY ColumnName, DatabaseName, TableName;

/**************
  SAMPLE DATA
**************/
SELECT TOP 10
     *
  FROM 
 WHERE 1 = 1