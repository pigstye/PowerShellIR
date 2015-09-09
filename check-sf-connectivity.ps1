<#

.SYNOPSIS     
    Tests whether a computer has connectivity to the SourceFire hosts.   
     
.DESCRIPTION   
    Tests whether a computer has connectivity to the SourceFire hosts.    
	It returns a powershell object with the computername, the SourceFire host
	and port and whether or not there is connectvity
      
.PARAMETER computername   
    Name of computer to test.
       
.NOTES     
	Author: Tom Willett
	Date: 8/28/2014
	© 2014 Fishnet Security
	Based on a script by Brian Payne from August 13, 2014

.EXAMPLE     
    .\check-sf-connectivity.ps1
    Checks whether the local computer has connectivity

#>

begin {
	$report = @()
	$sfhosts = @(
		("enterprise-event.amp.sourcefire.com","443"),
		("enterprise-mgmt.amp.sourcefire.com","443"),
		("policy.amp.sourcefire.com.s3.amazonaws.com","443"),
		("cloud-ec.amp.sourcefire.com","443"),
		("cloud-ec.amp.sourcefire.com","32137"),
		("crash.immunet.com","80"),
		("submit.amp.sourcefire.com","80"),
		("update.immunet.com","80"),
		("enterprise-event.eu.amp.sourcefire.com","443"),
		("enterprise-mgmt.eu.amp.sourcefire.com","443"),
		("policy.eu.amp.sourcefire.com.s3.amazonaws.com","443"),
		("crash.eu.amp.sourcefire.com","80"),
		("cloud-ec.eu.amp.sourcefire.com","443"),
		("cloud-ec.eu.amp.sourcefire.com","32137"),
		("submit.eu.amp.sourcefire.com","80"),
		("endpoint-ioc-prod-us.s3.amazonaws.com","443")
	)
}

process {
	$computername = $env:computername
	foreach ($sfhost in $sfhosts) {
		$hostname = $sfhost[0]
		$port = $sfhost[1]
		$tmp = "" | select Host, SFhost, Port, Connected
		$tmp.Host = $computername
		$tmp.SFhost = $hostname
		$tmp.Port = $port
		$tmp.Connected = $False
		ForEach ($addr in ([Net.DNS]::GetHostEntry($hostname).AddressList)) {
		  $ip = $addr.IPAddressToString
		  $socket = new-object System.Net.Sockets.TcpClient
		  $connect = $socket.BeginConnect($ip, $port, $null, $null)
		  $wait = $connect.AsyncWaitHandle.WaitOne(1000,$false)
		  If($wait) {
			$error.clear()
			$socket.EndConnect($connect) | out-Null
			If ($Error.count -eq 0) {
				$tmp.Connected = $True
			}
		  }
		}
		$report += $tmp
	}
}

end {
	$report
}
