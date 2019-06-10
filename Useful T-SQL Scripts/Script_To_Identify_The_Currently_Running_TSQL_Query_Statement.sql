/*
 ===============================================================================
 Author:	     NAKUL VACHHRAJANI
 Source:       http://nakulvachhrajani.com/2015/09/21/0361-sql-server-script-to-identify-the-currently-running-t-sql-query-statement/
 Article Name: #0361 – SQL Server – Script to identify the currently running 
               T-SQL query statement
 Create Date:  N/A
 Description:  This script provides the T-SQL query statement that is currently 
               running on a SQL Server instance.	
 Revision History:
 02-OCT-2015 - RAGHUNANDAN CUMBAKONAM
			Formatted the code.
			Added the history.

 Usage:		N/A			   
 ===============================================================================
*/  

SELECT st.text AS CommandBeingExecuted,
       --Query being executed
       SUBSTRING(text,
                    -- starting value for substring
                    CASE WHEN ISNULL(statement_start_offset, 0) = 0 THEN 1
                         ELSE statement_start_offset/2 + 1 
				END,
                    -- ending value for substring
                    CASE WHEN ISNULL(NULLIF(statement_end_offset, -1), 0) = 0 THEN LEN(st.text)
                         ELSE statement_end_offset/2 
                    END 
					- 
					CASE WHEN ISNULL(statement_start_offset, 0) = 0 THEN 1
                              ELSE statement_start_offset/2 
					END + 1
                ) AS SQLStatementBeingExecuted,
       sr.wait_type AS WaitType,
       sr.wait_time AS WaitDuration,
       sr.command AS SQLCommandType,
       sr.status AS RequestStatus,
       ses.host_name AS HostName,
       ses.program_name AS ProgramName,
       ses.login_name AS LoginName,
       ses.login_time AS LoginTime,
       ses.host_process_id AS WindowsProcessId,
       sr.last_wait_type AS LastWaitType
  FROM sys.dm_exec_requests AS sr
       INNER JOIN sys.dm_exec_sessions AS ses ON sr.session_id = ses.session_id
       CROSS APPLY sys.dm_exec_sql_text(sr.plan_handle) AS st;