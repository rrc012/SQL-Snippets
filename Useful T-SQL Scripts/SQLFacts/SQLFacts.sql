/* ------------------------------ *\

   © Copyright 2021 by Wingenious

   see README for license details

\* ------------------------------ */


SET NOCOUNT ON

DECLARE @Match TABLE ([Schema] varchar(0128))

/*

INSERT @Match ([Schema])
VALUES ('dbo')
     , ('dba')

*/

   INSERT @Match ([Schema])
   SELECT S.name
     FROM sys.schemas AS S
    WHERE CASE WHEN S.schema_id  =     1 THEN 1
               WHEN S.schema_id  =     2 THEN 0
               WHEN S.schema_id  =     3 THEN 0
               WHEN S.schema_id  =     4 THEN 0
               WHEN S.schema_id !< 16384 THEN 0 ELSE 1 END != 0
 ORDER BY S.schema_id

DECLARE @Alert TABLE ([Search] varchar(0080), [Reason] varchar(0200), AlertID smallint IDENTITY(1,1))

INSERT @Alert ([Search], [Reason])
VALUES ('%SP_OACREATE%'                         , 'contains sp_OACreate')
     , ('%XP_CMDSHELL%'                         , 'contains xp_cmdshell')
     , ('%[^A-Z0-9_@#$]@@IDENTITY[^A-Z0-9_@#$]%', 'contains @@IDENTITY')
     , ('%[^A-Z0-9_@#$]UPDATETEXT[^A-Z0-9_@#$]%', 'contains UPDATETEXT')
     , ('%[^A-Z0-9_@#$]WRITETEXT[^A-Z0-9_@#$]%' , 'contains WRITETEXT')
     , ('%[^A-Z0-9_@#$]READTEXT[^A-Z0-9_@#$]%'  , 'contains READTEXT')
     , ('%[^A-Z0-9_@#$]COMPUTE[^A-Z0-9_@#$]%'   , 'contains COMPUTE')
     , ('%[^A-Z0-9_@#$]NOLOCK[^A-Z0-9_@#$]%'    , 'contains NOLOCK')
     , ('%[^A-Z0-9_@#$]WHILE[^A-Z0-9_@#$]%'     , 'contains WHILE')
     , ('%[^A-Z0-9_@#$]GOTO[^A-Z0-9_@#$]%'      , 'contains GOTO')
     , ('%[^A-Z0-9_@#$]NUMERIC[^A-Z0-9_@#$(]%'  , 'missing size on numeric')
     , ('%[^A-Z0-9_@#$]DECIMAL[^A-Z0-9_@#$(]%'  , 'missing size on decimal')
     , ('%[^A-Z0-9_@#$]CHAR[^A-Z0-9_@#$(]%'     , 'missing size on char')
     , ('%[^A-Z0-9_@#$]VARCHAR[^A-Z0-9_@#$(]%'  , 'missing size on varchar')
     , ('%[^A-Z0-9_@#$]NCHAR[^A-Z0-9_@#$(]%'    , 'missing size on nchar')
     , ('%[^A-Z0-9_@#$]NVARCHAR[^A-Z0-9_@#$(]%' , 'missing size on nvarchar')
     , ('%[^A-Z0-9_@#$]BINARY[^A-Z0-9_@#$(]%'   , 'missing size on binary')
     , ('%[^A-Z0-9_@#$]VARBINARY[^A-Z0-9_@#$(]%', 'missing size on varbinary')

DECLARE @Layer smallint

DECLARE @Batch smallint

DECLARE @GBs decimal(19,05)

IF OBJECT_ID('tempdb..#Base'      , 'U ') IS NOT NULL DROP TABLE #Base

IF OBJECT_ID('tempdb..#More'      , 'U ') IS NOT NULL DROP TABLE #More

IF OBJECT_ID('tempdb..#RoleDBUser', 'U ') IS NOT NULL DROP TABLE #RoleDBUser

IF OBJECT_ID('tempdb..#RuleSchema', 'U ') IS NOT NULL DROP TABLE #RuleSchema

IF OBJECT_ID('tempdb..#RuleObject', 'U ') IS NOT NULL DROP TABLE #RuleObject

IF OBJECT_ID('tempdb..#Work'      , 'U ') IS NOT NULL DROP TABLE #Work

IF OBJECT_ID('tempdb..#Task'      , 'U ') IS NOT NULL DROP TABLE #Task

IF OBJECT_ID('tempdb..#PKey'      , 'U ') IS NOT NULL DROP TABLE #PKey
IF OBJECT_ID('tempdb..#PKeys'     , 'U ') IS NOT NULL DROP TABLE #PKeys

IF OBJECT_ID('tempdb..#FKey'      , 'U ') IS NOT NULL DROP TABLE #FKey
IF OBJECT_ID('tempdb..#FKeys'     , 'U ') IS NOT NULL DROP TABLE #FKeys

IF OBJECT_ID('tempdb..#ZKey'      , 'U ') IS NOT NULL DROP TABLE #ZKey
IF OBJECT_ID('tempdb..#ZKeys'     , 'U ') IS NOT NULL DROP TABLE #ZKeys

IF OBJECT_ID('tempdb..#TKey'      , 'U ') IS NOT NULL DROP TABLE #TKey
IF OBJECT_ID('tempdb..#TKeys'     , 'U ') IS NOT NULL DROP TABLE #TKeys

IF OBJECT_ID('tempdb..#UKey'      , 'U ') IS NOT NULL DROP TABLE #UKey
IF OBJECT_ID('tempdb..#UKeys'     , 'U ') IS NOT NULL DROP TABLE #UKeys

IF OBJECT_ID('tempdb..#VKey'      , 'U ') IS NOT NULL DROP TABLE #VKey

IF OBJECT_ID('tempdb..#WKey'      , 'U ') IS NOT NULL DROP TABLE #WKey

IF OBJECT_ID('tempdb..#Hack'      , 'U ') IS NOT NULL DROP TABLE #Hack

-- base objects

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        , CONVERT(varchar(0040), O.create_date, 120) AS create_date
        , CONVERT(varchar(0040), O.modify_date, 120) AS modify_date
        , O.parent_object_id AS VariousID
        , CONVERT(varchar(max ), ISNULL(M.definition, SPACE(0))) AS SQLServerCode
     INTO #Base
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
LEFT JOIN sys.sql_modules AS M
       ON O.object_id
        = M.object_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ', 'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
 ORDER BY O.type
        , S.name
        , O.name

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        , CONVERT(varchar(0040), Z.create_date, 120) AS create_date
        , CONVERT(varchar(0040), Z.modify_date, 120) AS modify_date
        , Z.is_disabled
        , Z.is_not_trusted
        , ISNULL(C.name, SPACE(0))                               AS GeneralColumn
        , ISNULL(Z.name, SPACE(0))                               AS SQLServerName
        , CONVERT(varchar(max ), ISNULL(Z.definition, SPACE(0))) AS SQLServerCode
     INTO #More
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.check_constraints AS Z
       ON        O.object_id
        = Z.parent_object_id
LEFT JOIN sys.columns AS C
       ON Z.parent_object_id
        =        C.object_id
      AND Z.parent_column_id
        =        C.column_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY O.type
        , S.name
        , O.name
        , Z.name

   SELECT U.type AS DBUserType
        , U.name AS DBUserName
        , CONVERT(varchar(0040), U.create_date, 120) AS create_date
        , CONVERT(varchar(0040), U.modify_date, 120) AS modify_date
        , ISNULL(L.name                  , SPACE(0)) AS SQLServerName
--      , ISNULL(L.default_database_name , SPACE(0)) AS [Database]
--      , ISNULL(L.default_language_name , SPACE(0)) AS [Language]
        , MAX(CASE WHEN Z.name = 'db_owner'          THEN 'Owner'      ELSE SPACE(0) END) AS [Owner]
        , MAX(CASE WHEN Z.name = 'db_accessadmin'    THEN 'Access'     ELSE SPACE(0) END) AS [Access]
        , MAX(CASE WHEN Z.name = 'db_securityadmin'  THEN 'Security'   ELSE SPACE(0) END) AS [Security]
        , MAX(CASE WHEN Z.name = 'db_ddladmin'       THEN 'DDL'        ELSE SPACE(0) END) AS [DDL]
        , MAX(CASE WHEN Z.name = 'db_backupoperator' THEN 'BACKUP'     ELSE SPACE(0) END) AS [BACKUP]
        , MAX(CASE WHEN Z.name = 'db_datareader'     THEN 'DataReader' ELSE SPACE(0) END) AS [DataReader]
        , MAX(CASE WHEN Z.name = 'db_datawriter'     THEN 'DataWriter' ELSE SPACE(0) END) AS [DataWriter]
        , MAX(CASE WHEN Z.name = 'db_denydatareader' THEN 'DenyReader' ELSE SPACE(0) END) AS [DenyReader]
        , MAX(CASE WHEN Z.name = 'db_denydatawriter' THEN 'DenyWriter' ELSE SPACE(0) END) AS [DenyWriter]
     INTO #RoleDBUser
     FROM sys.database_principals   AS U
LEFT JOIN sys.server_principals     AS L
       ON U.sid
        = L.sid
LEFT JOIN sys.database_role_members AS T
       ON        U.principal_id
        = T.member_principal_id
LEFT JOIN sys.database_principals   AS Z
       ON   T.role_principal_id
        =        Z.principal_id
      AND Z.is_fixed_role != 0
    WHERE U.is_fixed_role  = 0
      AND U.type     IN ('S', 'U', 'G')
      AND U.name NOT LIKE 'RSExec%'
      AND U.name != 'INFORMATION_SCHEMA'
      AND U.name != 'sys'
 GROUP BY U.type
        , U.name
        , U.create_date
        , U.modify_date
        , L.name
 ORDER BY U.type
        , U.name

   SELECT S.name            AS GeneralSchema
        , W.type            AS DBRoleType
        , W.name            AS DBRoleName
        , Z.type            AS DBUserType
        , Z.name            AS DBUserName
        , M.permission_name AS DBAction
        , CASE M.state
          WHEN 'W'  THEN 'GRANT+'
          WHEN 'G'  THEN 'GRANT'
          WHEN 'D'  THEN 'DENY'     ELSE SPACE(0) END AS DBStatus
     INTO #RuleSchema
     FROM sys.database_principals   AS W
     JOIN sys.database_role_members AS T
       ON      W.principal_id
        = T.role_principal_id
     JOIN sys.database_principals   AS Z
       ON T.member_principal_id
               = Z.principal_id
     JOIN sys.database_permissions  AS M
       ON         W.principal_id
        = M.grantee_principal_id
     JOIN sys.schemas               AS S
       ON M.major_id
        = S.schema_id
    WHERE M.class = 3
      AND W.type     IN ('R', 'A')
    UNION
   SELECT S.name            AS GeneralSchema
        , SPACE(0)          AS DBRoleType
        , SPACE(0)          AS DBRoleName
        , U.type            AS DBUserType
        , U.name            AS DBUserName
        , M.permission_name AS DBAction
        , CASE M.state
          WHEN 'W'  THEN 'GRANT+'
          WHEN 'G'  THEN 'GRANT'
          WHEN 'D'  THEN 'DENY'     ELSE SPACE(0) END AS DBStatus
     FROM sys.database_principals   AS U
     JOIN sys.database_permissions  AS M
       ON         U.principal_id
        = M.grantee_principal_id
     JOIN sys.schemas               AS S
       ON M.major_id
        = S.schema_id
    WHERE M.class = 3
      AND U.type NOT IN ('R', 'A')
      AND U.name NOT LIKE 'RSExec%'
 ORDER BY   GeneralSchema
        ,   DBRoleType
        ,   DBRoleName
        ,   DBUserType
        ,   DBUserName
        ,   DBAction

   SELECT M.major_id        AS GeneralID
        , M.minor_id        AS column_id
        , W.type            AS DBRoleType
        , W.name            AS DBRoleName
        , Z.type            AS DBUserType
        , Z.name            AS DBUserName
        , M.permission_name AS DBAction
        , CASE M.state
          WHEN 'W'  THEN 'GRANT+'
          WHEN 'G'  THEN 'GRANT'
          WHEN 'D'  THEN 'DENY'     ELSE SPACE(0) END AS DBStatus
     INTO #RuleObject
     FROM sys.database_principals   AS W
     JOIN sys.database_role_members AS T
       ON      W.principal_id
        = T.role_principal_id
     JOIN sys.database_principals   AS Z
       ON T.member_principal_id
               = Z.principal_id
     JOIN sys.database_permissions  AS M
       ON         W.principal_id
        = M.grantee_principal_id
    WHERE M.class = 1
      AND W.type     IN ('R', 'A')
    UNION
   SELECT M.major_id        AS GeneralID
        , M.minor_id        AS column_id
        , SPACE(0)          AS DBRoleType
        , SPACE(0)          AS DBRoleName
        , U.type            AS DBUserType
        , U.name            AS DBUserName
        , M.permission_name AS DBAction
        , CASE M.state
          WHEN 'W'  THEN 'GRANT+'
          WHEN 'G'  THEN 'GRANT'
          WHEN 'D'  THEN 'DENY'     ELSE SPACE(0) END AS DBStatus
     FROM sys.database_principals   AS U
     JOIN sys.database_permissions  AS M
       ON         U.principal_id
        = M.grantee_principal_id
    WHERE M.class = 1
      AND U.type NOT IN ('R', 'A')
      AND U.name NOT LIKE 'RSExec%'
      AND M.major_id > 0
 ORDER BY   GeneralID
        ,   column_id
        ,   DBRoleType
        ,   DBRoleName
        ,   DBUserType
        ,   DBUserName
        ,   DBAction

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        , CONVERT(     int, -1) AS Layer
        , CONVERT(     int, -1) AS Estimate
        , CONVERT(smallint,  0) AS Factor01
        , CONVERT(smallint,  0) AS Factor02
        , CONVERT(smallint,  0) AS Factor03
        , CONVERT(smallint,  0) AS Factor04
        , CONVERT(smallint,  0) AS Factor05
     INTO #Work
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN (      'V ', 'P ', 'FN', 'IF', 'TF', 'TR')

   SELECT O.object_id AS ReferenceByID
        , O.type      AS ReferenceByType
        , O.name      AS ReferenceByObject
        , S.name      AS ReferenceBySchema
        , W.object_id AS ReferenceOfID
        , W.type      AS ReferenceOfType
        , W.name      AS ReferenceOfObject
        , Z.name      AS ReferenceOfSchema
     INTO #Task
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN
  (SELECT D.referencing_id AS ReferenceByID
        , D.referenced_id  AS ReferenceOfID
     FROM sys.sql_expression_dependencies AS D
    WHERE D.referencing_id
       != D.referenced_id
 GROUP BY D.referencing_id
        , D.referenced_id) AS K
       ON O.object_id
        = K.ReferenceByID
     JOIN sys.objects AS W
       ON K.ReferenceOfID
        = W.object_id
     JOIN sys.schemas AS Z
       ON W.schema_id
        = Z.schema_id
      AND Z.name IN (SELECT [Schema] FROM @Match)
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type NOT IN ('C ')
 ORDER BY   ReferenceByID
        ,   ReferenceOfID

-- primary keys

   SELECT O.object_id AS GeneralID
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        ,        H.name          AS SQLServerFile
        , ISNULL(I.name, O.name) AS SQLServerName
        , I.index_id
        , I.type      AS table_type
        , I.type      AS index_type
        , I.fill_factor
        , I.is_primary_key
        , I.is_unique_constraint
        , M.is_descending_key
        , M.partition_ordinal
        , M.key_ordinal
        , C.name      AS GeneralColumn
     INTO #PKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.indexes AS I
       ON O.object_id
        = I.object_id
      AND CASE WHEN I.is_primary_key       != 0 THEN 1
               WHEN I.is_unique_constraint != 0 THEN 1 ELSE 0 END != 0
     JOIN sys.index_columns AS M
       ON I.object_id
        = M.object_id
      AND I.index_id
        = M.index_id
     JOIN sys.columns AS C
       ON M.object_id
        = C.object_id
      AND M.column_id
        = C.column_id
     JOIN sys.data_spaces AS H
       ON I.data_space_id
        = H.data_space_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY   GeneralSchema
        ,   GeneralObject
        ,   SQLServerName
        ,   key_ordinal

   SELECT P.GeneralID
        , P.GeneralObject
        , P.GeneralSchema
        , P.SQLServerFile
        , P.SQLServerName
        , CONVERT(     int, -1) AS Layer
        , CONVERT(     int, -1) AS Estimate
        , CONVERT(smallint,  0) AS Factor01
        , CONVERT(smallint,  0) AS Factor02
        , CONVERT(smallint,  0) AS Factor03
        , CONVERT(smallint,  0) AS Factor04
        , CONVERT(smallint,  0) AS Factor05
     INTO #PKeys
     FROM #PKey AS P
    WHERE P.is_primary_key != 0
 GROUP BY P.GeneralID
        , P.GeneralObject
        , P.GeneralSchema
        , P.SQLServerFile
        , P.SQLServerName
 ORDER BY P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerName

-- foreign keys

   SELECT O.object_id AS ForeignID
        , W.object_id AS PrimaryID
        , O.name      AS ForeignObject
        , W.name      AS PrimaryObject
        , S.name      AS ForeignSchema
        , Z.name      AS PrimarySchema
        , F.name      AS SQLServerName
        , CONVERT(varchar(0040), F.create_date, 120) AS create_date
        , CONVERT(varchar(0040), F.modify_date, 120) AS modify_date
        , F.is_disabled
        , F.is_not_trusted
        , M.constraint_column_id
        , C.name      AS ForeignColumn
        , K.name      AS PrimaryColumn
     INTO #FKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.foreign_keys AS F
       ON        O.object_id
        = F.parent_object_id
     JOIN sys.foreign_key_columns AS M
       ON            F.object_id
        = M.constraint_object_id
     JOIN sys.columns AS C
       ON M.parent_object_id
        =        C.object_id
      AND M.parent_column_id
        =        C.column_id
     JOIN sys.columns AS K
       ON M.referenced_object_id
        =            K.object_id
      AND M.referenced_column_id
        =            K.column_id
     JOIN sys.objects AS W
       ON F.referenced_object_id
        =            W.object_id
--    AND            O.object_id
--     !=            W.object_id
     JOIN sys.schemas AS Z
       ON W.schema_id
        = Z.schema_id
      AND Z.name IN (SELECT [Schema] FROM @Match)
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY   PrimarySchema
        ,   PrimaryObject
        ,   ForeignSchema
        ,   ForeignObject
        ,   constraint_column_id

   SELECT F.PrimaryID
        , F.ForeignID
        , F.PrimaryObject
        , F.ForeignObject
        , F.PrimarySchema
        , F.ForeignSchema
        , F.SQLServerName
        , COUNT(*) AS Columns
     INTO #FKeys
     FROM #FKey AS F
    WHERE F.PrimaryID
       != F.ForeignID
 GROUP BY F.PrimaryID
        , F.ForeignID
        , F.PrimaryObject
        , F.ForeignObject
        , F.PrimarySchema
        , F.ForeignSchema
        , F.SQLServerName
 ORDER BY F.PrimarySchema
        , F.PrimaryObject
        , F.ForeignSchema
        , F.ForeignObject

-- indexes

   SELECT O.object_id AS GeneralID
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        ,        H.name          AS SQLServerFile
        , ISNULL(I.name, O.name) AS SQLServerName
        , I.index_id
        , I.type      AS table_type
        , I.type      AS index_type
        , I.fill_factor
        , I.is_primary_key
        , I.is_unique_constraint
        , I.is_unique
        , I.is_disabled
        , M.is_included_column
        , M.is_descending_key
        , M.partition_ordinal
        , ISNULL(M.index_column_id, 0) AS index_column_id
        , CASE WHEN M.is_included_column  = 0 THEN ROW_NUMBER() OVER (PARTITION BY M.object_id, M.index_id, M.is_included_column ORDER BY M.index_column_id) ELSE 0 END AS regular_column_id
        , CASE WHEN M.is_included_column != 0 THEN ROW_NUMBER() OVER (PARTITION BY M.object_id, M.index_id, M.is_included_column ORDER BY M.index_column_id) ELSE 0 END AS include_column_id
        , ISNULL(I.filter_definition, SPACE(0)) AS GeneralFilter
        , C.name      AS GeneralColumn
        , T.name
        , CASE WHEN T.name LIKE 'n%char' AND C.max_length > 0 THEN C.max_length / 2 ELSE C.max_length END AS min_length
        , C.max_length
        , C.precision
        , C.scale
     INTO #ZKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.indexes AS I
       ON O.object_id
        = I.object_id
LEFT JOIN sys.index_columns AS M
       ON I.object_id
        = M.object_id
      AND I.index_id
        = M.index_id
LEFT JOIN sys.columns AS C
       ON M.object_id
        = C.object_id
      AND M.column_id
        = C.column_id
LEFT JOIN sys.types   AS T
       ON C.user_type_id
        = T.user_type_id
     JOIN sys.data_spaces AS H
       ON I.data_space_id
        = H.data_space_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY   GeneralSchema
        ,   GeneralObject
        ,   SQLServerName
        ,   index_column_id

   SELECT Z.*
        , CASE WHEN Z.name = 'time'           THEN Z.name + '(' +                                                   STR(Z.scale,       1)     + ')'
               WHEN Z.name = 'datetime2'      THEN Z.name + '(' +                                                   STR(Z.scale,       1)     + ')'
               WHEN Z.name = 'datetimeoffset' THEN Z.name + '(' +                                                   STR(Z.scale,       1)     + ')'
               WHEN Z.name = 'float'          THEN Z.name + '(' + RIGHT(STR(Z.precision + 100, 3), 2)                                         + ')'
               WHEN Z.name = 'numeric'        THEN Z.name + '(' + RIGHT(STR(Z.precision + 100, 3), 2) + ',' + RIGHT(STR(Z.scale + 100, 3), 2) + ')'
               WHEN Z.name = 'decimal'        THEN Z.name + '(' + RIGHT(STR(Z.precision + 100, 3), 2) + ',' + RIGHT(STR(Z.scale + 100, 3), 2) + ')'
               WHEN Z.name = 'vardecimal'     THEN Z.name + '(' + RIGHT(STR(Z.precision + 100, 3), 2) + ',' + RIGHT(STR(Z.scale + 100, 3), 2) + ')'
               WHEN Z.name = 'binary'         THEN Z.name + '(' +                                 RIGHT(STR(Z.max_length + 10000, 5), 4)                 + ')'
               WHEN Z.name = 'varbinary'      THEN Z.name + '(' + CASE WHEN Z.max_length > 0 THEN RIGHT(STR(Z.max_length + 10000, 5), 4) ELSE 'max ' END + ')'
               WHEN Z.name = 'nchar'          THEN Z.name + '(' +                                 RIGHT(STR(Z.min_length + 10000, 5), 4)                 + ')'
               WHEN Z.name = 'nvarchar'       THEN Z.name + '(' + CASE WHEN Z.min_length > 0 THEN RIGHT(STR(Z.min_length + 10000, 5), 4) ELSE 'max ' END + ')'
               WHEN Z.name = 'char'           THEN Z.name + '(' +                                 RIGHT(STR(Z.max_length + 10000, 5), 4)                 + ')'
               WHEN Z.name = 'varchar'        THEN Z.name + '(' + CASE WHEN Z.max_length > 0 THEN RIGHT(STR(Z.max_length + 10000, 5), 4) ELSE 'max ' END + ')'
                                              ELSE Z.name END AS SQLServerType
     INTO #ZKeys
     FROM #ZKey AS Z
 ORDER BY Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerName
        , Z.index_column_id

-- columns

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        , C.column_id
        , ISNULL(M.index_column_id, 0) AS index_column_id
        , C.is_nullable
        , C.is_computed
        , C.is_identity
        , CASE WHEN C.is_identity != 0 THEN CONVERT(decimal(38,00), IDENT_SEED   (S.name + '.' + O.name)) ELSE 0 END AS [From]
        , CASE WHEN C.is_identity != 0 THEN CONVERT(decimal(38,00), IDENT_INCR   (S.name + '.' + O.name)) ELSE 0 END AS [Plus]
        , CASE WHEN C.is_identity != 0 THEN CONVERT(decimal(38,00), IDENT_CURRENT(S.name + '.' + O.name)) ELSE 0 END AS [Used]
        , C.name      AS GeneralColumn
        , T.name
        , CASE WHEN T.name LIKE 'n%char' AND C.max_length > 0 THEN C.max_length / 2 ELSE C.max_length END AS min_length
        , C.max_length
        , C.precision
        , C.scale
        , ISNULL(                   C.collation_name , '') AS collation_name
        , ISNULL(CONVERT(varchar(4000), W.definition), '') AS FormulaCode
        , ISNULL(CONVERT(varchar(4000), Z.definition), '') AS DefaultCode
        , ISNULL(                             Z.name , '') AS DefaultName
     INTO #TKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.columns AS C
       ON O.object_id
        = C.object_id
     JOIN sys.types   AS T
       ON C.user_type_id
        = T.user_type_id
LEFT JOIN sys.indexes AS I
       ON O.object_id
        = I.object_id
      AND I.is_primary_key != 0
LEFT JOIN sys.index_columns AS M
       ON I.object_id
        = M.object_id
      AND I.index_id
        = M.index_id
      AND C.column_id
        = M.column_id
LEFT JOIN sys.computed_columns AS W
       ON C.object_id
        = W.object_id
      AND C.column_id
        = W.column_id
LEFT JOIN sys.default_constraints AS Z
       ON        C.object_id
        = Z.parent_object_id
      AND        C.column_id
        = Z.parent_column_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ', 'V ', 'P ', 'FN', 'IF', 'TF')
 ORDER BY   GeneralType
        ,   GeneralSchema
        ,   GeneralObject
        ,   column_id

   SELECT T.*
        , CASE WHEN T.name = 'time'           THEN T.name + '(' +                                                   STR(T.scale,       1)     + ')'
               WHEN T.name = 'datetime2'      THEN T.name + '(' +                                                   STR(T.scale,       1)     + ')'
               WHEN T.name = 'datetimeoffset' THEN T.name + '(' +                                                   STR(T.scale,       1)     + ')'
               WHEN T.name = 'float'          THEN T.name + '(' + RIGHT(STR(T.precision + 100, 3), 2)                                         + ')'
               WHEN T.name = 'numeric'        THEN T.name + '(' + RIGHT(STR(T.precision + 100, 3), 2) + ',' + RIGHT(STR(T.scale + 100, 3), 2) + ')'
               WHEN T.name = 'decimal'        THEN T.name + '(' + RIGHT(STR(T.precision + 100, 3), 2) + ',' + RIGHT(STR(T.scale + 100, 3), 2) + ')'
               WHEN T.name = 'vardecimal'     THEN T.name + '(' + RIGHT(STR(T.precision + 100, 3), 2) + ',' + RIGHT(STR(T.scale + 100, 3), 2) + ')'
               WHEN T.name = 'binary'         THEN T.name + '(' +                                 RIGHT(STR(T.max_length + 10000, 5), 4)                 + ')'
               WHEN T.name = 'varbinary'      THEN T.name + '(' + CASE WHEN T.max_length > 0 THEN RIGHT(STR(T.max_length + 10000, 5), 4) ELSE 'max ' END + ')'
               WHEN T.name = 'nchar'          THEN T.name + '(' +                                 RIGHT(STR(T.min_length + 10000, 5), 4)                 + ')'
               WHEN T.name = 'nvarchar'       THEN T.name + '(' + CASE WHEN T.min_length > 0 THEN RIGHT(STR(T.min_length + 10000, 5), 4) ELSE 'max ' END + ')'
               WHEN T.name = 'char'           THEN T.name + '(' +                                 RIGHT(STR(T.max_length + 10000, 5), 4)                 + ')'
               WHEN T.name = 'varchar'        THEN T.name + '(' + CASE WHEN T.max_length > 0 THEN RIGHT(STR(T.max_length + 10000, 5), 4) ELSE 'max ' END + ')'
                                              ELSE T.name END AS SQLServerType
     INTO #TKeys
     FROM #TKey AS T
--  WHERE T.GeneralType IN ('U ', 'V ', 'P ', 'FN', 'IF', 'TF')
 ORDER BY T.GeneralType
        , T.GeneralSchema
        , T.GeneralObject
        , T.column_id

-- parameters

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        , W.parameter_id
        , CONVERT(bit, COLUMNPROPERTY(O.object_id, W.name, 'AllowsNull')) AS is_nullable
        , CONVERT(bit, COLUMNPROPERTY(O.object_id, W.name, 'IsOutParam')) AS is_output
        , W.name      AS GeneralColumn
        , T.name
        , CASE WHEN T.name LIKE 'n%char' AND W.max_length > 0 THEN W.max_length / 2 ELSE W.max_length END AS min_length
        , W.max_length
        , W.precision
        , W.scale
     INTO #UKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.parameters AS W
       ON O.object_id
        = W.object_id
      AND W.parameter_id != 0
     JOIN sys.types AS T
       ON W.user_type_id
        = T.user_type_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN (            'P ', 'FN', 'IF', 'TF')
 ORDER BY   GeneralType
        ,   GeneralSchema
        ,   GeneralObject
        ,   parameter_id

   SELECT U.*
        , CASE WHEN U.name = 'time'           THEN U.name + '(' +                                                   STR(U.scale,       1)     + ')'
               WHEN U.name = 'datetime2'      THEN U.name + '(' +                                                   STR(U.scale,       1)     + ')'
               WHEN U.name = 'datetimeoffset' THEN U.name + '(' +                                                   STR(U.scale,       1)     + ')'
               WHEN U.name = 'float'          THEN U.name + '(' + RIGHT(STR(U.precision + 100, 3), 2)                                         + ')'
               WHEN U.name = 'numeric'        THEN U.name + '(' + RIGHT(STR(U.precision + 100, 3), 2) + ',' + RIGHT(STR(U.scale + 100, 3), 2) + ')'
               WHEN U.name = 'decimal'        THEN U.name + '(' + RIGHT(STR(U.precision + 100, 3), 2) + ',' + RIGHT(STR(U.scale + 100, 3), 2) + ')'
               WHEN U.name = 'vardecimal'     THEN U.name + '(' + RIGHT(STR(U.precision + 100, 3), 2) + ',' + RIGHT(STR(U.scale + 100, 3), 2) + ')'
               WHEN U.name = 'binary'         THEN U.name + '(' +                                 RIGHT(STR(U.max_length + 10000, 5), 4)                 + ')'
               WHEN U.name = 'varbinary'      THEN U.name + '(' + CASE WHEN U.max_length > 0 THEN RIGHT(STR(U.max_length + 10000, 5), 4) ELSE 'max ' END + ')'
               WHEN U.name = 'nchar'          THEN U.name + '(' +                                 RIGHT(STR(U.min_length + 10000, 5), 4)                 + ')'
               WHEN U.name = 'nvarchar'       THEN U.name + '(' + CASE WHEN U.min_length > 0 THEN RIGHT(STR(U.min_length + 10000, 5), 4) ELSE 'max ' END + ')'
               WHEN U.name = 'char'           THEN U.name + '(' +                                 RIGHT(STR(U.max_length + 10000, 5), 4)                 + ')'
               WHEN U.name = 'varchar'        THEN U.name + '(' + CASE WHEN U.max_length > 0 THEN RIGHT(STR(U.max_length + 10000, 5), 4) ELSE 'max ' END + ')'
                                              ELSE U.name END AS SQLServerType
     INTO #UKeys
     FROM #UKey AS U
--  WHERE U.GeneralType IN (            'P ', 'FN', 'IF', 'TF')
 ORDER BY U.GeneralType
        , U.GeneralSchema
        , U.GeneralObject
        , U.parameter_id

-- partitions

   SELECT O.object_id AS GeneralID
        , O.type      AS GeneralType
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        ,        H.name          AS SQLServerFile
        , ISNULL(I.name, O.name) AS SQLServerName
        , X.name AS [PS_Name]
        , Y.name AS [PF_Name]
        , C.GeneralColumn
        , C.SQLServerType
        , CASE WHEN Y.boundary_value_on_right = 0 THEN 'THRU' ELSE 'FROM' END + ' - ' + ISNULL(CASE WHEN T.name LIKE '%datetime%' THEN LEFT(CONVERT(varchar(0400), CONVERT(datetime, W.value), 120), 16) ELSE CONVERT(varchar(0400), W.value) END, SPACE(0)) AS Boundary
        , P.partition_number AS [Partition]
        , P.rows             AS [Rows]
        , CASE WHEN P.data_compression = 1 THEN 'ROW'
               WHEN P.data_compression = 2 THEN 'PAGE'
               WHEN P.data_compression > 2 THEN 'COLUMNSTORE' ELSE SPACE(0) END AS [Compression]
        , I.type      AS table_type
        , I.type      AS index_type
        , I.fill_factor
     INTO #VKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.indexes AS I
       ON O.object_id
        = I.object_id
LEFT JOIN #ZKeys AS C
       ON I.object_id
        = C.GeneralID
      AND I.index_id
        = C.index_id
      AND C.partition_ordinal = 1
     JOIN sys.partitions AS P
       ON I.object_id
        = P.object_id
      AND I.index_id
        = P.index_id
     JOIN sys.partition_schemes AS X
       ON I.data_space_id
        = X.data_space_id
     JOIN sys.partition_functions AS Y
       ON X.function_id
        = Y.function_id
     JOIN sys.partition_parameters AS Z
       ON Y.function_id
        = Z.function_id
     JOIN sys.types AS T
       ON Z.user_type_id
        = T.user_type_id
LEFT JOIN sys.partition_range_values AS W
       ON Z.function_id
        = W.function_id
      AND Z.parameter_id = 1
      AND W.parameter_id = 1
      AND P.partition_number
        = W.boundary_id + CASE WHEN Y.boundary_value_on_right = 0 THEN 0 ELSE 1 END
     JOIN
  (SELECT E.partition_scheme_id AS data_space_id
        , E.destination_id      AS partition_number
        , K.name
     FROM sys.destination_data_spaces AS E
     JOIN sys.data_spaces AS K
       ON E.data_space_id
        = K.data_space_id) AS H
       ON X.data_space_id
        = H.data_space_id
      AND P.partition_number
        = H.partition_number
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY   GeneralSchema
        ,   GeneralObject
        ,   [Partition]

-- table_type

   UPDATE P SET table_type = E.index_type FROM #PKey  AS P JOIN #ZKey AS E ON P.GeneralID = E.GeneralID AND E.index_type IN (0, 1, 5) AND E.index_column_id IN (0, 1)

   UPDATE Z SET table_type = E.index_type FROM #ZKey  AS Z JOIN #ZKey AS E ON Z.GeneralID = E.GeneralID AND E.index_type IN (0, 1, 5) AND E.index_column_id IN (0, 1)
   UPDATE Z SET table_type = E.index_type FROM #ZKeys AS Z JOIN #ZKey AS E ON Z.GeneralID = E.GeneralID AND E.index_type IN (0, 1, 5) AND E.index_column_id IN (0, 1)

   UPDATE V SET table_type = E.index_type FROM #VKey  AS V JOIN #ZKey AS E ON V.GeneralID = E.GeneralID AND E.index_type IN (0, 1, 5) AND E.index_column_id IN (0, 1)

-- layers

SET @Layer = 0

SET @Batch = 0

   UPDATE P SET Layer = @Layer
     FROM #PKeys AS P
LEFT JOIN #FKeys AS F
       ON P.GeneralID
        = F.ForeignID
    WHERE F.ForeignID IS NULL

SET @Batch = @@ROWCOUNT

WHILE @Batch > 0 AND @Layer < 90

    BEGIN

    SET @Layer = @Layer + 1

       UPDATE P SET Layer = @Layer
         FROM #PKeys AS P
        WHERE NOT EXISTS
      (SELECT *
         FROM #PKeys AS W
         JOIN #FKeys AS Z
           ON W.GeneralID
            = Z.PrimaryID
          AND P.GeneralID
            = Z.ForeignID
        WHERE W.Layer < 0)
          AND P.Layer < 0

    SET @Batch = @@ROWCOUNT

    END

SET @Layer = 0

SET @Batch = 0

   UPDATE W SET Layer = @Layer
     FROM #Work AS W
LEFT JOIN #Task AS T
       ON W.GeneralID
        = T.ReferenceOfID
    WHERE T.ReferenceOfID IS NULL

SET @Batch = @@ROWCOUNT

WHILE @Batch > 0 AND @Layer < 50

    BEGIN

    SET @Layer = @Layer + 1

       UPDATE P SET Layer = @Layer
         FROM #Work AS P
        WHERE NOT EXISTS
      (SELECT *
         FROM #Work AS W
         JOIN #Task AS T
           ON W.GeneralID
            = T.ReferenceByID
          AND P.GeneralID
            = T.ReferenceOfID
        WHERE W.Layer < 0)
          AND P.Layer < 0

    SET @Batch = @@ROWCOUNT

    END

-- rows / GBs

   SELECT O.object_id AS GeneralID
        , O.name      AS GeneralObject
        , S.name      AS GeneralSchema
        ,        H.name          AS SQLServerFile
        , ISNULL(I.name, O.name) AS SQLServerName
        , ISNULL(CONVERT(decimal(38,00), IDENT_SEED   (S.name + '.' + O.name)), 0) AS [From]
        , ISNULL(CONVERT(decimal(38,00), IDENT_INCR   (S.name + '.' + O.name)), 0) AS [Plus]
        , ISNULL(CONVERT(decimal(38,00), IDENT_CURRENT(S.name + '.' + O.name)), 0) AS [Used]
        , T.index_id
        , I.type      AS table_type
        , I.type      AS index_type
        , CASE WHEN T.DC_MIN  = T.DC_MAX AND T.DC_MIN = 1 THEN 'ROW'
               WHEN T.DC_MIN  = T.DC_MAX AND T.DC_MIN = 2 THEN 'PAGE'
               WHEN T.DC_MIN  = T.DC_MAX AND T.DC_MIN > 2 THEN 'COLUMNSTORE'
               WHEN T.DC_MIN != T.DC_MAX                  THEN 'MIXED TYPES' ELSE SPACE(0) END AS [Compression]
        , T.[Partitions]
        , T.total_rows          AS [Rows]
        , ISNULL(Z.index_id, 0) AS [Indexes]
        , CONVERT(decimal(19,05), ISNULL(W.total_pages, 0) / 128.0 / 1024.0) AS GBs_Table
        , CONVERT(decimal(19,05), ISNULL(Z.total_pages, 0) / 128.0 / 1024.0) AS GBs_Indexes
     INTO #WKey
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.indexes AS I
       ON O.object_id
        = I.object_id
      AND I.type                     IN (0, 1, 5)
     JOIN sys.data_spaces AS H
       ON I.data_space_id
        = H.data_space_id
     JOIN
  (SELECT I.object_id
        , MIN(I.index_id)            AS index_id
        , SUM(P.rows)                AS total_rows
        , COUNT(*)                   AS Partitions
        , MIN(P.data_compression)    AS DC_MIN
        , MAX(P.data_compression)    AS DC_MAX
     FROM sys.indexes    AS I
     JOIN sys.partitions AS P
       ON I.object_id
        = P.object_id
      AND I.index_id
        = P.index_id
    WHERE I.type                     IN (0, 1, 5)
 GROUP BY I.object_id)               AS T
       ON O.object_id
        = T.object_id
     JOIN
  (SELECT I.object_id
        , MIN(I.index_id)            AS index_id
        , SUM(A.total_pages)         AS total_pages
     FROM sys.indexes    AS I
     JOIN sys.partitions AS P
       ON I.object_id
        = P.object_id
      AND I.index_id
        = P.index_id
     JOIN sys.allocation_units       AS A
       ON P.partition_id
        = A.container_id
      AND A.type != 0
    WHERE I.type                     IN (0, 1, 5)
 GROUP BY I.object_id)               AS W
       ON O.object_id
        = W.object_id
LEFT JOIN
  (SELECT I.object_id
        , COUNT(DISTINCT I.index_id) AS index_id
        , SUM(A.total_pages)         AS total_pages
     FROM sys.indexes    AS I
     JOIN sys.partitions AS P
       ON I.object_id
        = P.object_id
      AND I.index_id
        = P.index_id
     JOIN sys.allocation_units       AS A
       ON P.partition_id
        = A.container_id
      AND A.type != 0
    WHERE I.type                 NOT IN (0, 1, 5)
 GROUP BY I.object_id)               AS Z
       ON O.object_id
        = Z.object_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 ORDER BY   GeneralSchema
        ,   GeneralObject

   SELECT @GBs = SUM(W.GBs_Table) + SUM(W.GBs_Indexes) FROM #WKey AS W

-- estimate prominence

   UPDATE #PKeys SET
          Factor01 = A.MyCOUNT
        , Estimate = A.MyCOUNT
     FROM #PKeys AS P
     JOIN
  (SELECT T.GeneralID
        , COUNT(*)        AS MyCOUNT
     FROM #TKey  AS T
 GROUP BY T.GeneralID) AS A
       ON P.GeneralID
        = A.GeneralID

   UPDATE #PKeys SET
          Factor02 =               A.MyCOUNT
        , Estimate = P.Estimate + (A.MyCOUNT * 3)
     FROM #PKeys AS P
     JOIN
  (SELECT Z.GeneralID
        , COUNT(*)        AS MyCOUNT
     FROM #ZKeys AS Z
    WHERE Z.index_column_id = 1
 GROUP BY Z.GeneralID) AS A
       ON P.GeneralID
        = A.GeneralID

   UPDATE #PKeys SET
          Factor03 =               A.MyCOUNT
        , Estimate = P.Estimate + (A.MyCOUNT * 9)
     FROM #PKeys AS P
     JOIN
  (SELECT K.GeneralID
        , COUNT(*)        AS MyCOUNT
     FROM #PKey  AS K
    WHERE K.key_ordinal = 1
 GROUP BY K.GeneralID) AS A
       ON P.GeneralID
        = A.GeneralID

   UPDATE #PKeys SET
          Factor04 =               A.MyCOUNT
        , Estimate = P.Estimate + (A.MyCOUNT * 7)
     FROM #PKeys AS P
     JOIN
  (SELECT F.PrimaryID     AS GeneralID
        , COUNT(*)        AS MyCOUNT
     FROM #FKeys AS F
 GROUP BY F.PrimaryID) AS A
       ON P.GeneralID
        = A.GeneralID

   UPDATE #PKeys SET
          Factor05 =               A.MyCOUNT
        , Estimate = P.Estimate + (A.MyCOUNT * 5)
     FROM #PKeys AS P
     JOIN
  (SELECT T.ReferenceOfID AS GeneralID
        , COUNT(*)        AS MyCOUNT
     FROM #Task  AS T
    WHERE T.ReferenceByType IN (      'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
      AND T.ReferenceByObject NOT LIKE 'uspG[SIUD]%'
      AND T.ReferenceByObject NOT LIKE 'trgG[SIUD]%'
 GROUP BY T.ReferenceOfID) AS A
       ON P.GeneralID
        = A.GeneralID

-- estimate prominence

   UPDATE #Work  SET
          Factor01 = A.MyCOUNT
        , Estimate = A.MyCOUNT
     FROM #Work  AS W
     JOIN
  (SELECT T.GeneralID
        , COUNT(*)        AS MyCOUNT
     FROM #TKey  AS T
 GROUP BY T.GeneralID) AS A
       ON W.GeneralID
        = A.GeneralID

   UPDATE #Work  SET
          Factor02 =               A.MyCOUNT
        , Estimate = W.Estimate + (A.MyCOUNT * 3)
     FROM #Work  AS W
     JOIN
  (SELECT U.GeneralID
        , COUNT(*)        AS MyCOUNT
     FROM #UKey  AS U
 GROUP BY U.GeneralID) AS A
       ON W.GeneralID
        = A.GeneralID

   UPDATE #Work  SET
          Factor03 =               A.MyCOUNT
        , Estimate = W.Estimate + (A.MyCOUNT * 7)
     FROM #Work  AS W
     JOIN
  (SELECT E.GeneralID
        , CONVERT(smallint, (LEN(E.SQLServerCode) / 1024) + 1) AS MyCOUNT
     FROM #Base  AS E) AS A
       ON W.GeneralID
        = A.GeneralID

   UPDATE #Work  SET
          Factor04 =               A.MyCOUNT
        , Estimate = W.Estimate + (A.MyCOUNT * 5)
     FROM #Work  AS W
     JOIN
  (SELECT T.ReferenceByID AS GeneralID
        , COUNT(*)        AS MyCOUNT
     FROM #Task  AS T
    WHERE T.ReferenceOfType IN ('U ', 'V ', 'P ', 'FN', 'IF', 'TF', 'SN')
      AND T.ReferenceOfObject NOT LIKE 'uspG[SIUD]%'
      AND T.ReferenceOfObject NOT LIKE 'trgG[SIUD]%'
 GROUP BY T.ReferenceByID) AS A
       ON W.GeneralID
        = A.GeneralID

   UPDATE #Work  SET
          Factor05 =               A.MyCOUNT
        , Estimate = W.Estimate + (A.MyCOUNT * 9)
     FROM #Work  AS W
     JOIN
  (SELECT T.ReferenceOfID AS GeneralID
        , COUNT(*)        AS MyCOUNT
     FROM #Task  AS T
    WHERE T.ReferenceByType IN (      'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
      AND T.ReferenceByObject NOT LIKE 'uspG[SIUD]%'
      AND T.ReferenceByObject NOT LIKE 'trgG[SIUD]%'
 GROUP BY T.ReferenceOfID) AS A
       ON W.GeneralID
        = A.GeneralID

/*

   SELECT E.*
     FROM #Base AS E
 ORDER BY E.GeneralType
        , E.GeneralSchema
        , E.GeneralObject

   SELECT M.*
     FROM #More AS M
 ORDER BY M.GeneralType
        , M.GeneralSchema
        , M.GeneralObject
        , M.SQLServerName

   SELECT R.*
     FROM #RoleDBUser AS R
 ORDER BY R.DBUserType
        , R.DBUserName

   SELECT R.*
     FROM #RuleSchema AS R
 ORDER BY R.DBRoleType
        , R.DBRoleName
        , R.DBUserType
        , R.DBUserName
        , R.DBAction
        , R.GeneralSchema

   SELECT R.*
     FROM #RuleObject AS R
 ORDER BY R.DBRoleType
        , R.DBRoleName
        , R.DBUserType
        , R.DBUserName
        , R.DBAction
        , R.GeneralID
        , R.column_id

   SELECT W.*
     FROM #Work AS W
 ORDER BY W.GeneralType
        , W.GeneralSchema
        , W.GeneralObject

   SELECT T.*
     FROM #Task AS T
 ORDER BY T.ReferenceByType
        , T.ReferenceBySchema
        , T.ReferenceByObject
        , T.ReferenceOfType
        , T.ReferenceOfSchema
        , T.ReferenceOfObject

   SELECT P.*
     FROM #PKey AS P
    WHERE P.is_primary_key != 0
 ORDER BY P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerName
        , P.key_ordinal

   SELECT P.*
     FROM #PKey AS P
    WHERE P.is_unique_constraint != 0
 ORDER BY P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerName
        , P.key_ordinal

   SELECT F.*
     FROM #FKey AS F
 ORDER BY F.PrimarySchema
        , F.PrimaryObject
        , F.ForeignSchema
        , F.ForeignObject
        , F.constraint_column_id

   SELECT Z.*
     FROM #ZKey AS Z
 ORDER BY Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerName
        , Z.index_column_id

   SELECT T.*
     FROM #TKey AS T
 ORDER BY T.GeneralType
        , T.GeneralSchema
        , T.GeneralObject
        , T.column_id

   SELECT U.*
     FROM #UKey AS U
 ORDER BY U.GeneralType
        , U.GeneralSchema
        , U.GeneralObject
        , U.parameter_id

   SELECT W.*
     FROM #WKey AS W
 ORDER BY W.GeneralSchema
        , W.GeneralObject

   SELECT Z.fill_factor AS Factor
        , SUM(CASE WHEN Z.index_type = 0 THEN 1 ELSE 0 END) AS Index_0
        , SUM(CASE WHEN Z.index_type = 1 THEN 1 ELSE 0 END) AS Index_1
        , SUM(CASE WHEN Z.index_type = 5 THEN 1 ELSE 0 END) AS Index_5
        , SUM(CASE WHEN Z.index_type = 2 THEN 1 ELSE 0 END) AS Index_2
        , SUM(CASE WHEN Z.index_type = 6 THEN 1 ELSE 0 END) AS Index_6
     FROM #ZKeys AS Z
    WHERE Z.index_column_id IN (0, 1)
 GROUP BY Z.fill_factor
 ORDER BY Z.fill_factor

*/

-- SQLFacts <> 01 Filegroups

PRINT '-- Fact 01 Filegroups'

   SELECT '01' AS Fact
        , H.name AS SQLServerFile
        , H.is_default
        , SUM(CASE WHEN Z.type = 0 THEN Z.MyCOUNT ELSE 0 END) AS Index_0
        , SUM(CASE WHEN Z.type = 1 THEN Z.MyCOUNT ELSE 0 END) AS Index_1
        , SUM(CASE WHEN Z.type = 5 THEN Z.MyCOUNT ELSE 0 END) AS Index_5
        , SUM(CASE WHEN Z.type = 2 THEN Z.MyCOUNT ELSE 0 END) AS Index_2
        , SUM(CASE WHEN Z.type = 6 THEN Z.MyCOUNT ELSE 0 END) AS Index_6
--   INTO SQLFacts.dbo.Fact_01
     FROM sys.data_spaces AS H
     JOIN
  (SELECT A.data_space_id
        , I.type
        , COUNT(DISTINCT S.name + '.' + O.name + '.' + ISNULL(I.name, O.name)) AS MyCOUNT
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.indexes AS I
       ON O.object_id
        = I.object_id
     JOIN sys.partitions AS P
       ON I.object_id
        = P.object_id
      AND I.index_id
        = P.index_id
     JOIN sys.allocation_units AS A
       ON P.partition_id
        = A.container_id
      AND A.type != 0
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ')
 GROUP BY A.data_space_id
        , I.type) AS Z
       ON H.data_space_id
        = Z.data_space_id
    WHERE H.type = 'FG'
 GROUP BY H.name
        , H.is_default
 ORDER BY H.name

-- SQLFacts <> 02 Database Files

PRINT '-- Fact 02 Database Files'

   SELECT '02' AS Fact
        , ISNULL(H.name, '< LOG >') AS SQLServerFile
        , F.physical_name           AS SQLServerPath
        , F.name                    AS SQLServerName
        , CASE WHEN F.is_percent_growth  = 0 THEN  0       ELSE CONVERT(decimal(09,00), F.growth                   ) END AS [Percent]
        , CASE WHEN F.is_percent_growth != 0 THEN  0.00000 ELSE CONVERT(decimal(19,05), F.growth   / 128.0 / 1024.0) END AS [GBs_ADD]
        ,                                                       CONVERT(decimal(19,05), F.size     / 128.0 / 1024.0)     AS [GBs_NOW]
        , CASE WHEN F.max_size           < 0 THEN -1.00000 ELSE CONVERT(decimal(19,05), F.max_size / 128.0 / 1024.0) END AS [GBs_MAX]
--   INTO SQLFacts.dbo.Fact_02
     FROM sys.database_files AS F
LEFT JOIN sys.data_spaces    AS H
       ON F.data_space_id
        = H.data_space_id
      AND H.type = 'FG'
    WHERE CASE WHEN F.type = 0 THEN 1 WHEN F.type = 1 THEN 2 ELSE 0 END != 0
 ORDER BY CASE WHEN F.type = 0 THEN 1 WHEN F.type = 1 THEN 2 ELSE 0 END 
        , F.file_id

-- SQLFacts <> 03 Database Users

PRINT '-- Fact 03 Database Users'

   SELECT '03' AS Fact
        , Z.DBUserType
        , Z.DBUserName
        , Z.create_date
        , Z.modify_date
        , Z.SQLServerName
        , Z.[Owner]
        , Z.[Access]
        , Z.[Security]
        , Z.[DDL]
        , Z.[BACKUP]
        , Z.[DataReader]
        , Z.[DataWriter]
        , Z.[DenyReader]
        , Z.[DenyWriter]
--   INTO SQLFacts.dbo.Fact_03
     FROM #RoleDBUser AS Z
 ORDER BY Z.DBUserType
        , Z.DBUserName

-- SQLFacts <> 04 Schemas

PRINT '-- Fact 04 Schemas'

   SELECT '04' AS Fact
        , E.GeneralSchema
        , SUM(CASE WHEN E.GeneralType = 'U ' THEN 1 ELSE 0 END) AS [U ]
        , SUM(CASE WHEN E.GeneralType = 'V ' THEN 1 ELSE 0 END) AS [V ]
        , SUM(CASE WHEN E.GeneralType = 'P ' THEN 1 ELSE 0 END) AS [P ]
        , SUM(CASE WHEN E.GeneralType = 'FN' THEN 1 ELSE 0 END) AS [FN]
        , SUM(CASE WHEN E.GeneralType = 'IF' THEN 1 ELSE 0 END) AS [IF]
        , SUM(CASE WHEN E.GeneralType = 'TF' THEN 1 ELSE 0 END) AS [TF]
        , SUM(CASE WHEN E.GeneralType = 'TR' THEN 1 ELSE 0 END) AS [TR]
        , (SELECT COUNT(*) FROM sys.schemas AS S JOIN sys.objects AS O ON S.schema_id = O.schema_id WHERE S.name = E.GeneralSchema AND O.type = 'SN') AS [SN]
        , (SELECT COUNT(*) FROM sys.schemas AS S JOIN sys.objects AS O ON S.schema_id = O.schema_id WHERE S.name = E.GeneralSchema AND O.type = 'SO') AS [SO]
--   INTO SQLFacts.dbo.Fact_04
     FROM #Base AS E
    WHERE E.GeneralType IN ('U ', 'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
      AND E.GeneralObject NOT LIKE 'uspG[SIUD]%'
      AND E.GeneralObject NOT LIKE 'trgG[SIUD]%'
 GROUP BY E.GeneralSchema
 ORDER BY E.GeneralSchema

-- SQLFacts <> 05 Schema Permissions

PRINT '-- Fact 05 Schema Permissions'

   SELECT '05' AS Fact
        , R.GeneralSchema
        , R.DBRoleType
        , R.DBRoleName
        , R.DBUserType
        , R.DBUserName
        , R.DBAction
        , R.DBStatus
--   INTO SQLFacts.dbo.Fact_05
     FROM #RuleSchema AS R
 ORDER BY R.GeneralSchema
        , R.DBRoleType
        , R.DBRoleName
        , R.DBUserType
        , R.DBUserName
        , R.DBAction

-- SQLFacts <> 06 Table Details, by name

PRINT '-- Fact 06 Table Details, by name'

   SELECT '06' AS Fact
        , E.GeneralSchema
        , E.GeneralObject
        , W.SQLServerFile
--      , W.SQLServerName
        , E.create_date
        , E.modify_date
        , (SELECT COUNT(*) FROM #PKey AS P WHERE P.GeneralID = E.GeneralID AND P.is_primary_key       != 0 AND P.key_ordinal          = 1) AS [PKs]
        , (SELECT COUNT(*) FROM #PKey AS P WHERE P.GeneralID = E.GeneralID AND P.is_unique_constraint != 0 AND P.key_ordinal          = 1) AS [AKs]
        , (SELECT COUNT(*) FROM #FKey AS F WHERE F.ForeignID = E.GeneralID                                 AND F.constraint_column_id = 1) AS [FKs_P]
        , (SELECT COUNT(*) FROM #FKey AS F WHERE F.PrimaryID = E.GeneralID                                 AND F.constraint_column_id = 1) AS [FKs_C]
        , (SELECT COUNT(*) FROM #TKey AS T WHERE T.GeneralID = E.GeneralID                                                               ) AS [Columns]
        , W.[From]
        , W.[Plus]
        , W.[Used]
        , W.[Compression]
        , W.[Partitions]
        , W.[Rows]
        , W.[table_type]
        , W.[Indexes]
        , W.GBs_Table
        , W.GBs_Indexes
        , CONVERT(decimal(05,02), (W.GBs_Table + W.GBs_Indexes) * 100.0 / @GBs) AS [Percent]
--      , (SELECT COUNT(*) FROM #More AS M WHERE M.GeneralID     = E.GeneralID                                               ) AS [Checks]
--      , (SELECT COUNT(*) FROM #Base AS A WHERE A.GeneralID     = E.GeneralID AND A.GeneralType       IN ('TR')
--                                                                             AND A.GeneralObject     NOT LIKE 'uspG[SIUD]%'
--                                                                             AND A.GeneralObject     NOT LIKE 'trgG[SIUD]%') AS [Triggers]
--      , (SELECT COUNT(*) FROM #Task AS T WHERE T.ReferenceOfID = E.GeneralID AND T.ReferenceByType   IN (      'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
--                                                                             AND T.ReferenceByObject NOT LIKE 'uspG[SIUD]%'
--                                                                             AND T.ReferenceByObject NOT LIKE 'trgG[SIUD]%') AS [References]
--   INTO SQLFacts.dbo.Fact_06
     FROM #Base AS E
LEFT JOIN #WKey AS W
       ON E.GeneralID
        = W.GeneralID
    WHERE E.GeneralType IN ('U ')
 ORDER BY E.GeneralSchema
        , E.GeneralObject

-- SQLFacts <> 07 Table Details, by row count

PRINT '-- Fact 07 Table Details, by row count'

   SELECT '07' AS Fact
        , E.GeneralSchema
        , E.GeneralObject
        , W.SQLServerFile
--      , W.SQLServerName
        , E.create_date
        , E.modify_date
        , (SELECT COUNT(*) FROM #PKey AS P WHERE P.GeneralID = E.GeneralID AND P.is_primary_key       != 0 AND P.key_ordinal          = 1) AS [PKs]
        , (SELECT COUNT(*) FROM #PKey AS P WHERE P.GeneralID = E.GeneralID AND P.is_unique_constraint != 0 AND P.key_ordinal          = 1) AS [AKs]
        , (SELECT COUNT(*) FROM #FKey AS F WHERE F.ForeignID = E.GeneralID                                 AND F.constraint_column_id = 1) AS [FKs_P]
        , (SELECT COUNT(*) FROM #FKey AS F WHERE F.PrimaryID = E.GeneralID                                 AND F.constraint_column_id = 1) AS [FKs_C]
        , (SELECT COUNT(*) FROM #TKey AS T WHERE T.GeneralID = E.GeneralID                                                               ) AS [Columns]
        , W.[From]
        , W.[Plus]
        , W.[Used]
        , W.[Compression]
        , W.[Partitions]
        , W.[Rows]
        , W.[table_type]
        , W.[Indexes]
        , W.GBs_Table
        , W.GBs_Indexes
        , CONVERT(decimal(05,02), (W.GBs_Table + W.GBs_Indexes) * 100.0 / @GBs) AS [Percent]
--      , (SELECT COUNT(*) FROM #More AS M WHERE M.GeneralID     = E.GeneralID                                               ) AS [Checks]
--      , (SELECT COUNT(*) FROM #Base AS A WHERE A.GeneralID     = E.GeneralID AND A.GeneralType       IN ('TR')
--                                                                             AND A.GeneralObject     NOT LIKE 'uspG[SIUD]%'
--                                                                             AND A.GeneralObject     NOT LIKE 'trgG[SIUD]%') AS [Triggers]
--      , (SELECT COUNT(*) FROM #Task AS T WHERE T.ReferenceOfID = E.GeneralID AND T.ReferenceByType   IN (      'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
--                                                                             AND T.ReferenceByObject NOT LIKE 'uspG[SIUD]%'
--                                                                             AND T.ReferenceByObject NOT LIKE 'trgG[SIUD]%') AS [References]
--   INTO SQLFacts.dbo.Fact_07
     FROM #Base AS E
LEFT JOIN #WKey AS W
       ON E.GeneralID
        = W.GeneralID
    WHERE E.GeneralType IN ('U ')
 ORDER BY W.Rows DESC
        , E.GeneralSchema
        , E.GeneralObject

-- SQLFacts <> 08 Partitions (Table)

PRINT '-- Fact 08 Partitions (Table)'

   SELECT '08' AS Fact
        , V.GeneralSchema
        , V.GeneralObject
        , V.SQLServerFile
        , V.SQLServerName
        , V.table_type
        , V.index_type
        , V.fill_factor AS Factor
        , V.[PS_Name]
        , V.[PF_Name]
        , V.GeneralColumn
        , V.SQLServerType
        , V.Boundary
        , V.[Partition]
        , V.[Rows]
        , V.[Compression]
--   INTO SQLFacts.dbo.Fact_08
     FROM #VKey AS V
    WHERE V.index_type     IN (0, 1, 5)
 ORDER BY V.GeneralSchema
        , V.GeneralObject
        , V.[Partition]

-- SQLFacts <> 09 Partitions (Index)

PRINT '-- Fact 09 Partitions (Index)'

   SELECT '09' AS Fact
        , E.GeneralSchema
        , E.GeneralObject
        , E.SQLServerFile
        , E.SQLServerName
        , E.table_type
        , E.index_type
        , E.fill_factor AS Factor
        , E.[PS_Name]
        , E.[PF_Name]
        , E.GeneralColumn
        , E.SQLServerType
        , E.Boundary
        , E.[Partition]
        , E.[Rows]
        , E.[Compression]
--   INTO SQLFacts.dbo.Fact_09
     FROM #VKey AS E
LEFT JOIN #VKey AS V
       ON E.GeneralID
        = V.GeneralID
      AND E.[PS_Name]
        = V.[PS_Name]
      AND V.index_type     IN (0, 1, 5)
    WHERE E.index_type NOT IN (0, 1, 5)
      AND V.index_type     IS NULL
    UNION
   SELECT '09' AS Fact
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerFile
        , Z.SQLServerName
        , Z.table_type
        , Z.index_type
        , Z.fill_factor AS Factor
        , NULL AS [PS_Name]
        , NULL AS [PF_Name]
        , NULL AS GeneralColumn
        , NULL AS SQLServerType
        , NULL AS Boundary
        , NULL AS [Partition]
        , NULL AS [Rows]
        , NULL AS [Compression]
     FROM #ZKey AS Z
     JOIN #VKey AS V
       ON Z.GeneralID
        = V.GeneralID
      AND Z.SQLServerFile
       != V.[PS_Name]
      AND V.index_type     IN (0, 1, 5)
    WHERE Z.index_type NOT IN (0, 1, 5)
      AND Z.index_column_id = 1
 ORDER BY   GeneralSchema
        ,   GeneralObject
        ,   index_type
        ,   SQLServerName
        ,   [Partition]

-- SQLFacts <> 10 Primary Keys

PRINT '-- Fact 10 Primary Keys'

   SELECT '10' AS Fact
        , P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerFile
        , P.SQLServerName
        , P.table_type
        , P.index_type
        , P.fill_factor AS Factor
        , 'PK' AS [Key]
        , MAX(CASE WHEN P.key_ordinal = 1 THEN   '[' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 2 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 3 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 4 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 5 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 6 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 7 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 8 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 9 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal > 9 THEN ', [...]'                                                                                         ELSE SPACE(0) END) AS GeneralColumn
--   INTO SQLFacts.dbo.Fact_10
     FROM #PKey AS P
    WHERE P.is_primary_key != 0
 GROUP BY P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerFile
        , P.SQLServerName
        , P.table_type
        , P.index_type
        , P.fill_factor
 ORDER BY P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerName

-- SQLFacts <> 11 Alternate Keys

PRINT '-- Fact 11 Alternate Keys'

   SELECT '11' AS Fact
        , P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerFile
        , P.SQLServerName
        , P.table_type
        , P.index_type
        , P.fill_factor AS Factor
        , 'AK' AS [Key]
        , MAX(CASE WHEN P.key_ordinal = 1 THEN   '[' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 2 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 3 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 4 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 5 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 6 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 7 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 8 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 9 THEN ', [' + P.GeneralColumn + ']' + CASE WHEN P.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal > 9 THEN ', [...]'                                                                                         ELSE SPACE(0) END) AS GeneralColumn
--   INTO SQLFacts.dbo.Fact_11
     FROM #PKey AS P
    WHERE P.is_unique_constraint != 0
 GROUP BY P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerFile
        , P.SQLServerName
        , P.table_type
        , P.index_type
        , P.fill_factor
 ORDER BY P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerName

-- SQLFacts <> 12 Indexes

PRINT '-- Fact 12 Indexes'

   SELECT Z.GeneralID
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerFile
        , Z.SQLServerName
        , Z.index_id
        , Z.table_type
        , Z.index_type
        , Z.fill_factor
        , Z.is_primary_key
        , Z.is_unique_constraint
        , Z.is_unique
        , Z.is_disabled
        , Z.GeneralFilter
        , COUNT(*) AS KeyColumns
        , MAX(CASE WHEN Z.regular_column_id =  1 THEN   '[' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  2 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  3 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  4 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  5 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  6 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  7 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  8 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id =  9 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 10 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 11 THEN   '[' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 12 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 13 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 14 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 15 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 16 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 17 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 18 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 19 THEN ', [' + Z.GeneralColumn + ']' + CASE WHEN Z.is_descending_key != 0 THEN ' DESC' ELSE SPACE(0) END ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id > 19 THEN ', [...]'                                                                                         ELSE SPACE(0) END) AS RegularColumn
        , MAX(CASE WHEN Z.include_column_id =  1 THEN   '[' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  2 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  3 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  4 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  5 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  6 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  7 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  8 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id =  9 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 10 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 11 THEN   '[' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 12 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 13 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 14 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 15 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 16 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 17 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 18 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id = 19 THEN ', [' + Z.GeneralColumn + ']'                                                                     ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.include_column_id > 19 THEN ', [...]'                                                                                         ELSE SPACE(0) END) AS IncludeColumn
     INTO #Hack
     FROM #ZKey AS Z
 GROUP BY Z.GeneralID
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerFile
        , Z.SQLServerName
        , Z.index_id
        , Z.table_type
        , Z.index_type
        , Z.fill_factor
        , Z.is_primary_key
        , Z.is_unique_constraint
        , Z.is_unique
        , Z.is_disabled
        , Z.GeneralFilter
 ORDER BY Z.GeneralSchema
        , Z.GeneralObject
        , Z.index_id

   SELECT '12' AS Fact
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerFile
        , Z.SQLServerName
        , Z.table_type
        , Z.index_type
        , Z.fill_factor AS Factor
        , Z.is_unique
        , Z.is_disabled
        , Z.RegularColumn
        , Z.IncludeColumn
        , Z.GeneralFilter
        , (SELECT SUM(P.rows) FROM sys.partitions AS P WHERE P.object_id = Z.GeneralID AND P.index_id = Z.index_id) AS [Rows]
--   INTO SQLFacts.dbo.Fact_12
     FROM #Hack AS Z
    WHERE CASE WHEN Z.is_primary_key       != 0 THEN 1
               WHEN Z.is_unique_constraint != 0 THEN 1 ELSE 0 END  = 0
 ORDER BY Z.GeneralSchema
        , Z.GeneralObject
        , CASE Z.index_type
          WHEN 0 THEN 0
          WHEN 1 THEN 0
          WHEN 5 THEN 0
          WHEN 2 THEN 1
          WHEN 6 THEN 2 ELSE 3 END
        , Z.SQLServerName

-- SQLFacts <> 13 Foreign Keys

PRINT '-- Fact 13 Foreign Keys'

   SELECT '13' AS Fact
        , F.PrimarySchema
        , F.PrimaryObject
        , MAX(CASE WHEN F.constraint_column_id = 1 THEN   '[' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 2 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 3 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 4 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 5 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 6 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 7 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 8 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 9 THEN ', [' + F.PrimaryColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id > 9 THEN ', [...]'                     ELSE SPACE(0) END) AS PrimaryColumn
        , F.SQLServerName
        , F.create_date
        , F.modify_date
        , F.is_disabled
        , F.is_not_trusted
        , F.ForeignSchema
        , F.ForeignObject
        , MAX(CASE WHEN F.constraint_column_id = 1 THEN   '[' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 2 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 3 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 4 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 5 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 6 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 7 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 8 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 9 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id > 9 THEN ', [...]'                     ELSE SPACE(0) END) AS ForeignColumn
--   INTO SQLFacts.dbo.Fact_13
     FROM #FKey AS F
 GROUP BY F.PrimarySchema
        , F.PrimaryObject
        , F.SQLServerName
        , F.create_date
        , F.modify_date
        , F.is_disabled
        , F.is_not_trusted
        , F.ForeignSchema
        , F.ForeignObject
 ORDER BY F.PrimarySchema
        , F.PrimaryObject
--      , F.SQLServerName
        , F.ForeignSchema
        , F.ForeignObject

-- SQLFacts <> 14 Check Constraints

PRINT '-- Fact 14 Check Constraints'

   SELECT '14' AS Fact
        , M.GeneralSchema
        , M.GeneralObject
        , M.SQLServerName
        , M.create_date
        , M.modify_date
        , M.is_disabled
        , M.is_not_trusted
        , M.SQLServerCode
--   INTO SQLFacts.dbo.Fact_14
     FROM #More AS M
 ORDER BY M.GeneralSchema
        , M.GeneralObject
        , M.SQLServerName

-- SQLFacts <> 15 Triggers

PRINT '-- Fact 15 Triggers'

   SELECT '15' AS Fact
        , E.GeneralSchema
        , E.GeneralObject
        , A.GeneralObject AS SQLServerName
        , A.create_date
        , A.modify_date
        , N.is_disabled
        , N.is_instead_of_trigger AS is_instead_of
        , CASE WHEN ISNULL(CONVERT(bit, OBJECTPROPERTY(A.GeneralID, 'ExecIsInsertTrigger')), 0) != 0 THEN 'INSERT' ELSE '' END AS [INSERT]
        , CASE WHEN ISNULL(CONVERT(bit, OBJECTPROPERTY(A.GeneralID, 'ExecIsUpdateTrigger')), 0) != 0 THEN 'UPDATE' ELSE '' END AS [UPDATE]
        , CASE WHEN ISNULL(CONVERT(bit, OBJECTPROPERTY(A.GeneralID, 'ExecIsDeleteTrigger')), 0) != 0 THEN 'DELETE' ELSE '' END AS [DELETE]
--   INTO SQLFacts.dbo.Fact_15
     FROM #Base AS E
     JOIN #Base AS A
       ON E.GeneralID
        = A.VariousID
     JOIN sys.triggers AS N
       ON A.GeneralID
        = N.object_id
    WHERE E.GeneralType IN ('U ')
      AND A.GeneralType IN ('TR')
      AND A.GeneralObject NOT LIKE 'uspG[SIUD]%'
      AND A.GeneralObject NOT LIKE 'trgG[SIUD]%'
 ORDER BY E.GeneralType
        , E.GeneralSchema
        , E.GeneralObject
        , A.GeneralObject

-- SQLFacts <> 16 Table Columns

PRINT '-- Fact 16 Table Columns'

   SELECT '16' AS Fact
        , T.GeneralType
        , T.GeneralSchema
        , T.GeneralObject
        , T.column_id
        , T.GeneralColumn
        , T.SQLServerType
        , T.collation_name
        , T.is_nullable
        , T.is_identity
        , T.[From]
        , T.[Plus]
        , T.[Used]
        , T.index_column_id AS PK_column_id
        , T.DefaultName
        , T.DefaultCode
        , T.FormulaCode
--   INTO SQLFacts.dbo.Fact_16
     FROM #TKeys AS T
    WHERE T.GeneralType IN ('U ')
 ORDER BY T.GeneralType
        , T.GeneralSchema
        , T.GeneralObject
        , T.column_id

-- SQLFacts <> 17 Routine Columns

PRINT '-- Fact 17 Routine Columns'

   SELECT '17' AS Fact
        , T.GeneralType
        , T.GeneralSchema
        , T.GeneralObject
        , T.column_id
        , T.GeneralColumn
        , T.SQLServerType
        , T.collation_name
        , T.is_nullable
--      , T.is_identity
--      , T.[From]
--      , T.[Plus]
--      , T.[Used]
--      , T.index_column_id AS PK_column_id
--      , T.DefaultName
--      , T.DefaultCode
--      , T.FormulaCode
--   INTO SQLFacts.dbo.Fact_17
     FROM #TKeys AS T
    WHERE T.GeneralType IN (      'V ', 'P ', 'FN', 'IF', 'TF')
 ORDER BY CASE T.GeneralType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , T.GeneralSchema
        , T.GeneralObject
        , T.column_id

-- SQLFacts <> 18 Routine Parameters

PRINT '-- Fact 18 Routine Parameters'

   SELECT '18' AS Fact
        , U.GeneralType
        , U.GeneralSchema
        , U.GeneralObject
        , U.parameter_id
        , U.GeneralColumn
        , U.SQLServerType
        , U.is_nullable
        , U.is_output
--   INTO SQLFacts.dbo.Fact_18
     FROM #UKeys AS U
    WHERE U.GeneralType IN (            'P ', 'FN', 'IF', 'TF')
      AND U.GeneralObject NOT LIKE 'uspG[SIUD]%'
      AND U.GeneralObject NOT LIKE 'trgG[SIUD]%'
 ORDER BY CASE U.GeneralType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , U.GeneralSchema
        , U.GeneralObject
        , U.parameter_id

-- SQLFacts <> 19 Table/Routine Permissions

PRINT '-- Fact 19 Table/Routine Permissions'

   SELECT '19' AS Fact
        , E.GeneralType
        , E.GeneralSchema
        , E.GeneralObject
        , ISNULL(T.GeneralColumn, SPACE(0)) AS GeneralColumn
        , R.DBRoleType
        , R.DBRoleName
        , R.DBUserType
        , R.DBUserName
        , R.DBAction
        , R.DBStatus
--   INTO SQLFacts.dbo.Fact_19
     FROM #Base AS E
     JOIN #RuleObject AS R
       ON E.GeneralID
        = R.GeneralID
LEFT JOIN #TKey AS T
       ON R.GeneralID
        = T.GeneralID
      AND R.column_id
        = T.column_id
 ORDER BY CASE E.GeneralType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , E.GeneralSchema
        , E.GeneralObject
        , R.column_id
        , R.DBRoleType
        , R.DBRoleName
        , R.DBUserType
        , R.DBUserName
        , R.DBAction

-- SQLFacts <> 20 Sequences

PRINT '-- Fact 20 Sequences'

   SELECT '20' AS Fact
        , O.type      AS GeneralType
        , S.name      AS GeneralSchema
        , O.name      AS GeneralObject
        , CONVERT(varchar(0040), O.create_date, 120) AS create_date
        , CONVERT(varchar(0040), O.modify_date, 120) AS modify_date
        , CONVERT(bigint, O.start_value  ) AS [From]
        , CONVERT(bigint, O.increment    ) AS [Plus]
        , CONVERT(bigint, O.current_value) AS [Used]
--   INTO SQLFacts.dbo.Fact_20
     FROM sys.schemas   AS S
     JOIN sys.sequences AS O -- SQL Server 2012 and newer
       ON S.schema_id
        = O.schema_id
--  WHERE O.type = 'SO'
 ORDER BY   GeneralType
        ,   GeneralSchema
        ,   GeneralObject

/*

   SELECT '20' AS Fact
        , O.type      AS GeneralType
        , S.name      AS GeneralSchema
        , O.name      AS GeneralObject
        , CONVERT(varchar(0040), O.create_date, 120) AS create_date
        , CONVERT(varchar(0040), O.modify_date, 120) AS modify_date
        , CONVERT(bigint, 0) AS [From]
        , CONVERT(bigint, 0) AS [Plus]
        , CONVERT(bigint, 0) AS [Used]
--   INTO SQLFacts.dbo.Fact_20
     FROM sys.schemas   AS S
     JOIN sys.objects   AS O -- less than SQL Server 2012
       ON S.schema_id
        = O.schema_id
    WHERE O.type = 'SO'
 ORDER BY   GeneralType
        ,   GeneralSchema
        ,   GeneralObject

*/

-- SQLFacts <> 21 Synonyms

PRINT '-- Fact 21 Synonyms'

   SELECT '21' AS Fact
        , O.type      AS GeneralType
        , S.name      AS GeneralSchema
        , O.name      AS GeneralObject
        , CONVERT(varchar(0040), O.create_date, 120) AS create_date
        , CONVERT(varchar(0040), O.modify_date, 120) AS modify_date
        , O.base_object_name  AS SQLServerPath
--   INTO SQLFacts.dbo.Fact_21
     FROM sys.schemas   AS S
     JOIN sys.synonyms  AS O
       ON S.schema_id
        = O.schema_id
--  WHERE O.type = 'SN'
 ORDER BY   GeneralType
        ,   GeneralSchema
        ,   GeneralObject

-- SQLFacts <> 22 External References

PRINT '-- Fact 22 External References'

   SELECT '22' AS Fact
        , O.type      AS GeneralType
        , S.name      AS GeneralSchema
        , O.name      AS GeneralObject
        , CONVERT(varchar(0040), O.create_date, 120) AS create_date
        , CONVERT(varchar(0040), O.modify_date, 120) AS modify_date
        , CASE WHEN D.referenced_server_name   IS NULL THEN SPACE(0) ELSE                                                                           '[' + D.referenced_server_name   + ']' END
        + CASE WHEN D.referenced_database_name IS NULL THEN SPACE(0) ELSE CASE WHEN D.referenced_server_name   IS NULL THEN SPACE(0) ELSE '.' END + '[' + D.referenced_database_name + ']' END
        + CASE WHEN D.referenced_schema_name   IS NULL THEN SPACE(0) ELSE CASE WHEN D.referenced_database_name IS NULL THEN SPACE(0) ELSE '.' END + '[' + D.referenced_schema_name   + ']' END
        + CASE WHEN D.referenced_entity_name   IS NULL THEN SPACE(0) ELSE CASE WHEN D.referenced_schema_name   IS NULL THEN SPACE(0) ELSE '.' END + '[' + D.referenced_entity_name   + ']' END AS SQLServerPath
--   INTO SQLFacts.dbo.Fact_22
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
     JOIN sys.sql_expression_dependencies AS D
       ON O.object_id
        = D.referencing_id
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('U ', 'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
      AND D.referenced_id IS NULL
 ORDER BY CASE O.type
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , GeneralSchema
        , GeneralObject
        , SQLServerPath

-- SQLFacts <> 23 Internal References, by object caller

PRINT '-- Fact 23 Internal References, by object caller'

   SELECT '23' AS Fact
        , T.ReferenceByType
        , T.ReferenceBySchema
        , T.ReferenceByObject
        , T.ReferenceOfType
        , T.ReferenceOfSchema
        , T.ReferenceOfObject
--   INTO SQLFacts.dbo.Fact_23
     FROM #Task AS T
    WHERE T.ReferenceByType IN (      'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
      AND T.ReferenceByObject NOT LIKE 'uspG[SIUD]%'
      AND T.ReferenceByObject NOT LIKE 'trgG[SIUD]%'
 ORDER BY CASE T.ReferenceByType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , T.ReferenceBySchema
        , T.ReferenceByObject
        , CASE T.ReferenceOfType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , T.ReferenceOfSchema
        , T.ReferenceOfObject

-- SQLFacts <> 24 Internal References, by object called

PRINT '-- Fact 24 Internal References, by object called'

   SELECT '24' AS Fact
        , T.ReferenceByType
        , T.ReferenceBySchema
        , T.ReferenceByObject
        , T.ReferenceOfType
        , T.ReferenceOfSchema
        , T.ReferenceOfObject
--   INTO SQLFacts.dbo.Fact_24
     FROM #Task AS T
    WHERE T.ReferenceByType IN (      'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
      AND T.ReferenceByObject NOT LIKE 'uspG[SIUD]%'
      AND T.ReferenceByObject NOT LIKE 'trgG[SIUD]%'
 ORDER BY CASE T.ReferenceOfType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , T.ReferenceOfSchema
        , T.ReferenceOfObject
        , CASE T.ReferenceByType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , T.ReferenceBySchema
        , T.ReferenceByObject

-- SQLFacts <> 25 Table Summary, by name

PRINT '-- Fact 25 Table Summary, by name'

   SELECT '25' AS Fact
        , E.GeneralType
        , E.GeneralSchema
        , E.GeneralObject
        , E.create_date
        , E.modify_date
        , P.Factor01 AS [Columns]
        , P.Factor02 AS [Indexes]
        , P.Factor03 AS [PKs_AKs]
        , P.Factor04 AS [Children]
        , P.Factor05 AS [ReferenceOf]
        , P.Estimate
        , P.Layer
--   INTO SQLFacts.dbo.Fact_25
     FROM #Base  AS E
LEFT JOIN #PKeys AS P
       ON E.GeneralID
        = P.GeneralID
    WHERE E.GeneralType IN ('U ')
 ORDER BY E.GeneralType
        , E.GeneralSchema
        , E.GeneralObject

-- SQLFacts <> 26 Table Summary, by layer

PRINT '-- Fact 26 Table Summary, by layer'

   SELECT '26' AS Fact
        , E.GeneralType
        , E.GeneralSchema
        , E.GeneralObject
        , E.create_date
        , E.modify_date
        , P.Factor01 AS [Columns]
        , P.Factor02 AS [Indexes]
        , P.Factor03 AS [PKs_AKs]
        , P.Factor04 AS [Children]
        , P.Factor05 AS [ReferenceOf]
        , P.Estimate
        , P.Layer
--   INTO SQLFacts.dbo.Fact_26
     FROM #Base  AS E
LEFT JOIN #PKeys AS P
       ON E.GeneralID
        = P.GeneralID
    WHERE E.GeneralType IN ('U ')
 ORDER BY P.Layer
        , E.GeneralType
        , E.GeneralSchema
        , E.GeneralObject

-- SQLFacts <> 27 Table Summary, by estimate

PRINT '-- Fact 27 Table Summary, by estimate'

   SELECT '27' AS Fact
        , E.GeneralType
        , E.GeneralSchema
        , E.GeneralObject
        , E.create_date
        , E.modify_date
        , P.Factor01 AS [Columns]
        , P.Factor02 AS [Indexes]
        , P.Factor03 AS [PKs_AKs]
        , P.Factor04 AS [Children]
        , P.Factor05 AS [ReferenceOf]
        , P.Estimate
        , P.Layer
--   INTO SQLFacts.dbo.Fact_27
     FROM #Base  AS E
LEFT JOIN #PKeys AS P
       ON E.GeneralID
        = P.GeneralID
    WHERE E.GeneralType IN ('U ')
 ORDER BY P.Estimate DESC
        , E.GeneralType
        , E.GeneralSchema
        , E.GeneralObject

-- SQLFacts <> 28 Routine Summary, by name

PRINT '-- Fact 28 Routine Summary, by name'

   SELECT '28' AS Fact
        , W.GeneralType
        , W.GeneralSchema
        , W.GeneralObject
        , E.create_date
        , E.modify_date
        , W.Factor01 AS [Columns]
        , W.Factor02 AS [Parameters]
        , W.Factor03 AS [KBs_SQL]
        , W.Factor04 AS [ReferenceBy]
        , W.Factor05 AS [ReferenceOf]
        , W.Estimate
        , W.Layer
--   INTO SQLFacts.dbo.Fact_28
     FROM #Base AS E
     JOIN #Work AS W
       ON E.GeneralID
        = W.GeneralID
    WHERE E.GeneralType IN (      'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
      AND E.GeneralObject NOT LIKE 'uspG[SIUD]%'
      AND E.GeneralObject NOT LIKE 'trgG[SIUD]%'
 ORDER BY CASE W.GeneralType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , W.GeneralSchema
        , W.GeneralObject

-- SQLFacts <> 29 Routine Summary, by layer

PRINT '-- Fact 29 Routine Summary, by layer'

   SELECT '29' AS Fact
        , W.GeneralType
        , W.GeneralSchema
        , W.GeneralObject
        , E.create_date
        , E.modify_date
        , W.Factor01 AS [Columns]
        , W.Factor02 AS [Parameters]
        , W.Factor03 AS [KBs_SQL]
        , W.Factor04 AS [ReferenceBy]
        , W.Factor05 AS [ReferenceOf]
        , W.Estimate
        , W.Layer
--   INTO SQLFacts.dbo.Fact_29
     FROM #Base AS E
     JOIN #Work AS W
       ON E.GeneralID
        = W.GeneralID
    WHERE E.GeneralType IN (      'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
      AND E.GeneralObject NOT LIKE 'uspG[SIUD]%'
      AND E.GeneralObject NOT LIKE 'trgG[SIUD]%'
 ORDER BY W.Layer
        , CASE W.GeneralType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , W.GeneralSchema
        , W.GeneralObject

-- SQLFacts <> 30 Routine Summary, by estimate

PRINT '-- Fact 30 Routine Summary, by estimate'

   SELECT '30' AS Fact
        , W.GeneralType
        , W.GeneralSchema
        , W.GeneralObject
        , E.create_date
        , E.modify_date
        , W.Factor01 AS [Columns]
        , W.Factor02 AS [Parameters]
        , W.Factor03 AS [KBs_SQL]
        , W.Factor04 AS [ReferenceBy]
        , W.Factor05 AS [ReferenceOf]
        , W.Estimate
        , W.Layer
--   INTO SQLFacts.dbo.Fact_30
     FROM #Base AS E
     JOIN #Work AS W
       ON E.GeneralID
        = W.GeneralID
    WHERE E.GeneralType IN (      'V ', 'P ', 'FN', 'IF', 'TF', 'TR')
      AND E.GeneralObject NOT LIKE 'uspG[SIUD]%'
      AND E.GeneralObject NOT LIKE 'trgG[SIUD]%'
 ORDER BY W.Estimate DESC
        , CASE W.GeneralType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , W.GeneralSchema
        , W.GeneralObject

-- SQLFacts <> 31 Data Type Analysis (Primary Keys)

PRINT '-- Fact 31 Data Type Analysis (Primary Keys)'

   SELECT '31' AS Fact
        , T.SQLServerType
        , T.is_identity
        , P.key_ordinal
        , COUNT(DISTINCT T.GeneralSchema + '.' + T.GeneralObject) AS [Objects]
        , COUNT(*)                                                AS [Columns]
--   INTO SQLFacts.dbo.Fact_31
     FROM #TKeys AS T
     JOIN #PKey  AS P
       ON T.GeneralID
        = P.GeneralID
      AND T.GeneralColumn
        = P.GeneralColumn
    WHERE P.is_primary_key != 0
 GROUP BY T.SQLServerType
        , T.is_identity
        , P.key_ordinal
 ORDER BY T.SQLServerType
        , T.is_identity
        , P.key_ordinal

-- SQLFacts <> 32 Data Type Analysis (Table Columns)

PRINT '-- Fact 32 Data Type Analysis (Table Columns)'

   SELECT '32' AS Fact
        , T.SQLServerType
        , T.is_nullable
        , T.is_computed
        , COUNT(DISTINCT T.GeneralSchema + '.' + T.GeneralObject) AS [Objects]
        , COUNT(*)                                                AS [Columns]
--   INTO SQLFacts.dbo.Fact_32
     FROM #TKeys AS T
    WHERE T.GeneralType IN ('U ')
 GROUP BY T.SQLServerType
        , T.is_nullable
        , T.is_computed
 ORDER BY T.SQLServerType
        , T.is_nullable
        , T.is_computed

-- SQLFacts <> 33 Data Type Analysis (Routine Parameters)

PRINT '-- Fact 33 Data Type Analysis (Routine Parameters)'

   SELECT '33' AS Fact
        , U.SQLServerType
        , U.is_nullable
        , U.is_output
        , COUNT(DISTINCT U.GeneralSchema + '.' + U.GeneralObject) AS [Objects]
        , COUNT(*)                                                AS [Parameters]
--   INTO SQLFacts.dbo.Fact_33
     FROM #UKeys AS U
    WHERE U.GeneralType IN (            'P ', 'FN', 'IF', 'TF')
      AND U.GeneralObject NOT LIKE 'uspG[SIUD]%'
      AND U.GeneralObject NOT LIKE 'trgG[SIUD]%'
 GROUP BY U.SQLServerType
        , U.is_nullable
        , U.is_output
 ORDER BY U.SQLServerType
        , U.is_nullable
        , U.is_output

-- SQLFacts <> 34 Name Analysis (Table Columns)

PRINT '-- Fact 34 Name Analysis (Table Columns)'

   SELECT '34' AS Fact
        , T.GeneralColumn                 AS [Column]
        , COUNT(DISTINCT T.SQLServerType) AS [Types]
        , COUNT(*)                        AS [Objects]
--   INTO SQLFacts.dbo.Fact_34
     FROM #TKeys AS T
    WHERE T.GeneralType IN ('U ')
 GROUP BY T.GeneralColumn
 ORDER BY T.GeneralColumn

-- SQLFacts <> 35 Name Analysis (Routine Parameters)

PRINT '-- Fact 35 Name Analysis (Routine Parameters)'

   SELECT '35' AS Fact
        , U.GeneralColumn                 AS [Parameter]
        , COUNT(DISTINCT U.SQLServerType) AS [Types]
        , COUNT(*)                        AS [Objects]
--   INTO SQLFacts.dbo.Fact_35
     FROM #UKeys AS U
    WHERE U.GeneralType IN (            'P ', 'FN', 'IF', 'TF')
      AND U.GeneralObject NOT LIKE 'uspG[SIUD]%'
      AND U.GeneralObject NOT LIKE 'trgG[SIUD]%'
 GROUP BY U.GeneralColumn
 ORDER BY U.GeneralColumn

-- SQLFacts <> 36 Foreign Keys To Consider

PRINT '-- Fact 36 Foreign Keys To Consider'

   SELECT '36' AS Fact
        , W.PrimarySchema
        , W.PrimaryObject
--      , W.SQLServerName
--      , W.PrimaryColumn
        , Z.ForeignSchema
        , Z.ForeignObject
        , Z.ForeignColumn
--   INTO SQLFacts.dbo.Fact_36
     FROM
  (SELECT P.GeneralID     AS PrimaryID
        , P.GeneralSchema AS PrimarySchema
        , P.GeneralObject AS PrimaryObject
        , P.SQLServerName
        , MAX(CASE WHEN P.key_ordinal = 1 THEN   '[' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 2 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 3 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 4 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 5 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 6 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 7 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 8 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 9 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal > 9 THEN ', [...]'                     ELSE SPACE(0) END) AS PrimaryColumn
     FROM #PKey AS P
    WHERE P.is_primary_key != 0
 GROUP BY P.GeneralID
        , P.GeneralSchema
        , P.GeneralObject
        , P.SQLServerName) AS W
     JOIN
  (SELECT T.GeneralID     AS ForeignID
        , T.GeneralSchema AS ForeignSchema
        , T.GeneralObject AS ForeignObject
        , P.GeneralID     AS PrimaryID
        , P.SQLServerName
        , MAX(CASE WHEN P.key_ordinal = 1 THEN   '[' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 2 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 3 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 4 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 5 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 6 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 7 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 8 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal = 9 THEN ', [' + P.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN P.key_ordinal > 9 THEN ', [...]'                     ELSE SPACE(0) END) AS ForeignColumn
     FROM #PKey AS P
     JOIN #TKey AS T
       ON P.GeneralColumn
        = T.GeneralColumn
    WHERE P.GeneralID
       != T.GeneralID
      AND T.GeneralType = 'U '
 GROUP BY P.GeneralID
        , T.GeneralID
        , T.GeneralSchema
        , T.GeneralObject
        , P.GeneralID
        , P.SQLServerName) AS Z
       ON W.PrimaryID
        = Z.PrimaryID
      AND W.SQLServerName
        = Z.SQLServerName
      AND W.PrimaryColumn
        = Z.ForeignColumn
LEFT JOIN
  (SELECT F.PrimaryID
        , F.ForeignID
     FROM #FKey AS F
 GROUP BY F.PrimaryID
        , F.ForeignID) AS T
       ON Z.PrimaryID
        = T.PrimaryID
      AND Z.ForeignID
        = T.ForeignID
    WHERE T.PrimaryID IS NULL
 ORDER BY Z.ForeignSchema
        , Z.ForeignObject
        , Z.ForeignColumn

-- SQLFacts <> 37 Foreign Key Indexes

PRINT '-- Fact 37 Foreign Key Indexes'

   SELECT '37' AS Fact
        , A.PrimarySchema
        , A.PrimaryObject
--      , A.SQLServerName
        , A.ForeignSchema
        , A.ForeignObject
        , A.ForeignColumn
        , U.SQLServerName
        , U.RegularColumn
--   INTO SQLFacts.dbo.Fact_37
     FROM
  (SELECT F.PrimaryID
        , F.PrimarySchema
        , F.PrimaryObject
        , F.SQLServerName
        , F.ForeignID
        , F.ForeignSchema
        , F.ForeignObject
        , MAX(CASE WHEN F.constraint_column_id = 1 THEN   '[' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 2 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 3 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 4 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 5 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 6 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 7 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 8 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id = 9 THEN ', [' + F.ForeignColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN F.constraint_column_id > 9 THEN ', [...]'                     ELSE SPACE(0) END) AS ForeignColumn
     FROM #FKey AS F
 GROUP BY F.PrimaryID
        , F.PrimarySchema
        , F.PrimaryObject
        , F.SQLServerName
        , F.ForeignID
        , F.ForeignSchema
        , F.ForeignObject) AS A
LEFT JOIN
  (SELECT Z.GeneralID
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerName
        , MAX(CASE WHEN Z.regular_column_id = 1 THEN   '[' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 2 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 3 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 4 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 5 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 6 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 7 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 8 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id = 9 THEN ', [' + Z.GeneralColumn + ']' ELSE SPACE(0) END)
        + MAX(CASE WHEN Z.regular_column_id > 9 THEN ', [...]'                     ELSE SPACE(0) END) AS RegularColumn
     FROM #ZKey AS Z
    WHERE Z.GeneralFilter = SPACE(0)
 GROUP BY Z.GeneralID
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerName) AS U
       ON A.ForeignID
        = U.GeneralID
      AND REPLACE(REPLACE(U.RegularColumn, '[', '<'), ']', '>')
     LIKE REPLACE(REPLACE(A.ForeignColumn, '[', '<'), ']', '>') + '%'
 ORDER BY A.ForeignSchema
        , A.ForeignObject
        , A.ForeignColumn
        , U.RegularColumn DESC

-- SQLFacts <> 38 Index Redundancy

PRINT '-- Fact 38 Index Redundancy'

/*

   SELECT Z.GeneralSchema
        , Z.GeneralObject
--      , Z.SQLServerFile
        , Z.SQLServerName
        , Z.RegularColumn
        , Z.IncludeColumn
--      , W.SQLServerFile AS SQLServerFile_
        , W.SQLServerName AS SQLServerName_
        , W.RegularColumn AS RegularColumn_
        , W.IncludeColumn AS IncludeColumn_
     FROM #Hack AS Z
     JOIN #Hack AS W
       ON Z.GeneralSchema
        = W.GeneralSchema
      AND Z.GeneralObject
        = W.GeneralObject
      AND Z.GeneralFilter
        = W.GeneralFilter
      AND Z.SQLServerName
       != W.SQLServerName
    WHERE W.index_type IN (1, 2)
      AND REPLACE(REPLACE(Z.RegularColumn, '[', '<'), ']', '>')
     LIKE REPLACE(REPLACE(W.RegularColumn, '[', '<'), ']', '>') + '%'
      AND CASE WHEN Z.RegularColumn > W.RegularColumn THEN 1
               WHEN Z.RegularColumn = W.RegularColumn
                AND Z.IncludeColumn > W.IncludeColumn THEN 1
               WHEN Z.RegularColumn = W.RegularColumn
                AND Z.IncludeColumn = W.IncludeColumn
                AND Z.SQLServerName < W.SQLServerName THEN 1 ELSE 0 END != 0
 ORDER BY Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerName
        , W.SQLServerName

*/

   SELECT '38' AS Fact
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerName
        , Z.table_type
        , Z.index_type
        , Z.RegularColumn
        , Z.IncludeColumn
--      , Z.GeneralFilter
--      , Z.SQLServerFile
--      , Z.fill_factor AS Factor
        , Z.is_primary_key
        , Z.is_unique_constraint
        , Z.is_unique
        , Z.is_disabled
        , ROW_NUMBER() OVER (ORDER BY Z.GeneralSchema, Z.GeneralObject, Z.index_type, W.index_type, Z.SQLServerName, W.SQLServerName) AS Redundancy
--   INTO SQLFacts.dbo.Fact_38
     FROM #Hack AS Z
     JOIN #Hack AS W
       ON Z.GeneralSchema
        = W.GeneralSchema
      AND Z.GeneralObject
        = W.GeneralObject
      AND Z.GeneralFilter
        = W.GeneralFilter
      AND Z.SQLServerName
       != W.SQLServerName
    WHERE W.index_type IN (1, 2)
      AND REPLACE(REPLACE(Z.RegularColumn, '[', '<'), ']', '>')
     LIKE REPLACE(REPLACE(W.RegularColumn, '[', '<'), ']', '>') + '%'
      AND CASE WHEN Z.RegularColumn > W.RegularColumn THEN 1
               WHEN Z.RegularColumn = W.RegularColumn
                AND Z.IncludeColumn > W.IncludeColumn THEN 1
               WHEN Z.RegularColumn = W.RegularColumn
                AND Z.IncludeColumn = W.IncludeColumn
                AND Z.SQLServerName < W.SQLServerName THEN 1 ELSE 0 END != 0
    UNION ALL
   SELECT '38' AS Fact
        , Z.GeneralSchema
        , Z.GeneralObject
        , W.SQLServerName
        , W.table_type
        , W.index_type
        , W.RegularColumn
        , W.IncludeColumn
--      , W.GeneralFilter
--      , W.SQLServerFile
--      , W.fill_factor AS Factor
        , W.is_primary_key
        , W.is_unique_constraint
        , W.is_unique
        , W.is_disabled
        , ROW_NUMBER() OVER (ORDER BY Z.GeneralSchema, Z.GeneralObject, Z.index_type, W.index_type, Z.SQLServerName, W.SQLServerName) AS Redundancy
     FROM #Hack AS Z
     JOIN #Hack AS W
       ON Z.GeneralSchema
        = W.GeneralSchema
      AND Z.GeneralObject
        = W.GeneralObject
      AND Z.GeneralFilter
        = W.GeneralFilter
      AND Z.SQLServerName
       != W.SQLServerName
    WHERE W.index_type IN (1, 2)
      AND REPLACE(REPLACE(Z.RegularColumn, '[', '<'), ']', '>')
     LIKE REPLACE(REPLACE(W.RegularColumn, '[', '<'), ']', '>') + '%'
      AND CASE WHEN Z.RegularColumn > W.RegularColumn THEN 1
               WHEN Z.RegularColumn = W.RegularColumn
                AND Z.IncludeColumn > W.IncludeColumn THEN 1
               WHEN Z.RegularColumn = W.RegularColumn
                AND Z.IncludeColumn = W.IncludeColumn
                AND Z.SQLServerName < W.SQLServerName THEN 1 ELSE 0 END != 0
 ORDER BY   Redundancy
        ,   RegularColumn DESC
        ,   IncludeColumn DESC
        ,   index_type
        ,   SQLServerName

-- SQLFacts <> 39 Questionable Indexes

PRINT '-- Fact 39 Questionable Indexes'

   SELECT '39' AS Fact
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerName
        , Z.table_type
        , Z.index_type
        , Z.GeneralColumn
        , Z.SQLServerType
        , CASE WHEN Z.name =             'char' AND Z.max_length > 24 THEN 'long string indexing key'
               WHEN Z.name =            'nchar' AND Z.max_length > 16 THEN 'long string indexing key'
               WHEN Z.name =          'varchar' AND Z.max_length > 30 THEN 'long string indexing key'
               WHEN Z.name =         'nvarchar' AND Z.max_length > 20 THEN 'long string indexing key'
               WHEN Z.name = 'uniqueidentifier' AND Z.index_type =  1 THEN 'GUID type clustering key' ELSE SPACE(0) END AS Question
--   INTO SQLFacts.dbo.Fact_39
     FROM #ZKeys AS Z
    WHERE Z.include_column_id = 0
      AND CASE WHEN Z.name =             'char' AND Z.max_length > 24 THEN 1
               WHEN Z.name =            'nchar' AND Z.max_length > 16 THEN 1
               WHEN Z.name =          'varchar' AND Z.max_length > 30 THEN 1
               WHEN Z.name =         'nvarchar' AND Z.max_length > 20 THEN 1
               WHEN Z.name = 'uniqueidentifier' AND Z.index_type =  1 THEN 1 ELSE 0 END != 0
    UNION
   SELECT '39' AS Fact
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.SQLServerName
        , Z.table_type
        , Z.index_type
        , Z.RegularColumn AS GeneralColumn
        , Z.IncludeColumn AS SQLServerType
        , CASE WHEN Z.fill_factor BETWEEN 1 AND 69          THEN 'markedly low fill factor'
               WHEN Z.is_disabled != 0                      THEN 'disabled (blocked) index'
               WHEN Z.index_type   = 1 AND Z.KeyColumns > 2 THEN '3+ column clustering key' ELSE SPACE(0) END AS Question
     FROM #Hack AS Z
    WHERE CASE WHEN Z.fill_factor BETWEEN 1 AND 69          THEN 1
               WHEN Z.is_disabled != 0                      THEN 1
               WHEN Z.index_type   = 1 AND Z.KeyColumns > 2 THEN 1 ELSE 0 END != 0
 ORDER BY   GeneralSchema
        ,   GeneralObject
        ,   SQLServerName
        ,   GeneralColumn
        ,   Question

-- SQLFacts <> 40 Questionable Tables

PRINT '-- Fact 40 Questionable Tables'

   SELECT '40' AS Fact
        , E.GeneralSchema
        , E.GeneralObject
        , W.SQLServerFile
        , E.create_date
        , E.modify_date
        , (SELECT COUNT(*) FROM #PKey AS P WHERE P.GeneralID = E.GeneralID AND P.is_primary_key       != 0 AND P.key_ordinal          = 1) AS [PKs]
--      , (SELECT COUNT(*) FROM #PKey AS P WHERE P.GeneralID = E.GeneralID AND P.is_unique_constraint != 0 AND P.key_ordinal          = 1) AS [AKs]
--      , (SELECT COUNT(*) FROM #FKey AS F WHERE F.ForeignID = E.GeneralID                                 AND F.constraint_column_id = 1) AS [FKs_P]
--      , (SELECT COUNT(*) FROM #FKey AS F WHERE F.PrimaryID = E.GeneralID                                 AND F.constraint_column_id = 1) AS [FKs_C]
--      , (SELECT COUNT(*) FROM #TKey AS T WHERE T.GeneralID = E.GeneralID                                                               ) AS [Columns]
        , W.[Rows]
        , W.[table_type]
        , W.[Indexes]
        , CASE WHEN (SELECT COUNT(*) FROM #PKey AS P WHERE P.GeneralID = E.GeneralID AND P.is_primary_key       != 0 AND P.key_ordinal          = 1) = 0 THEN 'no PK'
--             WHEN (SELECT COUNT(*) FROM #PKey AS P WHERE P.GeneralID = E.GeneralID AND P.is_unique_constraint != 0 AND P.key_ordinal          = 1) = 0 THEN 'no AK'
--             WHEN (SELECT COUNT(*) FROM #FKey AS F WHERE F.ForeignID = E.GeneralID                                 AND F.constraint_column_id = 1) = 0 THEN 'no FKs_P'
--             WHEN (SELECT COUNT(*) FROM #FKey AS F WHERE F.PrimaryID = E.GeneralID                                 AND F.constraint_column_id = 1) = 0 THEN 'no FKs_C'
--             WHEN (SELECT COUNT(*) FROM #TKey AS T WHERE T.GeneralID = E.GeneralID                                                               ) < 2 THEN 'one column'
               WHEN W.[Rows]  =      0                                                                                                                   THEN 'no rows'
               WHEN W.[Rows] !< 100000 AND W.[table_type] = 0 AND W.[Indexes] = 0                                                                        THEN 'no indexes' ELSE SPACE(0) END AS Question
--   INTO SQLFacts.dbo.Fact_40
     FROM #Base AS E
LEFT JOIN #WKey AS W
       ON E.GeneralID
        = W.GeneralID
    WHERE E.GeneralType IN ('U ')
      AND CASE WHEN (SELECT COUNT(*) FROM #PKey AS P WHERE P.GeneralID = E.GeneralID AND P.is_primary_key       != 0 AND P.key_ordinal          = 1) = 0 THEN 1
--             WHEN (SELECT COUNT(*) FROM #PKey AS P WHERE P.GeneralID = E.GeneralID AND P.is_unique_constraint != 0 AND P.key_ordinal          = 1) = 0 THEN 1
--             WHEN (SELECT COUNT(*) FROM #FKey AS F WHERE F.ForeignID = E.GeneralID                                 AND F.constraint_column_id = 1) = 0 THEN 1
--             WHEN (SELECT COUNT(*) FROM #FKey AS F WHERE F.PrimaryID = E.GeneralID                                 AND F.constraint_column_id = 1) = 0 THEN 1
--             WHEN (SELECT COUNT(*) FROM #TKey AS T WHERE T.GeneralID = E.GeneralID                                                               ) < 2 THEN 1
               WHEN W.[Rows]  =      0                                                                                                                   THEN 1
               WHEN W.[Rows] !< 100000 AND W.[table_type] = 0 AND W.[Indexes] = 0                                                                        THEN 1 ELSE 0 END != 0
 ORDER BY E.GeneralSchema
        , E.GeneralObject

-- SQLFacts <> 41 Questionable Foreign Keys

PRINT '-- Fact 41 Questionable Foreign Keys'

   SELECT '41' AS Fact
        , F.ForeignSchema AS GeneralSchema
        , F.ForeignObject AS GeneralObject
        , F.SQLServerName
        , F.create_date
        , F.modify_date
        , F.is_disabled
        , F.is_not_trusted
        , CASE WHEN F.is_disabled  = 0 AND F.is_not_trusted != 0 THEN 'untrusted FK constraint'
               WHEN F.is_disabled != 0 AND F.is_not_trusted  = 0 THEN  'disabled FK constraint'
               WHEN F.is_disabled != 0 AND F.is_not_trusted != 0 THEN  'disabled FK constraint' ELSE SPACE(0) END AS Question
--   INTO SQLFacts.dbo.Fact_41
     FROM #FKey AS F
    WHERE CASE WHEN F.is_disabled  = 0 AND F.is_not_trusted != 0 THEN 1
               WHEN F.is_disabled != 0 AND F.is_not_trusted  = 0 THEN 1
               WHEN F.is_disabled != 0 AND F.is_not_trusted != 0 THEN 1 ELSE 0 END != 0
      AND F.constraint_column_id = 1
 ORDER BY   GeneralSchema
        ,   GeneralObject
        ,   SQLServerName

-- SQLFacts <> 42 Questionable Constraints

PRINT '-- Fact 42 Questionable Constraints'

   SELECT '42' AS Fact
        , M.GeneralSchema
        , M.GeneralObject
        , M.SQLServerName
        , M.create_date
        , M.modify_date
        , M.is_disabled
        , M.is_not_trusted
        , CASE WHEN M.is_disabled  = 0 AND M.is_not_trusted != 0 THEN 'untrusted check constraint'
               WHEN M.is_disabled != 0 AND M.is_not_trusted  = 0 THEN  'disabled check constraint'
               WHEN M.is_disabled != 0 AND M.is_not_trusted != 0 THEN  'disabled check constraint' ELSE SPACE(0) END AS Question
--   INTO SQLFacts.dbo.Fact_42
     FROM #More AS M
    WHERE CASE WHEN M.is_disabled  = 0 AND M.is_not_trusted != 0 THEN 1
               WHEN M.is_disabled != 0 AND M.is_not_trusted  = 0 THEN 1
               WHEN M.is_disabled != 0 AND M.is_not_trusted != 0 THEN 1 ELSE 0 END != 0
 ORDER BY   GeneralSchema
        ,   GeneralObject
        ,   SQLServerName

-- SQLFacts <> 43 Questionable Defaults

PRINT '-- Fact 43 Questionable Defaults'

   SELECT '43' AS Fact
        , S.name AS DefaultSchema
        , O.name AS DefaultObject
        , CONVERT(varchar(0040), O.create_date, 120) AS create_date
        , CONVERT(varchar(0040), O.modify_date, 120) AS modify_date
        , W.type AS GeneralType
        , Z.name AS GeneralSchema
        , W.name AS GeneralObject
        , C.name AS GeneralColumn
        , 'obsolete feature' AS Question
--   INTO SQLFacts.dbo.Fact_43
     FROM sys.schemas AS S
     JOIN sys.objects AS O
       ON S.schema_id
        = O.schema_id
LEFT JOIN sys.columns AS C
       ON         O.object_id
        = C.default_object_id
LEFT JOIN sys.objects AS W
       ON C.object_id
        = W.object_id
LEFT JOIN sys.schemas AS Z
       ON W.schema_id
        = Z.schema_id
      AND Z.name IN (SELECT [Schema] FROM @Match)
    WHERE S.name IN (SELECT [Schema] FROM @Match)
      AND O.type IN ('D ')
      AND ISNULL(O.parent_object_id, 0) = 0
 ORDER BY   DefaultSchema
        ,   DefaultObject
        ,   GeneralSchema
        ,   GeneralObject
        ,   GeneralColumn

-- SQLFacts <> 44 Questionable Routines

PRINT '-- Fact 44 Questionable Routines'

   SELECT '44' AS Fact
        , E.GeneralType
        , E.GeneralSchema
        , E.GeneralObject
--      , E.create_date
--      , E.modify_date
        , LEN(E.SQLServerCode) AS SQLCodeSize
        , V.[Reason]           AS Question
--   INTO SQLFacts.dbo.Fact_44
     FROM #Base  AS E
     JOIN @Alert AS V
       ON E.SQLServerCode LIKE V.[Search]
 ORDER BY CASE E.GeneralType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , E.GeneralSchema
        , E.GeneralObject
        , V.AlertID

-- SQLFacts <> 45 Questionable Data Types

PRINT '-- Fact 45 Questionable Data Types'

   SELECT '45' AS Fact
        , T.GeneralType
        , T.GeneralSchema
        , T.GeneralObject
        , T.column_id
        , T.index_column_id AS PK_column_id
        , T.GeneralColumn
        , T.SQLServerType
        , CASE WHEN T.name =        'char' AND T.max_length > 16                      THEN 'long fixed storage'
               WHEN T.name =       'nchar' AND T.max_length > 16                      THEN 'long fixed storage'
               WHEN T.name =     'varchar' AND T.max_length >  0 AND T.max_length < 4 THEN 'short varying size'
               WHEN T.name =    'nvarchar' AND T.max_length >  0 AND T.max_length < 4 THEN 'short varying size'
               WHEN T.name =        'text'                                            THEN 'obsolete data type'
               WHEN T.name =       'ntext'                                            THEN 'obsolete data type'
               WHEN T.name =       'image'                                            THEN 'obsolete data type'
               WHEN T.name = 'sql_variant'                                            THEN 'variable data type'
               WHEN T.collation_name != SPACE(0) AND T.collation_name !=   SERVERPROPERTY  (           'Collation') THEN 'collation mismatch'
               WHEN T.collation_name != SPACE(0) AND T.collation_name != DATABASEPROPERTYEX(DB_NAME(), 'Collation') THEN 'collation mismatch' ELSE SPACE(0) END AS Question
--   INTO SQLFacts.dbo.Fact_45
     FROM #TKeys AS T
    WHERE T.GeneralType IN ('U ')
      AND CASE WHEN T.name =        'char' AND T.max_length > 16                      THEN 1
               WHEN T.name =       'nchar' AND T.max_length > 16                      THEN 1
               WHEN T.name =     'varchar' AND T.max_length >  0 AND T.max_length < 4 THEN 1
               WHEN T.name =    'nvarchar' AND T.max_length >  0 AND T.max_length < 4 THEN 1
               WHEN T.name =        'text'                                            THEN 1
               WHEN T.name =       'ntext'                                            THEN 1
               WHEN T.name =       'image'                                            THEN 1
               WHEN T.name = 'sql_variant'                                            THEN 1
               WHEN T.collation_name != SPACE(0) AND T.collation_name !=   SERVERPROPERTY  (           'Collation') THEN 1
               WHEN T.collation_name != SPACE(0) AND T.collation_name != DATABASEPROPERTYEX(DB_NAME(), 'Collation') THEN 1 ELSE 0 END != 0
 ORDER BY T.GeneralSchema
        , T.GeneralObject
        , T.column_id

-- SQLFacts <> 46 Questionable Names

PRINT '-- Fact 46 Questionable Names'

   SELECT Z.Fact
        , Z.GeneralType
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.GeneralColumn
--   INTO SQLFacts.dbo.Fact_46
     FROM
  (SELECT '46' AS Fact
        , T.GeneralType
        , T.GeneralSchema
        , T.GeneralObject
        , T.GeneralColumn
        , T.column_id
     FROM #TKey AS T
    WHERE CASE WHEN T.GeneralColumn = 'ID'                 THEN 1
               WHEN T.GeneralColumn LIKE '[^A-Z]%'         THEN 1
               WHEN T.GeneralColumn LIKE '%[^A-Z0-9_@#$]%' THEN 1 ELSE 0 END != 0
    UNION
   SELECT '46' AS Fact
        , E.GeneralType
        , E.GeneralSchema
        , E.GeneralObject
        , SPACE(0) AS GeneralColumn
        ,       0  AS column_id
     FROM #Base AS E
    WHERE CASE WHEN E.GeneralObject LIKE 'sp[_]%'          THEN 1
               WHEN E.GeneralObject LIKE '[^A-Z]%'         THEN 1
               WHEN E.GeneralObject LIKE '%[^A-Z0-9_@#$]%' THEN 1 ELSE 0 END != 0) AS Z
 ORDER BY CASE Z.GeneralType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , Z.GeneralSchema
        , Z.GeneralObject
        , Z.column_id

-- SQLFacts <> 47 Questionable Parameters

PRINT '-- Fact 47 Questionable Parameters'

   SELECT '47' AS Fact
        , U.GeneralType
        , U.GeneralSchema
        , U.GeneralObject
        , U.parameter_id
        , U.GeneralColumn
        , U.SQLServerType
        , T.GeneralType   AS GeneralType_
        , T.GeneralSchema AS GeneralSchema_
        , T.GeneralObject AS GeneralObject_
        , T.column_id
        , T.GeneralColumn AS GeneralColumn_
        , T.SQLServerType AS SQLServerType_
--   INTO SQLFacts.dbo.Fact_47
     FROM #UKeys AS U
     JOIN #Task  AS V
       ON U.GeneralID
        = V.ReferenceByID
     JOIN #TKeys AS T
       ON V.ReferenceOfID
        = T.GeneralID
      AND SUBSTRING(U.GeneralColumn, 002, 128)
        =           T.GeneralColumn
    WHERE U.GeneralType IN (            'P ', 'FN', 'IF', 'TF')
      AND U.GeneralObject NOT LIKE 'uspG[SIUD]%'
      AND U.GeneralObject NOT LIKE 'trgG[SIUD]%'
      AND U.SQLServerType
       != T.SQLServerType
 ORDER BY CASE U.GeneralType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , U.GeneralSchema
        , U.GeneralObject
        , U.parameter_id

-- SQLFacts <> 48 Questionable References

PRINT '-- Fact 48 Questionable References'

   SELECT '48' AS Fact
        , T.ReferenceByType
        , T.ReferenceBySchema
        , T.ReferenceByObject
        , T.ReferenceOfType
        , T.ReferenceOfSchema
        , T.ReferenceOfObject
--   INTO SQLFacts.dbo.Fact_48
     FROM #Task AS T
    WHERE CASE WHEN T.ReferenceByType = 'V ' AND T.ReferenceOfType IN (      'V ', 'IF', 'TF') THEN 1
               WHEN T.ReferenceByType = 'IF' AND T.ReferenceOfType IN (      'V ', 'IF', 'TF') THEN 1
               WHEN T.ReferenceByType = 'TF' AND T.ReferenceOfType IN (      'V ', 'IF', 'TF') THEN 1
               WHEN T.ReferenceByType = 'TR' AND T.ReferenceOfType IN ('P ', 'V ', 'IF', 'TF') THEN 1
               WHEN T.ReferenceByType = 'FN'                                                   THEN 1 ELSE 0 END != 0
 ORDER BY CASE T.ReferenceByType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , T.ReferenceBySchema
        , T.ReferenceByObject
        , CASE T.ReferenceOfType
          WHEN 'U ' THEN 1
          WHEN 'V ' THEN 2
          WHEN 'P ' THEN 3
          WHEN 'FN' THEN 4
          WHEN 'IF' THEN 5
          WHEN 'TF' THEN 6
          WHEN 'TR' THEN 7 ELSE 8 END
        , T.ReferenceOfSchema
        , T.ReferenceOfObject

DROP TABLE #Base

DROP TABLE #More

DROP TABLE #RoleDBUser

DROP TABLE #RuleSchema

DROP TABLE #RuleObject

DROP TABLE #Work

DROP TABLE #Task

DROP TABLE #PKey
DROP TABLE #PKeys

DROP TABLE #FKey
DROP TABLE #FKeys

DROP TABLE #ZKey
DROP TABLE #ZKeys

DROP TABLE #TKey
DROP TABLE #TKeys

DROP TABLE #UKey
DROP TABLE #UKeys

DROP TABLE #VKey

DROP TABLE #WKey

DROP TABLE #Hack

SET NOCOUNT OFF

