USE Sandbox;
GO

SET NOCOUNT ON;

--execute Sandbox.dbo.CompanyPhoneWorkoff;

-------------------------------------------------------------------------------------
-- Basic union all so we can see the data side by side
-------------------------------------------------------------------------------------
SELECT 'Raw' as TableType,
	   CompanyId,
	   Phone
  FROM Sandbox.dbo.CompanyPhoneRaw
 UNION ALL
SELECT 'Presentation' as TableType,
       CompanyId,
       Phone
  FROM Sandbox.dbo.CompanyPhone
 ORDER BY CompanyId, TableType;

-------------------------------------------------------------------------------------
-- Union all with group by
-------------------------------------------------------------------------------------
;WITH CTE AS
(
SELECT 'Raw' as TableType,
	   CompanyId,
	   Phone
  FROM Sandbox.dbo.CompanyPhoneRaw
 UNION ALL
SELECT 'Presentation' as TableType,
       CompanyId,
       Phone
  FROM Sandbox.dbo.CompanyPhone
)
SELECT COUNT(*) as Cnt,
       CompanyId,
       Phone
  FROM CTE
 GROUP BY CompanyId, Phone
 ORDER BY CompanyId;

-------------------------------------------------------------------------------------
-- Union all with group by and has count equal to one (i.e. filter for only what has changed)
-------------------------------------------------------------------------------------
;WITH CTE AS
(
SELECT 'I' AS DBAction, --Data in Raw table we want to insert
	   CompanyId,
	   Phone
  FROM Sandbox.dbo.CompanyPhoneRaw
 UNION ALL
SELECT 'D' AS DBAction, --Data in Presentation table we want to delete
       CompanyId,
       Phone
  FROM Sandbox.dbo.CompanyPhone
)
SELECT MIN(DBAction) as DBAction,
       CompanyId,
       Phone
  FROM CTE
 GROUP BY CompanyId, Phone
HAVING COUNT(*) = 1
 ORDER BY CompanyId;