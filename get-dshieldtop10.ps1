<#

.SYNOPSIS
	Returns a PowerShell object of the current DShield top 10
	
.DESCRIPTION
	Reads the DShield top 10 from the web and converts it to a PowerShell object

.EXAMPLE
	ps> .\get-dshieldtop10.ps1
	
.NOTES

 Author: Tom Willett 
 Date:  3/23/2012

#>

((new-object net.webclient).DownloadString("http://feeds.dshield.org/block.txt") -split '[\r\n]') | ? {$_} | Where-Object { !$_.StartsWith("#") } | ConvertFrom-Csv -delimiter "`t"