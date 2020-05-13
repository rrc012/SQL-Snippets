/*
 ===============================================================================
 Author:	     Unknown
 Source:       https://dzone.com/articles/query-get-all-datails
 Article Name: Query To Get All The Details For Transaction Locks In Sql Server
 Create Date:  28-JAN-2012
 Description:  This query gets all the details for transaction locks in sql server.
 ===============================================================================
*/

SET NOCOUNT ON
GO

SELECT L.request_session_id AS SPID, 
       DB_NAME(L.resource_database_id) AS DatabaseName,
       O.Name AS LockedObjectName, 
       P.object_id AS LockedObjectId, 
       L.resource_type AS LockedResource, 
       L.request_mode AS LockType,
       ST.text AS SqlStatementText,        
       ES.login_name AS LoginName,
       ES.host_name AS HostName,
       TST.is_user_transaction as IsUserTransaction,
       ACT.name AS TransactionName,
       CN.auth_scheme AS AuthenticationMethod
  FROM sys.dm_tran_locks AS L
       INNER JOIN sys.partitions AS P ON P.hobt_id = L.resource_associated_entity_id
       INNER JOIN sys.objects AS O ON O.object_id = P.object_id
       INNER JOIN sys.dm_exec_sessions AS ES ON ES.session_id = L.request_session_id
       INNER JOIN sys.dm_tran_session_transactions AS TST ON ES.session_id = TST.session_id
       INNER JOIN sys.dm_tran_active_transactions AS ACT ON TST.transaction_id = ACT.transaction_id
       INNER JOIN sys.dm_exec_connections AS CN ON CN.session_id = ES.session_id
       CROSS APPLY sys.dm_exec_sql_text(CN.most_recent_sql_handle) AS ST
 WHERE resource_database_id = DB_ID()
 ORDER BY L.request_session_id;