<#

.SYNOPSIS

Gets dns debug logs from a dns server.

.DESCRIPTION

Gets dns logs from a Microsoft dns server.  Assumes that the logs are at c:\windows\system32\dns\dns.log
Returns a Powershell Object

Message logging key (for packets - other items use a subset of these fields):
	Field #  Information         Values
	-------  -----------         ------
	   1     Date
	   2     Time
	   3     Thread ID
	   4     Context
	   5     Internal packet identifier
	   6     UDP/TCP indicator
	   7     Send/Receive indicator
	   8     Remote IP
	   9     Xid (hex)
	  10     Query/Response      R = Response
	                             blank = Query
	  11     Opcode              Q = Standard Query
	                             N = Notify
	                             U = Update
	                             ? = Unknown
	  12     [ Flags (hex)
	  13     Flags (char codes)  A = Authoritative Answer
	                             T = Truncated Response
	                             D = Recursion Desired
	                             R = Recursion Available
	  14     ResponseCode ]
	  15     Question Type
	  16     Question Name

.PARAMETER $computername

The $computername paramater is required

.INPUTS

One of more server names to get the logs from

.OUTPUTS

Powershell object containing the log(s)

.EXAMPLE

ps> .\get-dnsDebugLogs.ps1  servername

Gets dns debug logs from a dns server.

.EXAMPLE

type names.txt | .\get-dnsDebugLogs.ps1

Gets dns logs from multiple servers listed in names.txt (one server per line)

.EXAMPLE

type names.txt | .\get-dnsDebugLogs.ps1 | export-csv -notypeinformation dns.csv

Gets dns logs from multiple servers listed in names.txt (one server per line)
Returns output in the dns.csv file

.NOTES

Author: Tom Willett 
Date: 10/8/2014
© 2014 Oink Software

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$computername)

begin {
	$out = @()
	$ErrorActionPreference = "SilentlyContinue"
}
process {
	$log = get-content \\$computername\c$\windows\system32\dns\dns.log
	if ($log) {
		foreach($line in $log) {
			if ( $line -match "^\d\d" -AND $line -notlike "*EVENT*") {
				$temp = "" | Select Date, Time, Protocol, Client, SendReceive, QueryType, RecordType, Query, Result
				$fields = $line.split(' ')
			    $temp.Date = $fields[0]
				$TheReverseRegExString="\(\d\)in-addr\(\d\)arpa\(\d\)"
			   if ($_ -match $TheReverseRegExString) {
					$temp.QueryType="Reverse"
				}
				else {
					$temp.QueryType="Forward"
				}
				# Check log time format and set properties
                if ($line -match ":\d\d AM|:\d\d  PM") {
					$temp.Time=$fields[1,2] -join " "
					$temp.Protocol=$fields[7]
					$temp.Client=$fields[9]
					$temp.SendReceive=$fields[8]
					$temp.RecordType=(($line -split "]")[1] -split " ")[1]
					$temp.Query=($line.ToString().Substring(99)) -replace "\s" -replace "\(\d?\d\)","." -replace "^\." -replace "\.$"
					$temp.Result=(((($line -split "\[")[1]).ToString().Substring(9)) -split "]")[0] -replace " "
				}
				elseif ($line -match "^\d\d\d\d\d\d\d\d \d\d:") {
					$temp.Date=$temp.Date.Substring(0,4) + "-" + $temp.Date.Substring(4,2) + "-" + $temp.Date.Substring(6,2)
					$temp.Time=$fields[1]
					$temp.Protocol=$fields[6]
					$temp.Client=$fields[8]
					$temp.SendReceive=$fields[7]
					$temp.RecordType=(($line -split "]")[1] -split " ")[1]
					$temp.Query=($line.ToString().Substring(99)) -replace "\s" -replace "\(\d?\d\)","." -replace "^\." -replace "\.$"
					$temp.Result=(((($line -split "\[")[1]).ToString().Substring(9)) -split "]")[0] -replace " "
				}
				else {
					$temp.Time=$fields[1]
					$temp.Protocol=$fields[6]
					$temp.Client=$fields[8]
					$temp.SendReceive=$fields[7]
					$temp.RecordType=(($line -split "]")[1] -split " ")[1]
					$temp.Query=($line.ToString().Substring(99)) -replace "\s" -replace "\(\d?\d\)","." -replace "^\." -replace "\.$"
					$temp.Result=(((($line -split "\[")[1]).ToString().Substring(9)) -split "]")[0] -replace " "
				}

				$out += $temp
			}
		}
	} else {
		"Log not found on $computername"
	}
}

end {
	$out
}

