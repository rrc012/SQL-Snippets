USE tempdb;  --Be sure to test in a safe environment
GO

/*
 ===============================================================================
 Author:	     LUIS CAZARES
 Source:       http://www.sqlservercentral.com/articles/T-SQL/130558/
 Article Name: Wildcard Searches
 Create Date:  29-SEP-2015
 Description:  This script demonstrates the serach pattern using wildcard
               characters.	
 Revision History:
 30-OCT-2015 - RAGHUNANDAN CUMBAKONAM
		   - Formatted the code.
		   - Added the history.

 Usage:		N/A			   
 ===============================================================================
*/  

--If the table exists, drop it.
IF OBJECT_ID('tempdb..LikeTest') IS NOT NULL DROP TABLE #LikeTest;
GO

CREATE TABLE #LikeTest
(
    Id                 INT IDENTITY CONSTRAINT PK_LikeTest PRIMARY KEY NONCLUSTERED,
    Name               VARCHAR(1000),
    Phone              VARCHAR(1000),
    Last_Movie_Release DATE,
    Amount             VARCHAR(1000),
    Comments           VARCHAR(1000)
);

CREATE CLUSTERED INDEX IX_LIKETest ON #LikeTest(Name);

INSERT INTO #LikeTest(Name, Phone, Last_Movie_Release, Amount, Comments)
VALUES
    ('Bruce Wayne',     'Confidential',   '20120720', '35131'        , 'Reach at email: bwayne@WayneIndustries.com'),
    ('Clark Kent',      '8457390095',     '20130614', '58455.64'     , 'Work email: ckent@daily_planet.com'),
    ('Richard Grayson', '212-555-0187',   '19970620', '.63521'       , 'Known as Dick Grayson'),
    ('Diana Prince',    '849-555-0139',    NULL     , '58485.'       , 'Amazon princess, treat with respect'),
    ('J''onn J''onzz',  'N/A',             NULL     , '-15612'       , 'Last Martian'),
    ('Barry Allen',     '(697) 555-0142',  NULL     , '-1.5413'      , 'Too fast'),
    ('Reed Richards',   '917-330-2568',   '20150807', '-4156-15'     , NULL),
    ('Susan Storm',     '917-970-0138',   '20150807', '156.516.51'   , NULL),
    ('Johnny Storm',    '917-913-0172',   '20150807', '665465-'      , NULL),
    ('Ben Grimm',       '917-708-0141',   '20150807', 'One Thousand' , NULL),
    ('Peter Parker',    '917-919-0140',   '20140502', '56E6546'      , 'With great power comes great responsibility'),
    ('Tony Stark',      '492-167-0139',   '20130503', '$'            , ''),
    ('Wade Wilson',     '692-257-1937',    NULL     , 'ss'           , 'Just 50% hero'),
    ('Bruce Banner',    '781-167-4628',   '20080613', 'FFFFFF'       , 'sdo@a#%^add34.voi');

----------------------------------------------------------------------------------------
-- Basic Searches
----------------------------------------------------------------------------------------
--A) Return all rows when the name starts by B    
SELECT * FROM #LikeTest WHERE Name LIKE 'B%';
--B) Return all rows when the phone starts by 917
SELECT * FROM #LikeTest WHERE phone LIKE '917%';
--C) Return all rows when the name starts by any character between A and L
SELECT * FROM #LikeTest WHERE Name LIKE '[A-L]%';
--D) Return all rows when the name starts by the characters C, D or W
SELECT * FROM #LikeTest WHERE Name LIKE N'[CDW]%';
--E) Return all rows when the last_movie_release starts by 2015
SELECT * FROM #LikeTest WHERE last_movie_release LIKE '2015%';

--F) Ends with ‘some string’
SELECT * FROM #LikeTest WHERE Name LIKE '%Parker';

--G) Contains ‘some string’
SELECT * FROM #LikeTest WHERE Name LIKE '%Richard%';

--H) Contains ‘exact word’
SELECT * FROM #LikeTest WHERE Name LIKE '% Richard %';
SELECT * FROM #LikeTest WHERE ' ' + Name + ' ' LIKE '%[^A-Za-z]Richard[^A-Za-z]%';

--I) The N character is ‘some character’
SELECT * FROM #LikeTest WHERE Name LIKE REPLICATE('_', 3) + 'n%';
SELECT * FROM #LikeTest WHERE Name LIKE '%n' + REPLICATE('_', 3);

--J) Only valid strings
SELECT *
  FROM #LikeTest
 WHERE Amount NOT LIKE '%[^-0-9.]%' --Only digits, decimal points and minus signs
   AND Amount NOT LIKE '%[.]%[.]%' --Only one decimal point allowed
   AND Amount NOT LIKE '_%[-]%'; --Minus sign should only appear at the beginning of the string
--Or invalid strings
SELECT *
  FROM #LikeTest
 WHERE Amount  LIKE '%[^-0-9.]%' --Only digits, decimal points and minus signs
    OR Amount  LIKE '%[.]%[.]%' --Only one decimal point allowed
    OR Amount  LIKE '_%[-]%'; --Minus sign should only appear at the beginning of the string

----------------------------------------------------------------------------------------
-- Common problems
----------------------------------------------------------------------------------------
--K) Not returning all the results
SELECT * FROM #LikeTest WHERE comments LIKE '%';

--L) Need to include characters used as wildcards
SELECT * FROM #LikeTest WHERE comments LIKE '%[0-9]~%%' ESCAPE '~';
SELECT * FROM #LikeTest WHERE comments LIKE '%[0-9][%]%';

--M) Ignoring trailing (or leading) spaces
DECLARE @Name CHAR(50) = 'Bruce';
SET @Name = RTRIM(@Name) + '%';

SELECT @Name;

SELECT * FROM #LikeTest WHERE Name LIKE @Name;

--N) Thinking that because something complies with a rule, it won’t bring invalid values
SELECT *
  FROM #LikeTest
 WHERE comments LIKE '%[A-Za-z0-9.+_]@[A-Za-z0-9.+_]%.[A-Za-z][A-Za-z]%';
GO

DROP TABLE #LikeTest;