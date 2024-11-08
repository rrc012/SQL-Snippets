USE msdb;
GO

SET NOCOUNT ON;

DECLARE @iStepID       TINYINT = NULL,     --IF NULL FETCH ALL THE STEPS ASSOCIATED WITH A JOB, ELSE FETCH THE SPECIFIED STEP DETAILS TIED TO A JOB.
        @iProxyID      TINYINT = NULL,     --IF 0 FETCH ONLY THOSE JOBS THAT HAVE PROXIES ASSOCIATED WITH IT.
        @sFreqType     VARCHAR(10) = NULL, --DAILY/WEEKLY/MONTHLY etc
        @sSubSystem    VARCHAR(10) = NULL, --TSQL/SSIS/CmdExec/PowerShell etc
        @sJobsNameList VARCHAR(1000) = '', --IF BLANK FETCH ALL JOBS, ELSE FETCH THE SPECIFIED JOB DETAILS. ENTER A COMMA-SEPARATED LIST OF JOB NAMES.
        @iCharPosition TINYINT;

--Used to hold list of SQL Agent Job names to process
IF OBJECT_ID('tempdb..#JobsNamesList') IS NOT NULL DROP TABLE tempdb..#JobsNamesList;
CREATE TABLE #JobsNamesList 
(
 job_name VARCHAR(128)
);

--Process list
SET @sJobsNameList += ',';

WHILE CHARINDEX(',', @sJobsNameList) > 0
BEGIN
	SET @iCharPosition = CHARINDEX(',', @sJobsNameList)
	INSERT INTO #JobsNamesList (job_name)
	SELECT LTRIM(RTRIM(LEFT(@sJobsNameList, @iCharPosition - 1)));
	SET @sJobsNameList = STUFF(@sJobsNameList, 1, @iCharPosition, '');
END  -- While loop

--SELECT * FROM #JobsNamesList;

SELECT j.name AS job_name,
       px.name AS proxy_name,
       j.description AS job_description,
	  j.start_step_id,
       js.step_id,
       js.step_name,
	  ss.name AS schedule_name,
       ft.freq_type,
       fi.freq_interval,
	  fst.freq_subday_type,
/*       
       ss.freq_subday_interval,
       ss.freq_relative_interval,
       ss.freq_recurrence_factor,
       ss.active_start_date,
       ss.active_end_date,
       ss.active_start_time,
       ss.active_end_time,
--*/
       js.subsystem,
       js.command,
       pkg.ssis_package_path,
       js.database_name,
       js.output_file_name,
       j.date_created AS job_created_on,
       j.date_modified AS job_modified_on,
       j.version_number AS job_version_number,
       ss.date_created AS schedule_created_on,
       ss.date_modified AS schedule_modified_on,
       ss.version_number AS schedule_version_number
  FROM dbo.sysjobs AS j
       INNER JOIN #JobsNamesList AS jnl ON j.name LIKE COALESCE(CONCAT('%', jnl.job_name, '%'), j.name)
       LEFT JOIN dbo.sysjobsteps AS js ON j.job_id = js.job_id
       LEFT JOIN dbo.sysjobschedules AS jss ON j.job_id = jss.job_id
       LEFT JOIN dbo.sysschedules AS ss ON jss.schedule_id = ss.schedule_id
       LEFT JOIN dbo.sysproxies AS px ON js.proxy_id = px.proxy_id
       --Removing all the characters in CMD starting from CMD'" /SERVER "*" /CHECKPOINTING OFF /REPORTING E' in the cmd to extract the name of the SSIS package which is called by a step in a SQL Job
       OUTER APPLY (SELECT STUFF(js.command, CHARINDEX('" /SERVER', js.command), LEN(js.command), '') AS cleanup1) AS p1
       --Removing all instances of '"\' & '/SQL ' & '\"' from cleanup1 to extract the name of the SSIS Package and the Folder under which it is present
       OUTER APPLY (SELECT '\' + REPLACE(REPLACE(REPLACE(REPLACE(p1.cleanup1, '"\', ''), '/SQL ', ''), '\"', ''), '"', '') AS ssis_package_path) AS pkg
	  OUTER APPLY (SELECT CASE ss.freq_relative_interval
                                WHEN 1  THEN 'first'
                                WHEN 2  THEN 'second'
                                WHEN 4  THEN 'third'
                                WHEN 8  THEN 'fourth'
                                WHEN 16 THEN 'last'
                           END AS freq_relative_interval
                   ) AS fri
       OUTER APPLY (SELECT CASE ss.freq_type
                                WHEN 1   THEN 'Once'
                                WHEN 4   THEN 'Daily'
                                WHEN 8   THEN 'Weekly'
                                WHEN 16  THEN 'Monthly'
                                WHEN 32  THEN 'Monthly, Relative'
                                WHEN 64  THEN 'Starts when SQL Server Agent service starts'
                                WHEN 128 THEN 'Runs when computer is idle'
                           END AS freq_type
                   ) AS ft
        OUTER APPLY (SELECT CASE WHEN ss.freq_type IN (1, 64, 128) THEN 'Unused'
                                 --Daily
                                 WHEN ss.freq_type = 4 THEN CONCAT('Every ', freq_interval, ' day(s)')
                                 --Weekly
                                 WHEN ss.freq_type = 8 THEN CASE ss.freq_interval
                                                                 WHEN 1  THEN 'Every Sunday of the week'
                                                                 WHEN 2  THEN 'Every Monday of the week'
                                                                 WHEN 4  THEN 'Every Tuesday of the week'
                                                                 WHEN 8  THEN 'Every Wednesday of the week'
                                                                 WHEN 16 THEN 'Every Thursday of the week'
                                                                 WHEN 32 THEN 'Every Friday of the week'
                                                                 WHEN 64 THEN 'Every Saturday of the week'
                                                                 ELSE 'Multiple days in a week'
                                                                 /*
                                                                 WHEN 3 (1+2) THEN Every Sunday, Monday of the week
													WHEN 9 (1+4+8) THEN Every Sunday, Tuesday, Wednesday of the week
													WHEN 62 (2+4+8+16+32) THEN Every Sunday, Monday, Tuesday, Wednesday, Thursday & Friday of the week
													....so on and so forth
                                                                 */
                                                            END
                                 --Monthly
                                 WHEN ss.freq_type = 16 THEN CONCAT('On the ',
                                                                    ss.freq_interval,
                                                                    CASE ss.freq_interval
                                                                         WHEN 1  THEN 'st'
                                                                         WHEN 21 THEN 'st'
                                                                         WHEN 31 THEN 'st'
                                                                         WHEN 2  THEN 'nd'
                                                                         WHEN 22 THEN 'nd'
                                                                         WHEN 3  THEN 'rd'
                                                                         WHEN 23 THEN 'rd'
                                                                         ELSE 'th'
                                                                    END,
                                                                    ' day of the month')
                                 --Monthly, relative (also uses freq_relative_interval)
                                 WHEN ss.freq_type = 32 THEN  CONCAT('On the ',
                                                                     fri.freq_relative_interval,
                                                                     SPACE(1),
                                                                     CASE ss.freq_interval
                                                                          WHEN 1  THEN 'Sunday'
                                                                          WHEN 2  THEN 'Monday'
                                                                          WHEN 3  THEN 'Tuesday'
                                                                          WHEN 4  THEN 'Wednesday'
                                                                          WHEN 5  THEN 'Thursday'
                                                                          WHEN 6  THEN 'Friday'
                                                                          WHEN 7  THEN 'Saturday'
                                                                          WHEN 8  THEN 'day'
                                                                          WHEN 9  THEN 'weekday'
                                                                          WHEN 10 THEN 'weekend day'
                                                                     END,
                                                                     ' of the month'
                                                                    )
                            END AS freq_interval
                   ) AS fi
        OUTER APPLY (SELECT STUFF(STUFF(RIGHT(REPLICATE('0', 6) + CAST(ss.active_start_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS active_start_time) AS ast
        OUTER APPLY (SELECT CASE WHEN ss.freq_subday_type = 2 THEN CONCAT(' every ', freq_subday_interval, ' seconds starting at ', ast.active_start_time)
                                 WHEN ss.freq_subday_type = 4 THEN CONCAT(' every ', freq_subday_interval, ' minutes starting at ', ast.active_start_time)
                                 WHEN ss.freq_subday_type = 8 THEN CONCAT(' every ', freq_subday_interval, ' hours starting at ',   ast.active_start_time)
                                 ELSE ' starting at ' + ast.active_start_time
                            END AS freq_subday_type
                    ) AS fst
 WHERE 1 = 1
   AND js.step_id >= COALESCE(@iStepID, js.step_id)
   AND COALESCE(ft.freq_type, '') LIKE COALESCE(CONCAT('%', @sFreqType, '%'), ft.freq_type)
   AND js.subsystem LIKE COALESCE(CONCAT('%', @sSubSystem, '%'), js.subsystem)
   AND COALESCE(px.proxy_id, 0) > COALESCE(@iProxyID, -1)
 ORDER BY j.name, js.step_id;