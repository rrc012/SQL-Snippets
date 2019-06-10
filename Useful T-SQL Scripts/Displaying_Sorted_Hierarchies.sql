/*
 ===============================================================================
 Author:	     JEFF MODEN
 Source:       http://www.sqlservercentral.com/articles/T-SQL/72503/
 Article Name: Displaying Sorted Hierarchies
 Create Date:  23-AUG-2013
 Description:  This script analyses the data.	
 Revision History:
 23-AUG-2013 - RAGHUNANDAN CUMBAKONAM
			Formatted the code.
			Added the history.
 Usage:		N/A			   
 ===============================================================================
*/ 

/************************************************
 Create an "Adjacency List" Hierarchical Model
************************************************/
USE HPG_EDW
GO

--===== Conditionally drop Temp tables to make reruns easy
IF OBJECT_ID('dbo.Employee','U') IS NOT NULL DROP TABLE dbo.Employee;

--===== Create the test table with a clustered PK 
 CREATE TABLE dbo.Employee
        (
        EmployeeID   INT         NOT NULL,
        ManagerID    INT         NULL,
        EmployeeName VARCHAR(10) NOT NULL,
        Sales        INT         NOT NULL,
        CONSTRAINT PK_Employee PRIMARY KEY CLUSTERED (EmployeeID ASC),
        CONSTRAINT FK_Employee_Employee FOREIGN KEY (ManagerID) REFERENCES dbo.Employee (EmployeeID)
        );

--===== Populate the test table with test data.
     -- Since each row forms a parent/child relationship, 
     -- it's an "Adjacency Model.
 INSERT INTO dbo.Employee
(EmployeeID, ManagerID, EmployeeName, Sales)
 SELECT  1,NULL,'Jim'    ,200000 UNION ALL
 SELECT  2,   1,'Lynne'  , 90000 UNION ALL
 SELECT  3,   1,'Bob'    ,100000 UNION ALL
 SELECT  6,  17,'Eric'   , 75000 UNION ALL
 SELECT  8,   3,'Bill'   , 80000 UNION ALL
 SELECT  7,   3,'Vivian' , 60000 UNION ALL
 SELECT 12,   8,'Megan'  , 50000 UNION ALL
 SELECT 13,   8,'Kim'    , 55000 UNION ALL
 SELECT 17,   2,'Butch'  , 70000 UNION ALL
 SELECT 18,  39,'Lisa'   , 40000 UNION ALL
 SELECT 20,   3,'Natalie', 40000 UNION ALL
 SELECT 21,  39,'Homer'  , 30000 UNION ALL
 SELECT 39,   1,'Ken'    , 90000 UNION ALL
 SELECT 40,   1,'Marge'  ,120000;

--===== Add an index to speed things up a bit for the code that follows.
 CREATE INDEX IX_Employee_Composite01 ON dbo.Employee (ManagerID, EmployeeID, EmployeeName);

--===== Display the data in the Employee table
 SELECT * 
   FROM dbo.Employee
  ORDER BY EmployeeID;

WITH cteDirectReports
AS 
(
 SELECT EmployeeID, ManagerID, EmployeeName, EmployeeLevel = 1,
        HierarchicalPath = CAST('\'+CAST(EmployeeName AS VARCHAR(10)) AS VARCHAR(4000))
   FROM dbo.Employee
  WHERE ManagerID IS NULL
  UNION ALL
 SELECT e.EmployeeID, e.ManagerID, e.EmployeeName, EmployeeLevel = d.EmployeeLevel + 1,
        HierarchicalPath = CAST(d.HierarchicalPath + '\'+CAST(e.EmployeeName AS VARCHAR(10)) AS VARCHAR(4000))
   FROM dbo.Employee e
        INNER JOIN cteDirectReports d ON e.ManagerID = d.EmployeeID 
)
 SELECT EmployeeID,
        ManagerID,
        EmployeeName = SPACE((EmployeeLevel-1)*4) + EmployeeName,
        EmployeeLevel,
        HierarchicalPath 
   FROM cteDirectReports
  ORDER BY HierarchicalPath;