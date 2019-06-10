/*
 ===============================================================================
 Author:	     CHRIS BELL
 Source:       https://wateroxconsulting.com/archives/quick-ps-script-get-sql-server-configuration-aliases/
 Article Name: Quick PS script to get SQL Server Configuration Aliases
 Create Date:  N/A
 Description:  This very simple script helps to get the details of both
               the 32 and 64bit SQL Server aliases that are setup on a system.	   
 ===============================================================================
*/  

Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo' #| Out-File -filepath C:\Alias_Names.txt