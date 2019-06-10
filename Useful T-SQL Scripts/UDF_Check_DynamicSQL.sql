/*
***************************************************************************
Database    : 
Name        : dbo.USP_Check_DynamicSQL
Purpose     : This scalar user defined function gets an input SQL string
              to check and then outputs an error message if the SQL string
              check returns an error or returns OK if the SQL string's
              check passed successfully.
Used By     : 
Author      : Eli Leiba
Source      : https://www.mssqltips.com/sqlservertip/4981/sql-server-function-to-check-dynamic-sql-syntax/
Created     : 2017-06-01
Usage       : SELECT dbo.UDF_Check_DynamicSQL ('SELECT *, FROM Orders');
***************************************************************************
Change History
***************************************************************************
Name               Date               Reason for modification
---------------    -----------        -----------------------
Raghu C            2017-08-15         1. Changed the Function Name.
                                      2. Increased the VARCHAR size to 8K & MAX.
**************************************************************************/
CREATE FUNCTION dbo.UDF_Check_DynamicSQL (@p1 VARCHAR (MAX))
RETURNS VARCHAR (8000)
AS
BEGIN

   DECLARE @Result VARCHAR (8000);

   IF EXISTS (SELECT 1
                FROM sys.dm_exec_describe_first_result_set (@p1, NULL, 0)
               WHERE error_message IS NOT NULL
                 AND error_number IS NOT NULL
                 AND error_severity IS NOT NULL
                 AND error_state IS NOT NULL
                 AND error_type IS NOT NULL
                 AND error_type_desc IS NOT NULL
             )
        BEGIN
             SELECT @Result = error_message
               FROM sys.dm_exec_describe_first_result_set(@p1, NULL, 0)
              WHERE column_ordinal = 0
        END
   ELSE
        SET @Result = 'OK';

   RETURN (@Result);
END