<#

.SYNOPSIS

Get information about an internet server, includes blacklist, geoip, traceroute, dns and a service scan

.DESCRIPTION

This looks up an ip from ipinfo.io which returns reverse lookup and geoip information and blacklist
status from ipvoid.com, a traceroute, complete DNS information, WhoIS and a service scan.  Note you are limited 
to 1000 lookups a day with this.  It uses SysInternals whois utility which must be in the path or current directory.
It requires PowerShell 4.0 or greater. It outputs a PowerShell object.

.PARAMETER Computer

The Computer or IP to look up.

.EXAMPLE     
    .\get-ipInfo.ps1 8.8.8.8
	
    Returns the information for 8.8.8.8 as a PowerShell object

.EXAMPLE     
    type .\ip.txt |.\get-ipStatus.ps1 | export-csv -notypeinformation ip.csv
    Looks up the information for all the ips or computernames in ip.txt (one per line) 
	It puts the output in ip.csv
	
.NOTES
	
 Author: Tom Willett
 Date: 9/15/2015
 © 2015 Oink Software

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$ip)

Begin {
	function Test-Port {
	<#
		.Synopsis
			Tests a port and returns any output
		.Description
			Uses the net.sockets.tcpclient to test if a port is open.  If it is open and replies with anything it is returned also
		.Parameter computer
			Computer to test
		.Parameter port
			Port to connect to
		.NOTES
			Author: Tom Willett
			Date: 9/15/2015
			© 2015 Oink Software
	#>


	Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$computer,
		[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][int]$port)
		Begin {
			$result = @()
		}

		process {
			$timeout = 3000
			$success = $true
			$info = "" | Select Success, Data
			$ErrorActionPreference = "SilentlyContinue"
			# Create TCP Client
			$tcpclient = new-Object system.Net.Sockets.TcpClient
			# Tell TCP Client to connect to machine on Port
			$iar = $tcpclient.BeginConnect($computer,$port,$null,$null)
			# Set the wait time
			$wait = $iar.AsyncWaitHandle.WaitOne($timeout,$false)
			# Check to see if the connection is done
			if(!$wait) {
				# Close the connection and report timeout
				$tcpclient.Close()
				$success = $false
			} else {
				#Read connection and read response if any
				$stream = $tcpclient.GetStream()
				$dta = New-Object System.Byte[] 512
				$Encoding = New-Object System.Text.AsciiEncoding
				$stream.ReadTimeout = 2000
				$read = $stream.read($dta,0,512)
				$tcpclient.EndConnect($iar) | out-Null
				if(!$?) {$success = $false}
				$tcpclient.Close()
				$info.Data = $Encoding.GetString($dta, 0, $Read)
			}
			if ($success) {
				if ($info.data -eq "") {
					$result += "True"
				} else {
					$result += $info.data
				}
			} else {
				$result += "False"
			}
		}
		end {
			$result
		}
	}
}

process {
	$ErrorActionPreference = "SilentlyContinue"
	$info = "" | Select ip, hostname, Aliases, status, pingable, traceroute, city, region, country, loc, org, ipvoid, ipinfo, Whois, DNSInfo, FTP, SSH, Telnet, SMTP, DNS, HTTP, POP3, IMAP, SNMP, LDAP, HTTPS, SMB, MSSQL, MySQL, RDP
	$hostEntry = [System.Net.Dns]::GetHostEntry($ip)
	$info.ip = $hostEntry.AddressList
	$info.hostname = $ip
	$info.aliases = $hostEntry.Aliases
	$y = test-connection $ip -count 1
	if ($y) {
		$p = test-netconnection $ip -traceroute
		$info.pingable = $p.pingsucceeded
		$info.traceroute = $p.traceroute
	} else {
		$info.pingable = $false
		$info.traceroute = ""
	}
	#get geoip info
	$tmpip = $info.ip[0]
	$params = @{ip="$tmpip"}
	$tmp = Invoke-WebRequest -uri 'http://www.ipvoid.com' -method POST -body $params
	$geoip = (new-object net.webclient).DownloadString("http://ipinfo.io/$tmpip")
	$info.ipinfo = "http://ipinfo.io/$ip"
	if (-not ($geoip -match '"hostname": "(.*)",')) {
		$n = $geoip -match '"hostname": (.*),'
	}
	$info.hostname = $matches[1]
	if (-not ($geoip -match '"city": "(.*)",')) {
		$n = $geoip -match '"city": (.*),'
	}
	$info.city = $matches[1]
	if (-not ($geoip -match '"region": "(.*)",')) {
		$n = $geoip -match '"region": (.*),'
	}
	$info.region = $matches[1]
	if (-not ($geoip -match '"country": "(.*)",')) {
		$n = $geoip -match '"country: (.*),'
	}
	$info.country = $matches[1]
	if (-not ($geoip -match '"loc": "(.*)",')) {
		$n = $geoip -match '"loc": (.*),'
	}
	$info.loc = $matches[1]
	if (-not ($geoip -match '"org": "(.*)"')) {
		$n = $geoip -match '"org": (.*)'
	}
	$info.org = $matches[1]
	$ipvoid = (new-object net.webclient).DownloadString("http://www.ipvoid.com/scan/$tmpip")
	$info.ipvoid = "http://www.ipvoid.com/scan/$tmpip"
	if ($ipvoid -match '<tr><td>Blacklist Status<\/td><td><span class=".*">(.*)<\/span><\/td><\/tr>') {
		$info.status = $matches[1]
	}
	$info.whois = whois $ip -v
	$info.DNSInfo = Resolve-DnsName $ip
	$info.DNSInfo += Resolve-DnsName $ip -type mx
	$info.DNSInfo += Resolve-DnsName $ip -type ns
	$info.DNSInfo += Resolve-DnsName $ip -type soa
	$info.DNSInfo += Resolve-DnsName $ip -type txt
	$info.DNSInfo += Resolve-DnsName $ip -type ptr
	$info.ftp = test-port $ip 21
	$info.SSH = test-port $ip 22
	$info.Telnet = test-port $ip 23
	$info.SMTP = test-port $ip 25
	$info.DNS = test-port $ip 53
	$tmp = (new-object net.webclient).DownloadString("http://$ip")
	$info.HTTP = $tmp.substring(0,255)
	$info.POP3 = test-port $ip 110
	$info.IMAP = test-port $ip 143
	$info.SNMP = test-port $ip 161
	$info.LDAP = test-port $ip 389
	$tmp = (new-object net.webclient).DownloadString("https://$ip")
	$info.HTTPS = $tmp.substring(0,255)
	$info.SMB = test-port $ip 445
	$info.MSSQL = test-port $ip 1433
	$info.MySQL = test-port $ip 3306
	$info.RDP = test-port $ip 3389
	write-output $info
}
