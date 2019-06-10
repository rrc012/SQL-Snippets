/*********************
  DDL for tbl_d_time 
*********************/
USE [DB_NAME]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

/*
 ===============================================================================
 Author:	     REZA RAD
 Source:       http://www.rad.pasfu.com/index.php?/archives/122-Script-for-Creating-and-Generating-members-for-Time-Dimension.html#extended
 Article Name: Script for Creating and Generating members for Time Dimension
 Create Date:  14-JUL-2013
 Description:  This script generates the Time Dimension structure 
	           and also loads the time dimension with members.	
 Revision History:
 16-JUL-2013 - RAGHUNANDAN CUMBAKONAM
			Formatted the code.
			Added the history.
 Usage:		N/A			   
 ===============================================================================
*/ 

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tbl_d_time' AND TYPE = 'U')
BEGIN
	 DROP TABLE tbl_d_time
END
GO

CREATE TABLE [dbo].[tbl_d_time] 
(
	 [TimeKey] [INT] NOT NULL
	,[Hour24] [INT] NULL
	,[Hour24ShortString] [VARCHAR](2) NULL
	,[Hour24MinString] [VARCHAR](5) NULL
	,[Hour24FullString] [VARCHAR](8) NULL
	,[Hour12] [INT] NULL
	,[Hour12ShortString] [VARCHAR](2) NULL
	,[Hour12MinString] [VARCHAR](5) NULL
	,[Hour12FullString] [VARCHAR](8) NULL
	,[AmPmCode] [INT] NULL
	,[AmPmString] [VARCHAR](2) NOT NULL
	,[MINUTE] [INT] NULL
	,[MinuteCode] [INT] NULL
	,[MinuteShortString] [VARCHAR](2) NULL
	,[MinuteFullString24] [VARCHAR](8) NULL
	,[MinuteFullString12] [VARCHAR](8) NULL
	,[HalfHour] [INT] NULL
	,[HalfHourCode] [INT] NULL
	,[HalfHourShortString] [VARCHAR](2) NULL
	,[HalfHourFullString24] [VARCHAR](8) NULL
	,[HalfHourFullString12] [VARCHAR](8) NULL
	,[SECOND] [INT] NULL
	,[SecondShortString] [VARCHAR](2) NULL
	,[FullTimeString24] [VARCHAR](8) NULL
	,[FullTimeString12] [VARCHAR](8) NULL
	,[FullTime] [TIME](7) NULL
,CONSTRAINT [PK_DimTime] PRIMARY KEY CLUSTERED 
(
	[TimeKey] ASC
) 
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

SET ANSI_PADDING OFF
GO

--SCRIPT FOR GENERATING MEMBERS (RECORDS) FOR TIME DIMENSION:

DECLARE @hour INT,
	    @minute INT,
	    @second INT;

SET @hour = 0

WHILE @hour < 24
BEGIN
	SET @minute = 0

	WHILE @minute < 60
	BEGIN
		SET @second = 0

		WHILE @second < 60
		BEGIN
			INSERT INTO [dbo].[tbl_d_time] 
			(
			 [TimeKey],
			 [Hour24],
			 [Hour24ShortString],
			 [Hour24MinString],
			 [Hour24FullString],
			 [Hour12],
			 [Hour12ShortString],
			 [Hour12MinString],
			 [Hour12FullString],
			 [AmPmCode],
			 [AmPmString],
			 [MINUTE],
			 [MinuteCode],
			 [MinuteShortString],
			 [MinuteFullString24],
			 [MinuteFullString12],
			 [HalfHour],
			 [HalfHourCode],
			 [HalfHourShortString],
			 [HalfHourFullString24],
			 [HalfHourFullString12],
			 [SECOND],
			 [SecondShortString],
			 [FullTimeString24],
			 [FullTimeString12],
			 [FullTime]
			)
			SELECT (@hour * 10000) + (@minute * 100) + @second AS TimeKey,
				   @hour AS [Hour24],
				   RIGHT('0' + CONVERT(VARCHAR(2), @hour), 2) [Hour24ShortString],
				   RIGHT('0' + CONVERT(VARCHAR(2), @hour), 2) + ':00' [Hour24MinString],
				   RIGHT('0' + CONVERT(VARCHAR(2), @hour), 2) + ':00:00' [Hour24FullString],
				   @hour % 12 AS [Hour12],
				   RIGHT('0' + CONVERT(VARCHAR(2), @hour % 12), 2) [Hour12ShortString],
				   RIGHT('0' + CONVERT(VARCHAR(2), @hour % 12), 2) + ':00' [Hour12MinString],
				   RIGHT('0' + CONVERT(VARCHAR(2), @hour % 12), 2) + ':00:00' [Hour12FullString],
				   @hour / 12 AS [AmPmCode],
				   CASE WHEN @hour < 12 THEN 'AM' ELSE 'PM' END AS [AmPmString],
				   @minute AS [MINUTE],
				   (@hour * 100) + (@minute) [MinuteCode],
				   RIGHT('0' + CONVERT(VARCHAR(2), @minute), 2) [MinuteShortString],
				   RIGHT('0' + CONVERT(VARCHAR(2), @hour), 2) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), @minute), 2) + ':00' [MinuteFullString24],
				   RIGHT('0' + CONVERT(VARCHAR(2), @hour % 12), 2) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), @minute), 2) + ':00' [MinuteFullString12],
				   @minute / 30 AS [HalfHour],
				   (@hour * 100) + ((@minute / 30) * 30) [HalfHourCode],
				   RIGHT('0' + CONVERT(VARCHAR(2), ((@minute / 30) * 30)), 2) [HalfHourShortString],
				   RIGHT('0' + CONVERT(VARCHAR(2), @hour), 2) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), ((@minute / 30) * 30)), 2) + ':00' [HalfHourFullString24],
				   RIGHT('0' + CONVERT(VARCHAR(2), @hour % 12), 2) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), ((@minute / 30) * 30)), 2) + ':00' [HalfHourFullString12],
				   @second AS [SECOND],
				   RIGHT('0' + CONVERT(VARCHAR(2), @second), 2) [SecondShortString],
				   RIGHT('0' + CONVERT(VARCHAR(2), @hour), 2) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), @minute), 2) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), @second), 2) [FullTimeString24],
				   RIGHT('0' + CONVERT(VARCHAR(2), @hour % 12), 2) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), @minute), 2) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), @second), 2) [FullTimeString12],
				   CONVERT(TIME, RIGHT('0' + CONVERT(VARCHAR(2), @hour), 2) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), @minute), 2) + ':' + RIGHT('0' + CONVERT(VARCHAR(2), @second), 2)) AS [FullTime]
				   
			SET @second = @second + 1;
		END

		SET @minute = @minute + 1;
	END

	SET @hour = @hour + 1;
END