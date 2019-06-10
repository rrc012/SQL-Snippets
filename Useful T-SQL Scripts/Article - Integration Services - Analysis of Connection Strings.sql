DECLARE @RootLabel VARCHAR(100);
DECLARE @SeparatorChar CHAR;
SET @RootLabel = '';
SET @SeparatorChar = '/'

IF(OBJECT_ID('tempdb..#SSISPackagesList') IS NOT NULL)
BEGIN
    EXEC sp_executesql N'DROP TABLE #SSISPackagesList';
END;

CREATE TABLE #SSISPackagesList (
    PackageUniqifier        BIGINT IDENTITY(1,1) NOT NULL,
    PackageRunningId        NVARCHAR(50)   NOT NULL,
    RootFolderName          VARCHAR(256)   NOT NULL,
    ParentFolderFullPath    VARCHAR(4000)  NOT NULL,
    PackageOwner            VARCHAR(256)   NOT NULL,
    PackageName             VARCHAR(256)   NOT NULL,
    PackageDescription      VARCHAR(4000)      NULL,
    isEncrypted             BIT            NOT NULL,
    PackageFormat4Version   CHAR(4)        NOT NULL,
    PackageType             VARCHAR(128)   NOT NULL,
    CreationDate            DATETIME       NULL,
    PackageVersionMajor     TINYINT        NOT NULL,
    PackageVersionMinor     TINYINT        NOT NULL,
    PackageVersionBuild     INT            NOT NULL,
    PackageVersionComments  VARCHAR(4000)  NOT NULL,
    PackageSizeKb           BIGINT             NULL,
    PackageXmlContent       XML                NULL
);


with ChildFolders
as (
    select 
        PARENT.parentfolderid, 
        PARENT.folderid,
        PARENT.foldername,
        cast(@RootLabel as sysname) as RootFolder,
        cast(CASE 
            WHEN (LEN(PARENT.foldername) = 0) THEN @SeparatorChar 
            ELSE PARENT.foldername 
        END as varchar(max)) as FullPath,
        0 as Lvl
    from msdb.dbo.sysssispackagefolders PARENT
    where PARENT.parentfolderid is null
    UNION ALL
    select 
        CHILD.parentfolderid, CHILD.folderid, CHILD.foldername,
        case ChildFolders.Lvl
            when 0 then CHILD.foldername
            else ChildFolders.RootFolder
        end as RootFolder,
        cast(
            CASE WHEN (ChildFolders.FullPath = @SeparatorChar) THEN '' 
                ELSE ChildFolders.FullPath 
            END + @SeparatorChar + CHILD.foldername as varchar(max)
        ) as FullPath,
        ChildFolders.Lvl + 1 as Lvl
    from msdb.dbo.sysssispackagefolders CHILD
    inner join ChildFolders 
    on ChildFolders.folderid = CHILD.parentfolderid
)
INSERT INTO #SSISPackagesList (
    PackageRunningId,RootFolderName,ParentFolderFullPath,PackageOwner,
    PackageName,PackageDescription,isEncrypted,PackageFormat4Version,
    PackageType,CreationDate,PackageVersionMajor,PackageVersionMinor,
    PackageVersionBuild,PackageVersionComments,
    PackageSizeKb,PackageXmlContent
)
Select
    CONVERT(NVARCHAR(50),P.id) As PackageId,
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
    DATALENGTH(P.packagedata) /1024 AS PackageSizeKb,
    cast(cast(P.packagedata as varbinary(max)) as xml) as PackageData
from ChildFolders F
inner join msdb.dbo.sysssispackages P 
on P.folderid = F.folderid
order by F.FullPath asc, P.name asc
;

IF(OBJECT_ID('tempdb..#StagingPackageConnStrs') IS NOT NULL)
BEGIN
    EXEC sp_executesql N'DROP TABLE #StagingPackageConnStrs';
END;

CREATE TABLE #StagingPackageConnStrs (
    PackageUniqifier    BIGINT   NOT NULL,
    DelayValidation     VARCHAR(100),
    ObjectName          VARCHAR(256),
    ObjectDescription   VARCHAR(4000),
    Retain              VARCHAR(100),
    ConnectionString    VARCHAR(MAX)
);




WITH XMLNAMESPACES (
    'www.microsoft.com/SqlServer/Dts' AS pNS1, 
    'www.microsoft.com/SqlServer/Dts' AS DTS
) -- declare XML namespaces
INSERT INTO #StagingPackageConnStrs (
    PackageUniqifier,
    DelayValidation,
    ObjectName,
    ObjectDescription,
    Retain,
    ConnectionString
)   
SELECT PackageUniqifier,
    CASE 
        WHEN SSIS_XML.value('./pNS1:Property [@pNS1:Name="DelayValidation"][1]', 'varchar(100)') = 0 
            THEN 'False' 
        WHEN SSIS_XML.value('./pNS1:Property [@pNS1:Name="DelayValidation"][1]', 'varchar(100)') = -1 
            THEN 'True'
        ELSE SSIS_XML.value('./pNS1:Property [@pNS1:Name="DelayValidation"][1]', 'varchar(100)') 
   END AS DelayValidation,
   SSIS_XML.value('./pNS1:Property[@pNS1:Name="ObjectName"][1]',
                  'varchar(100)') AS ObjectName,
   SSIS_XML.value('./pNS1:Property[@pNS1:Name="Description"][1]',  
                  'varchar(100)') AS ObjectDescription,
   CASE 
        WHEN  SSIS_XML.value('pNS1:ObjectData[1]/pNS1:ConnectionManager[1]/pNS1:Property[@pNS1:Name="Retain"][1]', 'varchar(MAX)') = 0 THEN 'True'
       WHEN SSIS_XML.value('pNS1:ObjectData[1]/pNS1:ConnectionManager[1]/pNS1:Property[@pNS1:Name="Retain"][1]', 'varchar(MAX)') = -1 THEN 'False'
   ELSE SSIS_XML.value('pNS1:ObjectData[1]/pNS1:ConnectionManager[1]/pNS1:Property[@pNS1:Name="Retain"][1]', 'varchar(MAX)')
   END AS Retain,
SSIS_XML.value('pNS1:ObjectData[1]/pNS1:ConnectionManager[1]/pNS1:Property[@pNS1:Name="ConnectionString"][1]', 'varchar(MAX)') AS ConnectionString
FROM #SSISPackagesList PackageXML 
CROSS APPLY 
    PackageXMLContent.nodes (
        '/DTS:Executable/DTS:ConnectionManager'
    ) AS SSIS_XML(SSIS_XML)    
;

IF(OBJECT_ID('tempdb..#StagingPackageJobs') IS NOT NULL)
    BEGIN
        EXEC sp_executesql N'DROP TABLE #StagingPackageJobs';
    END;

CREATE TABLE #StagingPackageJobs (
    PackageUniqifier                BIGINT NOT NULL,
    JobId                           VARCHAR(128)   NOT NULL,
    JobName                         VARCHAR(256),
    JobStep                         INT            NOT NULL,
    TargetServerName                VARCHAR(512),
    FullCommand                     VARCHAR(MAX),
    isJobEnabled                    BIT,
    hasJobAlreadyRun                BIT
);

WITH PkgList 
AS (
    SELECT 
        PackageUniqifier,
        CASE WHEN ParentFolderFullPath = '/' THEN '' ELSE ParentFolderFullPath END + '/' + PackageName as PackageFullPath
    FROM #SSISPackagesList
), 
JobSteps 
AS (
    SELECT CONVERT(VARCHAR(128),j.job_id)       as JobId,
           s.srvname      as AgentServerName,
           j.name         as JobName,
           js.step_id     as JobStepId,
           REPLACE(SUBSTRING(
                SUBSTRING(REPLACE(js.command,'\"',''),CHARINDEX('/SQL "',REPLACE(js.command,'\"','')) + LEN('/SQL "'),LEN(REPLACE(js.command,'\"',''))-CHARINDEX('/SQL "',REPLACE(js.command,'\"',''))-LEN('/SQL "')),
                0,
                CHARINDEX('"',SUBSTRING(REPLACE(js.command,'\"',''),CHARINDEX('/SQL "',REPLACE(js.command,'\"','')) + LEN('/SQL "'),LEN(REPLACE(js.command,'\"',''))-CHARINDEX('/SQL "',REPLACE(js.command,'\"',''))-LEN('/SQL "')))
           ),'\','/')    as PackageFullPath,
           LOWER(SUBSTRING(SUBSTRING(REPLACE(js.command,'\"',''),CHARINDEX('/SERVER "',REPLACE(js.command,'\"','')) + LEN('/SERVER "'),LEN(REPLACE(js.command,'\"',''))-CHARINDEX('/SERVER "',REPLACE(js.command,'\"',''))-LEN('/SERVER "')),
                0,
                CHARINDEX('"',SUBSTRING(REPLACE(js.command,'\"',''),CHARINDEX('/SERVER "',REPLACE(js.command,'\"','')) + LEN('/SERVER "'),LEN(REPLACE(js.command,'\"',''))-CHARINDEX('/SERVER "',REPLACE(js.command,'\"',''))-LEN('/SERVER "')))
           )) as TargetServerName,
           js.command as FullCommand,
           CASE WHEN j.enabled = 1 THEN 1 ELSE 0 END as isJobEnabled,
           CASE WHEN js.last_run_date IS NULL THEN 0 ELSE 1 END as hasJobAlreadyRun
    FROM   msdb.dbo.sysjobs j
    JOIN   msdb.dbo.sysjobsteps js
       ON  js.job_id = j.job_id 
    JOIN   master.dbo.sysservers s
       ON  s.srvid = j.originating_server_id
    --filter only the job steps which are executing SSIS packages 
    WHERE  subsystem = 'SSIS'
)
INSERT INTO #StagingPackageJobs (
    PackageUniqifier,JobId,JobName,JobStep,TargetServerName,FullCommand,isJobEnabled,hasJobAlreadyRun
)
SELECT 
    p.PackageUniqifier,
    s.JobId,
    s.JobName,
    s.JobStepId,
    s.TargetServerName,
    s.FullCommand,
    s.isJobEnabled,
    s.hasJobAlreadyRun
FROM PkgList p
INNER JOIN JobSteps s
ON p.PackageFullPath = s.PackageFullPath
;

-- Display results
SELECT * FROM #SSISPackagesList;
SELECT * FROM #StagingPackageConnStrs;
SELECT * FROM #StagingPackageJobs;


-- Cleanups
IF(OBJECT_ID('tempdb..#StagingPackageConnStrs') IS NOT NULL)
BEGIN
    EXEC sp_executesql N'DROP TABLE #StagingPackageConnStrs';
END;

IF(OBJECT_ID('tempdb..#SSISPackagesList') IS NOT NULL)
BEGIN
    EXEC sp_executesql N'DROP TABLE #SSISPackagesList';
END;

IF(OBJECT_ID('tempdb..#StagingPackageJobs') IS NOT NULL)
BEGIN
    EXEC sp_executesql N'DROP TABLE #StagingPackageJobs';
END;