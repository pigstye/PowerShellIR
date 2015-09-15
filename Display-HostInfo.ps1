<#

.SYNOPSIS

Get information about an internet server, includes blacklist, geoip, traceroute, dns and a service scan

.DESCRIPTION

This looks up an ip from ipinfo.io which returns reverse lookup and geoip information and blacklist
status from ipvoid.com, a traceroute, complete DNS information, WhoIS and a service scan.  Note you are limited 
to 1000 lookups a day with this.  It uses SysInternals whois utility which must be in the path or current directory.
This displays the information on the screen.

.PARAMETER Computer

The Computer or IP to look up.

.EXAMPLE     
    .\get-ipInfo.ps1 8.8.8.8
	
    Returns the information for 8.8.8.8 as a text

.EXAMPLE     
    type .\ip.txt |.\get-ipStatus.ps1 > hostinfo.txt
    Looks up the information for all the ips or computernames in ip.txt (one per line) 
	It puts the output in hostinfo.txt

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
	write-output "------- Host Information for $ip -------"
	$hostinfo = [System.Net.Dns]::GetHostEntry($ip)
	$hostinfo | format-list
	$y = test-connection $ip -count 1
	if ($y) {
		$p = test-netconnection $ip -traceroute
		$p
	} else {
		write-output "Not Pingable"
	}
	#get geoip info
	$tmpip = $hostinfo.addresslist[0]
	$params = @{ip="$tmpip"}
	$tmp = Invoke-WebRequest -uri 'http://www.ipvoid.com' -method POST -body $params
	write-output "------- http://ipinfo.io/$ip -------"
	(new-object net.webclient).DownloadString("http://ipinfo.io/$tmpip")
	$ipvoid = (new-object net.webclient).DownloadString("http://www.ipvoid.com/scan/$tmpip")
	write-output "------- http://www.ipvoid.com/scan/$tmpip -------"
	if ($ipvoid -match '<tr><td>Blacklist Status<\/td><td><span class=".*">(.*)<\/span><\/td><\/tr>') {
		$matches[1]
	}
	write-output "------- Whois -------"
	whois $ip -v
	write-output "------- DNS -------"
	Resolve-DnsName $ip
	Resolve-DnsName $ip -type mx
	Resolve-DnsName $ip -type ns
	Resolve-DnsName $ip -type soa
	Resolve-DnsName $ip -type txt
	Resolve-DnsName $ip -type ptr
	write-output "------- Service Scan -------"
	write-output "Ftp"
	test-port $ip 21
	write-output "SSH"
	test-port $ip 22
	write-output "Telnet"
	test-port $ip 23
	write-output "SMTP"
	test-port $ip 25
	write-output "DNS"
	test-port $ip 53
	write-output "HTTP"
	$tmp = (new-object net.webclient).DownloadString("http://$ip")
	$tmp.substring(0,255)
	write-output "POP3"
	test-port $ip 110
	write-output "IMAP"
	test-port $ip 143
	write-output "SNMP"
	test-port $ip 161
	write-output "LDAP"
	test-port $ip 389
	write-output "HTTPS"
	$tmp = (new-object net.webclient).DownloadString("https://$ip")
	$tmp.substring(0,255)
	write-output "SMB"
	test-port $ip 445
	write-output "MSSQL"
	test-port $ip 1433
	write-output "MySQL"
	test-port $ip 3306
	write-output "RDP"
	test-port $ip 3389
}
