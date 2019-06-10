/*
 ===============================================================================
 Author:	    GLENN BERRY
 Source:      https://sqlserverperformance.wordpress.com/2010/08/02/a-small-collection-of-dbcc-commands/
 Create Date: 02-AUG-2010
 Description: A Small Collection of Useful DBCC Commands.	
 Revision History:
 Usage:		   N/A			   
 ===============================================================================
*/

-- Clears out contents of buffer cache
-- Use caution before doing this on a production system!
DBCC DROPCLEANBUFFERS;

-- Clears procedure cache on entire SQL instance
DBCC FREEPROCCACHE;

-- Remove the specific plan from the cache using the plan handle
DBCC FREEPROCCACHE (0x060006001ECA270EC0215D05000000000000000000000000);

-- Clear ad-hoc SQL plans for entire SQL instance
DBCC FREESYSTEMCACHE('SQL Plans'); 

-- Clears TokenAndPermUserStore cache on entire SQL instance
DBCC FREESYSTEMCACHE ('TokenAndPermUserStore');

-- Releases all unused cache entries from all caches. ALL specifies all supported caches
-- Asynchronously frees currently used entries from their respective caches after they become unused
DBCC FREESYSTEMCACHE ('ALL') WITH MARK_IN_USE_FOR_REMOVAL;


-- Determine the id of the current database
-- and flush the procedure cache for only that database
DECLARE @intDBID AS INT = (SELECT DB_ID());
DBCC FLUSHPROCINDB (@intDBID);

-- Clear Wait Stats for entire instance
DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);

-- Get VLF count for transaction log for the current database,
-- number of rows equals VLF count. Lower is better!
DBCC LOGINFO;

-- Returns lots of useful information about memory usage
DBCC MEMORYSTATUS;

-- Find oldest open transaction
DBCC OPENTRAN;

-- Get input buffer for a SPID
DBCC INPUTBUFFER(21);

-- Check trace status for instance
DBCC TRACESTATUS(-1)