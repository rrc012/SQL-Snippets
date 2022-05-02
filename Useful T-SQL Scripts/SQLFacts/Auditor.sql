/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

   SELECT DB_ID()   AS database_id
        , DB_NAME() AS database_name
        , database_specification_id
        , audit_guid
        , name
        , create_date
        , modify_date
        , is_state_enabled
     INTO    #database_audit_specifications
     FROM sys.database_audit_specifications
    WHERE 0 = 1

   SELECT DB_ID()   AS database_id
        , DB_NAME() AS database_name
        , database_specification_id
        , audited_principal_id
        , class_desc
        , audit_action_name
        , audited_result
     INTO    #database_audit_specification_details
     FROM sys.database_audit_specification_details
    WHERE 0 = 1

  DECLARE @database_id int

  DECLARE @name   varchar(0128) = '%' -- database name LIKE

  DECLARE @DBName varchar(0128)

  DECLARE @DBCode varchar(2000)

  DECLARE @audit_name      varchar(0128)

  DECLARE @audit_file_path varchar(0512)

  DECLARE DBNames CURSOR FAST_FORWARD FOR
   SELECT D.database_id
        , D.name
     FROM sys.databases AS D
    WHERE D.name LIKE @name
 ORDER BY D.name

OPEN DBNames

FETCH NEXT FROM DBNames INTO @database_id, @DBName

WHILE @@FETCH_STATUS = 0

    BEGIN

    SET @DBCode = 'USE [' + @DBName + ']; '
                + '   SELECT ' + CONVERT(varchar(0010), @database_id) + ' AS database_id, '
                               + CHAR(39) + @DBName + CHAR(39)        + ' AS database_name, '
                               + 'D.database_specification_id, '
                               + 'D.audit_guid, '
                               + 'D.name, '
                               + 'D.create_date, '
                               + 'D.modify_date, '
                               + 'D.is_state_enabled '
                + '     FROM sys.database_audit_specifications AS D '

    INSERT #database_audit_specifications EXECUTE (@DBCode)

    SET @DBCode = 'USE [' + @DBName + ']; '
                + '   SELECT ' + CONVERT(varchar(0010), @database_id) + ' AS database_id, '
                               + CHAR(39) + @DBName + CHAR(39)        + ' AS database_name, '
                               + 'M.database_specification_id, '
                               + 'M.audited_principal_id, '
                               + 'M.class_desc, '
                               + 'M.audit_action_name, '
                               + 'M.audited_result '
                + '     FROM sys.database_audit_specification_details AS M '

    INSERT #database_audit_specification_details EXECUTE (@DBCode)

    FETCH NEXT FROM DBNames INTO @database_id, @DBName

    END

CLOSE DBNames DEALLOCATE DBNames

   SELECT A.name             AS AuditName
        , L.name             AS OwnerName
        , CONVERT(varchar(0040), A.create_date, 120) AS create_date
        , CONVERT(varchar(0040), A.modify_date, 120) AS modify_date
        , A.is_state_enabled AS is_enabled
        , E.status_desc      AS [status]
        , A.predicate        AS [filter] -- SQL Server 2012 and newer
        , A.type_desc        AS destination
--      , F.log_file_path
--      , F.log_file_name
        , E.audit_file_size
        , E.audit_file_path
     FROM sys.server_audits      AS A
LEFT JOIN sys.server_file_audits AS F
       ON A.audit_id
        = F.audit_id
LEFT JOIN sys.dm_server_audit_status AS E
       ON A.audit_id
        = E.audit_id
     JOIN sys.server_principals  AS L
       ON A.principal_id
        = L.principal_id
 ORDER BY A.name

   SELECT A.name                          AS AuditName
        , 'SERVER - ' + @@SERVERNAME      AS SpecificationType
        , S.name                          AS SpecificationName
        , CONVERT(varchar(0040), S.create_date, 120) AS create_date
        , CONVERT(varchar(0040), S.modify_date, 120) AS modify_date
        , S.is_state_enabled AS is_enabled
     FROM sys.server_audits               AS A
     JOIN sys.server_audit_specifications AS S
       ON A.audit_guid
        = S.audit_guid
    UNION
   SELECT A.name                          AS AuditName
        , 'DATABASE - ' + D.database_name AS SpecificationType
        , D.name                          AS SpecificationName
        , CONVERT(varchar(0040), D.create_date, 120) AS create_date
        , CONVERT(varchar(0040), D.modify_date, 120) AS modify_date
        , D.is_state_enabled AS is_enabled
     FROM sys.server_audits               AS A
     JOIN #database_audit_specifications  AS D
       ON A.audit_guid
        = D.audit_guid
 ORDER BY   AuditName
        ,   SpecificationType DESC
        ,   SpecificationName

   SELECT A.name                          AS AuditName
        , 'SERVER - ' + @@SERVERNAME      AS SpecificationType
        , S.name                          AS SpecificationName
        , M.class_desc                    AS audited_class
        , M.audit_action_name             AS audited_action
        , M.audited_result
        , ISNULL(L.name, SPACE(0)) AS principal
     FROM sys.server_audits               AS A
     JOIN sys.server_audit_specifications AS S
       ON A.audit_guid
        = S.audit_guid
     JOIN sys.server_audit_specification_details AS M
       ON S.server_specification_id
        = M.server_specification_id
LEFT JOIN sys.server_principals  AS L
       ON M.audited_principal_id
        =         L.principal_id
    UNION
   SELECT A.name                          AS AuditName
        , 'DATABASE - ' + D.database_name AS SpecificationType
        , D.name                          AS SpecificationName
        , M.class_desc                    AS audited_class
        , M.audit_action_name             AS audited_action
        , M.audited_result
        , ISNULL(L.name, SPACE(0)) AS principal
     FROM sys.server_audits               AS A
     JOIN #database_audit_specifications  AS D
       ON A.audit_guid
        = D.audit_guid
     JOIN #database_audit_specification_details  AS M
       ON D.database_specification_id
        = M.database_specification_id
LEFT JOIN sys.server_principals  AS L
       ON M.audited_principal_id
        =         L.principal_id
 ORDER BY   AuditName
        ,   SpecificationType DESC
        ,   SpecificationName
        ,   audited_class
        ,   audited_action

  DECLARE Audits CURSOR FAST_FORWARD FOR
   SELECT A.name
        , E.audit_file_path
     FROM sys.server_audits      AS A
     JOIN sys.dm_server_audit_status AS E
       ON A.audit_id
        = E.audit_id
    WHERE E.audit_file_path IS NOT NULL
 ORDER BY A.name

OPEN Audits

FETCH NEXT FROM Audits INTO @audit_name, @audit_file_path

WHILE @@FETCH_STATUS = 0

    BEGIN

    SET @DBCode =                       '   SELECT ''' + @audit_name + ''' AS AuditName'
                + CHAR(13) + CHAR(10) + '        , E.event_time'
                + CHAR(13) + CHAR(10) + '        , E.session_server_principal_name'
                + CHAR(13) + CHAR(10) + '        , E.server_principal_name'
                + CHAR(13) + CHAR(10) + '        , E.database_principal_name'
--              + CHAR(13) + CHAR(10) + '        , E.target_server_principal_name'
--              + CHAR(13) + CHAR(10) + '        , E.target_database_principal_name'
                + CHAR(13) + CHAR(10) + '        , E.database_name'
                + CHAR(13) + CHAR(10) + '        , E.schema_name'
                + CHAR(13) + CHAR(10) + '        , E.object_name'
                + CHAR(13) + CHAR(10) + '        , E.statement'
                + CHAR(13) + CHAR(10) + '        , E.succeeded'
                + CHAR(13) + CHAR(10) + '     FROM sys.fn_get_audit_file (''' + @audit_file_path + ''', DEFAULT, DEFAULT) AS E'
                + CHAR(13) + CHAR(10) + ' ORDER BY E.event_time'
                + CHAR(13) + CHAR(10)
                + CHAR(13) + CHAR(10)

    PRINT @DBCode

    FETCH NEXT FROM Audits INTO @audit_name, @audit_file_path

    END

CLOSE Audits DEALLOCATE Audits

IF (SELECT COUNT(*)
      FROM sys.server_audits      AS A
      JOIN sys.dm_server_audit_status AS E
        ON A.audit_id
         = E.audit_id
     WHERE E.audit_file_path IS NOT NULL) = 1 EXECUTE (@DBCode)

DROP TABLE #database_audit_specifications

DROP TABLE #database_audit_specification_details

SET NOCOUNT OFF

