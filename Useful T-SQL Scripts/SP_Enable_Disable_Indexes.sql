USE master;
GO

IF NOT EXISTS (SELECT 1
                 FROM INFORMATION_SCHEMA.ROUTINES
                WHERE ROUTINE_NAME = 'USP_Enable_Disable_Indexes'
                  AND ROUTINE_SCHEMA = 'dbo')
BEGIN
  EXEC ('CREATE PROCEDURE dbo.USP_Enable_Disable_Indexes AS BEGIN PRINT ''STUB FOR PROCEDURE'' END');
END  
GO

/***
================================================================================
Name        : USP_Enable_Disable_Indexes
Author      : Joshua Feierman
Description : A stored procedure for enabling / disabling all indices on a 
              particular table. Since it is installed in the 'master' database
		    and marked as a system object it can be run in the context of any user
		    database.

License:
  USP_Enable_Disable_Indexes is free to download and use for personal, educational, and internal
  purposes, provided this license and all original attributions are included.
  Redistribution or sale in whole or in part is prohibited without the author's 
  express written consent.

  By using this stored procedure, you accept any and all responsibility for any loss
  or damages resulting from its use. Always test in a non production environment
  and evaluate function carefully!

This code and all contents are copyright 2015 Joshua Feierman, all rights reserved.

For more information, visit http://www.sqljosh.com/USP_Enable_Disable_Indexes/.

===============================================================================
Parameters   : 

Name                  | I/O   | Description
--------------------------------------------------------------------------------
@i_EnableDisable_Fl     I       A flag to designate whether we want to enable all disabled indices ('E')
                                or disable all enabled indices ('D').
@i_Schema_Name          I       The schema name of the object to target.
@i_Table_Name           I       The name of the object to target.
@i_Exclude_Unique_Fl    I       If set to 1, will not disable unique indices. Useful when loading data to
                                ensure constraints are not violated.
@i_ForReal_Fl           I       If set to 1, will actually perform the desired action. If set to 0,
                                the generated SQL is printed out and nothing is done. Defaults to 0.
@i_Column_To_Exclude_Nm I       When a value is provided, any index with the provided column name
                                as a leading column is not disabled. Useful for purging data so that
                                a full table scan may not occur.
@i_MaxDOP               I       Indicates the maximum parallel threads used when enabling indices.
                                When not specified option MAXDOP=1 will be used.
@i_Online               I       When set to 1 and the edition of SQL is Enterprise or Developer,
                                indices will be enabled in online mode.
Revisions    :
--------------------------------------------------------------------------------
Ini|   Date   | Description
--------------------------------------------------------------------------------

================================================================================
***/

ALTER PROCEDURE dbo.USP_Enable_Disable_Indexes 
      @i_EnableDisable_Fl     CHAR(1),
      @i_Schema_Name          SYSNAME,
      @i_Table_Name           SYSNAME,
      @i_Exclude_Unique_Fl    BIT     = 1,
      @i_ForReal_Fl           BIT     = 0,
      @i_Column_To_Exclude_Nm SYSNAME = NULL,
      @i_MaxDOP               TINYINT = NULL,
      @i_Online               BIT     = 1
AS

DECLARE @SQL NVARCHAR(MAX);

SET @SQL = (
    SELECT CONCAT('RAISERROR(',
			   QUOTENAME(CASE @i_EnableDisable_Fl
						   WHEN 'E' THEN 'Enabling '
						   ELSE 'Disabling '
					   END + ' index ' + sidx.name + ' on table ' + ssch.name + '.' + sobj.name,
				   ''''),
			   ',10,1) with nowait;',
                  'ALTER INDEX ',
                  QUOTENAME(sidx.name),
                  ' ON ',
                  QUOTENAME(ssch.name),
                  '.' + QUOTENAME(sobj.name),
                  ' ',
                  CASE @i_EnableDisable_Fl
                       WHEN 'E' THEN 'REBUILD' + ' WITH (MAXDOP =' + CASE WHEN @i_MaxDOP IS NULL THEN CONVERT(CHAR, 1)
                                                                          ELSE CONVERT(VARCHAR, @i_MaxDOP)
                                                                     END +
                                                      ',ONLINE =' + CASE WHEN (@i_Online = 1 AND SERVERPROPERTY('EngineEdition') = 3) THEN 'ON'
                                                                         ELSE 'OFF'
                                                                    END +
                                                       ')'
                       WHEN 'D' then 'DISABLE'
                  END,
                  ';'
			   ) --End of CONCAT
      FROM sys.schemas ssch 
	      INNER JOIN sys.objects sobj ON ssch.schema_id = sobj.schema_id
                  AND ssch.name = @i_Schema_Name
                  AND (sobj.name = @i_Table_Name OR @i_Table_Name = '')
           INNER JOIN sys.indexes sidx ON sobj.object_id = sidx.object_id
                  AND sidx.is_primary_key = 0 -- exclude primary keys
                  AND sidx.is_unique = CASE WHEN @i_Exclude_Unique_Fl = 1 THEN 0 ELSE sidx.is_unique END -- exclude unique indexes
                  AND sidx.index_id > 1 -- exclude clustered index and heap
                  AND sidx.is_disabled = CASE @i_EnableDisable_Fl
                                              WHEN 'E' THEN 1 -- only include disabled indexes when the "Enable" option is set
                                              WHEN 'D' THEN 0 -- only include enabled indexes when the "Disable" option is set
                                         END
     WHERE NOT EXISTS (SELECT 1
                         FROM sys.index_columns ic 
					     INNER JOIN sys.columns c ON c.column_id = ic.column_id
                                     AND c.object_id = ic.object_id
                        WHERE ic.index_id = sidx.index_id
                          AND ic.object_id = sidx.object_id
                          AND c.name = @i_Column_To_Exclude_Nm
                          AND ic.key_ordinal = 1
                          AND ic.is_included_column = 0
                       )
   FOR XML PATH('')
);

IF @i_ForReal_Fl = 1
  EXEC sp_executesql @SQL;
ELSE IF @SQL IS NOT NULL
  PRINT @SQL;

GO

-- We mark this as a system object so that it can be used in the context of any database.
EXEC sys.sp_MS_marksystemobject
	@objname = N'dbo.USP_Enable_Disable_Indexes';