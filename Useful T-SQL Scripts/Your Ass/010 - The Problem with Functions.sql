USE
	YourAss;
GO


SET STATISTICS IO ON;
GO


-- Check out this query, which uses a scalar function

SELECT
	InvitationId		= Invitations.Id ,
	InvitationStatus	= InvitationStatuses.Name ,
	CreationDateTime	= Invitations.CreationDateTime ,
	ResponseDateTime	= Invitations.ResponseDateTime
FROM
	Operation.Invitations AS Invitations
INNER JOIN
	Lists.InvitationStatuses AS InvitationStatuses
ON
	Invitations.StatusId = InvitationStatuses.Id
WHERE
	Operation.udf_InvitationRank (StatusId , CreationDateTime , ResponseDateTime) = N'Excellent';
GO


-- Put the function logic inside the query

SELECT
	InvitationId		= Invitations.Id ,
	InvitationStatus	= InvitationStatuses.Name ,
	CreationDateTime	= Invitations.CreationDateTime ,
	ResponseDateTime	= Invitations.ResponseDateTime
FROM
	Operation.Invitations AS Invitations
INNER JOIN
	Lists.InvitationStatuses AS InvitationStatuses
ON
	Invitations.StatusId = InvitationStatuses.Id
WHERE
	Invitations.StatusId = 2	-- Accepted
AND
	DATEDIFF (DAY , Invitations.CreationDateTime , Invitations.ResponseDateTime) <= 10;
GO


-- Rewrite the scalar function as an inline function

CREATE FUNCTION
	Operation.udf_InvitationRank_Inline
(
	@inStatusId			AS TINYINT ,
	@inCreationDateTime	AS DATETIME2(0) ,
	@inResponseDateTime	AS DATETIME2(0)
)
RETURNS
	TABLE
AS

RETURN
(
	SELECT
		InvitationRank =
			CASE
				WHEN @inStatusId = 1 AND DATEDIFF (DAY , @inCreationDateTime , SYSDATETIME ()) > 30
					THEN N'Very Poor'
				WHEN @inStatusId = 1 AND DATEDIFF (DAY , @inCreationDateTime , SYSDATETIME ()) <= 30 AND DATEDIFF (DAY , @inCreationDateTime , SYSDATETIME ()) > 10
					THEN N'Poor'
				WHEN @inStatusId = 1 AND DATEDIFF (DAY , @inCreationDateTime , SYSDATETIME ()) <= 10
					THEN N'Maybe'
				WHEN @inStatusId = 2 AND DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) > 30
					THEN N'Nice'
				WHEN @inStatusId = 2 AND DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) <= 30 AND DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) > 10
					THEN N'Good'
				WHEN @inStatusId = 2 AND DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) <= 10
					THEN N'Excellent'
				WHEN @inStatusId = 3 AND DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) > 30
					THEN N'Not Good'
				WHEN @inStatusId = 3 AND DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) <= 30 AND DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) > 10
					THEN N'Bad'
				WHEN @inStatusId = 3 AND DATEDIFF (DAY , @inCreationDateTime , @inResponseDateTime) <= 10
					THEN N'Basa'
			END
);
GO


SELECT
	InvitationId		= Invitations.Id ,
	InvitationStatus	= InvitationStatuses.Name ,
	CreationDateTime	= Invitations.CreationDateTime ,
	ResponseDateTime	= Invitations.ResponseDateTime
FROM
	Operation.Invitations AS Invitations
INNER JOIN
	Lists.InvitationStatuses AS InvitationStatuses
ON
	Invitations.StatusId = InvitationStatuses.Id
CROSS APPLY
	Operation.udf_InvitationRank_Inline (StatusId , CreationDateTime , ResponseDateTime) AS InvitationRanks
WHERE
	InvitationRanks.InvitationRank = N'Excellent';
GO


-- Create a more complex scalar function

CREATE FUNCTION
	Operation.udf_InvitationRank_2
(
	@RequestingMemberId	AS INT ,
	@inStatusId			AS TINYINT ,
	@inCreationDateTime	AS DATETIME2(0) ,
	@inResponseDateTime	AS DATETIME2(0)
)
RETURNS
	NVARCHAR(10)
AS
BEGIN

	DECLARE
		@Result AS NVARCHAR(10);

	IF
		@inStatusId = 1	-- Sent
	BEGIN

		IF
			EXISTS
				(
					SELECT
						NULL
					FROM
						Billing.Payments
					WHERE
						MemberId = @RequestingMemberId
					AND
						DateAndTime < DATEADD (MONTH , -1 , SYSDATETIME ())
				)
		BEGIN

			SET @Result = N'Very Poor';

		END

		ELSE IF
			EXISTS
				(
					SELECT
						NULL
					FROM
						Billing.Payments
					WHERE
						MemberId = @RequestingMemberId
					AND
						DateAndTime >= DATEADD (MONTH , -1 , SYSDATETIME ())
					AND
						DateAndTime < DATEADD (WEEK , -1 , SYSDATETIME ())
				)
		BEGIN

			SET @Result = N'Poor';

		END

		ELSE IF
			EXISTS
				(
					SELECT
						NULL
					FROM
						Billing.Payments
					WHERE
						MemberId = @RequestingMemberId
					AND
						DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
				)
		BEGIN

			SET @Result = N'Maybe';

		END

	END

	ELSE IF
		@inStatusId = 2	-- Accepted
	BEGIN

		IF
			EXISTS
				(
					SELECT
						NULL
					FROM
						Billing.Payments
					WHERE
						MemberId = @RequestingMemberId
					AND
						DateAndTime < DATEADD (MONTH , -1 , SYSDATETIME ())
				)
		BEGIN

			SET @Result = N'Nice';

		END

		ELSE IF
			EXISTS
				(
					SELECT
						NULL
					FROM
						Billing.Payments
					WHERE
						MemberId = @RequestingMemberId
					AND
						DateAndTime >= DATEADD (MONTH , -1 , SYSDATETIME ())
					AND
						DateAndTime < DATEADD (WEEK , -1 , SYSDATETIME ())
				)
		BEGIN

			SET @Result = N'Good';

		END

		ELSE IF
			EXISTS
				(
					SELECT
						NULL
					FROM
						Billing.Payments
					WHERE
						MemberId = @RequestingMemberId
					AND
						DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
				)
		BEGIN

			SET @Result = N'Excellent';

		END

	END

	ELSE IF
		@inStatusId = 3	-- Denied
	BEGIN

		IF
			EXISTS
				(
					SELECT
						NULL
					FROM
						Billing.Payments
					WHERE
						MemberId = @RequestingMemberId
					AND
						DateAndTime < DATEADD (MONTH , -1 , SYSDATETIME ())
				)
		BEGIN

			SET @Result = N'Not Good';

		END

		ELSE IF
			EXISTS
				(
					SELECT
						NULL
					FROM
						Billing.Payments
					WHERE
						MemberId = @RequestingMemberId
					AND
						DateAndTime >= DATEADD (MONTH , -1 , SYSDATETIME ())
					AND
						DateAndTime < DATEADD (WEEK , -1 , SYSDATETIME ())
				)
		BEGIN

			SET @Result = N'Bad';

		END

		ELSE IF
			EXISTS
				(
					SELECT
						NULL
					FROM
						Billing.Payments
					WHERE
						MemberId = @RequestingMemberId
					AND
						DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
		)
		BEGIN

			SET @Result = N'Basa';

		END

	END;

	RETURN @Result;

END;
GO


-- Call the new scalar function from a query

SELECT
	InvitationId		= Invitations.Id ,
	InvitationStatus	= InvitationStatuses.Name ,
	CreationDateTime	= Invitations.CreationDateTime ,
	ResponseDateTime	= Invitations.ResponseDateTime
FROM
	Operation.Invitations AS Invitations
INNER JOIN
	Lists.InvitationStatuses AS InvitationStatuses
ON
	Invitations.StatusId = InvitationStatuses.Id
INNER JOIN
	Operation.MemberSessions AS MemberSessions
ON
	MemberSessions.Id = Invitations.RequestingSessionId
WHERE
	Invitations.Id <= 500
AND
	Operation.udf_InvitationRank_2 (MemberSessions.MemberId , StatusId , CreationDateTime , ResponseDateTime) = N'Nice';
GO


-- Rewrite the new scalar function as an inline funtion

CREATE FUNCTION
	Operation.udf_InvitationRank_Inline_2
(
	@RequestingMemberId	AS INT ,
	@inStatusId			AS TINYINT ,
	@inCreationDateTime	AS DATETIME2(0) ,
	@inResponseDateTime	AS DATETIME2(0)
)
RETURNS
	TABLE
AS

RETURN
(
	SELECT
		InvitationRank =
			CASE
				WHEN
					@inStatusId = 1
				AND
					EXISTS
						(
							SELECT
								NULL
							FROM
								Billing.Payments
							WHERE
								MemberId = @RequestingMemberId
							AND
								DateAndTime < DATEADD (MONTH , -1 , SYSDATETIME ())
						)
				THEN
					N'Very Poor'
				WHEN
					@inStatusId = 1
				AND
					EXISTS
						(
							SELECT
								NULL
							FROM
								Billing.Payments
							WHERE
								MemberId = @RequestingMemberId
							AND
								DateAndTime >= DATEADD (MONTH , -1 , SYSDATETIME ())
							AND
								DateAndTime < DATEADD (WEEK , -1 , SYSDATETIME ())
						)
				THEN
					N'Poor'
				WHEN
					@inStatusId = 1
				AND
					EXISTS
						(
							SELECT
								NULL
							FROM
								Billing.Payments
							WHERE
								MemberId = @RequestingMemberId
							AND
								DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
						)
				THEN
					N'Maybe'
				WHEN
					@inStatusId = 2
				AND
					EXISTS
						(
							SELECT
								NULL
							FROM
								Billing.Payments
							WHERE
								MemberId = @RequestingMemberId
							AND
								DateAndTime < DATEADD (MONTH , -1 , SYSDATETIME ())
						)
				THEN
					N'Nice'
				WHEN
					@inStatusId = 2
				AND
					EXISTS
						(
							SELECT
								NULL
							FROM
								Billing.Payments
							WHERE
								MemberId = @RequestingMemberId
							AND
								DateAndTime >= DATEADD (MONTH , -1 , SYSDATETIME ())
							AND
								DateAndTime < DATEADD (WEEK , -1 , SYSDATETIME ())
						)
				THEN
					N'Good'
				WHEN
					@inStatusId = 2
				AND
					EXISTS
						(
							SELECT
								NULL
							FROM
								Billing.Payments
							WHERE
								MemberId = @RequestingMemberId
							AND
								DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
						)
				THEN
					N'Excellent'
				WHEN
					@inStatusId = 3
				AND
					EXISTS
						(
							SELECT
								NULL
							FROM
								Billing.Payments
							WHERE
								MemberId = @RequestingMemberId
							AND
								DateAndTime < DATEADD (MONTH , -1 , SYSDATETIME ())
						)
				THEN
					N'Not Good'
				WHEN
					@inStatusId = 3
				AND
					EXISTS
						(
							SELECT
								NULL
							FROM
								Billing.Payments
							WHERE
								MemberId = @RequestingMemberId
							AND
								DateAndTime >= DATEADD (MONTH , -1 , SYSDATETIME ())
							AND
								DateAndTime < DATEADD (WEEK , -1 , SYSDATETIME ())
						)
				THEN
					N'Bad'
				WHEN
					@inStatusId = 3
				AND
					EXISTS
						(
							SELECT
								NULL
							FROM
								Billing.Payments
							WHERE
								MemberId = @RequestingMemberId
							AND
								DateAndTime >= DATEADD (WEEK , -1 , SYSDATETIME ())
						)
				THEN
					N'Basa'
			END
);
GO


-- Check the performance of the inline function compared to the scalar function

SELECT
	InvitationId		= Invitations.Id ,
	InvitationStatus	= InvitationStatuses.Name ,
	CreationDateTime	= Invitations.CreationDateTime ,
	ResponseDateTime	= Invitations.ResponseDateTime
FROM
	Operation.Invitations AS Invitations
INNER JOIN
	Lists.InvitationStatuses AS InvitationStatuses
ON
	Invitations.StatusId = InvitationStatuses.Id
INNER JOIN
	Operation.MemberSessions AS MemberSessions
ON
	MemberSessions.Id = Invitations.RequestingSessionId
CROSS APPLY
	Operation.udf_InvitationRank_Inline_2 (MemberSessions.MemberId , StatusId , CreationDateTime , ResponseDateTime) AS InvitationRanks_Inline_2
WHERE
	Invitations.Id <= 500
AND
	InvitationRanks_Inline_2.InvitationRank = N'Nice';
GO
