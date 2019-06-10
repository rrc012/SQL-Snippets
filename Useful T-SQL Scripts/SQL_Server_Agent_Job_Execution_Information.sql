/*
 ===============================================================================
 Author:	     DATTATREY SINDOL 
 Source:       http://www.mssqltips.com/sqlservertip/2561/querying-sql-server-agent-job-information/
 Create Date:  09-DEC-2011
 Description:  This script gives the details of last/latest execution of the SQL
               Server Agent Job and also the next time when the job is going to 
			   run (if it is scheduled).	
 Revision History:
 02-APR-2015 - RAGHUNANDAN CUMBAKONAM 
			Formatted the code.
			Replaced the subquery with CTE
			Added the history.
 Usage:		N/A			   
 ===============================================================================
*/
;
WITH sJOBSCH
AS
(
SELECT job_id,
	  MIN(next_run_date) AS NextRunDate,
	  MIN(next_run_time) AS NextRunTime
  FROM msdb.dbo.sysjobschedules
 GROUP BY job_id
),
sJOBH
AS
(
SELECT job_id,
	  run_date,
	  run_time,
	  run_status,
	  run_duration,
	  message,
	  ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY run_date DESC, run_time DESC) AS RowNumber
  FROM msdb.dbo.sysjobhistory
 WHERE step_id = 0
)
SELECT sJOB.job_id AS JobID,
       sJOB.name AS JobName,
	  CASE WHEN sJOBH.run_date IS NULL OR sJOBH.run_time IS NULL THEN NULL
		  ELSE CAST(CAST(sJOBH.run_date AS CHAR(8))
		       + ' '
		       + STUFF(STUFF(RIGHT('000000' + CAST(sJOBH.run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS DATETIME)
	  END AS LastRunDateTime,
	  CASE sJOBH.run_status
		  WHEN 0 THEN 'Failed'
		  WHEN 1 THEN 'Succeeded'
		  WHEN 2 THEN 'Retry'
		  WHEN 3 THEN 'Canceled'
		  WHEN 4 THEN 'Running' -- In Progress
	  END AS LastRunStatus,
       STUFF(STUFF(RIGHT('000000' + CAST(sJOBH.run_duration AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS [LastRunDuration (HH:MM:SS)],
       sJOBH.message AS LastRunStatusMessage,
       CASE sJOBSCH.NextRunDate
            WHEN 0 THEN NULL
            ELSE CAST(CAST(sJOBSCH.NextRunDate AS CHAR(8))
               + ' '
               + STUFF(STUFF(RIGHT('000000' + CAST(sJOBSCH.NextRunTime AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS DATETIME)
       END AS NextRunDateTime
  FROM msdb.dbo.sysjobs AS sJOB
       LEFT JOIN sJOBSCH ON sJOB.job_id = sJOBSCH.job_id
	  LEFT JOIN sJOBH ON sJOB.job_id = sJOBH.job_id
	        AND sJOBH.RowNumber = 1
 ORDER BY JobName;