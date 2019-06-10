-- =============================================
-- Author:		<Suvendu>
-- Description:	<Gets last name from supplied full name>
-- URL: http://beyondrelational.com/justlearned/posts/822/get-last-name-from-existing-full-name-using-udf-in-sql-server.aspx
-- =============================================
CREATE FUNCTION [dbo].[GetLastName]
(
	@FullName NVARCHAR(60)
)
RETURNS NVARCHAR(30)
AS
BEGIN
	DECLARE @LastName NVARCHAR(30);
	SELECT @LastName = RIGHT(@FullName, ISNULL(NULLIF(CHARINDEX(' ', REVERSE(@FullName))-1, -1),LEN(@FullName)));
	RETURN @LastName;
END
GO

--SELECT dbo.GetLastName ('Raghunadan Raju S Cumbakonam')