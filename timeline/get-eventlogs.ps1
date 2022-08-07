<#

.SYNOPSIS

Reads a windows event log file (evtx) and converts it to a csv file with filtering capability

.DESCRIPTION

Reads evt and evtx windows log files and outputs a powershell object. You can filter on error level, 
time/date, eventid, userid, and LogSourceType.

It returns DateTime, EventID, Level, ShortEvent, User, Event, LogSource, LogSourceType, and Machine.

Evt logs can sometimes get corrupted and you will get the error "The data is invalid".  Run fixevt.exe
to fix the log file.  http://www.whiteoaklabs.com/computer-forensics.html

.PARAMETER logFile

logfile is required -- the path to the log file.

.PARAMETER Level

Level -- optional -- severity level 2 = error 3 = warning 4 = informational

.PARAMETER StartTime

StartTime -- optional -- the start date/time for filtering logs

.PARAMETER EndTime

EndTime -- optional -- the end date/time for filtering logs

.PARAMETER EventID

EventID -- optional -- The event id to filter on -- multiple EventIDs can be entered seperated by a comma

.PARAMETER UserId

UserID -- optional -- The user id to filter on -- multiple UserIDs can be entered seperated by a comma

.PARAMETER LogSourceType

LogSourceType -- optional -- Where log came from e.g. "EMET", "MSSQL$SQLEXPRESS"

.PARAMETER Where

Where -- optional -- search the Message field for some text -- the new evtx format hides things such as user names there.

.EXAMPLE

 .\get-eventlogs.ps1 c:\windows\system32\winevt\application.evtx | export-csv -notype c:\temp\app.csv

 Reads the log file at c:\windows\system32\winevt\application.evtx and puts the output in c:\temp\app.csv

 .EXAMPLE

 .\get-eventlogs.ps1 c:\windows\system32\winevt\application.evtx | convert-eventlog-to-timeline.ps1 | export-csv -notype c:\temp\app.csv

 Reads the log file at c:\windows\system32\winevt\application.evtx, converts it to timelinel format and puts the output in c:\temp\app.csv
 
.EXAMPLE

 .\get-eventlogs.ps1 c:\windows\system32\winevt\application.evtx -level 2  | export-csv -notype c:\temp\app.csv

 Reads the log file at c:\windows\system32\winevt\application.evtx and puts the output in c:\temp\app.csv.  Selects only error logs.
 
.EXAMPLE

 .\get-eventlogs.ps1 c:\windows\system32\winevt\application.evtx -startdate "1/1/2014" -enddate "12/30/2014"  | export-csv -notype c:\temp\app.csv

 Reads the log file at c:\windows\system32\winevt\application.evtx and puts the output in c:\temp\app.csv.  Only returns
 the logs from 2014.
 
.EXAMPLE

 .\get-eventlogs.ps1 c:\windows\system32\winevt\security.evtx -where "AD73025" -eventid 4346  | export-csv -notype c:\temp\app.csv

 Reads the log file at c:\windows\system32\winevt\security.evtx and puts the output in c:\temp\app.csv.  Only logs
 that contain AD73025 in the message field and have event ID 4346 are returned.
 
.NOTES

Author: Tom Willett 
Date: 2/26/2015

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$logFile,
	[Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$Level,
	[Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$StartTime,
	[Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$EndTime,
	[Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$EventID,
	[Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$UserID,
	[Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$LogSourceType
)

$fext = [system.io.path]::getextension($logFile)
$filter = @{Path="$logFile"}
if ($level -ne "") { $filter.add("Level",$Level) }
if ($StartTime -ne "") { $filter.add("StartTime",$StartTime) }
if ($EndTime -ne "") { $filter.add("EndTime",$EndTime) }
if ($EventId-ne "") { $filter.add("ID",$EventID) }
if ($UserID -ne "") { $filter.add("UserID",$UserID) }
if ($LogSourceType -ne "") { $filter.add("ProviderName",$LogSourceType) }
$Where = "*" + $Where + "*"
if ($fext -eq ".evt") {
	$old = $true
} else {
	$old = $false
}
get-winevent -oldest:$old -filterhashtable $filter | 
select-object @{Name="DateTime";Expression={$_.timecreated}},@{Name="EventID";Expression={$_.ID}},Level,@{Name="ShortEvent";Expression={$_.TaskDisplayName}},@{Name="User";Expression={$_.UserId}}, @{Name="Event";Expression={(($_.message).replace("`n", " ")).replace("`t"," ")}}, @{Name="LogSource";Expression={$logfile}}, @{Name="LogSourceType";Expression={$_.ProviderName}},@{Name="Machine";Expression={$_.MachineName}}
