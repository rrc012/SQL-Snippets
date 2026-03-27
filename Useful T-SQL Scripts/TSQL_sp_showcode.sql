/*#info 
	
	# Author 
		Rodrigo Ribeiro Gomes

	# Description
		An improved version of sp_helptext, allowing greater flexibility...
		Features:
			- You can use % to search for the object (I really miss this, since the original only accepts the exact name)
			- You can specify multiple search options, including negation
			- Searches in any database (priority is the current one, but with a small adjustment you can search others)
			- Prints directly as text, to make copying easier, or as XML, just like sp_whoisactive does (WOW, this speeds things up a lot)
			- Allows filtering by type
			- Decrypts encrypted procs if you are connected as DAC (THIS SAVES A LOT OF TIME)

		Originally, sp_helptext requires you to pass the exact object name!

		Sometimes you only remember part of the name, don’t remember the exact database, etc.
		With sp_showcode you can search multiple procs, display the original code (in sp_helptext mode), or even return XML (which becomes clickable in SSMS).

		I left the original documentation in English (terrible English, I accept revisions), because I believe this proc can be useful worldwide.
		But below are some usage examples in Portuguese:

			Examples:
				> sp_showcode MinhaProc
					Displays the text of the proc MinhaProc (in the Messages tab) from the current database.
					The main difference here compared to the original is the way I print the output.
					The original sp_helptext would return it as a result set (which loses formatting when you copy it in SSMS).

				> sp_showcode '%.%.MinhaProc'
					Here we level up, making it search across all databases and schemas.
					If it finds more than one object with that name, it will display a list for you to refine.
					If it finds only one, it prints it directly.
					Note that by default it does not search all databases. You must explicitly request this using the wildcard.
					The format is Database.Schema.Object, where each part may contain a wildcard, as if you were filtering with LIKE.

				> sp_showcode '%.%.MinhaProc', @all = 1
					The difference from the previous example is that you are forcing it to print everything it finds...
					Be careful when using this, because if it returns 20 large procs, it will print all of that to your client.

				> sp_showcode '%.%.MinhaProc','xml', @all = 1
					Here we switch the mode to XML. Instead of printing, it returns a result set with the objects as XML, just like sp_whoisactive does.
					This makes it clickable in SSMS and it opens in another tab.

				> sp_showcode '%.%.MinhaProc','xml', @all = 1, @top = 100
					By default, it returns only the first 50 objects found.
					You can increase the limit using the @top parameter. If you set it to 0, it returns everything.

				> sp_showcode '%ven%'
					Here it will search for objects that have "ven" in the name.
					Since a schema filter was not explicitly defined, it will ignore the sys and INFORMATION_SCHEMA schemas.

				> sp_showcode '%.%ven%'
					This is the same as above, but now it will also search system schemas, because a schema filter (%) was explicitly defined.

				> sp_showcode 'Loja12%..vwNotasFiscais',@all = 1
					This is another example of a more elaborate filter...
					In this case, it will search for and display the object named vwNotasFiscais in all databases that start with Loja12, in all schemas.

				> sp_showcode 'Vendas..%','xml', @types = 'function'
					This is an example of the @types parameter. You can specify a value from sys.objects.type or type_desc,
					or even a fragment, as in the example above, where "function" will match all function types.
					In this case, it will list all functions in the Vendas database. If you set @all = 1, it prints everything!

				> sp_showcode 'chamados/isAberto','xml'
					Here you are searching for computed columns. By including a slash (/), the value after the slash becomes a column filter.
					You can use % to filter multiple columns.

				> sp_showcode '%..%/is%',@all = 1
					Here, for example, we are searching for all computed columns in all databases and all tables that start with "is".
					The definition of all of them will be printed as messages.

				> sp_showcode 'prcVenda,prcSales'
					Here we use a more advanced feature: multiple options.
					In this case, it will search for all user objects that contain "ven" or "sal".
					It would find, for example, prcVendas and prcSales.

		Warnings and considerations:
			- The proc uses temporary tables to load the procs and then print them.
			  Therefore, if there are many large procs matching your filter, this can use a lot of tempdb.
			- In the default mode, the proc uses the PRINT command to output the content.
			  This command has a limit of 4,000 Unicode characters that can be printed at once,
			  which in practice means a limit of 4,000 characters per line.
			  That is a lot, and it is unlikely you will encounter this.
			  But if you do, the proc will break the line into multiple lines,
			  which may make the proc body semantically incorrect compared to the original.
			  In such cases, consider using XML output.
			- sp_showcode was created primarily with SSMS day-to-day DBA usage in mind.
			  But if you need to export (using the command line, for example),
			  I recommend using export mode, which will adjust the parameters correctly
			  so you can write the output to a file, for example.
*/


USE master 
GO

-- for rc4 decryption (used for encrypted procs)
-- Based on Paul White (https://sqlperformance.com/2016/05/sql-performance/the-internals-of-with-encryption)
-- Reference: https://www.red-gate.com/simple-talk/databases/sql-server/how-to-view-sql-server-object-code-easily-with-sp_showcode/
-- Source Code: https://github.com/rrg92/sqlserver-lib/blob/main/Modulos/sp.showcode.sql

IF OBJECT_ID('dbo.sp_showcode_rc4decode','P') IS NULL
	EXEC('CREATE PROC dbo.sp_showcode_rc4decode AS')
GO

ALTER PROCEDURE dbo.sp_showcode_rc4decode
(
     @Pwd varbinary(256)
    ,@Text varbinary(MAX)
	,@Decrypted nvarchar(max) OUTPUT
)
AS
BEGIN
    DECLARE @Key table (i tinyint PRIMARY KEY,v tinyint NOT NULL);
	DECLARE @Box table (i tinyint PRIMARY KEY, v tinyint NOT NULL);
	DECLARE @nums TABLE(i tinyint);
    DECLARE
        @PwdLen tinyint = DATALENGTH(@Pwd);

	;WITH n as ( select * from (values(1),(2),(3),(4),(5),(6),(7)) v(n) )
	insert into @Key(i,v)
	select 
		N.n
		,CONVERT(tinyint, SUBSTRING(@Pwd, N.n % @PwdLen + 1, 1))
	from (
		select top(256)
			n = row_number() over(order by (select null))-1 
		from n,n n2,n n3,n n4
	) N

	insert into @Box(i,v) select i,i from @key;



    DECLARE
        @Index int = 0,
        @i smallint = 0,
        @j smallint = 0,
        @t tinyint = NULL,
		@b smallint = 0,
        @k smallint = NULL,
        @CipherBy tinyint = NULL,
        @Cipher varbinary(MAX) = 0x;
 
    WHILE @Index <= 255
    BEGIN
        SELECT @b = (@b + b.v + k.v) % 256
        FROM @Box AS b
        JOIN @Key AS k
            ON k.i = b.i
        WHERE b.i = @Index;
 
        SELECT @t = b.v
        FROM @Box AS b
        WHERE b.i = @Index;
 
        UPDATE b1 SET b1.v = (SELECT b2.v FROM @Box AS b2 WHERE b2.i = @b)
        FROM @Box AS b1 WHERE b1.i = @Index;
 
        UPDATE @Box SET v = @t  WHERE i = @b;
 
        SET @Index += 1;
    END;


	select 
		@Index = 1
	
 
    WHILE @Index <= DATALENGTH(@Text)
    BEGIN
        SET @i = (@i + 1) % 256;
 
        SELECT
            @j = (@j + b.v) % 256,
            @t = b.v
        FROM @Box AS b
        WHERE b.i = @i;
 
        UPDATE b
        SET b.v = (SELECT w.v FROM @Box AS w WHERE w.i = @j)
        FROM @Box AS b
        WHERE b.i = @i;
 
        UPDATE @Box
        SET v = @t
        WHERE i = @j;
 
        SELECT @k = b.v
        FROM @Box AS b
        WHERE b.i = @i;
 
        SELECT @k = (@k + b.v) % 256
        FROM @Box AS b
        WHERE b.i = @j;
 
        SELECT @k = b.v
        FROM @Box AS b
        WHERE b.i = @k;
 
        SELECT
            @CipherBy = CONVERT(tinyint, SUBSTRING(@Text, @Index, 1)) ^ @k,
            @Cipher = @Cipher + CONVERT(binary(1), @CipherBy);
 
        SET @Index += 1;
    END;
 
    SET @Decrypted = CONVERT(nvarchar(max),@Cipher);
END;
GO


IF OBJECT_ID('dbo.sp_showcode','P') IS NULL
	EXEC('CREATE PROC sp_showcode AS SELECT StubVersion = 1')
GO


ALTER PROC sp_showcode (
	 -- Specify the object name in format Db.Schema.ObjectName or Schema.ObjectName or ObjectName
	 -- You can add column filters, for search by computed columns, using syntax /ColumnName in ObjectName
	 -- you can specify multile options using comma and prefix with '-' to specify as "not".
	 -- You can use wildcards in any part, for example, sp_help%, ou Test_.%.vw%
	 -- By default, search only in current db, but using '%.%.%search%' will force search on all db and schema!
	 -- If want force search in current db, preped and dot, example: .SomeObject%
	 -- If no explicit schema filter is specified, proc will add implicit filters excluding sys and INFORMATION_SCHEMA, causing search happens only in user objects.
	 -- Check examples bellow
	 @text sysname

	,-- Specify the output mode.
	 -- Values can be (pipe mean alternative values):
	 --		sp_helptext|1	- Use the sp_helptext to print 
	 --		xml|2			- Return an XML, like sp_whoisactive do. Useful for click in SSMS.
							-- We try remove invalid XML chars to avoid xml conversion errors
	 --		text|3			-- Print directly output. With that, it is easy copy and bypass SSMS output limits due fact that it breaks into lines and issue many prints.
								-- Can be more slow in some cases due to line ending checks and splitting
								-- due fact we use print to output lines, max line size is 4000 chars, due print limit
								-- If a line is grather that this size, proc will split a line in multiple lines
								-- The disvantange that is the object code can be incorrect (for example, if line was part of literal string) or is break in middle of some statement
								-- But, for no code be hidden, we prefer this default behavior.
								-- If objects you are searching contains lines above that limit, consider using another mode, like XML or sp_helptext.
								-- You can lower the max using @MaxLineSize
	--		trunc|4			-- Same as text, but if a line exceed max print size, just show the a BIG LINE WARNING and truncate line.
	--		export|5		-- Return dafinitions safe to be exported, when you running this proc in some commandline or custom app that will handle by its own the result.
							-- no headers, GO statements are returned, just raw defintion, what is it useful for expor
							-- Will return one defintion per line.
	--		exportgo|6		-- Same as export, but include headers and GO statements to delimiter object end start and end!
	 @mode varchar(100) = 'text'

	,-- By default, proc only prints if just extacly one object is found.
	 -- If multiple matches are found, then proc will return a list of found objects you help refine your search
	 -- Specify @all = 1, force proc print all bodies of all objects found. Use with caution, because this can generate lot of processing
	 -- @all is automatically set to 1 if specify multiple expressions in @text, all with no wildcards;
	 @all bit = 0


	,-- specify object types to filter. By default accept all.
	 -- separate each type by comma. Same of type from sys.objects
	 @type varchar(100) = '%%%%'

	,-- limit the top first object found
	 -- 0 means no limit.
	 @top int = 50


	,-- set how proc will handle system object
	 -- when 0, only first occurrence of system object is returned
	 -- when 1, all occurence is returned
	 @sysall bit = 0

	,-- max line size for text or trunc modes. The maximum value for this is 4000, due print limit.
	 @MaxLineSize smallint = 4000

	,-- include GO statements between headers and at end of proc. Not used when mode ir xml or sp_helptext
	 @go bit = 1

	,-- include descriptive headers. NOt used when mode is sp_helptext and xml.
	 @headers bit = 1

	,-- force @text being trated as a literal, with no filter or expression. In another words, you are escaping entire @text param, losing its powers
	-- With that, proc will behaves almost sp_helptext, finding exact object name
	-- Remember it is a complete literal. The text must follow rules of parsename function, that is it, [schema].[object]. Literal [ or ]  require use ", for example "[abc]" or ["abc"]  for inverse
	@literal bit = 0

	,-- only return objects where definition match that text
	@find nvarchar(max) = NULL 

	-- Enable some messages for debugging.
	,@Debug bit = 0
)
/*
	Author: Rodrigo Ribeiro Gomes (thesqltimes.com)
	Description: 
		Advanced and flexible version of sp_helptext, to help find proc and its body.
		Allow you search and print body of objects with some definition (like procs, functions and views) to easy copy
		IF procs is encrypted and you are connect as DAC, the procedure automatically tries decrypts procs.

		Compatibility = sql server 2008+

		TODO:
			- Add jobs

	Examples:
		> sp_showcode MyProcName
			Search in current db only and Print the body of object MyProcName if found. 
		
		> sp_showcode '%.MyProcName'
			Print the body of proc MyProcName if exists just one.
			If multiple is found present the list to you choose.

		> sp_showcode '%.%.MyProcName', @all = 1
			Print the body of all object called MyProcName in instance

		> sp_showcode '%..MyProcName', @all = 1, @top = 100
			By default, only first 50 objects are returned. @top allows controls this. If 0, means unlimited.

		> sp_showcode '%..MyProcName','xml'
			Return the body of all MyProcName found in instance as XML, to be clicable in SSMS.
		
		> sp_showcode 'Test_%..proc1',@all = 1
			Print all body of objects with name proc1 found in every db, user schema only, which name start with Test_
			
		> sp_showcode 'Sales..%','xml', @types = 'proc'
			Return body of all user procedures in database called Sales, as a XML.	

		> sp_showcode '%.%test%','xml', @type = 'proc'
			Return all procedures, including system schemas, containing test in name.

		> sp_showcode '%..test/%','xml', @all = 1
			Return all user computed columns of table test in all dbs1
			
		> sp_showcode '%,-%test%','xml', @all = 1
			Return top user objects with text, except which contains test in name
			

		> sp_showcode 'sp_help,sp_helptrigger','xml'
			Return text of both sp_help and sp_helptrigger, as XML
			Note that dont need set @all = 1, because multiple options without wildcard was passed in first param.


*/
AS

SET NOCOUNT ON; 

DECLARE
	@IsWild sysname = 0

IF NOT @MaxLineSize BETWEEN 2 AND 4000
BEGIN
	RAISERROR('@MaxLineSize must be between 2 and 4000',16,1);
	return;
END

IF CHARINDEX('%',@text)	 > 0
	SET @IsWild = 1

-- Parse!
DECLARE
	 @i int = 0
	,@TextLen int = len(@text)
	,@CurrentChar nvarchar(1), @NextChar nvarchar(1)
	,@buff nvarchar(max) = ''
	,@UserFilterCount int

IF OBJECT_ID('tempdb..#sp_showcode_filters') IS NOT NULL
	DROP TABLE #sp_showcode_filters;

CREATE TABLE #sp_showcode_filters (
	ord int identity not null
	,expr nvarchar(max)
	,IsNeg bit
	,FilterDb nvarchar(4000)
	,FilterSchema nvarchar(4000)
	,FilterObject nvarchar(4000)
	,FilterColumn nvarchar(4000)
	,ExprReal nvarchar(max)
	,IsWild bit
);


while @i <=	@TextLen and @literal = 0 
begin
	set @i += 1;
	set @CurrentChar = substring(@text+',',@i,1)
	set @NextChar = substring(@text,@i+1,1)

	if @CurrentChar = N'\' and @NextChar in (N'\',N',')
		select @buff += @NextChar, @i += 1;
	else if @CurrentChar = '\' and @NextChar = '%' -- if found a \%, it is escaped. We handle this separated to avoid set @IsWild = 1
		select @buff += N'\%', @i += 1
	else if @CurrentChar = N',' 
	begin
	   insert into #sp_showcode_filters(expr,IsWild) values(@buff,@IsWild)
	   select @buff = '', @IsWild = 0
	end else begin
		
		if @CurrentChar = '%' --never reaches if \%, because when \ is found, handle in else above.
			set @IsWild = 1

		set @buff += @CurrentChar
	end
end

if @literal = 1
	insert into #sp_showcode_filters(expr,IsWild) values (@text,0);


update f 
set 
	 FilterDb	= PF.FilterDb
	,FilterSchema = PF.FilterSchema
	,FilterObject = PF.FilterObject
	,FilterColumn = PF.FilterColumn
	,IsNeg = E.IsNeg
	,ExprReal = e.ExprReal
from
	#sp_showcode_filters f
	cross apply (
		SELECT 
			IsNeg = CASE
						WHEN @literal = 0 AND left(expr,1) = '-' THEN 1
						ELSE 0 
					END
			,ExprReal = CASE
							WHEN left(expr,1) = '-' THEN STUFF(F.expr,1,1,'')
							ELSE expr 
					END 
	) E
	cross apply (
		SELECT 
			BF.FilterDb
			,BF.FilterSchema
			,FilterObject = CASE 
								WHEN @literal = 1 THEN FilterObject
								WHEN ColSepIndex > 0 THEN LEFT(BF.FilterObject,ColSepIndex-1)
								ELSE BF.FilterObject
							END
			,FilterColumn = CASE
								WHEN @literal = 1 THEN NULL
								WHEN ColSepIndex > 0 THEN SUBSTRING(BF.FilterObject,ColSepIndex+1,4000)
								ELSE '%'
							END
		FROM (
		   SELECT 
				 FilterDb		= isnull(parsename(E.ExprReal,3),db_name())
				,FilterSchema	= parsename(E.ExprReal,2)
				,FilterObject	= isnull(parsename(E.ExprReal,1),@text)
				,ColSepIndex	= CHARINDEX('/',parsename(E.ExprReal,1))
		) BF
		
	) PF
WHERE
	PF.FilterObject IS NOT NULL

SET @UserFilterCount = @@ROWCOUNT

set @IsWild = 0
if exists(select * from #sp_showcode_filters where IsWild = 1)
	set @IsWild = 1


-- if not explicit positive schema filter
if not exists(select * from #sp_showcode_filters where IsNeg = 0 and FilterSchema is not null) and @IsWild = 1
begin
	insert into #sp_showcode_filters(IsNeg,FilterDb,FilterSchema,FilterObject,FilterColumn)
	values
		(1,'%','sys','%','%')
		,(1,'%','INFORMATION_SCHEMA','%','%')
end

-- 
UPDATE #sp_showcode_filters
SET
	FilterSchema = ISNULL(FilterSchema,CASE WHEN @literal = 1 THEN SCHEMA_NAME() ELSE '%' END)


IF @Debug = 1
	SELECT * FROM #sp_showcode_filters f;

if @UserFilterCount = 0
begin
	raiserror('@text must be in format {[-][DbFilter.][SchemaFilter.]ObjectFilter[/column]}[,...n]',16,1)
	return;
end

 -- If user specified only non wild filter!
if @UserFilterCount = (select count(*) from #sp_showcode_filters where IsWild = 0 and expr is not null) 
begin
	set @all = 1;
	if @Debug  = 1 raiserror('Changed @all to 1 due user explicit multiple filter.',0,1) with nowait;
end

		
if object_id('tempdb..#sp_showcode_FilterTypes') IS NOT NULL
	DROP TABLE #sp_showcode_FilterTypes

DECLARE
	@TypesXML XML = '<t>'+REPLACE(@type,',','</t><t>')+'</t>'


select
	ot.TypeAb as TypeName
INTO
	#sp_showcode_FilterTypes
from
	(
		SELECT
			TypeFilter = UPPER(t.x.value('.','varchar(20)'))
		FROM
			@TypesXML.nodes('//t') t(x)
	) TF
	CROSS APPLY (
		SELECT 
			*
		FROM
			(
				values 
					('P','SQL_STORED_PROCEDURE'),('V','VIEW'),('TR','SQL_TRIGGER')
					,('FN','SQL_SCALAR_FUNCTION'),('IF','SQL_INLINE_TABLE_VALUED_FUNCTION'),('TF','SQL_TABLE_VALUED_FUNCTION')

					-- This dont exists officially. Created just for separate in filters!
					,('TRS','SERVER_DDL_TRIGGER')	
					,('TRD','DATABASE_DDL_TRIGGER')
					,('CCC','COMPUTED_COLUMN')
			)  ot(TypeAb,TypeDesc) 
		WHERE
			TypeAb = TF.TypeFilter		-- Filter exactly types (two chars)
			OR
			TypeDesc = TF.TypeFilter	-- exactly type-desc
			OR
			-- other type desc based on part of word that dont match previous.  
			-- for example, if user want filter all functions, just provide "function" as value.
			-- Chose len = 3, due to custom types I created to represent other objects that dont exists in sys.objects (like server triggers, jobs, etc)
			(TypeDesc like '%'+TF.TypeFilter+'%' AND LEN(TF.TypeFilter) > 3 AND TypeDesc != TF.TypeFilter)

	) ot

IF @Debug = 1
	select * from #sp_showcode_FilterTypes

-- validate mode!
SET @mode = CASE @mode
				WHEN '1' THEN 'sp_helptext'
				WHEN '2' THEN 'xml'
				WHEN '3' THEN 'text'
				WHEN '4' THEN 'trunc'
				WHEN '5' THEN 'export'
				WHEN '6' THEN 'exportgo'
				ELSE @mode
			END

IF @Debug = 1
	RAISERROR('Output mode = %s',0,1,@mode) with nowait;


IF @mode NOT IN ('sp_helptext','xml','text','trunc','export','exportgo')
BEGIN
	RAISERROR('Invalid @mode: %s',16,1,@mode);
	return;
END




DECLARE @DbList TABLE(Seq int, DbName sysname);

INSERT INTO @DbList(Seq,DBName)
SELECT
	ROW_NUMBER() OVER(ORDER BY IsCurrentDB DESC, database_id)
	,name
FROM
	sys.databases d 
	CROSS APPLY (
		SELECT 
			IsCurrentDb = CASE WHEN DB_NAME()  = name THEN 1 ELSE 0 END
	) c
WHERE
	-- an explicit db must be select with a positive filter
	-- Negative filters can remove this db, but anyway, before remove, we must be able to have something to select
	-- So, this step, we just intereseted include filters, because it determines which dbs we must look on.
	-- If user specify just negative filter, this dont intereset in this part, because by default, no db is selected unless user explicity filter
	-- FOr example, if @text is '-DbX.%sys.%', because no positive filter exists, then nothing is select.
	-- The intent of negative filters is a "second chance" over positives, because, by default, nothing is selected, unless positive filter select it.
	-- Due that, at this point, we just select dbs in positive filters.
	exists ( 
		select
			*
		from
			#sp_showcode_filters f
		where
			d.name like f.FilterDb
			and
			f.IsNeg = 0
	)


IF @Debug = 1
	SELECT * FROM @DbList

DECLARE @FoundObjects TABLE (
	 Id int not null identity primary key
	,DbName sysname 
	,ObjectName sysname 
	,ObjectSchema sysname
	,ColName sysname null
	,ObjectId int
	,ObjectDefinition nvarchar(max)
	,IsEncrypted bit 
	,ObjType varchar(10)
	,TypeDesc varchar(200)
	,IsInSysComments bit
	,IsInMasterComments bit
	,FullName as QUOTENAME(DbName)+'.'+QUOTENAME(ObjectSchema)+'.'+QUOTENAME(ObjectName)
)

DECLARE
	@Seq int = 0
	,@DbName sysname
	,@spsql sysname
	,@FoundCount int
	,@TotalFound int = 0
	,@NeedsDefinition bit = 0
	,@sql nvarchar(max)
	,@LeftLimit int = @top
	,@StartId int = 0

IF @mode IN ('xml','text','trunc')
	SET @NeedsDefinition = 1

if @LeftLimit = 0
	set @LeftLimit = NULL

-- contians found systemprocs, to prevent load duplicates
if object_id('tempdb..#sp_showcode_SystemProcs') IS NOT NULL
	DROP TABLE #sp_showcode_SystemProcs

create table #sp_showcode_SystemProcs(
	 SchemaName sysname
	 ,ObjectName sysname
)
create unique index IxSystemProcs ON #sp_showcode_SystemProcs(SchemaName,ObjectName);

WHILE 1 = 1
BEGIN
	SELECT TOP 1 
		@Seq = Seq
		,@DbName = DbName
	FROM
		@DbList
	WHERE
		Seq > @Seq
	ORDER BY
		Seq 
	IF @@ROWCOUNT = 0
		BREAK

	set @spsql = @DbName+'.sys.sp_executesql'

	IF @Debug = 1
		RAISERROR('Searching in db %s',0,1,@DbName) with nowait;

	
	set @sql = N'
		SELECT '+ISNULL('TOP('+CONVERT(varchar(10),@LeftLimit)+')','')+'
			 DB_NAME()
			,O.name 
			,S.name
			,ColName
			,O.object_id
			,OBJECTPROPERTY(O.object_id, ''IsEncrypted'')
			,O.type
			,O.type_desc
			,InSysComments
			,IsInMasterSysComments
		FROM
			(
				select
					name,object_id,type = CONVERT(varchar(3),type),type_desc ,schema_id
					,ColName = CONVERT(sysname,NULL)
				from
					sys.all_objects O 

				union all 

				select 
					name COLLATE DATABASE_DEFAULT,object_id,''TRS'',''SERVER_DDL_TRIGGER'',1,NULL
				from
					sys.server_triggers
				WHERE
					DB_ID() = 1

				union all 

				select 
					name COLLATE DATABASE_DEFAULT,object_id,''TRD'',''DATABASE_DDL_TRIGGER'',1,NULL
				from
					sys.triggers
				WHERE
					parent_class_desc = ''DATABASE''

				union all 

				select
					 OBJECT_NAME(C.object_id)
					,C.object_id
					,''CCC'',''COMPUTED_COLUMN''
					,O.schema_id
					,C.name
				from
					sys.computed_columns  C
					JOIN
					sys.all_objects O
						ON O.object_id = C.object_id
			) O
			JOIN
			sys.schemas	S
				ON S.schema_id = O.schema_id
			cross apply (
				SELECT 
					I.*
				FROM
				(
					SELECT 
						InSysComments = CASE WHEN EXISTS (
														SELECT * FROM sys.syscomments C
														WHERE C.id = O.object_id
													) THEN 1 
											ELSE 0 
										END
						,IsInMasterSysComments = CASE WHEN EXISTS (
														SELECT * FROM master.sys.syscomments C
														WHERE C.id = O.object_id
													) THEN 1 
											ELSE 0 
										END
				) I
			) A
		WHERE

			'+CASE WHEN @literal = 1 THEN
			'
				EXISTS (
					SELECT -- literal enabled 
						*
					FROM
						#sp_showcode_filters F
					WHERE
						F.FilterObject = O.name COLLATE DATABASE_DEFAULT
						AND
						F.FilterSchema = S.name COLLATE DATABASE_DEFAULT
				)
			'  
			ELSE 
			'0 = (
				SELECT 
					max(convert(int,IsNeg))
				FROM
					#sp_showcode_filters F
				WHERE
					O.name LIKE F.FilterObject COLLATE DATABASE_DEFAULT ESCAPE ''\''
					AND
					S.name LIKE F.FilterSchema COLLATE DATABASE_DEFAULT	ESCAPE ''\'' 
					AND
					DB_NAME() LIKE F.FilterDb COLLATE DATABASE_DEFAULT ESCAPE ''\''
					AND
					isnull(O.ColName,'''') LIKE F.FilterColumn COLLATE DATABASE_DEFAULT ESCAPE ''\''

			)
			'
			END+

			'AND (
				(
					O.type in (''P'',''FN'',''IF'',''TF'',''V'',''TR'')
					AND
					(InSysComments = 1 OR IsInMasterSysComments = 1 OR O.object_id < 0)
				)
				OR
				O.type IN (''TRS'',''TRD'',''CCC'')
			)
			AND
			O.type IN (SELECT TypeName COLLATE DATABASE_DEFAULT FROM #sp_showcode_FilterTypes)
			AND NOT EXISTS (
				SELECT * FROM #sp_showcode_SystemProcs
				WHERE SchemaName = S.name COLLATE DATABASE_DEFAULT 
				and Objectname = O.name COLLATE DATABASE_DEFAULT
			)
	'
	
	
	select @StartId = max(id) from @FoundObjects
	INSERT INTO @FoundObjects(DbName,ObjectName,ObjectSchema,ColName,ObjectId,IsEncrypted,ObjType,TypeDesc,IsInSysComments,IsInMasterComments)
	exec @spsql @sql,N''
	set @FoundCount = @@ROWCOUNT;
	set @TotalFound += @FoundCount
	
	if @top > 0
		SET @LeftLimit -= @FoundCount;

	IF @Debug = 1
		RAISERROR('	Found: %d objects (total = %d), Top: %d, LeftLimit: %d. StartId: %d',0,1,@FoundCount,@TotalFound,@top,@LeftLimit,@StartId) with nowait;

	-- If user specified just 1 filter, without wildcards, and we found somehting, we assume it searching extactly object name!
	IF @Seq = 1 AND @IsWild = 0	and @FoundCount = 1 AND @UserFilterCount = 1
		break;

	-- if top enabled and no more 
	if @top > 0 and @LeftLimit <= 0
		break;

	-- add systemprocs!
	-- if sysall disable, keep that table empty, so it dont affect not exists filter!
	IF @sysall = 0 AND @FoundCount >= 1
		insert into #sp_showcode_SystemProcs
		select distinct ObjectSchema,ObjectName from @FoundObjects
		where 
			ObjectId < 0 
			and 
			ObjectSchema = 'sys' 
			and 
			(
				(IsInSysComments = 0 and IsInMasterComments = 1)
				or
				DbName = 'master'
			)
			and
			Id > @StartId

END



if @TotalFound > 1 and @all = 0
begin
	select * from @FoundObjects;
	select 'Multiple options found. Refine search and try again or use @all = 1'
	return;
end

IF @Debug = 1
BEGIN
	SELECT * FROM @FoundObjects
END




-- iterate over each proc and run original sp_helptext!
declare
	@id int  = 0
	,@SchemaObject sysname
	,@sphelptext sysname
	,@ObjectDefinition nvarchar(max)
	,@NextLineIndex int
	,@LineLength int
	,@len int
	,@start int
	,@IsEncrypted bit
	,@IsDac int 
	,@ImageVal varbinary(Max)
	,@ObjectId int
	,@SubObjectId int
	,@Rc4Key varbinary(256)
	,@ObjectType varchar(10)
	,@ColName sysname
	,@LineNum int
	,@WarningLines varchar(max)
	,@buffer nvarchar(max)
	,@line nvarchar(max) 

select 
	@IsDac = Ep.is_admin_endpoint
from
	sys.dm_exec_sessions S
	JOIN
	sys.endpoints EP
		ON EP.endpoint_id = S.endpoint_id
WHERE
	S.session_id = @@SPID	


while 1 = 1
begin
 	SELECT TOP 1 
		 @id = id
		,@DbName = DbName
		,@SchemaObject = QUOTENAME(ObjectSchema)+'.'+QUOTENAME(ObjectName)
		,@IsEncrypted = IsEncrypted
		,@ObjectId = ObjectId
		,@ObjectType = ObjType
		,@ColName = ColName
	FROM
		@FoundObjects
	WHERE
		Id > @id
	ORDER BY
		ID 
	IF @@ROWCOUNT = 0
		BREAK

	set @sphelptext = @DbName+'..sp_helptext';
	set @spsql = @DbName+'..sp_executesql';
	set @ObjectDefinition = null

	if @IsEncrypted = 1
	begin
		IF @IsDac != 1
		BEGIN
			raiserror('-- Object %s is encrypted. To view, connect as DAC!',0,1,@SchemaObject) with nowait;
			continue;
		END	

		IF @Debug = 1 RAISERROR('Object %s i encrypted and we are connected via DAC. Trying decrypt...',0,1) WITH NOWAIT;

		-- first lets get the encrypted value!
		EXEC @spsql N'
			select @val = imageval, @sub = OV.subobjid 
			from sys.sysobjvalues OV
			WHERE OV.objid = @ObjectId
			AND OV.valclass = 1
		',N'@ObjectId int,@val varbinary(max) OUTPUT, @sub int OUTPUT',@ObjectId,@ImageVal OUTPUT, @SubObjectId OUTPUT;

		IF @ImageVal IS NULL
		BEGIN
			raiserror('-- Object %s is encrypted we are in DAC but encrypted source not found. Submit a bug report.',0,1,@SchemaObject) with nowait;
			continue;
		END	

		-- Now we have the encrypted code, lets build the key!
		SELECT 
			@Rc4Key = CONVERT(binary(20),HASHBYTES('SHA1', DBGuid + ObjectID + SubID))
		FROM
			(
				SELECT
					DBGuid			= convert(binary(16),convert(uniqueidentifier,DRS.family_guid))
					,ObjectID		= convert(binary(4),reverse(convert(binary(4),@ObjectId)))
					,SubID			= convert(binary(2),reverse(convert(binary(2),@SubObjectId)))
					,EncryptedDef	= @ImageVal
				FROM
					sys.database_recovery_status DRS
				WHERE
					DRS.database_id = DB_ID(@DbName)
			) D 


		IF @Debug = 1 RAISERROR('Invoking Rc4 decrypt...',0,1) WITH NOWAIT;
		exec sp_showcode_rc4decode @Rc4Key,@ImageVal,@ObjectDefinition OUTPUT
		IF @Debug = 1 RAISERROR('	Decrypted!',0,1) WITH NOWAIT;
	end	else begin
		
		set @sql = '
			select 
				@definition = OBJECT_DEFINITION(@ObjectId)
		'

		if @ObjectType = 'CCC'
			SET @sql = '
				SELECT 
					@definition = definition 
				FROM 
					sys.computed_columns C
				WHERE
					C.object_id = @ObjectID
					AND
					C.name = @column
			'


		-- get object definition!
		IF @Debug = 1 RAISERROR('Getting object defintion',0,1) with nowait;
		exec @spsql @sql,N'@ObjectId int,@definition nvarchar(max) OUTPUT,@column sysname',@ObjectId,@ObjectDefinition OUTPUT,@ColName
		IF @Debug = 1 RAISERROR('	Done!',0,1) with nowait;
	end

	if @ObjectDefinition is null  -- must exists some definition. Dont exists due some bug in prev code or permissions. Likely permission.
	begin
		RAISERROR('Definition not found for [%s].%s. Check permissions or try with DAC. ObjectId: %d',0,1,@DbName,@SchemaObject, @ObjectId) with nowait;
		update @FoundObjects
		set ObjectDefinition = '/* Cannot determine %s definition. Check your permissions or try with DAC if it is internal object */'
		where id = @id
		continue;
	end

	if @find is not null and @ObjectDefinition not like @find collate database_default escape '\'
	begin
		if @Debug = 1  RAISERROR('	Object [%s].%s ignored due to @find',0,1,@DbName,@SchemaObject) with nowait;
		continue
	end

	
	if @mode in ('xml','export','exportgo')
	begin
		if @ObjectDefinition is not null
			update @FoundObjects 
			set ObjectDefinition = @ObjectDefinition, IsEncrypted = 0
			where  ObjectDefinition IS NULL
			and Id = @id

		continue -- useful just for check for encryptions!
	end
		

	if @mode = 'sp_helptext'
	begin
		exec @sphelptext @SchemaObject,@columnname = @ColName
		continue;
	end

	if @mode in ('text','trunc')
	begin
		set @len = len(@ObjectDefinition)
		set @i = 0;

		IF @headers = 1
		BEGIN
			raiserror('-- Generated by sp_showcode',0,1);
			raiserror('-- Object: [%s].%s',0,1,@DbName,@SchemaObject)
		
			IF @ObjectType = 'CCC' -- column
			BEGIN
			   raiserror('-- Column: [%s]',0,1,@ColName)
			   PRINT '-- '+@ObjectDefinition;
			END

			raiserror('',0,1) with nowait; -- try force a flush!

			if @go = 1
				print 'GO'
		END

		

		if @ObjectType = 'CCC'
			CONTINUE;



		-- force always have a last line break!
		if right(@ObjectDefinition,1) != NCHAR(10)
			SET @ObjectDefinition += NCHAR(10)
		
		-- iterative over chars 
		-- IF line break found, print it and starts again.
		set @LineNum = 0;
		set @buffer = '';
		WHILE @i < @len
		BEGIN
			-- Find next linebreak! 
			set @NextLineIndex = CHARINDEX(NCHAR(10),@ObjectDefinition,@i)

			IF @Debug = 1 RAISERROR('	-- NextLineIndex: %d',0,1,@NextLineIndex) with nowait;

			IF @NextLineIndex > 0
			begin
				set @LineNum += 1;
				-- print entire line!
				set @LineLength = @NextLineIndex-@i
				
				-- if prev char is Lf, skip it!
				if @NextLineIndex >= 2 AND unicode(substring(@ObjectDefinition,@NextLineIndex-1,1)) = 13
					set @LineLength -= 1;
					
				set @start = @i;
				set @i = @NextLineIndex + 1;

				IF @Debug = 1 RAISERROR('	--	LineNum:%d, Length: %d',0,1,@LineNum,@LineLength) with nowait;

				-- if current line overflows the limit, then we print just the limi, and next loop we check the rest.
				if @mode = 'text'
					if @LineLength > @MaxLineSize
					begin
						set @LineLength =  @MaxLineSize
						set @i = @start+@LineLength;
					end

			    if @LineLength <= 0
					set @LineLength = 0;

				set @line = substring(@ObjectDefinition,@start,@LineLength)	+ nchar(13)+nchar(10)

				-- we will bufferize max as possible to avoid lot of writes to client, optimizing performance
				-- because print limit of 4000, if current line dont fit in buffer, then we flush them to client.
				if len(@buffer) + len(@line) > 4000
				begin 
					if len(@buffer) > 0 -- security for void print if buffer is empty and line is already grather than 4k
						print @buffer;
					set @buffer = '';
				end
				
				set @buffer += @line; -- here, our buffer is ready to acept line!
									
				if @LineLength >  @MaxLineSize -- print limit
				begin
				   raiserror('-- BIG LINE WARNING: previous line can be incomplete due be grather than %d chars. Use XML output. Length: %d. LineNum: %d',0,1, @MaxLineSize,@LineLength,@LineNum) with nowait;
				end

			end else 
				break

			
		END

		-- if buffer contains something, print!
		if len(@buffer) > 0
			print @buffer;

		IF @go = 1
			print 'GO'

		print ''



	end

end



-- for each object, run original sp_helptext!
if @mode = 'xml'
begin
	select 
		 FullName = QUOTENAME(DbName)+'.'+QUOTENAME(ObjectSchema)+'.'+QUOTENAME(ObjectName)
		,ObjType
		,TypeDesc
		,ObjectDefinition = (
			select
				'-- ',
				[processing-instruction(q)] = case 
							when IsEncrypted = 1 then 'ENCRYPTED: Object definition encrypted. Connect as DAC to decrypt!'
							else 'generated by sp_showcode. you can copy and paste in new ssms tab to better visualize'+NCHAR(13)+NCHAR(10)
								+CleanObjectDefinition
								+nchar(13)+nchar(10)+'-- '
						end
					
					
			FOR XML PATH(''),TYPE
		)
	from
		@FoundObjects
		CROSS APPLY (
			SELECT -- Clean the object definition XMl chars! Tks from sp_whoisactive (https://github.com/amachanic/sp_whoisactive/blob/4e656dda2dc1d62b84eb92d443fadfc2c5625ae3/sp_WhoIsActive.sql#L4042)
				CleanObjectDefinition = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									ObjectDefinition COLLATE Latin1_General_Bin2
									,NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
                                        NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
                                        NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
                                    NCHAR(0),N'')
		) A	
	WHERE
		ObjectDefinition IS NOT NULL

	return;
end

if @mode in ('export','exportgo')
BEGIN
	

	IF @mode = 'export'
		select 
			@go = 0, @headers = 0

	SELECT
		[text] = 
		+case when @headers = 1 THEN 
		+CrLf+'-- Generated by sp_showcode '+F.FullName
		+CrLf+'-- Object: '+F.FullName
		+ISNULL(CrLf+'-- Column: '+F.ColName,'')
		+CrLf
		+case when @go = 1 then 'GO' else '' end
		ELSE '' END
		+CrLf
		+CrLf

		+ObjectDefinition
		
		+case when @go = 1 THEN 
		+CrLf
		+'GO'
		+CrLf
		ELSE '' END
		+CrLf
		+CrLf
	FROM
		@FoundObjects F
		CROSS JOIN (
			SELECT 
				CrLf = NCHAR(13)+NCHAR(10)
		) V
	WHERE
		F.ObjectDefinition IS NOT NULL
END	


GO

EXEC sp_ms_marksystemobject sp_showcode
GO
EXEC sp_ms_marksystemobject sp_showcode_rc4decode
GO