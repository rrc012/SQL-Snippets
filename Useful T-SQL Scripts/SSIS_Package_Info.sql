/*
 ===============================================================================
 Author:	     BILL 
 Source:       http://billfellows.blogspot.ca/2011/08/ssis-package-query.html
 Create Date:  15-AUG-2011
 Description:  This script uses a recursive CTE to build out information from 
               the system tables on the SSIS packages deployed to the MSDB and 
			any folder(s) they may be in.	
 Revision History:
 21-APR-2015 - RAGHUNANDAN CUMBAKONAM 
			Formatted the code.
			Used the CASE statement for the PackageType.
			Added the history.
 Usage:		N/A			   
 ===============================================================================
*/
;
WITH FOLDERS 
  AS
(
--Capture root node
SELECT CAST(PF.foldername AS VARCHAR(MAX)) AS FolderPath,
	  PF.folderid,
	  PF.parentfolderid,
	  PF.foldername
  FROM msdb.dbo.sysssispackagefolders PF
 WHERE PF.parentfolderid IS NULL
--Build recursive hierarchy
 UNION ALL
SELECT CAST(F.FolderPath + '\' + PF.foldername AS VARCHAR(MAX)) AS FolderPath,
	  PF.folderid,
	  PF.parentfolderid,
	  PF.foldername
  FROM msdb.dbo.sysssispackagefolders PF
       INNER JOIN FOLDERS F ON F.folderid = PF.parentfolderid
),
PACKAGES AS
(
--Pull information about stored SSIS packages
SELECT P.name AS PackageName,
	  P.createdate,
       P.id AS PackageId,
       P.description as PackageDescription,
       P.folderid,
       P.packageFormat,
       P.packageType,
       P.vermajor,
       P.verminor,
       P.verbuild,
       suser_sname(P.ownersid) AS ownername
  FROM msdb.dbo.sysssispackages P
)
SELECT P.PackageName,
	  F.FolderPath,
       P.CreateDate,
       P.PackageFormat,
       CASE P.packageType
	       WHEN 1 THEN 'SQL Server Import and Export Wizard'
		  WHEN 3 THEN 'SQL Server Replication'
		  WHEN 5 THEN 'SSIS Designer'
		  WHEN 6 THEN 'Maintenance Plan Designer or Wizard'
		  ELSE 'Default'
	  END AS PackageType,
       P.Vermajor,
       P.Verminor,
       P.Verbuild,
       P.OwnerName,
       P.PackageId
  FROM FOLDERS F
       INNER JOIN PACKAGES P ON P.folderid = F.folderid
 WHERE 1 = 1
 --Uncomment this if you want to filter out the native Data Collector packages
   AND F.FolderPath <> '\Data Collector'
 ORDER BY 1;