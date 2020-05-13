CREATE VOLATILE TABLE Col_Data
(
 ColumnId INTEGER NOT NULL,
 ColumnName VARCHAR(100) NOT NULL,
 DataType VARCHAR(50) NULL,
 IsNullable VARCHAR(3) NOT NULL
) ON COMMIT PRESERVE ROWS;

INSERT INTO Col_Data
(ColumnId, ColumnName, IsNullable)
SELECT ROW_NUMBER() Over(ORDER BY ColumnID),
       ColumnName,
       CASE Nullable
            WHEN 'Y' THEN 'Yes'
            WHEN 'N' THEN 'No'
            ELSE ''
	   END AS Nullable
  FROM DBC.ColumnsV
 WHERE 1 = 1
   AND DatabaseName = 'Database_Name'
   AND TableName = 'Table/ViewName';

--SELECT * FROM Col_Data;

--This Query builds an expression that can be subsequently used in another SELECT statement to return the data types of all the columns for a given table/view as a CSV.
;WITH CTE_DataType
AS
(
SELECT TRIM (Trailing ',' FROM (XmlAgg(CONCAT('TYPE(', ColumnName, ')', ', ', '''-''') || ',' ORDER BY ColumnID) (VARCHAR(10000)))) AS Col_Type_List
  FROM dbc.columnsV
 WHERE 1 = 1
   AND DatabaseName = 'Database_Name'
   AND TableName = 'TABLE/ViewName'
)
SELECT Substr(Col_Type_List, 1, Length(Col_Type_List)-5) AS Col_Type_List
  FROM CTE_DataType;

--This Query returns the data types of all the columns for a given table/view as a CSV. Use the Expresson returned from the above query and replace it between the keword
--"DISTINCT and "FROM".
SELECT DISTINCT
       CONCAT()
  FROM Database_Name.TABLE/ViewName;

UPDATE Col_Data
  FROM
(
--This Query splits a sting based on the delimiter specified.
SELECT *
  FROM TABLE (StrTok_Split_To_Table('string1', '', '-')
RETURNS (outkey VARCHAR(10) CHARACTER SET Unicode
        ,tokennum INTEGER
        ,token VARCHAR(50) CHARACTER SET Unicode)
        ) AS dt
) CTE
   SET DataType = token
 WHERE Col_Data.ColumnId = CTE.tokennum;
 
SELECT * FROM Col_Data;

DROP TABLE Col_Data;