/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


IF OBJECT_ID('dbo.SendAlertMessages', 'P ') IS NOT NULL DROP PROCEDURE dbo.SendAlertMessages
GO
CREATE PROCEDURE dbo.SendAlertMessages
       @PRINT_Only bit = 0
AS

SET NOCOUNT ON

DECLARE @Hour decimal(05,03) = 2.0 -- increase for less alerts, decrease for more alerts, number of standard deviations above/below the mean considered normal for hour
DECLARE @Week decimal(05,03) = 2.0 -- increase for less alerts, decrease for more alerts, number of standard deviations above/below the mean considered normal for week

DECLARE @Message varchar(8000) = 'MetricsHistory values to check:'

DECLARE @Length smallint = LEN(@Message)

DECLARE @CR char(0002) = CHAR(13) + CHAR(10)

DECLARE @DateTimeFrom datetime
DECLARE @DateTimeThru datetime
DECLARE @DateTimeBack datetime

-- CounterHistory

   SELECT @DateTimeThru = MAX(I.KeyDT) FROM dbo.CounterHistory AS I

   SELECT @DateTimeBack = MAX(I.KeyDT) FROM dbo.CounterHistory AS I WHERE I.KeyDT < @DateTimeThru

   SELECT @DateTimeFrom = DATEADD(second, -90, DATEADD(minute, 0 - (DATEDIFF(minute, @DateTimeBack, @DateTimeThru) * 6), @DateTimeThru))

   SELECT ROW_NUMBER() OVER (ORDER BY I.KeyID) - 1 AS KeyID
        , I.KeyDT
        , I.C101
        , I.C102
        , I.C103
        , I.C104
        , I.C105
        , I.C106
        , I.C107
        , I.C108
        , I.C109
        , I.C201
        , I.C202
        , I.C203
        , I.C204
        , I.C205
        , I.C206
        , I.C207
        , I.C208
        , I.C209
        , I.C301
        , I.C302
        , I.C303
        , I.C304
        , I.C305
        , I.C306
        , I.C307
        , I.C308
        , I.C309
        , I.C401
        , I.C402
        , I.C403
        , I.C404
        , I.C405
        , I.C406
        , I.C407
        , I.C408
        , I.C409
        , I.C501
        , I.C502
        , I.C503
        , I.C504
        , I.C505
        , I.C506
        , I.C507
        , I.C508
        , I.C509
        , I.C601
        , I.C602
        , I.C603
        , I.C604
        , I.C605
        , I.C606
        , I.C607
        , I.C608
        , I.C609
        , I.C701
        , I.C702
        , I.C703
        , I.C704
        , I.C705
        , I.C706
        , I.C707
        , I.C708
        , I.C709
     INTO    #CounterHistory
     FROM dbo.CounterHistory AS I
    WHERE I.KeyDT !< DATEADD(day, -7, @DateTimeThru)
 ORDER BY I.KeyID

   SELECT I.KeyDT
        , CONVERT(decimal(09,02), CASE WHEN I.C201 = 0 THEN 0.0 ELSE (I.C101 * 100.0) / I.C201 END) AS R101
        , CONVERT(decimal(09,02), CASE WHEN I.C202 = 0 THEN 0.0 ELSE (I.C102 * 100.0) / I.C202 END) AS R102
        , CONVERT(decimal(09,02), CASE WHEN I.C203 = 0 THEN 0.0 ELSE (I.C103 * 100.0) / I.C203 END) AS R103
--      , I.C101
--      , I.C102
--      , I.C103
        , I.C104
        , I.C105
        , I.C106
        , I.C107
        , I.C108
        , I.C109
--      , I.C201
--      , I.C202
--      , I.C203
        , I.C204
        , I.C205
        , I.C206
        , I.C207
        , I.C208
        , I.C209
        , I.C301
        , I.C302
        , I.C303
        , I.C304
        , I.C305
        , I.C306
        , I.C307
        , I.C308
        , I.C309
        , I.C401
        , I.C402
        , I.C403
        , I.C404
        , I.C405
        , I.C406
        , I.C407
        , I.C408
        , I.C409
        , I.C501
        , I.C502
        , I.C503
        , I.C504
        , I.C505
        , I.C506
        , I.C507
        , I.C508
        , I.C509
        , I.C601 - T.C601 AS C601
        , I.C602 - T.C602 AS C602
        , I.C603 - T.C603 AS C603
        , I.C604 - T.C604 AS C604
        , I.C605 - T.C605 AS C605
        , I.C606 - T.C606 AS C606
        , I.C607 - T.C607 AS C607
        , I.C608 - T.C608 AS C608
        , I.C609 - T.C609 AS C609
        , I.C701 - T.C701 AS C701
        , I.C702 - T.C702 AS C702
        , I.C703 - T.C703 AS C703
        , I.C704 - T.C704 AS C704
        , I.C705 - T.C705 AS C705
        , I.C706 - T.C706 AS C706
        , I.C707 - T.C707 AS C707
        , I.C708 - T.C708 AS C708
        , I.C709 - T.C709 AS C709
     INTO #CounterHistoryHour
     FROM #CounterHistory AS I
     JOIN #CounterHistory AS T
       ON I.KeyID - 1
        = T.KeyID
    WHERE I.KeyDT !< @DateTimeFrom
      AND I.KeyDT !> @DateTimeThru
 ORDER BY I.KeyID

   SELECT I.KeyDT
        , CONVERT(decimal(09,02), CASE WHEN I.C201 = 0 THEN 0.0 ELSE (I.C101 * 100.0) / I.C201 END) AS R101
        , CONVERT(decimal(09,02), CASE WHEN I.C202 = 0 THEN 0.0 ELSE (I.C102 * 100.0) / I.C202 END) AS R102
        , CONVERT(decimal(09,02), CASE WHEN I.C203 = 0 THEN 0.0 ELSE (I.C103 * 100.0) / I.C203 END) AS R103
--      , I.C101
--      , I.C102
--      , I.C103
        , I.C104
        , I.C105
        , I.C106
        , I.C107
        , I.C108
        , I.C109
--      , I.C201
--      , I.C202
--      , I.C203
        , I.C204
        , I.C205
        , I.C206
        , I.C207
        , I.C208
        , I.C209
        , I.C301
        , I.C302
        , I.C303
        , I.C304
        , I.C305
        , I.C306
        , I.C307
        , I.C308
        , I.C309
        , I.C401
        , I.C402
        , I.C403
        , I.C404
        , I.C405
        , I.C406
        , I.C407
        , I.C408
        , I.C409
        , I.C501
        , I.C502
        , I.C503
        , I.C504
        , I.C505
        , I.C506
        , I.C507
        , I.C508
        , I.C509
        , I.C601 - T.C601 AS C601
        , I.C602 - T.C602 AS C602
        , I.C603 - T.C603 AS C603
        , I.C604 - T.C604 AS C604
        , I.C605 - T.C605 AS C605
        , I.C606 - T.C606 AS C606
        , I.C607 - T.C607 AS C607
        , I.C608 - T.C608 AS C608
        , I.C609 - T.C609 AS C609
        , I.C701 - T.C701 AS C701
        , I.C702 - T.C702 AS C702
        , I.C703 - T.C703 AS C703
        , I.C704 - T.C704 AS C704
        , I.C705 - T.C705 AS C705
        , I.C706 - T.C706 AS C706
        , I.C707 - T.C707 AS C707
        , I.C708 - T.C708 AS C708
        , I.C709 - T.C709 AS C709
     INTO #CounterHistoryWeek
     FROM #CounterHistory AS I
     JOIN #CounterHistory AS T
       ON I.KeyID - 1
        = T.KeyID
    WHERE CASE WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -0, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -0, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -1, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -1, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -2, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -2, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -3, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -3, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -4, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -4, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -5, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -5, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -6, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -6, @DateTimeThru)) THEN 1 ELSE 0 END != 0
 ORDER BY I.KeyID

   SELECT @Message = @Message

        + CASE WHEN Z.R101 = W.R101 OR E.[Rows] < 3 OR (Z.R101 BETWEEN T.R101_AVG - (T.R101_STD * @Hour) AND T.R101_AVG + (T.R101_STD * @Hour)) OR (Z.R101 BETWEEN E.R101_AVG - (E.R101_STD * @Week) AND E.R101_AVG + (E.R101_STD * @Week)) THEN SPACE(0) ELSE @CR + 'BCHR'                   END
        + CASE WHEN Z.C301 = W.C301 OR E.[Rows] < 3 OR (Z.C301 BETWEEN T.C301_AVG - (T.C301_STD * @Hour) AND T.C301_AVG + (T.C301_STD * @Hour)) OR (Z.C301 BETWEEN E.C301_AVG - (E.C301_STD * @Week) AND E.C301_AVG + (E.C301_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Page_Life'              END
        + CASE WHEN Z.C309 = W.C309 OR E.[Rows] < 3 OR (Z.C309 BETWEEN T.C309_AVG - (T.C309_STD * @Hour) AND T.C309_AVG + (T.C309_STD * @Hour)) OR (Z.C309 BETWEEN E.C309_AVG - (E.C309_STD * @Week) AND E.C309_AVG + (E.C309_STD * @Week)) THEN SPACE(0) ELSE @CR + 'RAM_stalls'             END
        + CASE WHEN Z.C308 = W.C308 OR E.[Rows] < 3 OR (Z.C308 BETWEEN T.C308_AVG - (T.C308_STD * @Hour) AND T.C308_AVG + (T.C308_STD * @Hour)) OR (Z.C308 BETWEEN E.C308_AVG - (E.C308_STD * @Week) AND E.C308_AVG + (E.C308_STD * @Week)) THEN SPACE(0) ELSE @CR + 'RAM_grants'             END
        + CASE WHEN Z.C307 = W.C307 OR E.[Rows] < 3 OR (Z.C307 BETWEEN T.C307_AVG - (T.C307_STD * @Hour) AND T.C307_AVG + (T.C307_STD * @Hour)) OR (Z.C307 BETWEEN E.C307_AVG - (E.C307_STD * @Week) AND E.C307_AVG + (E.C307_STD * @Week)) THEN SPACE(0) ELSE @CR + 'GBs_RAM_task'           END
        + CASE WHEN Z.C306 = W.C306 OR E.[Rows] < 3 OR (Z.C306 BETWEEN T.C306_AVG - (T.C306_STD * @Hour) AND T.C306_AVG + (T.C306_STD * @Hour)) OR (Z.C306 BETWEEN E.C306_AVG - (E.C306_STD * @Week) AND E.C306_AVG + (E.C306_STD * @Week)) THEN SPACE(0) ELSE @CR + 'GBs_RAM_lock'           END
        + CASE WHEN Z.C303 = W.C303 OR E.[Rows] < 3 OR (Z.C303 BETWEEN T.C303_AVG - (T.C303_STD * @Hour) AND T.C303_AVG + (T.C303_STD * @Hour)) OR (Z.C303 BETWEEN E.C303_AVG - (E.C303_STD * @Week) AND E.C303_AVG + (E.C303_STD * @Week)) THEN SPACE(0) ELSE @CR + 'GBs_RAM_disk'           END -- SQL Server 2012 and newer
--      + CASE WHEN Z.C302 = W.C302 OR E.[Rows] < 3 OR (Z.C302 BETWEEN T.C302_AVG - (T.C302_STD * @Hour) AND T.C302_AVG + (T.C302_STD * @Hour)) OR (Z.C302 BETWEEN E.C302_AVG - (E.C302_STD * @Week) AND E.C302_AVG + (E.C302_STD * @Week)) THEN SPACE(0) ELSE @CR + 'GBs_RAM_disk'           END -- less than SQL Server 2012
        + CASE WHEN Z.C304 = W.C304 OR E.[Rows] < 3 OR (Z.C304 BETWEEN T.C304_AVG - (T.C304_STD * @Hour) AND T.C304_AVG + (T.C304_STD * @Hour)) OR (Z.C304 BETWEEN E.C304_AVG - (E.C304_STD * @Week) AND E.C304_AVG + (E.C304_STD * @Week)) THEN SPACE(0) ELSE @CR + 'GBs_RAM_total'          END
        + CASE WHEN Z.C305 = W.C305 OR E.[Rows] < 3 OR (Z.C305 BETWEEN T.C305_AVG - (T.C305_STD * @Hour) AND T.C305_AVG + (T.C305_STD * @Hour)) OR (Z.C305 BETWEEN E.C305_AVG - (E.C305_STD * @Week) AND E.C305_AVG + (E.C305_STD * @Week)) THEN SPACE(0) ELSE @CR + 'GBs_RAM_ideal'          END
        + CASE WHEN Z.C501 = W.C501 THEN SPACE(0) ELSE @CR + 'GBs_RAM_final'  END
        + CASE WHEN Z.C108 = W.C108 THEN SPACE(0) ELSE @CR + 'GBs_Server_Min' END
        + CASE WHEN Z.C109 = W.C109 THEN SPACE(0) ELSE @CR + 'GBs_Server_Max' END

        + CASE WHEN Z.R102 = W.R102 OR E.[Rows] < 3 OR (Z.R102 BETWEEN T.R102_AVG - (T.R102_STD * @Hour) AND T.R102_AVG + (T.R102_STD * @Hour)) OR (Z.R102 BETWEEN E.R102_AVG - (E.R102_STD * @Week) AND E.R102_AVG + (E.R102_STD * @Week)) THEN SPACE(0) ELSE @CR + 'PCHR_object'            END
        + CASE WHEN Z.R103 = W.R103 OR E.[Rows] < 3 OR (Z.R103 BETWEEN T.R103_AVG - (T.R103_STD * @Hour) AND T.R103_AVG + (T.R103_STD * @Hour)) OR (Z.R103 BETWEEN E.R103_AVG - (E.R103_STD * @Week) AND E.R103_AVG + (E.R103_STD * @Week)) THEN SPACE(0) ELSE @CR + 'PCHR_ad_hoc'            END
        + CASE WHEN Z.C204 = W.C204 OR E.[Rows] < 3 OR (Z.C204 BETWEEN T.C204_AVG - (T.C204_STD * @Hour) AND T.C204_AVG + (T.C204_STD * @Hour)) OR (Z.C204 BETWEEN E.C204_AVG - (E.C204_STD * @Week) AND E.C204_AVG + (E.C204_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Tally_PC_object'        END
        + CASE WHEN Z.C205 = W.C205 OR E.[Rows] < 3 OR (Z.C205 BETWEEN T.C205_AVG - (T.C205_STD * @Hour) AND T.C205_AVG + (T.C205_STD * @Hour)) OR (Z.C205 BETWEEN E.C205_AVG - (E.C205_STD * @Week) AND E.C205_AVG + (E.C205_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Tally_PC_ad_hoc'        END
        + CASE WHEN Z.C104 = W.C104 OR E.[Rows] < 3 OR (Z.C104 BETWEEN T.C104_AVG - (T.C104_STD * @Hour) AND T.C104_AVG + (T.C104_STD * @Hour)) OR (Z.C104 BETWEEN E.C104_AVG - (E.C104_STD * @Week) AND E.C104_AVG + (E.C104_STD * @Week)) THEN SPACE(0) ELSE @CR + 'GBs_PC_object'          END
        + CASE WHEN Z.C105 = W.C105 OR E.[Rows] < 3 OR (Z.C105 BETWEEN T.C105_AVG - (T.C105_STD * @Hour) AND T.C105_AVG + (T.C105_STD * @Hour)) OR (Z.C105 BETWEEN E.C105_AVG - (E.C105_STD * @Week) AND E.C105_AVG + (E.C105_STD * @Week)) THEN SPACE(0) ELSE @CR + 'GBs_PC_ad_hoc'          END
        + CASE WHEN Z.C206 = W.C206 THEN SPACE(0) ELSE @CR + 'Trigger_Nest'   END
        + CASE WHEN Z.C207 = W.C207 THEN SPACE(0) ELSE @CR + 'Favor_ad_hoc'   END
        + CASE WHEN Z.C106 = W.C106 THEN SPACE(0) ELSE @CR + 'DOP_Max'        END
        + CASE WHEN Z.C107 = W.C107 THEN SPACE(0) ELSE @CR + 'DOP_Cost'       END

        + CASE WHEN Z.C401 = W.C401 OR E.[Rows] < 3 OR (Z.C401 BETWEEN T.C401_AVG - (T.C401_STD * @Hour) AND T.C401_AVG + (T.C401_STD * @Hour)) OR (Z.C401 BETWEEN E.C401_AVG - (E.C401_STD * @Week) AND E.C401_AVG + (E.C401_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Transactions (Current)' END
        + CASE WHEN Z.C402 = W.C402 OR E.[Rows] < 3 OR (Z.C402 BETWEEN T.C402_AVG - (T.C402_STD * @Hour) AND T.C402_AVG + (T.C402_STD * @Hour)) OR (Z.C402 BETWEEN E.C402_AVG - (E.C402_STD * @Week) AND E.C402_AVG + (E.C402_STD * @Week)) THEN SPACE(0) ELSE @CR + 'XAs_tempdb (Current)'   END
        + CASE WHEN Z.C403 = W.C403 OR E.[Rows] < 3 OR (Z.C403 BETWEEN T.C403_AVG - (T.C403_STD * @Hour) AND T.C403_AVG + (T.C403_STD * @Hour)) OR (Z.C403 BETWEEN E.C403_AVG - (E.C403_STD * @Week) AND E.C403_AVG + (E.C403_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Cursors_All (Current)'  END
        + CASE WHEN Z.C404 = W.C404 OR E.[Rows] < 3 OR (Z.C404 BETWEEN T.C404_AVG - (T.C404_STD * @Hour) AND T.C404_AVG + (T.C404_STD * @Hour)) OR (Z.C404 BETWEEN E.C404_AVG - (E.C404_STD * @Week) AND E.C404_AVG + (E.C404_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Cursors_API (Current)'  END
--      + CASE WHEN Z.C405 = W.C405 OR E.[Rows] < 3 OR (Z.C405 BETWEEN T.C405_AVG - (T.C405_STD * @Hour) AND T.C405_AVG + (T.C405_STD * @Hour)) OR (Z.C405 BETWEEN E.C405_AVG - (E.C405_STD * @Week) AND E.C405_AVG + (E.C405_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Cursor_KB_All'          END
--      + CASE WHEN Z.C406 = W.C406 OR E.[Rows] < 3 OR (Z.C406 BETWEEN T.C406_AVG - (T.C406_STD * @Hour) AND T.C406_AVG + (T.C406_STD * @Hour)) OR (Z.C406 BETWEEN E.C406_AVG - (E.C406_STD * @Week) AND E.C406_AVG + (E.C406_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Cursor_KB_API'          END
        + CASE WHEN Z.C407 = W.C407 OR E.[Rows] < 3 OR (Z.C407 BETWEEN T.C407_AVG - (T.C407_STD * @Hour) AND T.C407_AVG + (T.C407_STD * @Hour)) OR (Z.C407 BETWEEN E.C407_AVG - (E.C407_STD * @Week) AND E.C407_AVG + (E.C407_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Temp_Tables (Current)'  END
        + CASE WHEN Z.C408 = W.C408 OR E.[Rows] < 3 OR (Z.C408 BETWEEN T.C408_AVG - (T.C408_STD * @Hour) AND T.C408_AVG + (T.C408_STD * @Hour)) OR (Z.C408 BETWEEN E.C408_AVG - (E.C408_STD * @Week) AND E.C408_AVG + (E.C408_STD * @Week)) THEN SPACE(0) ELSE @CR + 'SPID_Blocks'            END
        + CASE WHEN Z.C409 = W.C409 OR E.[Rows] < 3 OR (Z.C409 BETWEEN T.C409_AVG - (T.C409_STD * @Hour) AND T.C409_AVG + (T.C409_STD * @Hour)) OR (Z.C409 BETWEEN E.C409_AVG - (E.C409_STD * @Week) AND E.C409_AVG + (E.C409_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Connections'            END
        + CASE WHEN Z.C504 = W.C504 OR E.[Rows] < 3 OR (Z.C504 BETWEEN T.C504_AVG - (T.C504_STD * @Hour) AND T.C504_AVG + (T.C504_STD * @Hour)) OR (Z.C504 BETWEEN E.C504_AVG - (E.C504_STD * @Week) AND E.C504_AVG + (E.C504_STD * @Week)) THEN SPACE(0) ELSE @CR + 'CPUs_Idle'              END
        + CASE WHEN Z.C505 = W.C505 OR E.[Rows] < 3 OR (Z.C505 BETWEEN T.C505_AVG - (T.C505_STD * @Hour) AND T.C505_AVG + (T.C505_STD * @Hour)) OR (Z.C505 BETWEEN E.C505_AVG - (E.C505_STD * @Week) AND E.C505_AVG + (E.C505_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Workers_All'            END
        + CASE WHEN Z.C506 = W.C506 OR E.[Rows] < 3 OR (Z.C506 BETWEEN T.C506_AVG - (T.C506_STD * @Hour) AND T.C506_AVG + (T.C506_STD * @Hour)) OR (Z.C506 BETWEEN E.C506_AVG - (E.C506_STD * @Week) AND E.C506_AVG + (E.C506_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Workers_Wait'           END
        + CASE WHEN Z.C507 = W.C507 OR E.[Rows] < 3 OR (Z.C507 BETWEEN T.C507_AVG - (T.C507_STD * @Hour) AND T.C507_AVG + (T.C507_STD * @Hour)) OR (Z.C507 BETWEEN E.C507_AVG - (E.C507_STD * @Week) AND E.C507_AVG + (E.C507_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Tasks_All'              END
        + CASE WHEN Z.C508 = W.C508 OR E.[Rows] < 3 OR (Z.C508 BETWEEN T.C508_AVG - (T.C508_STD * @Hour) AND T.C508_AVG + (T.C508_STD * @Hour)) OR (Z.C508 BETWEEN E.C508_AVG - (E.C508_STD * @Week) AND E.C508_AVG + (E.C508_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Tasks_Wait'             END
        + CASE WHEN Z.C509 = W.C509 OR E.[Rows] < 3 OR (Z.C509 BETWEEN T.C509_AVG - (T.C509_STD * @Hour) AND T.C509_AVG + (T.C509_STD * @Hour)) OR (Z.C509 BETWEEN E.C509_AVG - (E.C509_STD * @Week) AND E.C509_AVG + (E.C509_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Pending_IOs'            END
        + CASE WHEN Z.C502 = W.C502 THEN SPACE(0) ELSE @CR + 'CPUs_All'       END
        + CASE WHEN Z.C503 = W.C503 THEN SPACE(0) ELSE @CR + 'CPUs_SQL'       END

        + CASE WHEN Z.C703 = W.C703 OR E.[Rows] < 3 OR (Z.C703 BETWEEN T.C703_AVG - (T.C703_STD * @Hour) AND T.C703_AVG + (T.C703_STD * @Hour)) OR (Z.C703 BETWEEN E.C703_AVG - (E.C703_STD * @Week) AND E.C703_AVG + (E.C703_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Transactions (History)' END
        + CASE WHEN Z.C704 = W.C704 OR E.[Rows] < 3 OR (Z.C704 BETWEEN T.C704_AVG - (T.C704_STD * @Hour) AND T.C704_AVG + (T.C704_STD * @Hour)) OR (Z.C704 BETWEEN E.C704_AVG - (E.C704_STD * @Week) AND E.C704_AVG + (E.C704_STD * @Week)) THEN SPACE(0) ELSE @CR + 'XAs_tempdb (History)'   END
        + CASE WHEN Z.C705 = W.C705 OR E.[Rows] < 3 OR (Z.C705 BETWEEN T.C705_AVG - (T.C705_STD * @Hour) AND T.C705_AVG + (T.C705_STD * @Hour)) OR (Z.C705 BETWEEN E.C705_AVG - (E.C705_STD * @Week) AND E.C705_AVG + (E.C705_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Cursors_All (History)'  END
        + CASE WHEN Z.C706 = W.C706 OR E.[Rows] < 3 OR (Z.C706 BETWEEN T.C706_AVG - (T.C706_STD * @Hour) AND T.C706_AVG + (T.C706_STD * @Hour)) OR (Z.C706 BETWEEN E.C706_AVG - (E.C706_STD * @Week) AND E.C706_AVG + (E.C706_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Cursors_API (History)'  END
        + CASE WHEN Z.C606 = W.C606 OR E.[Rows] < 3 OR (Z.C606 BETWEEN T.C606_AVG - (T.C606_STD * @Hour) AND T.C606_AVG + (T.C606_STD * @Hour)) OR (Z.C606 BETWEEN E.C606_AVG - (E.C606_STD * @Week) AND E.C606_AVG + (E.C606_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Temp_Tables (History)'  END
        + CASE WHEN Z.C601 = W.C601 OR E.[Rows] < 3 OR (Z.C601 BETWEEN T.C601_AVG - (T.C601_STD * @Hour) AND T.C601_AVG + (T.C601_STD * @Hour)) OR (Z.C601 BETWEEN E.C601_AVG - (E.C601_STD * @Week) AND E.C601_AVG + (E.C601_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Table_Scans'            END
        + CASE WHEN Z.C602 = W.C602 OR E.[Rows] < 3 OR (Z.C602 BETWEEN T.C602_AVG - (T.C602_STD * @Hour) AND T.C602_AVG + (T.C602_STD * @Hour)) OR (Z.C602 BETWEEN E.C602_AVG - (E.C602_STD * @Week) AND E.C602_AVG + (E.C602_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Page_Splits'            END
        + CASE WHEN Z.C603 = W.C603 OR E.[Rows] < 3 OR (Z.C603 BETWEEN T.C603_AVG - (T.C603_STD * @Hour) AND T.C603_AVG + (T.C603_STD * @Hour)) OR (Z.C603 BETWEEN E.C603_AVG - (E.C603_STD * @Week) AND E.C603_AVG + (E.C603_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Page_Reads'             END
        + CASE WHEN Z.C604 = W.C604 OR E.[Rows] < 3 OR (Z.C604 BETWEEN T.C604_AVG - (T.C604_STD * @Hour) AND T.C604_AVG + (T.C604_STD * @Hour)) OR (Z.C604 BETWEEN E.C604_AVG - (E.C604_STD * @Week) AND E.C604_AVG + (E.C604_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Page_Writes'            END
--      + CASE WHEN Z.C605 = W.C605 OR E.[Rows] < 3 OR (Z.C605 BETWEEN T.C605_AVG - (T.C605_STD * @Hour) AND T.C605_AVG + (T.C605_STD * @Hour)) OR (Z.C605 BETWEEN E.C605_AVG - (E.C605_STD * @Week) AND E.C605_AVG + (E.C605_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Page_Lookups'           END
--      + CASE WHEN Z.C607 = W.C607 OR E.[Rows] < 3 OR (Z.C607 BETWEEN T.C607_AVG - (T.C607_STD * @Hour) AND T.C607_AVG + (T.C607_STD * @Hour)) OR (Z.C607 BETWEEN E.C607_AVG - (E.C607_STD * @Week) AND E.C607_AVG + (E.C607_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Resets'                 END
--      + CASE WHEN Z.C608 = W.C608 OR E.[Rows] < 3 OR (Z.C608 BETWEEN T.C608_AVG - (T.C608_STD * @Hour) AND T.C608_AVG + (T.C608_STD * @Hour)) OR (Z.C608 BETWEEN E.C608_AVG - (E.C608_STD * @Week) AND E.C608_AVG + (E.C608_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Logins'                 END
--      + CASE WHEN Z.C609 = W.C609 OR E.[Rows] < 3 OR (Z.C609 BETWEEN T.C609_AVG - (T.C609_STD * @Hour) AND T.C609_AVG + (T.C609_STD * @Hour)) OR (Z.C609 BETWEEN E.C609_AVG - (E.C609_STD * @Week) AND E.C609_AVG + (E.C609_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Logouts'                END
        + CASE WHEN Z.C701 = W.C701 OR E.[Rows] < 3 OR (Z.C701 BETWEEN T.C701_AVG - (T.C701_STD * @Hour) AND T.C701_AVG + (T.C701_STD * @Hour)) OR (Z.C701 BETWEEN E.C701_AVG - (E.C701_STD * @Week) AND E.C701_AVG + (E.C701_STD * @Week)) THEN SPACE(0) ELSE @CR + 'SQL_Compiles'           END
        + CASE WHEN Z.C702 = W.C702 OR E.[Rows] < 3 OR (Z.C702 BETWEEN T.C702_AVG - (T.C702_STD * @Hour) AND T.C702_AVG + (T.C702_STD * @Hour)) OR (Z.C702 BETWEEN E.C702_AVG - (E.C702_STD * @Week) AND E.C702_AVG + (E.C702_STD * @Week)) THEN SPACE(0) ELSE @CR + 'SQL_Batches'            END
        + CASE WHEN Z.C707 = W.C707 OR E.[Rows] < 3 OR (Z.C707 BETWEEN T.C707_AVG - (T.C707_STD * @Hour) AND T.C707_AVG + (T.C707_STD * @Hour)) OR (Z.C707 BETWEEN E.C707_AVG - (E.C707_STD * @Week) AND E.C707_AVG + (E.C707_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Errors_11_19'           END
        + CASE WHEN Z.C708 = W.C708 OR E.[Rows] < 3 OR (Z.C708 BETWEEN T.C708_AVG - (T.C708_STD * @Hour) AND T.C708_AVG + (T.C708_STD * @Hour)) OR (Z.C708 BETWEEN E.C708_AVG - (E.C708_STD * @Week) AND E.C708_AVG + (E.C708_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Errors_20_25'           END
        + CASE WHEN Z.C709 = W.C709 OR E.[Rows] < 3 OR (Z.C709 BETWEEN T.C709_AVG - (T.C709_STD * @Hour) AND T.C709_AVG + (T.C709_STD * @Hour)) OR (Z.C709 BETWEEN E.C709_AVG - (E.C709_STD * @Week) AND E.C709_AVG + (E.C709_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Deadlocks'              END

     FROM
  (SELECT I.*
     FROM #CounterHistoryHour AS I
    WHERE I.KeyDT = @DateTimeThru) AS Z,
  (SELECT I.*
     FROM #CounterHistoryHour AS I
    WHERE I.KeyDT = @DateTimeBack) AS W,
  (SELECT COUNT(*) AS [Rows]
        , AVG(CONVERT(decimal(19,03), I.R101)) AS R101_AVG, STDEVP(I.R101) AS R101_STD
        , AVG(CONVERT(decimal(19,03), I.R102)) AS R102_AVG, STDEVP(I.R102) AS R102_STD
        , AVG(CONVERT(decimal(19,03), I.R103)) AS R103_AVG, STDEVP(I.R103) AS R103_STD
--      , AVG(CONVERT(decimal(19,03), I.C101)) AS C101_AVG, STDEVP(I.C101) AS C101_STD
--      , AVG(CONVERT(decimal(19,03), I.C102)) AS C102_AVG, STDEVP(I.C102) AS C102_STD
--      , AVG(CONVERT(decimal(19,03), I.C103)) AS C103_AVG, STDEVP(I.C103) AS C103_STD
        , AVG(CONVERT(decimal(19,03), I.C104)) AS C104_AVG, STDEVP(I.C104) AS C104_STD
        , AVG(CONVERT(decimal(19,03), I.C105)) AS C105_AVG, STDEVP(I.C105) AS C105_STD
        , AVG(CONVERT(decimal(19,03), I.C106)) AS C106_AVG, STDEVP(I.C106) AS C106_STD
        , AVG(CONVERT(decimal(19,03), I.C107)) AS C107_AVG, STDEVP(I.C107) AS C107_STD
        , AVG(CONVERT(decimal(19,03), I.C108)) AS C108_AVG, STDEVP(I.C108) AS C108_STD
        , AVG(CONVERT(decimal(19,03), I.C109)) AS C109_AVG, STDEVP(I.C109) AS C109_STD
--      , AVG(CONVERT(decimal(19,03), I.C201)) AS C201_AVG, STDEVP(I.C201) AS C201_STD
--      , AVG(CONVERT(decimal(19,03), I.C202)) AS C202_AVG, STDEVP(I.C202) AS C202_STD
--      , AVG(CONVERT(decimal(19,03), I.C203)) AS C203_AVG, STDEVP(I.C203) AS C203_STD
        , AVG(CONVERT(decimal(19,03), I.C204)) AS C204_AVG, STDEVP(I.C204) AS C204_STD
        , AVG(CONVERT(decimal(19,03), I.C205)) AS C205_AVG, STDEVP(I.C205) AS C205_STD
        , AVG(CONVERT(decimal(19,03), I.C206)) AS C206_AVG, STDEVP(I.C206) AS C206_STD
        , AVG(CONVERT(decimal(19,03), I.C207)) AS C207_AVG, STDEVP(I.C207) AS C207_STD
        , AVG(CONVERT(decimal(19,03), I.C208)) AS C208_AVG, STDEVP(I.C208) AS C208_STD
        , AVG(CONVERT(decimal(19,03), I.C209)) AS C209_AVG, STDEVP(I.C209) AS C209_STD
        , AVG(CONVERT(decimal(19,03), I.C301)) AS C301_AVG, STDEVP(I.C301) AS C301_STD
        , AVG(CONVERT(decimal(19,03), I.C302)) AS C302_AVG, STDEVP(I.C302) AS C302_STD
        , AVG(CONVERT(decimal(19,03), I.C303)) AS C303_AVG, STDEVP(I.C303) AS C303_STD
        , AVG(CONVERT(decimal(19,03), I.C304)) AS C304_AVG, STDEVP(I.C304) AS C304_STD
        , AVG(CONVERT(decimal(19,03), I.C305)) AS C305_AVG, STDEVP(I.C305) AS C305_STD
        , AVG(CONVERT(decimal(19,03), I.C306)) AS C306_AVG, STDEVP(I.C306) AS C306_STD
        , AVG(CONVERT(decimal(19,03), I.C307)) AS C307_AVG, STDEVP(I.C307) AS C307_STD
        , AVG(CONVERT(decimal(19,03), I.C308)) AS C308_AVG, STDEVP(I.C308) AS C308_STD
        , AVG(CONVERT(decimal(19,03), I.C309)) AS C309_AVG, STDEVP(I.C309) AS C309_STD
        , AVG(CONVERT(decimal(19,03), I.C401)) AS C401_AVG, STDEVP(I.C401) AS C401_STD
        , AVG(CONVERT(decimal(19,03), I.C402)) AS C402_AVG, STDEVP(I.C402) AS C402_STD
        , AVG(CONVERT(decimal(19,03), I.C403)) AS C403_AVG, STDEVP(I.C403) AS C403_STD
        , AVG(CONVERT(decimal(19,03), I.C404)) AS C404_AVG, STDEVP(I.C404) AS C404_STD
        , AVG(CONVERT(decimal(19,03), I.C405)) AS C405_AVG, STDEVP(I.C405) AS C405_STD
        , AVG(CONVERT(decimal(19,03), I.C406)) AS C406_AVG, STDEVP(I.C406) AS C406_STD
        , AVG(CONVERT(decimal(19,03), I.C407)) AS C407_AVG, STDEVP(I.C407) AS C407_STD
        , AVG(CONVERT(decimal(19,03), I.C408)) AS C408_AVG, STDEVP(I.C408) AS C408_STD
        , AVG(CONVERT(decimal(19,03), I.C409)) AS C409_AVG, STDEVP(I.C409) AS C409_STD
        , AVG(CONVERT(decimal(19,03), I.C501)) AS C501_AVG, STDEVP(I.C501) AS C501_STD
        , AVG(CONVERT(decimal(19,03), I.C502)) AS C502_AVG, STDEVP(I.C502) AS C502_STD
        , AVG(CONVERT(decimal(19,03), I.C503)) AS C503_AVG, STDEVP(I.C503) AS C503_STD
        , AVG(CONVERT(decimal(19,03), I.C504)) AS C504_AVG, STDEVP(I.C504) AS C504_STD
        , AVG(CONVERT(decimal(19,03), I.C505)) AS C505_AVG, STDEVP(I.C505) AS C505_STD
        , AVG(CONVERT(decimal(19,03), I.C506)) AS C506_AVG, STDEVP(I.C506) AS C506_STD
        , AVG(CONVERT(decimal(19,03), I.C507)) AS C507_AVG, STDEVP(I.C507) AS C507_STD
        , AVG(CONVERT(decimal(19,03), I.C508)) AS C508_AVG, STDEVP(I.C508) AS C508_STD
        , AVG(CONVERT(decimal(19,03), I.C509)) AS C509_AVG, STDEVP(I.C509) AS C509_STD
        , AVG(CONVERT(decimal(19,03), I.C601)) AS C601_AVG, STDEVP(I.C601) AS C601_STD
        , AVG(CONVERT(decimal(19,03), I.C602)) AS C602_AVG, STDEVP(I.C602) AS C602_STD
        , AVG(CONVERT(decimal(19,03), I.C603)) AS C603_AVG, STDEVP(I.C603) AS C603_STD
        , AVG(CONVERT(decimal(19,03), I.C604)) AS C604_AVG, STDEVP(I.C604) AS C604_STD
        , AVG(CONVERT(decimal(19,03), I.C605)) AS C605_AVG, STDEVP(I.C605) AS C605_STD
        , AVG(CONVERT(decimal(19,03), I.C606)) AS C606_AVG, STDEVP(I.C606) AS C606_STD
        , AVG(CONVERT(decimal(19,03), I.C607)) AS C607_AVG, STDEVP(I.C607) AS C607_STD
        , AVG(CONVERT(decimal(19,03), I.C608)) AS C608_AVG, STDEVP(I.C608) AS C608_STD
        , AVG(CONVERT(decimal(19,03), I.C609)) AS C609_AVG, STDEVP(I.C609) AS C609_STD
        , AVG(CONVERT(decimal(19,03), I.C701)) AS C701_AVG, STDEVP(I.C701) AS C701_STD
        , AVG(CONVERT(decimal(19,03), I.C702)) AS C702_AVG, STDEVP(I.C702) AS C702_STD
        , AVG(CONVERT(decimal(19,03), I.C703)) AS C703_AVG, STDEVP(I.C703) AS C703_STD
        , AVG(CONVERT(decimal(19,03), I.C704)) AS C704_AVG, STDEVP(I.C704) AS C704_STD
        , AVG(CONVERT(decimal(19,03), I.C705)) AS C705_AVG, STDEVP(I.C705) AS C705_STD
        , AVG(CONVERT(decimal(19,03), I.C706)) AS C706_AVG, STDEVP(I.C706) AS C706_STD
        , AVG(CONVERT(decimal(19,03), I.C707)) AS C707_AVG, STDEVP(I.C707) AS C707_STD
        , AVG(CONVERT(decimal(19,03), I.C708)) AS C708_AVG, STDEVP(I.C708) AS C708_STD
        , AVG(CONVERT(decimal(19,03), I.C709)) AS C709_AVG, STDEVP(I.C709) AS C709_STD
     FROM #CounterHistoryHour AS I) AS T,
  (SELECT COUNT(*) AS [Rows]
        , AVG(CONVERT(decimal(19,03), I.R101)) AS R101_AVG, STDEVP(I.R101) AS R101_STD
        , AVG(CONVERT(decimal(19,03), I.R102)) AS R102_AVG, STDEVP(I.R102) AS R102_STD
        , AVG(CONVERT(decimal(19,03), I.R103)) AS R103_AVG, STDEVP(I.R103) AS R103_STD
--      , AVG(CONVERT(decimal(19,03), I.C101)) AS C101_AVG, STDEVP(I.C101) AS C101_STD
--      , AVG(CONVERT(decimal(19,03), I.C102)) AS C102_AVG, STDEVP(I.C102) AS C102_STD
--      , AVG(CONVERT(decimal(19,03), I.C103)) AS C103_AVG, STDEVP(I.C103) AS C103_STD
        , AVG(CONVERT(decimal(19,03), I.C104)) AS C104_AVG, STDEVP(I.C104) AS C104_STD
        , AVG(CONVERT(decimal(19,03), I.C105)) AS C105_AVG, STDEVP(I.C105) AS C105_STD
        , AVG(CONVERT(decimal(19,03), I.C106)) AS C106_AVG, STDEVP(I.C106) AS C106_STD
        , AVG(CONVERT(decimal(19,03), I.C107)) AS C107_AVG, STDEVP(I.C107) AS C107_STD
        , AVG(CONVERT(decimal(19,03), I.C108)) AS C108_AVG, STDEVP(I.C108) AS C108_STD
        , AVG(CONVERT(decimal(19,03), I.C109)) AS C109_AVG, STDEVP(I.C109) AS C109_STD
--      , AVG(CONVERT(decimal(19,03), I.C201)) AS C201_AVG, STDEVP(I.C201) AS C201_STD
--      , AVG(CONVERT(decimal(19,03), I.C202)) AS C202_AVG, STDEVP(I.C202) AS C202_STD
--      , AVG(CONVERT(decimal(19,03), I.C203)) AS C203_AVG, STDEVP(I.C203) AS C203_STD
        , AVG(CONVERT(decimal(19,03), I.C204)) AS C204_AVG, STDEVP(I.C204) AS C204_STD
        , AVG(CONVERT(decimal(19,03), I.C205)) AS C205_AVG, STDEVP(I.C205) AS C205_STD
        , AVG(CONVERT(decimal(19,03), I.C206)) AS C206_AVG, STDEVP(I.C206) AS C206_STD
        , AVG(CONVERT(decimal(19,03), I.C207)) AS C207_AVG, STDEVP(I.C207) AS C207_STD
        , AVG(CONVERT(decimal(19,03), I.C208)) AS C208_AVG, STDEVP(I.C208) AS C208_STD
        , AVG(CONVERT(decimal(19,03), I.C209)) AS C209_AVG, STDEVP(I.C209) AS C209_STD
        , AVG(CONVERT(decimal(19,03), I.C301)) AS C301_AVG, STDEVP(I.C301) AS C301_STD
        , AVG(CONVERT(decimal(19,03), I.C302)) AS C302_AVG, STDEVP(I.C302) AS C302_STD
        , AVG(CONVERT(decimal(19,03), I.C303)) AS C303_AVG, STDEVP(I.C303) AS C303_STD
        , AVG(CONVERT(decimal(19,03), I.C304)) AS C304_AVG, STDEVP(I.C304) AS C304_STD
        , AVG(CONVERT(decimal(19,03), I.C305)) AS C305_AVG, STDEVP(I.C305) AS C305_STD
        , AVG(CONVERT(decimal(19,03), I.C306)) AS C306_AVG, STDEVP(I.C306) AS C306_STD
        , AVG(CONVERT(decimal(19,03), I.C307)) AS C307_AVG, STDEVP(I.C307) AS C307_STD
        , AVG(CONVERT(decimal(19,03), I.C308)) AS C308_AVG, STDEVP(I.C308) AS C308_STD
        , AVG(CONVERT(decimal(19,03), I.C309)) AS C309_AVG, STDEVP(I.C309) AS C309_STD
        , AVG(CONVERT(decimal(19,03), I.C401)) AS C401_AVG, STDEVP(I.C401) AS C401_STD
        , AVG(CONVERT(decimal(19,03), I.C402)) AS C402_AVG, STDEVP(I.C402) AS C402_STD
        , AVG(CONVERT(decimal(19,03), I.C403)) AS C403_AVG, STDEVP(I.C403) AS C403_STD
        , AVG(CONVERT(decimal(19,03), I.C404)) AS C404_AVG, STDEVP(I.C404) AS C404_STD
        , AVG(CONVERT(decimal(19,03), I.C405)) AS C405_AVG, STDEVP(I.C405) AS C405_STD
        , AVG(CONVERT(decimal(19,03), I.C406)) AS C406_AVG, STDEVP(I.C406) AS C406_STD
        , AVG(CONVERT(decimal(19,03), I.C407)) AS C407_AVG, STDEVP(I.C407) AS C407_STD
        , AVG(CONVERT(decimal(19,03), I.C408)) AS C408_AVG, STDEVP(I.C408) AS C408_STD
        , AVG(CONVERT(decimal(19,03), I.C409)) AS C409_AVG, STDEVP(I.C409) AS C409_STD
        , AVG(CONVERT(decimal(19,03), I.C501)) AS C501_AVG, STDEVP(I.C501) AS C501_STD
        , AVG(CONVERT(decimal(19,03), I.C502)) AS C502_AVG, STDEVP(I.C502) AS C502_STD
        , AVG(CONVERT(decimal(19,03), I.C503)) AS C503_AVG, STDEVP(I.C503) AS C503_STD
        , AVG(CONVERT(decimal(19,03), I.C504)) AS C504_AVG, STDEVP(I.C504) AS C504_STD
        , AVG(CONVERT(decimal(19,03), I.C505)) AS C505_AVG, STDEVP(I.C505) AS C505_STD
        , AVG(CONVERT(decimal(19,03), I.C506)) AS C506_AVG, STDEVP(I.C506) AS C506_STD
        , AVG(CONVERT(decimal(19,03), I.C507)) AS C507_AVG, STDEVP(I.C507) AS C507_STD
        , AVG(CONVERT(decimal(19,03), I.C508)) AS C508_AVG, STDEVP(I.C508) AS C508_STD
        , AVG(CONVERT(decimal(19,03), I.C509)) AS C509_AVG, STDEVP(I.C509) AS C509_STD
        , AVG(CONVERT(decimal(19,03), I.C601)) AS C601_AVG, STDEVP(I.C601) AS C601_STD
        , AVG(CONVERT(decimal(19,03), I.C602)) AS C602_AVG, STDEVP(I.C602) AS C602_STD
        , AVG(CONVERT(decimal(19,03), I.C603)) AS C603_AVG, STDEVP(I.C603) AS C603_STD
        , AVG(CONVERT(decimal(19,03), I.C604)) AS C604_AVG, STDEVP(I.C604) AS C604_STD
        , AVG(CONVERT(decimal(19,03), I.C605)) AS C605_AVG, STDEVP(I.C605) AS C605_STD
        , AVG(CONVERT(decimal(19,03), I.C606)) AS C606_AVG, STDEVP(I.C606) AS C606_STD
        , AVG(CONVERT(decimal(19,03), I.C607)) AS C607_AVG, STDEVP(I.C607) AS C607_STD
        , AVG(CONVERT(decimal(19,03), I.C608)) AS C608_AVG, STDEVP(I.C608) AS C608_STD
        , AVG(CONVERT(decimal(19,03), I.C609)) AS C609_AVG, STDEVP(I.C609) AS C609_STD
        , AVG(CONVERT(decimal(19,03), I.C701)) AS C701_AVG, STDEVP(I.C701) AS C701_STD
        , AVG(CONVERT(decimal(19,03), I.C702)) AS C702_AVG, STDEVP(I.C702) AS C702_STD
        , AVG(CONVERT(decimal(19,03), I.C703)) AS C703_AVG, STDEVP(I.C703) AS C703_STD
        , AVG(CONVERT(decimal(19,03), I.C704)) AS C704_AVG, STDEVP(I.C704) AS C704_STD
        , AVG(CONVERT(decimal(19,03), I.C705)) AS C705_AVG, STDEVP(I.C705) AS C705_STD
        , AVG(CONVERT(decimal(19,03), I.C706)) AS C706_AVG, STDEVP(I.C706) AS C706_STD
        , AVG(CONVERT(decimal(19,03), I.C707)) AS C707_AVG, STDEVP(I.C707) AS C707_STD
        , AVG(CONVERT(decimal(19,03), I.C708)) AS C708_AVG, STDEVP(I.C708) AS C708_STD
        , AVG(CONVERT(decimal(19,03), I.C709)) AS C709_AVG, STDEVP(I.C709) AS C709_STD
     FROM #CounterHistoryWeek AS I) AS E

-- WaitHistory

   SELECT @DateTimeThru = MAX(I.KeyDT) FROM dbo.WaitHistory AS I

   SELECT @DateTimeBack = MAX(I.KeyDT) FROM dbo.WaitHistory AS I WHERE I.KeyDT < @DateTimeThru

   SELECT @DateTimeFrom = DATEADD(second, -90, DATEADD(minute, 0 - (DATEDIFF(minute, @DateTimeBack, @DateTimeThru) * 6), @DateTimeThru))

   SELECT ROW_NUMBER() OVER (ORDER BY I.KeyID) - 1 AS KeyID
        , I.KeyDT
        , I.NIO_WS
        , I.NIO_WT
        , I.DIO_WS
        , I.DIO_WT
        , I.SIO_WS
        , I.SIO_WT
        , I.PIO_WS
        , I.PIO_WT
        , I.LOG_WS
        , I.LOG_WT
        , I.RAM_WS
        , I.RAM_WT
        , I.CPU_WS
        , I.CPU_WT
        , I.DOP_WS
        , I.DOP_WT
        , I.DBM_WS
        , I.DBM_WT
        , I.DBS_WS
        , I.DBS_WT
        , I.X___WS
        , I.X___WT
        , I.U___WS
        , I.U___WT
        , I.S___WS
        , I.S___WT
        , I.IX__WS
        , I.IX__WT
        , I.IU__WS
        , I.IU__WT
        , I.IS__WS
        , I.IS__WT
        , I.SIX_WS
        , I.SIX_WT
        , I.SIU_WS
        , I.SIU_WT
        , I.UIX_WS
        , I.UIX_WT
     INTO    #WaitHistory
     FROM dbo.WaitHistory AS I
    WHERE I.KeyDT !< DATEADD(day, -7, @DateTimeThru)
 ORDER BY I.KeyID

   SELECT I.KeyDT
        , I.NIO_WS - T.NIO_WS
        + I.DIO_WS - T.DIO_WS
        + I.SIO_WS - T.SIO_WS
        + I.PIO_WS - T.PIO_WS
        + I.LOG_WS - T.LOG_WS
        + I.RAM_WS - T.RAM_WS
        + I.CPU_WS - T.CPU_WS
        + I.DOP_WS - T.DOP_WS
        + I.DBM_WS - T.DBM_WS
        + I.DBS_WS - T.DBS_WS
        + I.X___WS - T.X___WS
        + I.U___WS - T.U___WS
        + I.S___WS - T.S___WS
        + I.IX__WS - T.IX__WS
        + I.IU__WS - T.IU__WS
        + I.IS__WS - T.IS__WS
        + I.SIX_WS - T.SIX_WS
        + I.SIU_WS - T.SIU_WS
        + I.UIX_WS - T.UIX_WS AS SQL_WS
        , I.NIO_WT - T.NIO_WT
        + I.DIO_WT - T.DIO_WT
        + I.SIO_WT - T.SIO_WT
        + I.PIO_WT - T.PIO_WT
        + I.LOG_WT - T.LOG_WT
        + I.RAM_WT - T.RAM_WT
        + I.CPU_WT - T.CPU_WT
        + I.DOP_WT - T.DOP_WT
        + I.DBM_WT - T.DBM_WT
        + I.DBS_WT - T.DBS_WT
        + I.X___WT - T.X___WT
        + I.U___WT - T.U___WT
        + I.S___WT - T.S___WT
        + I.IX__WT - T.IX__WT
        + I.IU__WT - T.IU__WT
        + I.IS__WT - T.IS__WT
        + I.SIX_WT - T.SIX_WT
        + I.SIU_WT - T.SIU_WT
        + I.UIX_WT - T.UIX_WT AS SQL_WT
        , I.NIO_WT - T.NIO_WT AS NIO_WT
        , I.DIO_WT - T.DIO_WT AS DIO_WT
        , I.SIO_WT - T.SIO_WT AS SIO_WT
        , I.PIO_WT - T.PIO_WT AS PIO_WT
        , I.LOG_WT - T.LOG_WT AS LOG_WT
        , I.RAM_WT - T.RAM_WT AS RAM_WT
        , I.CPU_WT - T.CPU_WT AS CPU_WT
        , I.DOP_WT - T.DOP_WT AS DOP_WT
        , I.DBM_WT - T.DBM_WT
        + I.DBS_WT - T.DBS_WT
        + I.X___WT - T.X___WT
        + I.U___WT - T.U___WT
        + I.S___WT - T.S___WT
        + I.IX__WT - T.IX__WT
        + I.IU__WT - T.IU__WT
        + I.IS__WT - T.IS__WT
        + I.SIX_WT - T.SIX_WT
        + I.SIU_WT - T.SIU_WT
        + I.UIX_WT - T.UIX_WT AS LCK_WT
     INTO #WaitHistoryHour
     FROM #WaitHistory AS I
     JOIN #WaitHistory AS T
       ON I.KeyID - 1
        = T.KeyID
    WHERE I.KeyDT !< @DateTimeFrom
      AND I.KeyDT !> @DateTimeThru
 ORDER BY I.KeyID

   SELECT I.KeyDT
        , I.NIO_WS - T.NIO_WS
        + I.DIO_WS - T.DIO_WS
        + I.SIO_WS - T.SIO_WS
        + I.PIO_WS - T.PIO_WS
        + I.LOG_WS - T.LOG_WS
        + I.RAM_WS - T.RAM_WS
        + I.CPU_WS - T.CPU_WS
        + I.DOP_WS - T.DOP_WS
        + I.DBM_WS - T.DBM_WS
        + I.DBS_WS - T.DBS_WS
        + I.X___WS - T.X___WS
        + I.U___WS - T.U___WS
        + I.S___WS - T.S___WS
        + I.IX__WS - T.IX__WS
        + I.IU__WS - T.IU__WS
        + I.IS__WS - T.IS__WS
        + I.SIX_WS - T.SIX_WS
        + I.SIU_WS - T.SIU_WS
        + I.UIX_WS - T.UIX_WS AS SQL_WS
        , I.NIO_WT - T.NIO_WT
        + I.DIO_WT - T.DIO_WT
        + I.SIO_WT - T.SIO_WT
        + I.PIO_WT - T.PIO_WT
        + I.LOG_WT - T.LOG_WT
        + I.RAM_WT - T.RAM_WT
        + I.CPU_WT - T.CPU_WT
        + I.DOP_WT - T.DOP_WT
        + I.DBM_WT - T.DBM_WT
        + I.DBS_WT - T.DBS_WT
        + I.X___WT - T.X___WT
        + I.U___WT - T.U___WT
        + I.S___WT - T.S___WT
        + I.IX__WT - T.IX__WT
        + I.IU__WT - T.IU__WT
        + I.IS__WT - T.IS__WT
        + I.SIX_WT - T.SIX_WT
        + I.SIU_WT - T.SIU_WT
        + I.UIX_WT - T.UIX_WT AS SQL_WT
        , I.NIO_WT - T.NIO_WT AS NIO_WT
        , I.DIO_WT - T.DIO_WT AS DIO_WT
        , I.SIO_WT - T.SIO_WT AS SIO_WT
        , I.PIO_WT - T.PIO_WT AS PIO_WT
        , I.LOG_WT - T.LOG_WT AS LOG_WT
        , I.RAM_WT - T.RAM_WT AS RAM_WT
        , I.CPU_WT - T.CPU_WT AS CPU_WT
        , I.DOP_WT - T.DOP_WT AS DOP_WT
        , I.DBM_WT - T.DBM_WT
        + I.DBS_WT - T.DBS_WT
        + I.X___WT - T.X___WT
        + I.U___WT - T.U___WT
        + I.S___WT - T.S___WT
        + I.IX__WT - T.IX__WT
        + I.IU__WT - T.IU__WT
        + I.IS__WT - T.IS__WT
        + I.SIX_WT - T.SIX_WT
        + I.SIU_WT - T.SIU_WT
        + I.UIX_WT - T.UIX_WT AS LCK_WT
     INTO #WaitHistoryWeek
     FROM #WaitHistory AS I
     JOIN #WaitHistory AS T
       ON I.KeyID - 1
        = T.KeyID
    WHERE CASE WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -0, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -0, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -1, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -1, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -2, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -2, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -3, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -3, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -4, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -4, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -5, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -5, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -6, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -6, @DateTimeThru)) THEN 1 ELSE 0 END != 0
 ORDER BY I.KeyID

   SELECT @Message = @Message

        + CASE WHEN Z.SQL_WS = W.SQL_WS OR E.[Rows] < 3 OR (Z.SQL_WS BETWEEN T.SQL_WS_AVG - (T.SQL_WS_STD * @Hour) AND T.SQL_WS_AVG + (T.SQL_WS_STD * @Hour)) OR (Z.SQL_WS BETWEEN E.SQL_WS_AVG - (E.SQL_WS_STD * @Week) AND E.SQL_WS_AVG + (E.SQL_WS_STD * @Week)) THEN SPACE(0) ELSE @CR + 'SQL_WP' END
        + CASE WHEN Z.SQL_WS = W.SQL_WS OR E.[Rows] < 3 OR (Z.SQL_WS BETWEEN T.SQL_WS_AVG - (T.SQL_WS_STD * @Hour) AND T.SQL_WS_AVG + (T.SQL_WS_STD * @Hour)) OR (Z.SQL_WS BETWEEN E.SQL_WS_AVG - (E.SQL_WS_STD * @Week) AND E.SQL_WS_AVG + (E.SQL_WS_STD * @Week)) THEN SPACE(0) ELSE @CR + 'SQL_WS' END
--      + CASE WHEN Z.SQL_WT = W.SQL_WT OR E.[Rows] < 3 OR (Z.SQL_WT BETWEEN T.SQL_WT_AVG - (T.SQL_WT_STD * @Hour) AND T.SQL_WT_AVG + (T.SQL_WT_STD * @Hour)) OR (Z.SQL_WT BETWEEN E.SQL_WT_AVG - (E.SQL_WT_STD * @Week) AND E.SQL_WT_AVG + (E.SQL_WT_STD * @Week)) THEN SPACE(0) ELSE @CR + 'SQL_WT' END
        + CASE WHEN Z.NIO_WT = W.NIO_WT OR E.[Rows] < 3 OR (Z.NIO_WT BETWEEN T.NIO_WT_AVG - (T.NIO_WT_STD * @Hour) AND T.NIO_WT_AVG + (T.NIO_WT_STD * @Hour)) OR (Z.NIO_WT BETWEEN E.NIO_WT_AVG - (E.NIO_WT_STD * @Week) AND E.NIO_WT_AVG + (E.NIO_WT_STD * @Week)) THEN SPACE(0) ELSE @CR + 'NIO_WT' END
        + CASE WHEN Z.DIO_WT = W.DIO_WT OR E.[Rows] < 3 OR (Z.DIO_WT BETWEEN T.DIO_WT_AVG - (T.DIO_WT_STD * @Hour) AND T.DIO_WT_AVG + (T.DIO_WT_STD * @Hour)) OR (Z.DIO_WT BETWEEN E.DIO_WT_AVG - (E.DIO_WT_STD * @Week) AND E.DIO_WT_AVG + (E.DIO_WT_STD * @Week)) THEN SPACE(0) ELSE @CR + 'DIO_WT' END
        + CASE WHEN Z.SIO_WT = W.SIO_WT OR E.[Rows] < 3 OR (Z.SIO_WT BETWEEN T.SIO_WT_AVG - (T.SIO_WT_STD * @Hour) AND T.SIO_WT_AVG + (T.SIO_WT_STD * @Hour)) OR (Z.SIO_WT BETWEEN E.SIO_WT_AVG - (E.SIO_WT_STD * @Week) AND E.SIO_WT_AVG + (E.SIO_WT_STD * @Week)) THEN SPACE(0) ELSE @CR + 'SIO_WT' END
        + CASE WHEN Z.PIO_WT = W.PIO_WT OR E.[Rows] < 3 OR (Z.PIO_WT BETWEEN T.PIO_WT_AVG - (T.PIO_WT_STD * @Hour) AND T.PIO_WT_AVG + (T.PIO_WT_STD * @Hour)) OR (Z.PIO_WT BETWEEN E.PIO_WT_AVG - (E.PIO_WT_STD * @Week) AND E.PIO_WT_AVG + (E.PIO_WT_STD * @Week)) THEN SPACE(0) ELSE @CR + 'PIO_WT' END
        + CASE WHEN Z.LOG_WT = W.LOG_WT OR E.[Rows] < 3 OR (Z.LOG_WT BETWEEN T.LOG_WT_AVG - (T.LOG_WT_STD * @Hour) AND T.LOG_WT_AVG + (T.LOG_WT_STD * @Hour)) OR (Z.LOG_WT BETWEEN E.LOG_WT_AVG - (E.LOG_WT_STD * @Week) AND E.LOG_WT_AVG + (E.LOG_WT_STD * @Week)) THEN SPACE(0) ELSE @CR + 'LOG_WT' END
        + CASE WHEN Z.RAM_WT = W.RAM_WT OR E.[Rows] < 3 OR (Z.RAM_WT BETWEEN T.RAM_WT_AVG - (T.RAM_WT_STD * @Hour) AND T.RAM_WT_AVG + (T.RAM_WT_STD * @Hour)) OR (Z.RAM_WT BETWEEN E.RAM_WT_AVG - (E.RAM_WT_STD * @Week) AND E.RAM_WT_AVG + (E.RAM_WT_STD * @Week)) THEN SPACE(0) ELSE @CR + 'RAM_WT' END
        + CASE WHEN Z.CPU_WT = W.CPU_WT OR E.[Rows] < 3 OR (Z.CPU_WT BETWEEN T.CPU_WT_AVG - (T.CPU_WT_STD * @Hour) AND T.CPU_WT_AVG + (T.CPU_WT_STD * @Hour)) OR (Z.CPU_WT BETWEEN E.CPU_WT_AVG - (E.CPU_WT_STD * @Week) AND E.CPU_WT_AVG + (E.CPU_WT_STD * @Week)) THEN SPACE(0) ELSE @CR + 'CPU_WT' END
        + CASE WHEN Z.DOP_WT = W.DOP_WT OR E.[Rows] < 3 OR (Z.DOP_WT BETWEEN T.DOP_WT_AVG - (T.DOP_WT_STD * @Hour) AND T.DOP_WT_AVG + (T.DOP_WT_STD * @Hour)) OR (Z.DOP_WT BETWEEN E.DOP_WT_AVG - (E.DOP_WT_STD * @Week) AND E.DOP_WT_AVG + (E.DOP_WT_STD * @Week)) THEN SPACE(0) ELSE @CR + 'DOP_WT' END
        + CASE WHEN Z.LCK_WT = W.LCK_WT OR E.[Rows] < 3 OR (Z.LCK_WT BETWEEN T.LCK_WT_AVG - (T.LCK_WT_STD * @Hour) AND T.LCK_WT_AVG + (T.LCK_WT_STD * @Hour)) OR (Z.LCK_WT BETWEEN E.LCK_WT_AVG - (E.LCK_WT_STD * @Week) AND E.LCK_WT_AVG + (E.LCK_WT_STD * @Week)) THEN SPACE(0) ELSE @CR + 'LCK_WT' END

     FROM
  (SELECT I.*
     FROM #WaitHistoryHour AS I
    WHERE I.KeyDT = @DateTimeThru) AS Z,
  (SELECT I.*
     FROM #WaitHistoryHour AS I
    WHERE I.KeyDT = @DateTimeBack) AS W,
  (SELECT COUNT(*) AS [Rows]
        , AVG(CONVERT(decimal(19,03), I.SQL_WS)) AS SQL_WS_AVG, STDEVP(I.SQL_WS) AS SQL_WS_STD
        , AVG(CONVERT(decimal(19,03), I.SQL_WT)) AS SQL_WT_AVG, STDEVP(I.SQL_WT) AS SQL_WT_STD
        , AVG(CONVERT(decimal(19,03), I.NIO_WT)) AS NIO_WT_AVG, STDEVP(I.NIO_WT) AS NIO_WT_STD
        , AVG(CONVERT(decimal(19,03), I.DIO_WT)) AS DIO_WT_AVG, STDEVP(I.DIO_WT) AS DIO_WT_STD
        , AVG(CONVERT(decimal(19,03), I.SIO_WT)) AS SIO_WT_AVG, STDEVP(I.SIO_WT) AS SIO_WT_STD
        , AVG(CONVERT(decimal(19,03), I.PIO_WT)) AS PIO_WT_AVG, STDEVP(I.PIO_WT) AS PIO_WT_STD
        , AVG(CONVERT(decimal(19,03), I.LOG_WT)) AS LOG_WT_AVG, STDEVP(I.LOG_WT) AS LOG_WT_STD
        , AVG(CONVERT(decimal(19,03), I.RAM_WT)) AS RAM_WT_AVG, STDEVP(I.RAM_WT) AS RAM_WT_STD
        , AVG(CONVERT(decimal(19,03), I.CPU_WT)) AS CPU_WT_AVG, STDEVP(I.CPU_WT) AS CPU_WT_STD
        , AVG(CONVERT(decimal(19,03), I.DOP_WT)) AS DOP_WT_AVG, STDEVP(I.DOP_WT) AS DOP_WT_STD
        , AVG(CONVERT(decimal(19,03), I.LCK_WT)) AS LCK_WT_AVG, STDEVP(I.LCK_WT) AS LCK_WT_STD
     FROM #WaitHistoryHour AS I) AS T,
  (SELECT COUNT(*) AS [Rows]
        , AVG(CONVERT(decimal(19,03), I.SQL_WS)) AS SQL_WS_AVG, STDEVP(I.SQL_WS) AS SQL_WS_STD
        , AVG(CONVERT(decimal(19,03), I.SQL_WT)) AS SQL_WT_AVG, STDEVP(I.SQL_WT) AS SQL_WT_STD
        , AVG(CONVERT(decimal(19,03), I.NIO_WT)) AS NIO_WT_AVG, STDEVP(I.NIO_WT) AS NIO_WT_STD
        , AVG(CONVERT(decimal(19,03), I.DIO_WT)) AS DIO_WT_AVG, STDEVP(I.DIO_WT) AS DIO_WT_STD
        , AVG(CONVERT(decimal(19,03), I.SIO_WT)) AS SIO_WT_AVG, STDEVP(I.SIO_WT) AS SIO_WT_STD
        , AVG(CONVERT(decimal(19,03), I.PIO_WT)) AS PIO_WT_AVG, STDEVP(I.PIO_WT) AS PIO_WT_STD
        , AVG(CONVERT(decimal(19,03), I.LOG_WT)) AS LOG_WT_AVG, STDEVP(I.LOG_WT) AS LOG_WT_STD
        , AVG(CONVERT(decimal(19,03), I.RAM_WT)) AS RAM_WT_AVG, STDEVP(I.RAM_WT) AS RAM_WT_STD
        , AVG(CONVERT(decimal(19,03), I.CPU_WT)) AS CPU_WT_AVG, STDEVP(I.CPU_WT) AS CPU_WT_STD
        , AVG(CONVERT(decimal(19,03), I.DOP_WT)) AS DOP_WT_AVG, STDEVP(I.DOP_WT) AS DOP_WT_STD
        , AVG(CONVERT(decimal(19,03), I.LCK_WT)) AS LCK_WT_AVG, STDEVP(I.LCK_WT) AS LCK_WT_STD
     FROM #WaitHistoryWeek AS I) AS E

-- FileHistory

   SELECT @DateTimeThru = MAX(I.KeyDT) FROM dbo.WaitHistory AS I

   SELECT @DateTimeBack = MAX(I.KeyDT) FROM dbo.WaitHistory AS I WHERE I.KeyDT < @DateTimeThru

   SELECT @DateTimeFrom = DATEADD(second, -90, DATEADD(minute, 0 - (DATEDIFF(minute, @DateTimeBack, @DateTimeThru) * 6), @DateTimeThru))

   SELECT ROW_NUMBER() OVER (PARTITION BY I.database_id ORDER BY I.KeyID) - 1 AS KeyID
        , I.KeyDT
        , I.database_id
        , I.num_of_files
        , I.size_on_disk_bytes
        , I.num_of_reads
        , I.num_of_writes
        , I.num_of_bytes_read
        , I.num_of_bytes_written
        , I.io_stall_read_ms
        , I.io_stall_write_ms
     INTO    #FileHistory
     FROM dbo.FileHistory AS I
    WHERE I.KeyDT !< DATEADD(day, -7, @DateTimeThru)
 ORDER BY I.database_id
        , I.KeyID

   SELECT  I.KeyDT
        ,  I.database_id
        ,  I.num_of_files                                  AS Files
        ,  I.size_on_disk_bytes                            AS Bytes
        ,  I.num_of_reads         - T.num_of_reads         AS NUM_R
        ,  I.num_of_writes        - T.num_of_writes        AS NUM_W
        ,  I.num_of_bytes_read    - T.num_of_bytes_read    AS BYT_R
        ,  I.num_of_bytes_written - T.num_of_bytes_written AS BYT_W
        ,  I.io_stall_read_ms     - T.io_stall_read_ms     AS IOS_R
        ,  I.io_stall_write_ms    - T.io_stall_write_ms    AS IOS_W
        , (I.io_stall_read_ms     - T.io_stall_read_ms    ) / CASE WHEN (I.num_of_reads  - T.num_of_reads ) = 0 THEN 1 ELSE (I.num_of_reads  - T.num_of_reads ) END AS PER_R
        , (I.io_stall_write_ms    - T.io_stall_write_ms   ) / CASE WHEN (I.num_of_writes - T.num_of_writes) = 0 THEN 1 ELSE (I.num_of_writes - T.num_of_writes) END AS PER_W
     INTO #FileHistoryHour
     FROM #FileHistory AS I
     JOIN #FileHistory AS T
       ON I.KeyID - 1
        = T.KeyID
      AND I.database_id
        = T.database_id
    WHERE I.KeyDT !< @DateTimeFrom
      AND I.KeyDT !> @DateTimeThru
 ORDER BY I.database_id
        , I.KeyID

   SELECT  I.KeyDT
        ,  I.database_id
        ,  I.num_of_files                                  AS Files
        ,  I.size_on_disk_bytes                            AS Bytes
        ,  I.num_of_reads         - T.num_of_reads         AS NUM_R
        ,  I.num_of_writes        - T.num_of_writes        AS NUM_W
        ,  I.num_of_bytes_read    - T.num_of_bytes_read    AS BYT_R
        ,  I.num_of_bytes_written - T.num_of_bytes_written AS BYT_W
        ,  I.io_stall_read_ms     - T.io_stall_read_ms     AS IOS_R
        ,  I.io_stall_write_ms    - T.io_stall_write_ms    AS IOS_W
        , (I.io_stall_read_ms     - T.io_stall_read_ms    ) / CASE WHEN (I.num_of_reads  - T.num_of_reads ) = 0 THEN 1 ELSE (I.num_of_reads  - T.num_of_reads ) END AS PER_R
        , (I.io_stall_write_ms    - T.io_stall_write_ms   ) / CASE WHEN (I.num_of_writes - T.num_of_writes) = 0 THEN 1 ELSE (I.num_of_writes - T.num_of_writes) END AS PER_W
     INTO #FileHistoryWeek
     FROM #FileHistory AS I
     JOIN #FileHistory AS T
       ON I.KeyID - 1
        = T.KeyID
      AND I.database_id
        = T.database_id
    WHERE CASE WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -0, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -0, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -1, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -1, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -2, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -2, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -3, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -3, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -4, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -4, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -5, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -5, @DateTimeThru)) THEN 1
               WHEN I.KeyDT BETWEEN DATEADD(second, -90, DATEADD(day, -6, @DateTimeThru)) AND DATEADD(second, 90, DATEADD(day, -6, @DateTimeThru)) THEN 1 ELSE 0 END != 0
 ORDER BY I.database_id
        , I.KeyID

   SELECT @Message = @Message

        + CASE WHEN Z.NUM_R = W.NUM_R OR E.[Rows] < 3 OR (Z.NUM_R BETWEEN T.NUM_R_AVG - (T.NUM_R_STD * @Hour) AND T.NUM_R_AVG + (T.NUM_R_STD * @Hour)) OR (Z.NUM_R BETWEEN E.NUM_R_AVG - (E.NUM_R_STD * @Week) AND E.NUM_R_AVG + (E.NUM_R_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Tally_Reads'     + ' / ' + A.name END
        + CASE WHEN Z.NUM_W = W.NUM_W OR E.[Rows] < 3 OR (Z.NUM_W BETWEEN T.NUM_W_AVG - (T.NUM_W_STD * @Hour) AND T.NUM_W_AVG + (T.NUM_W_STD * @Hour)) OR (Z.NUM_W BETWEEN E.NUM_W_AVG - (E.NUM_W_STD * @Week) AND E.NUM_W_AVG + (E.NUM_W_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Tally_Writes'    + ' / ' + A.name END
        + CASE WHEN Z.IOS_R = W.IOS_R OR E.[Rows] < 3 OR (Z.IOS_R BETWEEN T.IOS_R_AVG - (T.IOS_R_STD * @Hour) AND T.IOS_R_AVG + (T.IOS_R_STD * @Hour)) OR (Z.IOS_R BETWEEN E.IOS_R_AVG - (E.IOS_R_STD * @Week) AND E.IOS_R_AVG + (E.IOS_R_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Stall_Reads'     + ' / ' + A.name END
        + CASE WHEN Z.IOS_W = W.IOS_W OR E.[Rows] < 3 OR (Z.IOS_W BETWEEN T.IOS_W_AVG - (T.IOS_W_STD * @Hour) AND T.IOS_W_AVG + (T.IOS_W_STD * @Hour)) OR (Z.IOS_W BETWEEN E.IOS_W_AVG - (E.IOS_W_STD * @Week) AND E.IOS_W_AVG + (E.IOS_W_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Stall_Writes'    + ' / ' + A.name END
        + CASE WHEN Z.PER_R = W.PER_R OR E.[Rows] < 3 OR (Z.PER_R BETWEEN T.PER_R_AVG - (T.PER_R_STD * @Hour) AND T.PER_R_AVG + (T.PER_R_STD * @Hour)) OR (Z.PER_R BETWEEN E.PER_R_AVG - (E.PER_R_STD * @Week) AND E.PER_R_AVG + (E.PER_R_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Stall_Per_Read'  + ' / ' + A.name END
        + CASE WHEN Z.PER_W = W.PER_W OR E.[Rows] < 3 OR (Z.PER_W BETWEEN T.PER_W_AVG - (T.PER_W_STD * @Hour) AND T.PER_W_AVG + (T.PER_W_STD * @Hour)) OR (Z.PER_W BETWEEN E.PER_W_AVG - (E.PER_W_STD * @Week) AND E.PER_W_AVG + (E.PER_W_STD * @Week)) THEN SPACE(0) ELSE @CR + 'Stall_Per_Write' + ' / ' + A.name END
        + CASE WHEN Z.BYT_R = W.BYT_R OR E.[Rows] < 3 OR (Z.BYT_R BETWEEN T.BYT_R_AVG - (T.BYT_R_STD * @Hour) AND T.BYT_R_AVG + (T.BYT_R_STD * @Hour)) OR (Z.BYT_R BETWEEN E.BYT_R_AVG - (E.BYT_R_STD * @Week) AND E.BYT_R_AVG + (E.BYT_R_STD * @Week)) THEN SPACE(0) ELSE @CR + 'GBs_File_Reads'  + ' / ' + A.name END
        + CASE WHEN Z.BYT_W = W.BYT_W OR E.[Rows] < 3 OR (Z.BYT_W BETWEEN T.BYT_W_AVG - (T.BYT_W_STD * @Hour) AND T.BYT_W_AVG + (T.BYT_W_STD * @Hour)) OR (Z.BYT_W BETWEEN E.BYT_W_AVG - (E.BYT_W_STD * @Week) AND E.BYT_W_AVG + (E.BYT_W_STD * @Week)) THEN SPACE(0) ELSE @CR + 'GBs_File_Writes' + ' / ' + A.name END
        + CASE WHEN Z.Bytes = W.Bytes THEN SPACE(0) ELSE @CR + 'GBs_Size_Change' + ' / ' + A.name END
        + CASE WHEN Z.Files = W.Files THEN SPACE(0) ELSE @CR + 'Files'           + ' / ' + A.name END

     FROM
  (SELECT I.*
     FROM #FileHistoryHour AS I
    WHERE I.KeyDT = @DateTimeThru) AS Z
     JOIN
  (SELECT I.*
     FROM #FileHistoryHour AS I
    WHERE I.KeyDT = @DateTimeBack) AS W
       ON Z.database_id
        = W.database_id
     JOIN
  (SELECT COUNT(*) AS [Rows]
        , AVG(CONVERT(decimal(19,03), I.Files)) AS Files_AVG, STDEVP(I.Files) AS Files_STD
        , AVG(CONVERT(decimal(19,03), I.Bytes)) AS Bytes_AVG, STDEVP(I.Bytes) AS Bytes_STD
        , AVG(CONVERT(decimal(19,03), I.NUM_R)) AS NUM_R_AVG, STDEVP(I.NUM_R) AS NUM_R_STD
        , AVG(CONVERT(decimal(19,03), I.NUM_W)) AS NUM_W_AVG, STDEVP(I.NUM_W) AS NUM_W_STD
        , AVG(CONVERT(decimal(19,03), I.BYT_R)) AS BYT_R_AVG, STDEVP(I.BYT_R) AS BYT_R_STD
        , AVG(CONVERT(decimal(19,03), I.BYT_W)) AS BYT_W_AVG, STDEVP(I.BYT_W) AS BYT_W_STD
        , AVG(CONVERT(decimal(19,03), I.IOS_R)) AS IOS_R_AVG, STDEVP(I.IOS_R) AS IOS_R_STD
        , AVG(CONVERT(decimal(19,03), I.IOS_W)) AS IOS_W_AVG, STDEVP(I.IOS_W) AS IOS_W_STD
        , AVG(CONVERT(decimal(19,03), I.PER_R)) AS PER_R_AVG, STDEVP(I.PER_R) AS PER_R_STD
        , AVG(CONVERT(decimal(19,03), I.PER_W)) AS PER_W_AVG, STDEVP(I.PER_W) AS PER_W_STD
        , I.database_id
     FROM #FileHistoryHour AS I
 GROUP BY I.database_id) AS T
       ON Z.database_id
        = T.database_id
     JOIN
  (SELECT COUNT(*) AS [Rows]
        , AVG(CONVERT(decimal(19,03), I.Files)) AS Files_AVG, STDEVP(I.Files) AS Files_STD
        , AVG(CONVERT(decimal(19,03), I.Bytes)) AS Bytes_AVG, STDEVP(I.Bytes) AS Bytes_STD
        , AVG(CONVERT(decimal(19,03), I.NUM_R)) AS NUM_R_AVG, STDEVP(I.NUM_R) AS NUM_R_STD
        , AVG(CONVERT(decimal(19,03), I.NUM_W)) AS NUM_W_AVG, STDEVP(I.NUM_W) AS NUM_W_STD
        , AVG(CONVERT(decimal(19,03), I.BYT_R)) AS BYT_R_AVG, STDEVP(I.BYT_R) AS BYT_R_STD
        , AVG(CONVERT(decimal(19,03), I.BYT_W)) AS BYT_W_AVG, STDEVP(I.BYT_W) AS BYT_W_STD
        , AVG(CONVERT(decimal(19,03), I.IOS_R)) AS IOS_R_AVG, STDEVP(I.IOS_R) AS IOS_R_STD
        , AVG(CONVERT(decimal(19,03), I.IOS_W)) AS IOS_W_AVG, STDEVP(I.IOS_W) AS IOS_W_STD
        , AVG(CONVERT(decimal(19,03), I.PER_R)) AS PER_R_AVG, STDEVP(I.PER_R) AS PER_R_STD
        , AVG(CONVERT(decimal(19,03), I.PER_W)) AS PER_W_AVG, STDEVP(I.PER_W) AS PER_W_STD
        , I.database_id
     FROM #FileHistoryWeek AS I
 GROUP BY I.database_id) AS E
       ON Z.database_id
        = E.database_id
     JOIN sys.databases AS A
       ON Z.database_id
        = A.database_id

IF LEN(@Message) > @Length

    BEGIN

    IF @PRINT_Only = 0

        BEGIN

        EXECUTE msdb.dbo.sp_send_dbmail 'Wingenious', 'alerts@wingenious.com', NULL, NULL, 'MetricsHistory Alerts', @Message -- change the profile name and the recipient list

        END
        ELSE
        BEGIN

        PRINT @Message

        END

    END

DROP TABLE #CounterHistory
DROP TABLE #CounterHistoryHour
DROP TABLE #CounterHistoryWeek

DROP TABLE #WaitHistory
DROP TABLE #WaitHistoryHour
DROP TABLE #WaitHistoryWeek

DROP TABLE #FileHistory
DROP TABLE #FileHistoryHour
DROP TABLE #FileHistoryWeek

SET NOCOUNT OFF

GO

