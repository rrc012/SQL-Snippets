USE [DB_SSIS]
GO
/****** Object:  Table [dbo].[tbl_ssis_PkgExecLog]    Script Date: 11/08/2011 15:48:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tbl_ssis_PkgExecLog]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[tbl_ssis_PkgExecLog](
	[pexl_LogID_nbr] [int] IDENTITY(1,1) NOT NULL,
	[pexl_ParentLogID_nbr] [int] NULL,
	[pexl_PackageName_nm] [varchar](100) NULL,
	[pexl_PackageGuid_nbr] [uniqueidentifier] NOT NULL,
	[pexl_MachineName_nm] [varchar](40) NOT NULL,
	[pexl_ExecutionGuid_nbr] [uniqueidentifier] NOT NULL,
	[pexl_ProcessDate_dt] [datetime] NOT NULL,
	[pexl_Operator_dsc] [varchar](40) NOT NULL,
	[pexl_StartTimestamp_ts] [datetime] NOT NULL,
	[pexl_EndTimestamp_ts] [datetime] NULL,
	[pexl_StatusMessage_txt] [varchar](255) NOT NULL,
	[pexl_FailureTask_txt] [varchar](255) NULL,
	[pexl_ErrorDescription_txt] [varchar](255) NULL,
	[pexl_LastUpdateTimestamp_ts] [datetime] NOT NULL,
 CONSTRAINT [idx_PkgExecLog_p_cl_01] PRIMARY KEY CLUSTERED 
(
	[pexl_LogID_nbr] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [idx_pkgExecLog_i_nc_02]    Script Date: 11/08/2011 15:48:49 ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[tbl_ssis_PkgExecLog]') AND name = N'idx_pkgExecLog_i_nc_02')
CREATE NONCLUSTERED INDEX [idx_pkgExecLog_i_nc_02] ON [dbo].[tbl_ssis_PkgExecLog] 
(
	[pexl_StartTimestamp_ts] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [idx_pkgExecLog_i_nc_03]    Script Date: 11/08/2011 15:48:49 ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[tbl_ssis_PkgExecLog]') AND name = N'idx_pkgExecLog_i_nc_03')
CREATE NONCLUSTERED INDEX [idx_pkgExecLog_i_nc_03] ON [dbo].[tbl_ssis_PkgExecLog] 
(
	[pexl_PackageName_nm] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[usp_ssis_OnPackageStart]    Script Date: 11/08/2011 15:48:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_ssis_OnPackageStart]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'/*********************************************************************************************************
-- =============================================
-- Author:		Ravi Gudlavalleti
-- Create date: Oct 23, 2007

-- Description: This stored procedure is triggered on package start. A log ID is generated
-- and a log entry is created with parent log id, package name, description, GUID, machine name,
-- execution guid, logical process date, operator, start and end timestamps, job status and
-- failure task if any.
-- =============================================
-- Revision History:
-- Oct 23, 2007	(Ravi Gudlavalleti) - Adapted to MRS Contests templates
-- =============================================
**********************************************************************************************************/
CREATE PROCEDURE [dbo].[usp_ssis_OnPackageStart]
	 @ParentLogID			int
	,@PackageName			varchar(100)
	,@PackageGuid			uniqueidentifier
	,@MachineName			varchar(40)
	,@ExecutionGuid			uniqueidentifier
	,@ProcessDate			datetime
	,@Operator				varchar(40)
	,@LogID					int = NULL OUTPUT
WITH EXECUTE AS CALLER
AS

BEGIN
	SET NOCOUNT ON

	--Coalesce @logicalDate
	SET @ProcessDate = ISNULL(@ProcessDate, GETDATE())

	--Coalesce @Operator
	SET @Operator = NULLIF(LTRIM(RTRIM(@Operator)), '''')
	SET @Operator = ISNULL(@Operator, SUSER_SNAME())

	--Root-level nodes should have a null parent
	IF @ParentLogID <= 0 SET @ParentLogID = NULL

	--Insert the log record
	INSERT INTO [dbo].[tbl_ssis_PkgExecLog]
       ([pexl_ParentLogID_nbr],[pexl_PackageName_nm]
       ,[pexl_PackageGuid_nbr],[pexl_MachineName_nm],[pexl_ExecutionGuid_nbr]
       ,[pexl_ProcessDate_dt],[pexl_Operator_dsc],[pexl_StartTimestamp_ts]
       ,[pexl_EndTimestamp_ts],[pexl_StatusMessage_txt]
       ,[pexl_FailureTask_txt],[pexl_LastUpdateTimestamp_ts]
	) VALUES (
		 @ParentLogID,@PackageName,@PackageGuid
		,@MachineName,@ExecutionGuid,@ProcessDate,@Operator
		,GETDATE()
		,NULL
		,''Package Started''
		,NULL
		,GETDATE()
	)
	SET @LogID = SCOPE_IDENTITY()

	SET NOCOUNT OFF
END --PROC
'
END