/*
 ===============================================================================
 Author:	     BRAD SCHULZ
 Source:       http://beyondrelational.com/modules/2/blogs/114/posts/14617/delimited-string-tennis-anyone.aspx
 Article Name: Delimited String Tennis Anyone?
 Create Date:  20-MAY-2010
 Description:  This script converts a single comma separated row into multiple rows	
 Revision History:
 15-DEC-2015 - RAGHUNANDAN CUMBAKONAM
			Formatted the code.
			Added the history.
 Usage:		N/A
 ===============================================================================
*/
SET NOCOUNT ON

DECLARE @Comma_List VARCHAR(MAX) = 'ABC' + REPLICATE(CAST(',ABC' AS VARCHAR(MAX)), 9),
        @XML_List XML;

SELECT @Comma_List AS CSV_List;
SET @XML_List = CAST('<i>' + REPLACE(@Comma_List, ',', '</i><i>') + '</i>' AS XML);

SELECT LTRIM(RTRIM(x.i.value('.', 'VARCHAR(3)'))) AS Individual_Rows
  FROM @XML_List.nodes('i') x(i);