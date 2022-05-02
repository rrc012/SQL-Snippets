/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

DECLARE @Match TABLE (SQLAgentJobName varchar(0128)) -- populate with job names to exclude

INSERT @Match (SQLAgentJobName)
VALUES ('syspolicy_purge_history')
--   , ('syspolicy_purge_history')
--   , ('syspolicy_purge_history')

DECLARE @IOU smallint

DECLARE @DoW TABLE (DoW smallint)

DECLARE @HoD TABLE (HoD smallint)

INSERT @DoW -- choose which days of the week to include or exclude in a WHERE clause below
VALUES  (1) -- Sunday
     ,  (2) -- Monday
     ,  (3) -- Tuesday
     ,  (4) -- Wednesday
     ,  (5) -- Thursday
     ,  (6) -- Friday
     ,  (7) -- Saturday

INSERT @HoD
VALUES (00) -- 12:00 AM
     , (01) -- 01:00 AM
     , (02) -- 02:00 AM
     , (03) -- 03:00 AM
     , (04) -- 04:00 AM
     , (05) -- 05:00 AM
     , (06) -- 06:00 AM
     , (07) -- 07:00 AM
     , (08) -- 08:00 AM
     , (09) -- 09:00 AM
     , (10) -- 10:00 AM
     , (11) -- 11:00 AM
     , (12) -- 12:00 PM
     , (13) -- 01:00 PM
     , (14) -- 02:00 PM
     , (15) -- 03:00 PM
     , (16) -- 04:00 PM
     , (17) -- 05:00 PM
     , (18) -- 06:00 PM
     , (19) -- 07:00 PM
     , (20) -- 08:00 PM
     , (21) -- 09:00 PM
     , (22) -- 10:00 PM
     , (23) -- 11:00 PM

   SELECT J.name AS SQLAgentJobName
        , CONVERT(varchar(0040), J.date_created , 120) AS create_date
        , CONVERT(varchar(0040), J.date_modified, 120) AS modify_date
        , CASE WHEN J.enabled = 0 THEN 1 ELSE 0 END    AS is_disabled
        , C.name AS CategoryName
        , P.name AS OwnerName
        , ISNULL(Z.JobSteps , 0) AS JobSteps
        , ISNULL(S.Schedules, 0) AS Schedules
        , CONVERT(varchar(0040), msdb.dbo.agent_datetime(R.run_date, R.run_time), 120) AS next_run_date
        , CONVERT(varchar(0040), msdb.dbo.agent_datetime(H.run_date, H.run_time), 120) AS last_run_date
        , H.message AS last_run_message
     FROM msdb.dbo.sysjobs         AS J
     JOIN msdb.dbo.syscategories   AS C
       ON J.category_id
        = C.category_id
     JOIN sys.server_principals    AS P
       ON J.owner_sid
        =       P.sid
LEFT JOIN
  (SELECT W.job_id
        , COUNT(*) AS JobSteps
     FROM msdb.dbo.sysjobsteps     AS W
 GROUP BY W.job_id)                AS Z
       ON J.job_id
        = Z.job_id
LEFT JOIN
  (SELECT M.job_id
        , COUNT(*) AS Schedules
     FROM msdb.dbo.sysjobschedules AS M
 GROUP BY M.job_id)                AS S
       ON J.job_id
        = S.job_id
    OUTER APPLY
  (SELECT TOP 1
          M.schedule_id
        , M.next_run_date AS run_date
        , M.next_run_time AS run_time
     FROM msdb.dbo.sysjobschedules AS M
    WHERE M.job_id
        = J.job_id
 ORDER BY M.next_run_date
        , M.next_run_time)         AS R
LEFT JOIN
  (SELECT A.job_id
        , MAX(A.instance_id) AS instance_id
     FROM msdb.dbo.sysjobhistory   AS A
    WHERE A.step_id = 0
 GROUP BY A.job_id)                AS E
       ON J.job_id
        = E.job_id
LEFT JOIN msdb.dbo.sysjobhistory   AS H
       ON E.job_id
        = H.job_id
      AND E.instance_id
        = H.instance_id
    WHERE J.category_id NOT BETWEEN 1 AND 20
      AND J.name NOT IN (SELECT SQLAgentJobName FROM @Match)
 ORDER BY J.name

  DECLARE  DoW  CURSOR FAST_FORWARD FOR -- choose which days of the week to include (1) or exclude (0) in the WHERE clause
   SELECT  DoW
     FROM @DoW
    WHERE CASE DoW
          WHEN 1 THEN 1 -- Sunday
          WHEN 2 THEN 1 -- Monday
          WHEN 3 THEN 1 -- Tuesday
          WHEN 4 THEN 1 -- Wednesday
          WHEN 5 THEN 1 -- Thursday
          WHEN 6 THEN 1 -- Friday
          WHEN 7 THEN 1 -- Saturday
                 ELSE 0 END != 0
 ORDER BY CASE DoW
          WHEN 1 THEN 7
          WHEN 2 THEN 1
          WHEN 3 THEN 2
          WHEN 4 THEN 3
          WHEN 5 THEN 4
          WHEN 6 THEN 5
          WHEN 7 THEN 6
                 ELSE 0 END

OPEN DoW

FETCH NEXT FROM DoW INTO @IOU

WHILE @@FETCH_STATUS = 0

    BEGIN

       SELECT E.SQLAgentJobName
            , E.JobScheduleName
            , E.create_date
            , E.modify_date
            , E.is_disabled
            , MAX(CASE WHEN E.HoD = 00 THEN E.[Minute] ELSE SPACE(0) END) AS H00
            , MAX(CASE WHEN E.HoD = 01 THEN E.[Minute] ELSE SPACE(0) END) AS H01
            , MAX(CASE WHEN E.HoD = 02 THEN E.[Minute] ELSE SPACE(0) END) AS H02
            , MAX(CASE WHEN E.HoD = 03 THEN E.[Minute] ELSE SPACE(0) END) AS H03
            , MAX(CASE WHEN E.HoD = 04 THEN E.[Minute] ELSE SPACE(0) END) AS H04
            , MAX(CASE WHEN E.HoD = 05 THEN E.[Minute] ELSE SPACE(0) END) AS H05
            , MAX(CASE WHEN E.HoD = 06 THEN E.[Minute] ELSE SPACE(0) END) AS H06
            , MAX(CASE WHEN E.HoD = 07 THEN E.[Minute] ELSE SPACE(0) END) AS H07
            , MAX(CASE WHEN E.HoD = 08 THEN E.[Minute] ELSE SPACE(0) END) AS H08
            , MAX(CASE WHEN E.HoD = 09 THEN E.[Minute] ELSE SPACE(0) END) AS H09
            , MAX(CASE WHEN E.HoD = 10 THEN E.[Minute] ELSE SPACE(0) END) AS H10
            , MAX(CASE WHEN E.HoD = 11 THEN E.[Minute] ELSE SPACE(0) END) AS H11
            , MAX(CASE WHEN E.HoD = 12 THEN E.[Minute] ELSE SPACE(0) END) AS H12
            , MAX(CASE WHEN E.HoD = 13 THEN E.[Minute] ELSE SPACE(0) END) AS H13
            , MAX(CASE WHEN E.HoD = 14 THEN E.[Minute] ELSE SPACE(0) END) AS H14
            , MAX(CASE WHEN E.HoD = 15 THEN E.[Minute] ELSE SPACE(0) END) AS H15
            , MAX(CASE WHEN E.HoD = 16 THEN E.[Minute] ELSE SPACE(0) END) AS H16
            , MAX(CASE WHEN E.HoD = 17 THEN E.[Minute] ELSE SPACE(0) END) AS H17
            , MAX(CASE WHEN E.HoD = 18 THEN E.[Minute] ELSE SPACE(0) END) AS H18
            , MAX(CASE WHEN E.HoD = 19 THEN E.[Minute] ELSE SPACE(0) END) AS H19
            , MAX(CASE WHEN E.HoD = 20 THEN E.[Minute] ELSE SPACE(0) END) AS H20
            , MAX(CASE WHEN E.HoD = 21 THEN E.[Minute] ELSE SPACE(0) END) AS H21
            , MAX(CASE WHEN E.HoD = 22 THEN E.[Minute] ELSE SPACE(0) END) AS H22
            , MAX(CASE WHEN E.HoD = 23 THEN E.[Minute] ELSE SPACE(0) END) AS H23
            , CASE E.DoW
              WHEN 1 THEN '1 - Su'
              WHEN 2 THEN '2 - Mo'
              WHEN 3 THEN '3 - Tu'
              WHEN 4 THEN '4 - We'
              WHEN 5 THEN '5 - Th'
              WHEN 6 THEN '6 - Fr'
              WHEN 7 THEN '7 - Sa'
                     ELSE '0 - NA' END AS DoW
         FROM
      (SELECT J.name AS SQLAgentJobName
            , S.name AS JobScheduleName
            , CONVERT(varchar(0040), S.date_created , 120) AS create_date
            , CONVERT(varchar(0040), S.date_modified, 120) AS modify_date
            , CASE WHEN S.enabled = 0 THEN 1 ELSE 0 END    AS is_disabled
            , D.DoW
            , H.HoD
            , SUBSTRING(CONVERT(varchar(0007), S.active_start_time + 1000000), 4, 2) AS [Minute]
         FROM msdb.dbo.sysjobs         AS J
         JOIN msdb.dbo.sysjobschedules AS M
           ON J.job_id
            = M.job_id
         JOIN msdb.dbo.sysschedules    AS S
           ON M.schedule_id
            = S.schedule_id
         JOIN @DoW AS D
           ON CASE WHEN S.freq_type = 4 AND S.freq_interval                                                           = 1 THEN 1
                   WHEN S.freq_type = 8 AND S.freq_interval & 0x0000001 != 0 AND D.DoW = 1 AND freq_recurrence_factor = 1 THEN 1
                   WHEN S.freq_type = 8 AND S.freq_interval & 0x0000002 != 0 AND D.DoW = 2 AND freq_recurrence_factor = 1 THEN 1
                   WHEN S.freq_type = 8 AND S.freq_interval & 0x0000004 != 0 AND D.DoW = 3 AND freq_recurrence_factor = 1 THEN 1
                   WHEN S.freq_type = 8 AND S.freq_interval & 0x0000008 != 0 AND D.DoW = 4 AND freq_recurrence_factor = 1 THEN 1
                   WHEN S.freq_type = 8 AND S.freq_interval & 0x0000010 != 0 AND D.DoW = 5 AND freq_recurrence_factor = 1 THEN 1
                   WHEN S.freq_type = 8 AND S.freq_interval & 0x0000020 != 0 AND D.DoW = 6 AND freq_recurrence_factor = 1 THEN 1
                   WHEN S.freq_type = 8 AND S.freq_interval & 0x0000040 != 0 AND D.DoW = 7 AND freq_recurrence_factor = 1 THEN 1 ELSE 0 END != 0
         JOIN @HoD AS H
           ON S.active_start_time !> (H.HoD * 10000) + 5959
          AND S.active_end_time   !< (H.HoD * 10000)
          AND CASE WHEN S.freq_subday_type = 1 AND  H.HoD = (S.active_start_time / 10000)                               THEN 1
                   WHEN S.freq_subday_type = 2                                                                          THEN 1
                   WHEN S.freq_subday_type = 4                                                                          THEN 1
                   WHEN S.freq_subday_type = 8 AND (H.HoD - (S.active_start_time / 10000)) % S.freq_subday_interval = 0 THEN 1 ELSE 0 END != 0
        WHERE J.category_id NOT BETWEEN 1 AND 20
          AND J.name NOT IN (SELECT SQLAgentJobName FROM @Match)) AS E
        WHERE E.DoW = @IOU
     GROUP BY E.SQLAgentJobName
            , E.JobScheduleName
            , E.create_date
            , E.modify_date
            , E.is_disabled
            , E.DoW
     ORDER BY E.SQLAgentJobName
            , E.JobScheduleName

    FETCH NEXT FROM DoW INTO @IOU

    END

CLOSE DoW DEALLOCATE DoW

SET NOCOUNT OFF

