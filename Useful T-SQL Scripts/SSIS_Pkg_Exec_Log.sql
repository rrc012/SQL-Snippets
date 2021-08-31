USE SSISDB
GO

SET NOCOUNT ON;
GO

--//////////////////////////////////////////////////////
--CONTROL CENTER - DECLARE AND CONFIGURE THE VARIABLES
--//////////////////////////////////////////////////////
DECLARE @sFolderName      VARCHAR(255)  = 'DataIngest',
        @sProjectName     VARCHAR(255)  = 'SSIS_Demo',
        @iPrevExec        TINYINT       = 1,
        @bShowFullLog     BIT           = 0,
        @iExecutionID     BIGINT,
        @sEventName       NVARCHAR(255),
        @sMsgFilter       NVARCHAR(255),
        @sEnvironmentName VARCHAR(255);

IF @bShowFullLog = 0
BEGIN
     SET @sEventName = N'OnInformation';
     SET @sMsgFilter = N'%wrote%';
END

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
   AND environment_name = COALESCE(@sEnvironmentName, environment_name)
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