<#

.SYNOPSIS

Parse a task scheduler job file.

.DESCRIPTION

Parses the binary format of task Scheduler job files from Windows XP and Server 2003.

.PARAMETER jobFile

Jobfile is required -- the path to the job file.

.EXAMPLE

 .\parse-jobfile.ps1 at1.job

 Parse the job file called at1.job and displays the results.
 
.NOTES

Author: Tom Willett 
Date: 12/22/2014

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$false,ValueFromPipelinebyPropertyName=$false)][string]$jobFile)

function toHex {
	Param([Parameter(Mandatory=$True)][byte[]]$byte)
	$hx = "0x"
	switch ($byte.length) {
		1 { $hx += "{0:X2}" -f $byte }
		2 { $hx += "{0:X4}" -f [bitconverter]::touint16($byte,0) }
		4 { $hx += "{0:X8}" -f [bitconverter]::touint32($byte,0) }
		default { $hx += "00" }
	}
	$hx
}

function GetPriority {
	Param([Parameter(Mandatory=$True)][string]$Data)
	$p = ""
	if ($data -band 0x20) {
		$p = "Normal "
	}
	if ($data -band 0x40) {
		$p += "Idle "
	}
	if ($data -band 0x80) {
		$p += "Time-Critical"
	}
	if ($data -band 0x100) {
		$p += "Highest"
	}
	$p
}

function getFlags {
	Param([Parameter(Mandatory=$True)][int]$Data)
	$f = ""
	if ($data -band 0x1) { $f = " interact with the logged-on user " }
	if ($data -band 0x2) { $f += "Can be deleted when there are no more scheduled run times " }
	if ($data -band 0x4) { $f += "Disabled " }
	if ($data -band 0x10) { $f += "Task begins only if the computer is idle " }
	if ($data -band 0x20) { $f += "Task can be terminated if the computer makes an idle to non-idle transition while the task is running " }
	if ($data -band 0x40) { $f += "Task cannot start if its target computer is running on battery power " }
	if ($data -band 0x80) { $f += "Task can end, and the associated application quit if the task's target computer switches to battery power " }
	if ($data -band 0x200) { $f += "Task is hidden " }
	if ($data -band 0x800) { $f += "Task can start again if the computer makes a non-idle to idle transition " }
	if ($data -band 0x1000) { $f += "Task can cause the system to resume, or awaken if the system is sleeping " }
	if ($data -band 0x2000) { $f += "Task can only run if the user specified in the task is logged on interactively " }
	if ($data -band 0x1000000) { $f += "Task has an application name defined" }
	$f
}

function toASCII
{
	Param ([Parameter(Mandatory = $True)][System.byte[]]$byteArray)

	$aString = ""
	if ($byteArray.length -gt 1) {
		$encoding= [System.Text.Encoding]::ASCII
		$uencoding = [System.Text.Encoding]::UNICODE
		$aArray = [System.Text.Encoding]::Convert($uencoding, $encoding, $byteArray)
		foreach($a in $aArray) { $aString += [char]$a }
	}
	$aString
}

function getString {
	Param ([Parameter(Mandatory = $True)][System.byte[]]$byteArray)
	$len = [bitconverter]::touint16($byteArray,0) * 2
	$str = toASCII($byteArray[2..($len-1)])
	$str
}

function getTriggerFlags {
	Param ([Parameter(Mandatory = $True)][int]$data)
	$f = ""
	if ($data -band 0x1) { $f = "Task can stop at some point in time " }
	if ($data -band 0x2) { $f += "Task can be stopped at the end of the repetition period " }
	if ($data -band 0x4) { $f += "Disabled " }
	$f
}

function getDOW {
	Param([Parameter(Mandatory=$True)][int]$Data)
	$f = ""
	if ($data -band 0x1) { $f = "Mon " }
	if ($data -band 0x2) { $f += "Tue " }
	if ($data -band 0x4) { $f += "Wed " }
	if ($data -band 0x8) { $f += "Thu " }
	if ($data -band 0x10) { $f += "Fri " }
	if ($data -band 0x20) { $f += "Sat " }
	if ($data -band 0x40) { $f += "Sun " }
	$f
}

$out = @()
$ver = @{"0x0400" = "Windows NT 4.0";"0x0500" = "Windows 2000"; "0x0501" = "Windows XP"; "0x0600" = "Windows Vista"; "0x0601" = "Windows 7"; "0x0602" = "Windows 8"; "0x0603" = "Windows 8.1"}
$status = @{"0x00041300" = "Task is not running but is scheduled to run at some time in the future."; "0x00041301" = "Task is currently running.";"0x00041305" = "The task is not running and has no valid triggers."}
$days = $("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday")
$triggerType = @{"0x00000000" = "Once"; "0x00000001" = "DAILY ";"0x00000002" = "WEEKLY";"0x00000003" = "MONTHLYDATE";"0x00000004" = "MONTHLYDOW";"0x00000005" = "EVENT_ON_IDLE";"0x00000006" = "EVENT_AT_SYSTEMSTART";"0x00000007" = "EVENT_AT_LOGON"} 

$j = get-content $jobFile -encoding byte
$out += $jobFile
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Product Version"
$tmp.Offset = "0x00"
$tmp.Value = toHex($j[0..1])
$tmp.Notes = $ver.get_item($tmp.Value)
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "File Version"
$tmp.Offset = "0x02"
$tmp.Value = toHex($j[2..3])
$tmp.Notes = toHex($j[2..3])
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Job UID"
$tmp.Offset = "0x04"
$tmp.Value = ([bitconverter]::tostring($j,4,16)).replace("-"," ")
$tmp.Notes = $tmp.Value
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "App Name Offset"
$tmp.Offset = "0x14"
$tmp.Value = toHex($j[20..21])
$tmp.Notes = $tmp.Value
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Trigger Offset"
$tmp.Offset = "0x16"
$tmp.Value = toHex($j[22..23])
$tmp.Notes = $tmp.Value
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Error Retry Count"
$tmp.Offset = "0x18"
$tmp.Value = toHex($j[24..25])
$tmp.Notes = $tmp.Value
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Error Retry Interval"
$tmp.Offset = "0x1a"
$tmp.Value = toHex($j[26..27])
$tmp.Notes = "Minutes"
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Idol Deadline"
$tmp.Offset = "0x1c"
$tmp.Value = toHex($j[28..29])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,28)) + " Minutes"
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Idol Wait"
$tmp.Offset = "0x1e"
$tmp.Value = toHex($j[30..31])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,30)) + " Minutes"
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Priority"
$tmp.Offset = "0x20"
$tmp.Value = toHex($j[32..35])
$tmp.Notes = getPriority([bitconverter]::touint32($j,32))
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Max Run Time"
$tmp.Offset = "0x24"
$tmp.Value = toHex($j[36..39])
$tmp.Notes = [convert]::tostring([bitconverter]::touint32($j,36)) + " Milliseconds"
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Exit Code"
$tmp.Offset = "0x28"
$tmp.Value = toHex($j[40..43])
$tmp.Notes = $tmp.Value
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Status"
$tmp.Offset = "0x2c"
$tmp.Value = toHex($j[44..47])
$tmp.Notes = $status.get_item($tmp.value)
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Flags"
$tmp.Offset = "0x30"
$tmp.Value = toHex($j[48..51])
$fl = [bitconverter]::touint32($j,48)
$tmp.Notes = getFlags($fl)
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Year Last Run"
$tmp.Offset = "0x34"
$tmp.Value = toHex($j[52..53])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,52))
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Month Last Run"
$tmp.Offset = "0x36"
$tmp.Value = toHex($j[54..55])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,54))
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "WeekDay Last Run"
$tmp.Offset = "0x38"
$tmp.Value = toHex($j[56..57])
$tmp.Notes = $days[[bitconverter]::touint16($j,56)]
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Day Last Run"
$tmp.Offset = "0x3a"
$tmp.Value = toHex($j[58..59])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,58))
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Hour Last Run"
$tmp.Offset = "0x3c"
$tmp.Value = toHex($j[60..61])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,60))
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Minute Last Run"
$tmp.Offset = "0x3e"
$tmp.Value = toHex($j[0x3e..0x3f])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,0x3e))
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Second Last Run"
$tmp.Offset = "0x40"
$tmp.Value = toHex($j[0x40..0x41])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,0x40))
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Millisecond Last Run"
$tmp.Offset = "0x42"
$tmp.Value = toHex($j[0x42..0x43])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,0x42))
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Running Instance Count"
$tmp.Offset = "0x44"
$tmp.Value = toHex($j[0x44..0x45])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,0x44))
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$st = 0x46
$tmp.Data = "App Name"
$tmp.Offset = "0x" + [bitconverter]::tostring($st)
$lng = ([bitconverter]::touint16($j,$st) * 2)
if ($lng -gt 0) {
	$tmp.Value = ([bitconverter]::tostring($j,$st+2,$lng-1)).replace("-","")
	$tmp.Notes = getString($j[$st..($lng+$st)])
} else {
	$tmp.Value = ""
	$tmp.Notes = ""
}
$st += 2 + $lng
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Parameters"
$tmp.Offset = "0x{0:X4}" -f $st
$lng = ([bitconverter]::touint16($j,$st) * 2)
if ($lng -gt 0) {
	$tmp.Value = ([bitconverter]::tostring($j,$st+2,$lng-1)).replace("-","")
	$tmp.Notes = getString($j[$st..($lng+$st)])
} else {
	$tmp.Value = ""
	$tmp.Notes = ""
}
$st += 2 + $lng
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Working Directory"
$tmp.Offset = "0x{0:X4}" -f $st
$lng = ([bitconverter]::touint16($j,$st) * 2)
if ($lng -gt 0) {
	$tmp.Value = ([bitconverter]::tostring($j,$st+2,$lng-1)).replace("-","")
	$tmp.Notes = getString($j[$st..($lng+$st)])
} else {
	$tmp.Value = ""
	$tmp.Notes = ""
}
$st += 2 + $lng
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Author"
$tmp.Offset = "0x{0:X4}" -f $st
$lng = ([bitconverter]::touint16($j,$st) * 2)
if ($lng -gt 0) {
	$tmp.Value = ([bitconverter]::tostring($j,$st+2,$lng-1)).replace("-","")
	$tmp.Notes = getString($j[$st..($lng+$st)])
} else {
	$tmp.Value = ""
	$tmp.Notes = ""
}
$st += 2 + $lng
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Comment"
$tmp.Offset = "0x{0:X4}" -f $st
$lng = ([bitconverter]::touint16($j,$st) * 2)
if ($lng -gt 0) {
	$tmp.Value = ([bitconverter]::tostring($j,$st+2,$lng-1)).replace("-","")
	$tmp.Notes = getString($j[$st..($lng+$st)])
} else {
	$tmp.Value = ""
	$tmp.Notes = ""
}
$st += 2 + $lng
$out += $tmp
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "User Data"
$tmp.Offset = "0x{0:X4}" -f $st
$lng = ([bitconverter]::touint16($j,$st) * 2)
if ($lng -gt 0) {
	$tmp.Value = ([bitconverter]::tostring($j,$st+2,$lng-1)).replace("-","")
	$tmp.Notes = getString($j[$st..($lng+$st)])
} else {
	$tmp.Value = ""
	$tmp.Notes = ""
}
$st += 2 + $lng
$out += $tmp
$st = [bitconverter]::touint16($j,0x16)
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Trigger Count"
$tmp.Offset = "0x{0:X4}" -f $st
$tmp.Value = toHex($j[$st..($st+1)])
$tmp.Notes = "Offset 0x16 in fixed length section gives offset to here"
$out += $tmp
$st += 2
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Trigger Size"
$tmp.Offset = "0x{0:X4}" -f $st
$tmp.Value = toHex($j[$st..($st+1)])
$tmp.Notes = ""
$out += $tmp
$st += 4
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Begin Year"
$tmp.Offset = "0x{0:X4}" -f $st
$tmp.Value = toHex($j[$st..($st+1)])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,$st))
$out += $tmp
$st += 2
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Begin Month"
$tmp.Offset = "0x{0:X4}" -f $st
$tmp.Value = toHex($j[$st..($st+1)])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,$st))
$out += $tmp
$st += 2
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Begin Day"
$tmp.Offset = "0x{0:X4}" -f $st
$tmp.Value = toHex($j[$st..($st+1)])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,$st))
$out += $tmp
$st += 2
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "End Year"
$tmp.Offset = "0x{0:X4}" -f $st
$tmp.Value = toHex($j[$st..($st+1)])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,$st))
$out += $tmp
$st += 2
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "End Month"
$tmp.Offset = "0x{0:X4}" -f $st
$tmp.Value = toHex($j[$st..($st+1)])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,$st))
$out += $tmp
$st += 2
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "End Day"
$tmp.Offset = "0x{0:X4}" -f $st
$tmp.Value = toHex($j[$st..($st+1)])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,$st))
$out += $tmp
$st += 2
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Start Hour"
$tmp.Offset = "0x{0:X4}" -f $st
$tmp.Value = toHex($j[$st..($st+1)])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,$st))
$out += $tmp
$st += 2
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Start Minute"
$tmp.Offset = "0x{0:X4}" -f $st
$tmp.Value = toHex($j[$st..($st+1)])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,$st))
$out += $tmp
$st += 2
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Minutes Duration"
$tmp.Offset = "0x{0:X4}" -f $st
$tmp.Value = toHex($j[$st..($st+3)])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,$st))
$out += $tmp
$st += 4
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Minutes Interval"
$tmp.Offset = "0x{0:X4}" -f $st
$tmp.Value = toHex($j[$st..($st+3)])
$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,$st)) + "- The time period between repeated trigger firings"
$out += $tmp
$st += 4
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Trigger Flags"
$tmp.Offset = "0x{0:X4}" -f $st
$tmp.Value = toHex($j[$st..($st+3)])
$fl = [bitconverter]::touint32($j,$st)
$tmp.Notes = getFlags($fl)
$out += $tmp
$st += 4
$tmp = "" | Select Data, Offset, Value, Notes
$tmp.Data = "Trigger Type"
$tmp.Offset = "0x{0:X4}" -f $st
$tmp.Value = toHex($j[$st..($st+3)])
$tt = $tmp.Value
$tmp.Notes = $triggerType.get_item($tmp.Value)
$out += $tmp
$st += 4
switch ($tt) {
	"0x00000001" { 
		$tmp = "" | Select Data, Offset, Value, Notes
		$tmp.Data = "Trigger Interval"
		$tmp.Offset = "0x{0:X4}" -f $st
		$tmp.Value = toHex($j[$st..($st+1)])
		$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,$st))
		$out += $tmp
	}
	"0x00000002" {
		$tmp = "" | Select Data, Offset, Value, Notes
		$tmp.Data = "Trigger Interval"
		$tmp.Offset = "0x{0:X4}" -f $st
		$tmp.Value = toHex($j[$st..($st+1)])
		$tmp.Notes = [convert]::tostring([bitconverter]::touint16($j,$st))
		$out += $tmp
		$st += 2
		$tmp = "" | Select Data, Offset, Value, Notes
		$tmp.Data = "Days of Week"
		$tmp.Offset = "0x{0:X4}" -f $st
		$tmp.Value = toHex($j[$st..($st+1)])
		$dw = [bitconverter]::touint16($j,$st)
		$tmp.Notes = getDOW($dw)
		$out += $tmp
	}
	"0x00000003" {
		$tmp = "" | Select Data, Offset, Value, Notes
		$tmp.Data = "Days"
		$tmp.Offset = "0x{0:X4}" -f $st
		$tmp.Value = toHex($j[$st..($st+3)])
		$days = ""
		$v = [bitconverter]::touint32($j,$st)
		for ($i = 1; $i -lt 32; $i++) { if ($v -band 0x1) {$days += "$i "}; $v = $v -shr 1 }
		$tmp.Notes = $days
		$out += $tmp
		$st += 4
		$tmp = "" | Select Data, Offset, Value, Notes
		$tmp.Data = "Months"
		$tmp.Offset = "0x{0:X4}" -f $st
		$tmp.Value = toHex($j[$st..($st+1)])
		$months = ""
		$v = [bitconverter]::touint16($j,$st)
		for ($i = 1; $i -lt 32; $i++) { if ($v -band 0x1) {$Months += "$i "}; $v = $v -shr 1 }
		$tmp.Notes = $months
		$out += $tmp
	}
	"0x00000004" {
		$tmp = "" | Select Data, Offset, Value, Notes
		$tmp.Data = "Which Week"
		$tmp.Offset = "0x{0:X4}" -f $st
		$tmp.Value = toHex($j[$st..($st+3)])
		$week = ""
		$v = [bitconverter]::touint16($j,$st)
		for ($i = 1; $i -lt 32; $i++) { if ($v -band 0x1) {$week += "$i "}; $v = $v -shr 1 }
		$tmp.Notes = $week
		$out += $tmp
		$st += 2
		$tmp = "" | Select Data, Offset, Value, Notes
		$tmp.Data = "Day Of Week"
		$tmp.Offset = "0x{0:X4}" -f $st
		$tmp.Value = toHex($j[$st..($st+1)])
		$dw = [bitconverter]::touint16($j,$st)
		$tmp.Notes = getDOW($dw)
		$out += $tmp
		$st += 2
		$tmp = "" | Select Data, Offset, Value, Notes
		$tmp.Data = "Months"
		$tmp.Offset = "0x{0:X4}" -f $st
		$tmp.Value = toHex($j[$st..($st+1)])
		$months = ""
		$v = [bitconverter]::touint16($j,$st)
		for ($i = 1; $i -lt 32; $i++) { if ($v -band 0x1) {$Months += "$i "}; $v = $v -shr 1 }
		$tmp.Notes = $months
		$out += $tmp
	}
}
$out
