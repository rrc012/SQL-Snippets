USE [DB_SSIS]
GO
/****** Object:  Table [dbo].[tbl_ssis_PkgExecLog]    Script Date: 11/08/2011 15:48:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'[dbo].[tbl_ssis_PkgExecLog]') AND TYPE IN (N'U'))
BEGIN
CREATE TABLE [dbo].[tbl_ssis_PkgExecLog](
	[pexl_LogID_nbr] [INT] IDENTITY(1,1) NOT NULL,
	[pexl_ParentLogID_nbr] [INT] NULL,
	[pexl_PackageName_nm] [VARCHAR](100) NULL,
	[pexl_PackageGuid_nbr] [UNIQUEIDENTIFIER] NOT NULL,
	[pexl_MachineName_nm] [VARCHAR](40) NOT NULL,
	[pexl_ExecutionGuid_nbr] [UNIQUEIDENTIFIER] NOT NULL,
	[pexl_ProcessDate_dt] [DATETIME] NOT NULL,
	[pexl_Operator_dsc] [VARCHAR](40) NOT NULL,
	[pexl_StartTimestamp_ts] [DATETIME] NOT NULL,
	[pexl_EndTimestamp_ts] [DATETIME] NULL,
	[pexl_StatusMessage_txt] [VARCHAR](255) NOT NULL,
	[pexl_FailureTask_txt] [VARCHAR](255) NULL,
	[pexl_ErrorDescription_txt] [VARCHAR](255) NULL,
	[pexl_LastUpdateTimestamp_ts] [DATETIME] NOT NULL,
 CONSTRAINT [idx_PkgExecLog_p_cl_01] PRIMARY KEY CLUSTERED 
(
	[pexl_LogID_nbr] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_PADDING OFF
GO

/****** Object:  Index [idx_pkgExecLog_i_nc_02]    Script Date: 11/08/2011 15:48:45 ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE OBJECT_ID = OBJECT_ID(N'[dbo].[tbl_ssis_PkgExecLog]') AND name = N'idx_pkgExecLog_i_nc_02')
CREATE NONCLUSTERED INDEX [idx_pkgExecLog_i_nc_02] ON [dbo].[tbl_ssis_PkgExecLog] 
(
	[pexl_StartTimestamp_ts] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

/****** Object:  Index [idx_pkgExecLog_i_nc_03]    Script Date: 11/08/2011 15:48:45 ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE OBJECT_ID = OBJECT_ID(N'[dbo].[tbl_ssis_PkgExecLog]') AND name = N'idx_pkgExecLog_i_nc_03')
CREATE NONCLUSTERED INDEX [idx_pkgExecLog_i_nc_03] ON [dbo].[tbl_ssis_PkgExecLog] 
(
	[pexl_PackageName_nm] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[usp_ssis_OnPackageEnd]    Script Date: 11/08/2011 15:48:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE OBJECT_ID = OBJECT_ID(N'[dbo].[usp_ssis_OnPackageEnd]') AND TYPE IN (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'/*********************************************************************************************************
-- =============================================
-- Author:		Ravi Gudlavalleti
-- Create date: Oct 23, 2007

-- Description: This stored procedure is triggered on package completion. 
-- Log entries are updated with end timestamps, job status and
-- failure task is set to null upon successful completion.
-- =============================================
-- Revision History:
-- Oct 23, 2007	(Ravi Gudlavalleti) - Adapted to MRS Contests templates
-- =============================================
**********************************************************************************************************/

CREATE PROCEDURE [dbo].[usp_ssis_OnPackageEnd]
	 @LogID				INT
WITH EXECUTE AS CALLER
AS

BEGIN
	SET NOCOUNT ON
	--  Update log table with package completion details
	UPDATE tbl_ssis_PkgExecLog SET
		 pexl_EndTimestamp_ts = GETDATE() --Note: This should NOT be @logicalDate
		-- 0 = InProcess, 1 = Successful, 2 = Failed		
		,pexl_StatusMessage_txt = ''Package Finished''
		,pexl_FailureTask_txt = NULL
		,pexl_ErrorDescription_txt = NULL
		,pexl_LastUpdateTimestamp_ts = GETDATE()
	WHERE 
		pexl_LogID_nbr = @LogID

	SET NOCOUNT OFF
END --PROC
' 
END
