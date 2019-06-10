/************************************************************************************
Script to download file via FTP in SQL Server
http://beyondrelational.com/justlearned/posts/813/script-to-download-file-via-ftp-in-sql-server.aspx
************************************************************************************/
DECLARE @cmd          VARCHAR(1000),
        @FTPServer    VARCHAR(128) = 'FTP Server Name',
        @FTPUser      VARCHAR(128) = 'FTP User Name',
        @FTPPWD       VARCHAR(128) = 'Password',
        @FTPPath      VARCHAR(128) = '/subfolder1/subfolder2/', -- or '' if not having subfolders,
        @FTPFileName  VARCHAR(128) = 'FTP File Name',
        @SourcePath   VARCHAR(128) = 'Local Path for download',
        @SourceFile   VARCHAR(128) = 'Local File Name to be saved as',
        @workdir      VARCHAR(128) = 'C:\FTP\',
        @workfilename VARCHAR(128) = 'ftpcmd.txt';

-- Writing steps to working file
SELECT @cmd = 'echo '+ 'open ' + @FTPServer+ ' > ' + @workdir + @workfilename;
EXEC master..xp_cmdshell @cmd;

SELECT @cmd = 'echo '+ @FTPUser+ '>> ' + @workdir + @workfilename;
EXEC master..xp_cmdshell @cmd;

SELECT @cmd = 'echo '+ @FTPPWD+ '>> ' + @workdir + @workfilename;
EXEC master..xp_cmdshell @cmd;

SELECT @cmd = 'echo '+ 'get ' + @FTPPath + @FTPFileName + ' ' + @SourcePath + @SourceFile+ ' >> ' + @workdir + @workfilename;
EXEC master..xp_cmdshell @cmd;

SELECT @cmd = 'echo '+ 'quit'+ ' >> ' + @workdir + @workfilename;
-- Executing steps from working file
EXEC master..xp_cmdshell @cmd;

SELECT @cmd = 'ftp -s:' + @workdir + @workfilename;
-- Executing final step
EXEC master..xp_cmdshell @cmd;