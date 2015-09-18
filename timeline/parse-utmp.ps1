<#
 
.SYNOPSIS
 
Parse utmp, wtmp and btmp files from linux
 
.DESCRIPTION

Parse utmp, wtmp and btmp files from linux.  It does timezone conversion of the times.
It requires the companion script utmp-parser.ps1.  The output is DateTime, Utype, 
ProcessID, Device, User, HostName, Addr, Session, Note, LogName, LogPath.

.Parameter uTmpFile

The utmp file to parse-taskfile

.Parameter tz

The time zone to convert the date/times to.  See list-timezones.ps1 to get the time zone names.

.Parameter btmp

Set this value to $true if processing a btmp file or if the file is named btmp it will detect it 
automatically.

.EXAMPLE
 
.\parse-utmp.ps1 d:\btmp

Parses the contents of btmp and displays it on the console.
 
.EXAMPLE
 
.\parse-utmp.ps1 d:\btmp | .\convert-utmp-to-timeline.ps1 | export-csv -notype utmp.csv

Parses the contents of btmp, converts it to timeline format and saves it in utmp.csv
 
.NOTES

Author: Tom Willett 
Date: 3/2/2015
© 2015 Oink Software

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True)][string]$uTmpFile,
	[Parameter(Mandatory=$True,ValueFromPipeline=$false)][string]$tz,
	[Parameter(Mandatory=$False,ValueFromPipeline=$false)][boolean]$btmp=$false)

process {
	write-host "Processing " $uTmpFile
	$dt = get-childitem $uTmpFile
	get-content $uTmpFile -encoding byte -readcount 384 | .\utmp-parser.ps1 -btmp $btmp -logname $dt.name -logpath $dt.DirectoryName -tz $tz
}