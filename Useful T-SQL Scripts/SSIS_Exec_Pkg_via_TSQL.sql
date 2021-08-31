USE SSISDB
GO

SET NOCOUNT ON;
GO

/*
 ===============================================================================
 Author:	   ZappySys
 Source:       http://www.sqlservercentral.com/articles/T-SQL/72503/
 Article Name: Monitor, Run SSIS Package using Stored procedure / T-SQL
 Create Date:  10-MAY-2018
 Description:  This script monitors and executes SSIS Package using
               Stored Procedure (T-SQL Code) – Packages stored in SSIS Catalog.
 Usage:		   N/A

 -----------------
 Revision History:
 -----------------
 10-JUN-2021 - RAGHUNANDAN CUMBAKONAM
			   Formatted the code.
			   Added the history.
	   
 ===============================================================================
*/

--//////////////////////////////////////////////////////
--CONTROL CENTER - DECLARE AND CONFIGURE THE VARIABLES
--//////////////////////////////////////////////////////
DECLARE @iExecutionID     BIGINT,
        @sFolderName      VARCHAR(255)  = 'DataIngest',
        @sEnvironmentName VARCHAR(255)  = 'DEV',
        @sProjectName     VARCHAR(255)  = 'SSIS_Demo',
        @sPackageName     VARCHAR(255),
        @dtStartDate      DATETIME      = '2021-04-29',
        @dtEndDate        DATETIME      = '2021-04-30',
        @iPrevExec        TINYINT       = 5,
        @bResetPkgStatus  BIT           = 0,
        @bShowFullLog     BIT           = 0,
        @sEventName       NVARCHAR(255),
        @sMsgFilter       NVARCHAR(255),
        @iEnvRefID        INT; --Find Environment reference_id from name

IF @bShowFullLog = 0
BEGIN
     SET @sEventName = N'OnInformation';
     SET @sMsgFilter = N'%wrote%';
END

--////////////////////////////////////////////////
--EXTRACT THE SSIS PACKAGE NAME FROM THE PROJECT
--////////////////////////////////////////////////
SELECT DISTINCT @sPackageName = PK.[name]
  FROM internal.projects AS PR
       INNER JOIN internal.packages AS PK ON PR.project_id = PK.project_id
 WHERE 1 = 1
   AND PR.[name] = @sProjectName;
--SELECT @sPackageName;

--//////////////////////////////////////////////////////////
--ASSOCIATE THE ENVIRONMENT REFERENCE "n" WITH THE PROJECT
--//////////////////////////////////////////////////////////
SELECT @iEnvRefID = reference_id
  FROM [catalog].environment_references er
       INNER JOIN [catalog].projects p ON p.project_id = er.project_id
 WHERE er.environment_name = @sEnvironmentName
   AND p.[name] = @sProjectName;

--//////////////////////////////////////////////////////////
--FIRST CREATE EXECUTION AND GET EXECUTIONID IN A VARIABLE
--//////////////////////////////////////////////////////////
EXEC [catalog].create_execution 
     @folder_name  = @sFolderName,
     @project_name = @sProjectName,
     @package_name = @sPackageName,
     @reference_id = @iEnvRefID, --pass environment id here
     @execution_id = @iExecutionID OUTPUT;
 
--//////////////////////////////////////
--WAIT UNTIL PACKAGE EXECUTION IS DONE
--//////////////////////////////////////
EXEC [catalog].[set_execution_parameter_value] 
     @iExecutionID,  
     @object_type = 50, 
     @parameter_name = N'SYNCHRONIZED', 
     @parameter_value = 1;

--////////////////////////
--SET PROJECT PARAMETERS
--////////////////////////
EXEC [catalog].[set_execution_parameter_value] @iExecutionID, @object_type = 20, @parameter_name = N'Period_Start_Date', @parameter_value = @dtStartDate;
EXEC [catalog].[set_execution_parameter_value] @iExecutionID, @object_type = 20, @parameter_name = N'Period_End_Date',   @parameter_value = @dtEndDate;
 
--/////////////////
--Start Execution
--/////////////////
EXEC [catalog].[start_execution] @iExecutionID;

--/////////////////
--CHECK EXECUTION
--/////////////////
SELECT TOP (@iPrevExec)
       execution_id,
       CASE [status]
            WHEN 1 THEN 'Created' 
            WHEN 2 THEN 'Running' 
            WHEN 3 THEN 'Cancelled' 
            WHEN 4 THEN 'Failed' 
            WHEN 5 THEN 'Pending' 
            WHEN 6 THEN 'Ended Unexpectedly' 
            WHEN 7 THEN 'Succedded' 
            WHEN 8 THEN 'Stopping' 
            WHEN 9 THEN 'Completed' 
            ELSE 'Not Sure'
       END AS [status],
       project_name,
       package_name,
       environment_folder_name,
       environment_name,
       executed_as_name,
       CAST(start_time AS DATETIME) AS start_time,
       CAST(end_time AS DATETIME) AS end_time,
       DATEDIFF(ss, start_time, end_time) AS [duration (sec)]
  FROM [catalog].executions
 WHERE 1 = 1
   AND [status] != 1
   AND folder_name = @sFolderName
   AND project_name = @sProjectName
 ORDER BY execution_id DESC;

--/////////////////////
--CHECK EXECUTION LOG
--/////////////////////
SELECT operation_id AS execution_id,
       package_name,
       event_message_id,
       event_name,
       [message],
       TRY_CAST('<![CDATA[' + [message] + ']]>' AS XML) AS message_xml,
       message_source_name,
       subcomponent_name,
       execution_path,
       message_code
  FROM [catalog].event_messages AS em
 WHERE 1 = 1
   AND operation_id = COALESCE(@iExecutionID, operation_id)
   AND event_name = COALESCE(@sEventName, event_name)
   AND [message] LIKE COALESCE(@sMsgFilter, [message])
 ORDER BY event_message_id DESC;