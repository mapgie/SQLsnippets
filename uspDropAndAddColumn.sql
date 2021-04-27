-- ================================================
-- Template generated from Template Explorer using:
-- Create Scalar Function (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the function.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF OBJECTPROPERTY (object_id('dbo.uspDropAndAddColumn'), 'IsProcedure') = 1
DROP PROCEDURE [dbo].[uspDropAndAddColumn]
GO

-- =============================================
-- Author:		ms16865
-- Create date: 27/04/2021
-- Description: Drops a column and re-adds column IF:
				-- Column only contains nulls 
				-- @safemode is OFF ( = 0 )		-- @Safemode is always 1 by default 
-- =============================================
CREATE PROCEDURE uspDropAndAddColumn 
(
	@objectname	varchar(50),
	@newcolname	varchar(50),
	@datatype	varchar(50),
	@checkWithSelect bit = 0,	 -- 1 - runs an extra select to check 
	@debug bit = 0,				 -- 1 - prints extra messages 
	@safemode bit = 1			 -- 1 - default is ON
)
AS
BEGIN
	DECLARE @status bit = 0 -- 0: No errors found.

	BEGIN /* DECLARATIONS */ 

	DECLARE @dropquery nvarchar(max), @addquery nvarchar(max), @selectquery nvarchar(max);
	DECLARE @returnval int, @ParmDefinition nvarchar(500);
	PRINT @objectName

	SET @dropquery	= 'ALTER TABLE ' + @objectname + ' DROP COLUMN ' + @newcolname;
	SET @addquery	= REPLACE(@dropquery,'DROP COLUMN','ADD') + ' ' + @datatype;
	SET @selectquery = N'SELECT @returnvalOut = CAST(ISNULL((SELECT distinct ' + @newcolname + ' from ' + @objectname +'),0) as int)'

	if @debug = 1 	print @selectquery
	SET @ParmDefinition = N'@returnvalOut int OUTPUT';

	END   /* DECLARATIONS */ 

	/*DO NOT DROP COLUMNS THAT ARE NOT EMPTY */
	BEGIN /* CHECK COL EMPTY*/

	IF EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID(@objectName) AND [name] = @newcolname)
	BEGIN 

		EXEC sp_executesql @selectquery, @ParmDefinition, @returnvalOUT=@returnval OUTPUT;
		IF @returnval = 0 
		BEGIN
			SET @status = 1
			print 'Column contains only null values - can be removed'
		END
		ELSE 
		BEGIN
			SET @status = 0
			Print 'Procedure cannot be used to drop columns that contain values other than NULL'
			GOTO EOF
		END 

	END 
	ELSE
		SET @status = 1


	END /* EMPTY CHECK */ 
	

	IF @status = 1 AND EXISTS (SELECT * FROM sys.columns WHERE [object_id] = OBJECT_ID(@objectName) AND [name] = @newcolname)
	BEGIN	/* COL DROP */
		if @safemode != 1 EXEC sp_sqlexec @dropquery
		if @safemode != 0 print 'SAFEMODE ON - Action not taken:'
		if @debug = 1 	print @dropquery
		set @status = 1 
		print 'Successful Column Drop'
	END		/* COL DROP */
	
	IF @status = 1 
	BEGIN /* COL ADD */
		if @debug = 1 print @addquery
		if @safemode != 1 EXEC sp_sqlexec @addquery
		if @safemode != 0 print 'SAFEMODE ON - Action not taken:'
		set @status = 1
		print 'Successful Column Add'
	END	  /* COL ADD */

	/*****************************************************************************************/

	IF @checkWithSelect = 1
	BEGIN 
	set	  @selectquery = 'select ' + @newcolname + ', * from ' + @objectname
	if @debug = 1 	print @selectquery
	EXEC  sp_sqlexec @selectquery
	END

	EOF:

	IF @status = 1
		Print 'End of File
		'
	ELSE
		Print 'Error on ' + cast(@objectName as char) + '
		'

END
