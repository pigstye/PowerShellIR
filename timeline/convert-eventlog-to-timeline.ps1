<#

.SYNOPSIS

Takes the output from get-eventlogs.ps1 and converts it to timeline format.

.DESCRIPTION

Takes the output from get-eventlogs.ps1 and converts it to the following timeline format:
DateTime,MACB,User,Machine,SHA1,ShortEvent,Event,LogSource,LogSourceType,Inode,Notes

.PARAMETER DateTime

.PARAMETER EventID

.PARAMETER Level

.PARAMETER ShortEvent

.PARAMETER User

.PARAMETER Event

.PARAMETER LogSource

.PARAMETER LogSourceType

.PARAMETER Machine

Required can be entered on commandline.


.EXAMPLE

 .\get-eventlogs.ps1 c:\windows\system32\winevt\security.evtx | convert-eventlog-to-timeline.ps1 | export-csv -notypeinformation logs.csv

 Gets all the security event log and converts it to my timeline format and exports it to logs.csv
 
.EXAMPLE

 .\get-eventlogs.ps1 c:\windows\system32\winevt\application.evtx | convert-eventlog-to-timeline.ps1 | export-csv -notypeinformation logs.csv -append

 Gets the application event log and converts it to my timeline format and appends it to logs.csv
 
.NOTES

Author: Tom Willett 
Date: 2/26/2015

#>

Param([Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)][string]$DateTime,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$EventID,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Level,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$ShortEvent,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$User,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Event,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$LogSource,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$LogSourceType,
	[Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)][string]$Machine)
process {
	$tmp = "" | Select DateTime,MACB,User,Machine,SHA1,ShortEvent,Event,LogSource,LogSourceType,Inode,Notes
	$tmp.DateTime = $DateTime
	$tmp.User = $User
	$tmp.MACB = "B"
	$tmp.Machine = $Machine
	$tmp.ShortEvent = $ShortEvent
	$tmp.Event = $Event
	$tmp.LogSource = (get-childitem $logsource).name
	$tmp.LogSourceType = $LogSourceType
	$tmp.Notes = "EventID = " + $eventID + " Level = " + $Level
	write-output $tmp
}