<#

.SYNOPSIS

Converts the output from get-linuxFileInfo.ps1 and converts it to the timeline format.

.DESCRIPTION

Takes the output from get-linuxFileInfo.ps1 and converts it to the following timeline format:
DateTime,MACB,User,Machine,SHA1,ShortEvent,Event,LogSource,LogSourceType,Inode,Notes

.Parameter DateTime

.Parameter Machine

.Parameter LogSource

.Parameter LogSourceType

.Parameter Event


.EXAMPLE

 .\get-LinuxLog.ps1 G:\ | .\convert-linuxLog-to-timeline.ps1 | export-csv -notype files.csv

Retrieves the information about the files on the mounted linux file system at g: converts it to timeline format and exports to files.csv
 
.NOTES

Author: Tom Willett 
Date: 3/6/2015
© 2015 Oink Software

#>

# Timeline Format DateTime,MACB,User,Machine,ShortEvent,Event,LogSource,LogSourceType,Inode,Notes
Param([Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)][string]$DateTime,
	[Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)][string]$Machine,
	[Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)][string]$LogSource,
	[Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)][string]$LogSourceType,
	[Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)][string]$Event)

process {
	$tmp = "" | Select DateTime,MACB,User,Machine,SHA1,ShortEvent,Event,LogSource,LogSourceType,Inode,Notes
	$tmp.DateTime = $DateTime
	$tmp.MACB = "MAC"
	$tmp.Machine = $Machine
	$dt = get-childitem $logsource
	$tmp.LogSource = $dt.name
	$tmp.LogSourceType = $LogSourceType
	$tmp.event = $Event
	write-output $tmp
}
