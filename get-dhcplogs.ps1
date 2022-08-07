<#

.SYNOPSIS

Gets dhcp logs from a dhcp server.

.DESCRIPTION

Gets dhcp logs from a Microsoft dhcp server.  Assumes that the logs are at c:\windows\system32\dhcp
Returns a Powershell Object

Event ID  Meaning
00        The log was started.
01        The log was stopped.
02        The log was temporarily paused due to low disk space.
10        A new IP address was leased to a client.
11        A lease was renewed by a client.
12        A lease was released by a client.
13        An IP address was found to be in use on the network.
14        A lease request could not be satisfied because the scope's
          address pool was exhausted.
15        A lease was denied.
16        A lease was deleted.
17        A lease was expired.
20        A BOOTP address was leased to a client.
21        A dynamic BOOTP address was leased to a client.
22        A BOOTP request could not be satisfied because the scope's
          address pool for BOOTP was exhausted.
23        A BOOTP IP address was deleted after checking to see it was
          not in use.
24        IP address cleanup operation has began.
25        IP address cleanup statistics.
30        DNS update request to the named DNS server
31        DNS update failed
32        DNS update successful
50+       Codes above 50 are used for Rogue Server Detection information.

.PARAMETER $computername

The $computername paramater is required

.INPUTS

One of more server names to get the logs from

.OUTPUTS

Powershell object containing the log(s)

.EXAMPLE

ps> .\get-dhcplogs.ps1  servername


Gets dhcp logs from a dhcp server.

.EXAMPLE

type names.txt | .\get-dhcplogs.ps1

Gets dhcp logs from multiple servers listed in names.txt (one server per line)

.EXAMPLE

type names.txt | .\get-dhcplogs.ps1 | where {$_.id -eq '10' }

Gets dhcp logs from multiple servers listed in names.txt (one server per line)
It only returns id 10 logs: A new lease

.EXAMPLE

type names.txt | .\get-dhcplogs.ps1 | export-csv -notypeinformation dhcp.csv

Gets dhcp logs from multiple servers listed in names.txt (one server per line)
Returns output in the dhcp.csv file

.NOTES

Author: Tom Willett 
Date: 10/8/2014

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$computername)

begin {
	$out = @()
	$ErrorActionPreference = "SilentlyContinue"
}
process {
	$logs = dir \\$computername\c$\windows\system32\dhcp\dhcpsrvlog*.log
	if ($logs) {
		foreach ($dhcplog in $logs) {
			$ln = 1
			$log = get-content $dhcplog.fullname
			foreach($line in $log) { if ($line.startswith("ID,Date,Time")) { break } else { $ln = $ln + 1 }}
			for($i=$ln; $i -lt $log.length; $i++) {
				$temp = "" | Select ID, Date, Time, Description, IP, HostName, MAC
				$fields = $log[$i].split(',')
				$temp.ID = $fields[0].tostring()
				$temp.Date = $fields[1]
				$temp.Time = $fields[2]
				$temp.Description = $fields[3]
				$temp.IP = $fields[4]
				$temp.HostName = $fields[5]
				$temp.MAC = $fields[6]
				$out += $temp
			}
		}
	} else {
		"Logs not found on $computername"
	}
}

end {
	$out
}
