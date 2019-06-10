SET NOCOUNT ON;

DECLARE @RootLabel VARCHAR(3) = '/',
        @SeparatorChar VARCHAR(3) = '/';

IF (OBJECT_ID('tempdb..#SSISPackagesList') IS NOT NULL) DROP TABLE #SSISPackagesList;
IF (OBJECT_ID('tempdb..#StagingPackageConnStrs') IS NOT NULL) DROP TABLE #StagingPackageConnStrs;
IF (OBJECT_ID('tempdb..#StagingPackageJobs') IS NOT NULL) DROP TABLE #StagingPackageJobs;
 
CREATE TABLE #SSISPackagesList 
(
 PackageUniqifier       BIGINT IDENTITY(1,1) NOT NULL,
 PackageRunningId       NVARCHAR(50)         NOT NULL,
 RootFolderName         VARCHAR(256)         NOT NULL,
 ParentFolderFullPath   VARCHAR(4000)        NOT NULL,
 PackageOwner           VARCHAR(256)             NULL,
 PackageName            VARCHAR(256)         NOT NULL,
 PackageDescription     VARCHAR(4000)            NULL,
 IsEncrypted            BIT                  NOT NULL,
 PackageFormat4Version  CHAR(4)              NOT NULL,
 PackageType            VARCHAR(128)         NOT NULL,
 CreationDate           DATETIME             NULL,
 PackageVersionMajor    TINYINT              NOT NULL,
 PackageVersionMinor    TINYINT              NOT NULL,
 PackageVersionBuild    INT                  NOT NULL,
 PackageVersionComments VARCHAR(4000)        NOT NULL,
 PackageSizeKb          BIGINT               NULL,
 PackageXmlContent      XML                  NULL
);

CREATE TABLE #StagingPackageConnStrs
(
 PackageUniqifier  BIGINT NOT NULL,
 DelayValidation   VARCHAR(100),
 ObjectName        VARCHAR(256),
 ObjectDescription VARCHAR(4000),
 Retain            VARCHAR(100),
 ConnectionString  VARCHAR(MAX)
);

CREATE TABLE #StagingPackageJobs 
(
 PackageUniqifier BIGINT        NOT NULL,
 JobId            VARCHAR(128)  NOT NULL,
 JobName          VARCHAR(256),
 JobStep          INT           NOT NULL,
 TargetServerName VARCHAR(512),
 FullCommand      VARCHAR(MAX),
 IsJobEnabled     BIT,
 HasJobAlreadyRun BIT
);

WITH childfolders
AS 
( 
SELECT parent.parentfolderid, 
       parent.folderid, 
       parent.foldername, 
       CAST(@RootLabel AS SYSNAME) AS rootfolder, 
       CAST(CASE WHEN (LEN(parent.foldername) = 0) THEN @SeparatorChar ELSE parent.foldername END AS VARCHAR(MAX)) AS fullpath, 
       0 AS lvl 
  FROM msdb.dbo.sysssispackagefolders AS PARENT 
 WHERE parent.parentfolderid IS NULL 
 UNION ALL 
SELECT child.parentfolderid, 
       child.folderid, 
       child.foldername, 
       CASE childfolders.lvl 
            WHEN 0 THEN child.foldername 
            ELSE childfolders.rootfolder 
       END AS rootfolder, 
       CAST(CASE WHEN (childfolders.fullpath = @SeparatorChar) THEN '' 
	            ELSE childfolders.fullpath 
            END + @SeparatorChar + child.foldername AS VARCHAR(MAX)
		 ) AS fullpath, 
       childfolders.lvl + 1 AS lvl 
  FROM msdb.dbo.sysssispackagefolders AS CHILD 
       INNER JOIN childfolders ON childfolders.folderid = child.parentfolderid
)
INSERT INTO #SSISPackagesList 
(PackageRunningId, RootFolderName, ParentFolderFullPath, PackageOwner, PackageName, PackageDescription, isEncrypted, PackageFormat4Version, PackageType, CreationDate, PackageVersionMajor, PackageVersionMinor, PackageVersionBuild, PackageVersionComments, PackageSizeKb, PackageXmlContent)
SELECT CONVERT(NVARCHAR(50),P.id) As PackageId,
       F.RootFolder,
       F.FullPath,
       SUSER_SNAME(ownersid) as PackageOwner,
       P.name as PackageName,
       P.[description] as PackageDescription,
       P.isencrypted as isEncrypted,
       CASE P.packageformat
            WHEN 0 THEN '2005'
            WHEN 1 THEN '2008'
            ELSE 'N/A'
       END AS PackageFormat,
       CASE P.packagetype
            WHEN 0 THEN 'Default Client'
            WHEN 1 THEN 'SQL Server Import and Export Wizard'
            WHEN 2 THEN 'DTS Designer in SQL Server 2000'
            WHEN 3 THEN 'SQL Server Replication'
            WHEN 5 THEN 'SSIS Designer'
            WHEN 6 THEN 'Maintenance Plan Designer or Wizard'
            ELSE 'Unknown'
       END as PackageType,
       P.createdate as CreationDate,
       P.vermajor,
       P.verminor,
       P.verbuild,
       P.vercomments,
       DATALENGTH(P.packagedata)/1024 AS PackageSizeKb,
       CAST(CAST(P.packagedata AS VARBINARY(MAX)) AS XML) AS PackageData
  FROM ChildFolders AS F
       INNER JOIN msdb.dbo.sysssispackages AS P ON P.folderid = F.folderid
 ORDER BY F.FullPath ASC, P.name ASC;

WITH XMLNAMESPACES 
(
    'www.microsoft.com/SqlServer/Dts' AS pNS1, 
    'www.microsoft.com/SqlServer/Dts' AS DTS
) -- declare XML namespaces
INSERT INTO #stagingpackageconnstrs 
(packageuniqifier,delayvalidation, objectname, objectdescription, retain, connectionstring) 
SELECT packageuniqifier, 
       CASE WHEN ssis_xml.value('./pNS1:Property [@pNS1:Name="DelayValidation"][1]', 'varchar(100)') = 0 THEN 'False' 
            WHEN ssis_xml.value('./pNS1:Property [@pNS1:Name="DelayValidation"][1]', 'varchar(100)') = -1 THEN 'True' 
            ELSE ssis_xml.value('./pNS1:Property [@pNS1:Name="DelayValidation"][1]', 'varchar(100)') 
       END AS DelayValidation, 
       ssis_xml.value('./pNS1:Property[@pNS1:Name="ObjectName"][1]', 'varchar(100)')                                                  AS 
       ObjectName, 
       ssis_xml.value('./pNS1:Property[@pNS1:Name="Description"][1]', 'varchar(100)') AS ObjectDescription, 
       CASE WHEN ssis_xml.value('pNS1:ObjectData[1]/pNS1:ConnectionManager[1]/pNS1:Property[@pNS1:Name="Retain"][1]', 'varchar(MAX)') = 0 THEN 'True' 
            WHEN ssis_xml.value('pNS1:ObjectData[1]/pNS1:ConnectionManager[1]/pNS1:Property[@pNS1:Name="Retain"][1]', 'varchar(MAX)') = -1 THEN 'False' 
            ELSE ssis_xml.value('pNS1:ObjectData[1]/pNS1:ConnectionManager[1]/pNS1:Property[@pNS1:Name="Retain"][1]', 'varchar(MAX)') 
       END AS Retain, 
       ssis_xml.value('pNS1:ObjectData[1]/pNS1:ConnectionManager[1]/pNS1:Property[@pNS1:Name="ConnectionString"][1]', 'varchar(MAX)') AS ConnectionString 
  FROM #ssispackageslist PackageXML 
       CROSS apply packagexmlcontent.nodes ('/DTS:Executable/DTS:ConnectionManager') AS SSIS_XML(ssis_xml);