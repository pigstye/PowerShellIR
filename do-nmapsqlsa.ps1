<#

.SYNOPSIS

Scan a subnet with nmap looking for sql server with no sa password set

.DESCRIPTION

	Scan a subnet looking for sql server with no sa password set

	Look for results like this:
	Nmap scan report for 192.168.0.144
	 Host is up (0.00s latency).
	 PORT     STATE  SERVICE
	 1433/tcp open ms-sql-s

	 Host script results:
	 | ms-sql-empty-password:
	 |   [192.168.0.144\MSSQLSERVER]
	 |_    sa:<empty> => Login Success

	 This means you have an empty sa password that needs to be fixed.
	 
	If the the xp_cmdshell stored procedure is installed (it it installed by default).

	It allows you to run any dos command as system, e.g.

	sqlcmd -q "exec xp_cmdshell 'whoami'" -S computername

	or

	sqlcmd -q "exec xp_cmdshell 'dir c:\'" -S computername

.EXAMPLE

do-nmapsqlsa.psq  10.78.0.0/16

.NOTES

	Author: Tom Willett
	Date: 8/28/2014
	© 2014 Oink Software

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string[]]$subnet)

process {
	nmap -p 1433 --script ms-sql-empty-password --script-args mssql.instance-all $subnet
}