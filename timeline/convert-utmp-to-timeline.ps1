<#
 
.SYNOPSIS
 
Converts the output from parse-utmp.ps1 to timeline format.
 
.DESCRIPTION

Converts the output from parse-utmp.ps1 to timeline format.

.Parameter Machine

This can be entered on the commandline 

.EXAMPLE
 
.\parse-utmp.ps1 d:\btmp | .\convert-utmp-to-timeline.ps1 | export-csv -notype utmp.csv

Parses the contents of btmp, converts it to timeline format and saves it in utmp.csv
 
.NOTES

Author: Tom Willett 
Date: 3/2/2015
© 2015 Oink Software

#>

# Timeline Format DateTime,MACB,User,Machine,ShortEvent,Event,LogSource,LogSourceType,Inode,Notes
Param([Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)][string]$DateTime,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Utype,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$ProcessID,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Device,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$User,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$HostName,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Addr,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Session,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Note,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$LogName,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$LogPath,
	[Parameter(Mandatory=$False,ValueFromPipeline=$False)][string]$machine)

process {
	$tmp = "" | Select DateTime,Utype,ProcessID,Device,User,HostName,Addr,Session,Note,Machine,LogName
	$tmp.DateTime = $DateTime
	$tmp.Utype = $UType
	$tmp.ProcessID = $ProcessID
	$tmp.Device = $Device
	$tmp.User = $User
	$tmp.HostName = $HostName
	$tmp.Addr = $Addr
	$tmp.Session = $Session
	$tmp.Note = $Note
	$tmp.Machine = $Machine
	$tmp.LogName = $LogName
	$outPth = $LogPath + "\utmp.csv"
	$tmp | export-csv -notype $outPth -append
	$tmp = "" | Select DateTime,MACB,User,Machine,SHA1,ShortEvent,Event,LogSource,LogSourceType,Inode,Notes
	$tmp.DateTime = $DateTime
	$tmp.MACB = "MAC"
	$tmp.User = $User
	$tmp.machine = $Machine
	switch ($UType) {
		"User Process" {$tmp.ShortEvent = "Login"}
		"Process End" {$tmp.ShortEvent = "Logout"}
		default {$tmp.ShortEvent = $UType}
	}
	$tmp.Event = $Note
	$tmp.LogSource = $logname
	$tmp.LogSourceType = "utmp"
	write-output $tmp
}
