<#
 
.SYNOPSIS
 
Parse utmp, wtmp and btmp files from linux
 
.DESCRIPTION

Parse utmp, wtmp and btmp files from linux.  It does timezone conversion of the times.
This is an intermediate script it expects the data to be sent to it in 384 byte chuncks
for parsing.

.NOTES

Author: Tom Willett 
Date: 3/2/2015

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][byte[]]$uTemp,
	[boolean]$btmp, [string]$logName, [string]$LogPath, [string]$tz)

begin {
	$pidTable = @{}
}

process {
	function get_utType {
		Param([Parameter(Mandatory=$True)][int]$Data)
		switch ($Data)
		{
			0 {"empty"}        # No valid user accounting information
			1 {"Run Level"}    # The system's runlevel changed
			2 {"Boot Time"}    # Time of system boot
			3 {"New Time"}     # Time after system clock changed
			4 {"Old Time"}     # Time when system clock changed
			5 {"Init"}         # Process spawned by the init process
			6 {"Login"}        # Session leader of a logged in user
			7 {"User Process Start"} # Normal process
			8 {"Process End"}  # Terminated process
			9 {"Accounting"}   # Accounting
		}
	}
	if ($logName -eq "btmp") { $btmp = $true }
	$ErrorActionPreference = "SilentlyContinue"
	$ptr=0
	$tmp = "" | select "DateTime","Utype","ProcessID","Device","User","HostName","Addr","Session","Note","LogName", "LogPath"
	$utType = [bitconverter]::touint32($utemp,$ptr)
	$tmp.Utype = get_utType($utType)
	$ptr += 4
	$tmp.ProcessID = [bitconverter]::touint16($utemp,$ptr)
	$ptr += 4
	$StrEnd = $ptr
	While($utemp[$StrEnd] -ne 0x0) { $StrEnd += 1 }
	$tmp.Device = [System.Text.Encoding]::ASCII.GetString($utemp[$ptr..($StrEnd-1)])
	$ptr += 36
	$StrEnd = $ptr
	While($utemp[$StrEnd] -ne 0x0) { $StrEnd += 1 }
	$tmp.User = [System.Text.Encoding]::ASCII.GetString($utemp[$ptr..($StrEnd-1)])
	$ptr += 32
	$StrEnd = $ptr
	While($utemp[$StrEnd] -ne 0x0) { $StrEnd += 1 }
	$tmp.HostName = [System.Text.Encoding]::ASCII.GetString($utemp[$ptr..($StrEnd-1)])
	$ptr += 260
	$tmp.Session = [bitconverter]::touint32($utemp,$ptr)
	$ptr += 4
	$Utime = [bitconverter]::touint32($utemp,$ptr)
	[datetime]$origin = '1970-01-01 00:00:00'
	$cst = [system.timezoneinfo]::findsystemtimezonebyid($tz)
	$tmp.DateTime = [system.timezoneinfo]::converttimefromutc($origin.AddSeconds($Utime),$cst)
	$ptr += 8
	$tmp.Addr = $utemp[$ptr].tostring() + "." + $utemp[($ptr+1)].tostring() + "." + $utemp[($ptr+2)].tostring() + "." + $utemp[($ptr+3)].tostring()
	switch ($utType) 
	{
		0 { $tmp.note = "Not a valid entry" }
		1 { $tmp.note = "Run Level Change" }
		2 { $tmp.note = "Boot Time = " + $tmp.DateTime }
		3 { $tmp.note = "System Time changed to " + $tmp.DateTime }
		4 { $tmp.note = "System Time before date/time change = " + $tmp.DateTime }
		5 { $tmp.note = "Process spawned by Init(8) = " + $tmp.ProcessID }
		6 { $tmp.note = "Session leader Process for User Login = " + $tmp.processid }
		7 { 
			$tmp.note = "user=" + $tmp.User + "@" + $tmp.HostName + " (" + $tmp.addr +") ProcessID=" + $tmp.ProcessID + " logged in on device=" + $tmp.device
			$pidTable.add($tmp.ProcessID, $tmp.user)
		  }
		8 { 
			$tmp.user = $pidTable.get_item($tmp.processid)
			$tmp.note = "user=" + $tmp.user + " ProcessID=" + $tmp.ProcessID + " terminated (logged out) on device=" + $tmp.device
		  }
	}
	if ($btmp) {
		$tmp.note = "user=" + $tmp.User + "@" + $tmp.HostName + " (" + $tmp.addr +") log in failed on device=" + $tmp.device
	}
	$tmp.logname = $logname
	$tmp.logpath = $logpath
	write-output $tmp
}
