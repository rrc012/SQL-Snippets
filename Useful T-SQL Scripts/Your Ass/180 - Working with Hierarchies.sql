USE
	YourAss;
GO


SET STATISTICS IO ON;
GO


EXECUTE Operation.usp_GetReferralTree
	@inMemberId = 12;
GO


-- Create a non-clustered index on the "ReferringMemberId" column

CREATE NONCLUSTERED INDEX
	ix_Members_nc_nu_ReferringMemberId
ON
	Operation.Members (ReferringMemberId ASC);
GO


EXECUTE Operation.usp_GetReferralTree
	@inMemberId = 12;
GO


-- Rewrite the stored procedure using a recursive CTE

ALTER PROCEDURE Operation.usp_GetReferralTree
(
	@inMemberId AS INT
)
AS

WITH
	ReferralTree
(
	MemberId ,
	ReferralLevel
)
AS
(
	SELECT
		MemberId		= @inMemberId ,
		ReferralLevel	= 0

	UNION ALL
	
	SELECT
		MemberId		= ReferredMembers.Id ,
		ReferralLevel	= ReferralTree.ReferralLevel + 1
	FROM
		Operation.Members AS ReferredMembers
	INNER JOIN
		ReferralTree
	ON
		ReferredMembers.ReferringMemberId = ReferralTree.MemberId
)
SELECT
	MemberId ,
	ReferralLevel
FROM
	ReferralTree
ORDER BY
	ReferralLevel	ASC ,
	MemberId		ASC;
GO


EXECUTE Operation.usp_GetReferralTree
	@inMemberId = 12;
GO


-- Add a HIERARCHYID column to the "Operation.Members" table

ALTER TABLE
	Operation.Members
ADD
	Node HIERARCHYID NULL;
GO


-- Populate the HIERARCHYID values one-by-one

CREATE PROCEDURE Operation.usp_UpdateNodeValues
(
	@inReferringMemberId	AS INT ,
	@inNodeValue			AS HIERARCHYID
)
AS

DECLARE
	@ReferredMemberId	AS INT ,
	@LeftSibling		AS HIERARCHYID ,
	@NewNodeValue		AS HIERARCHYID;

IF
	@inReferringMemberId IS NULL
BEGIN

	DECLARE
		csrReferredMembers
	CURSOR
		LOCAL STATIC READ_ONLY FORWARD_ONLY
	FOR
		SELECT
			Id
		FROM
			Operation.Members
		WHERE
			ReferringMemberId IS NULL;

END
ELSE
BEGIN

	DECLARE
		csrReferredMembers
	CURSOR
		LOCAL STATIC READ_ONLY FORWARD_ONLY
	FOR
		SELECT
			Id
		FROM
			Operation.Members
		WHERE
			ReferringMemberId = @inReferringMemberId;

END;

OPEN csrReferredMembers;

FETCH NEXT FROM
	csrReferredMembers
INTO
	@ReferredMemberId;

WHILE
	@@FETCH_STATUS = 0
BEGIN

	SET @NewNodeValue = @inNodeValue.GetDescendant (@LeftSibling , NULL)

	UPDATE
		Operation.Members
	SET
		Node = @NewNodeValue
	WHERE
		Id = @ReferredMemberId;

	SET @LeftSibling = @NewNodeValue;
	
	EXECUTE Operation.usp_UpdateNodeValues
		@inReferringMemberId	= @ReferredMemberId ,
		@inNodeValue			= @NewNodeValue;

	FETCH NEXT FROM
		csrReferredMembers
	INTO
		@ReferredMemberId;

END;

CLOSE csrReferredMembers;

DEALLOCATE csrReferredMembers;
GO


DECLARE
	@RootNodeValue AS HIERARCHYID = HIERARCHYID::GetRoot ();

EXECUTE Operation.usp_UpdateNodeValues
	@inReferringMemberId	= NULL ,
	@inNodeValue			= @RootNodeValue;
GO


-- Alter the "Node" column to be non-nullable

ALTER TABLE
	Operation.Members
ALTER COLUMN
	Node HIERARCHYID NOT NULL;
GO


-- Create a unique non-clustered index on the "Node" column

CREATE UNIQUE NONCLUSTERED INDEX
	ix_Members_nc_u_Node
ON
	Operation.Members (Node ASC);
GO


-- Rewrite the "Operation.usp_GetReferralTree" stored procedure using the new "Node" column

ALTER PROCEDURE Operation.usp_GetReferralTree
(
	@inMemberId AS INT
)
AS

DECLARE
	@RootNodeValue	AS HIERARCHYID ,
	@RootLevel		AS INT;

SELECT
	@RootNodeValue = Node
FROM
	Operation.Members
WHERE
	Id = @inMemberId;

SET @RootLevel = @RootNodeValue.GetLevel ();

SELECT
	MemberId		= Id ,
	ReferralLevel	= Node.GetLevel () - @RootLevel
FROM
	Operation.Members
WHERE
	Node.IsDescendantOf (@RootNodeValue) = 1
ORDER BY
	ReferralLevel	ASC ,
	MemberId		ASC;
GO


EXECUTE Operation.usp_GetReferralTree
	@inMemberId = 12;
GO


-- Populate the HIERARCHYID values level-by-level

DROP INDEX
	ix_Members_nc_u_Node
ON
	Operation.Members;
GO


ALTER TABLE
	Operation.Members
ALTER COLUMN
	Node HIERARCHYID NULL;
GO


UPDATE
	Operation.Members
SET
	Node = NULL;
GO


DECLARE
	@RowCount AS INT;

UPDATE
	Operation.Members
SET
	Node =	CAST ((HIERARCHYID::GetRoot ().ToString () + CAST (Id AS NVARCHAR(MAX)) + N'/') AS HIERARCHYID)
WHERE
	ReferringMemberId IS NULL;

SET @RowCount = @@ROWCOUNT;

WHILE
	@RowCount > 0
BEGIN

	UPDATE
		ReferredMembers
	SET
		Node =	CAST ((ReferringMembers.Node.ToString () + CAST (ReferredMembers.Id AS NVARCHAR(MAX)) + N'/') AS HIERARCHYID)
	FROM
		Operation.Members AS ReferredMembers
	INNER JOIN
		Operation.Members AS ReferringMembers
	ON
		ReferredMembers.ReferringMemberId = ReferringMembers.Id
	AND
		ReferredMembers.Node IS NULL
	AND
		ReferringMembers.Node IS NOT NULL;

	SET @RowCount = @@ROWCOUNT;

END;
GO


ALTER TABLE
	Operation.Members
ALTER COLUMN
	Node HIERARCHYID NOT NULL;
GO


CREATE UNIQUE NONCLUSTERED INDEX
	ix_Members_nc_u_Node
ON
	Operation.Members (Node ASC);
GO


EXECUTE Operation.usp_GetReferralTree
	@inMemberId = 12;
GO
