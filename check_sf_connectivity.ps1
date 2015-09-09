#-------------------------------------------------------------------
# Script: check_sf_connectivity.ps1
# Author: Brian Payne, FishNet Security
# Date: August 13, 2014 17:03 EDT
# Keywords: FireAMP, Monitoring
# comments: This script checks for connectivity to Sourcefire hosts
#--------------------------------------------------------------------

Function CheckHost ($hostname, $port) {
   ForEach ($addr in ([Net.DNS]::GetHostEntry($hostname).AddressList)) {
      $ip = $addr.IPAddressToString
      $socket = new-object System.Net.Sockets.TcpClient
      $connect = $socket.BeginConnect($ip, $port, $null, $null)
      $wait = $connect.AsyncWaitHandle.WaitOne(1000,$false)
      If(-Not $wait) {
        "not connected to $hostname ($ip) on port $port"
      } Else {
         $error.clear()
         $socket.EndConnect($connect) | out-Null
         If ($Error[0]) {
            Write-warning ("{0}" -f $error[0].Exception.Message)
         } Else {
			"connected to $hostname ($ip) on port $port"
         }
      }
   }
}

#Main
$sfhosts = "enterprise-event.amp.sourcefire.com","enterprise-mgmt.amp.sourcefire.com","policy.amp.sourcefire.com.s3.amazonaws.com","cloud-ec.amp.sourcefire.com"
$port = 443
ForEach ($sfhost in $sfhosts) {
   CheckHost $sfhost $port
}

$sfhost = "cloud-ec.amp.sourcefire.com"
$port = 32137
CheckHost $sfhost $port

$sfhost = "crash.immunet.com"
$port=80
CheckHost $sfhost $port

$sfhost = "submit.amp.sourcefire.com"
$port = 80
CheckHost $sfhost $port

$sfhost = "update.immunet.com"
$port = 80
CheckHost $sfhost $port

$sfhosts = "enterprise-event.eu.amp.sourcefire.com","enterprise-mgmt.eu.amp.sourcefire.com","policy.eu.amp.sourcefire.com.s3.amazonaws.com"
$port = 443
ForEach ($sfhost in $sfhosts) {
   CheckHost $sfhost $port
}

$sfhost = "crash.eu.amp.sourcefire.com"
$port = 80
CheckHost $sfhost $port

$sfhost = "cloud-ec.eu.amp.sourcefire.com"
$port = 443
CheckHost $sfhost $port

$sfhost = "cloud-ec.eu.amp.sourcefire.com"
$port = 32137
CheckHost $sfhost $port

$sfhost = "submit.eu.amp.sourcefire.com"
$port = 80
CheckHost $sfhost $port
