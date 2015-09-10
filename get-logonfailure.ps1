<#

.SYNOPSIS

Get the logon failures from a domain controller

.DESCRIPTION

Get the logon failures from a domain controller

.PARAMETER $computerName

$computerName is required -- the Domain Controller name

.OUTPUTS

CSV File called [domain controller]failures.csv

.EXAMPLE

PS D:\> .\get-LogonFailure.ps1 servername

Gets the logon failures from DC servername

.NOTES

 Author: Tom Willett 
 Date: 9/29/2014
 © 2014 Oink Software 

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$computername)

begin {
	$out = @()
}
process { 
	$computername
	$log = Get-EventLog -LogName security -ComputerName $computerName -entrytype failureaudit -InstanceID 529 -newest 10000
	foreach ($line in $log) {
		$tmp = "" | select DC, Time,UserName,Domain,LogonType,LogonProcess, AuthenticationPackage,WorkstationName,CallerUserName, CallerDomain,CallerLogonID,CallerProcessID, TransitedServices,SourceNetworkAddress,SourcePort
		$tmp.dc = $computerName
		$tmp.time = $line.timegenerated.tostring()
		$tmp.UserName = $line.replacementstrings[0]
		$tmp.Domain = $line.replacementstrings[1]
		$tmp.ogonType = $line.replacementstrings[2]
		$tmp.LogonProcess[3]
		$tmp.AuthenticationPackage = $line.replacementstrings[4]
		$tmp.WorkstationName = $line.replacementstrings[5]
		$tmp.CallerUserName = $line.replacementstrings[6]
		$tmp.CallerDomain = $line.replacementstrings[7]
		$tmp.CallerLogonID = $line.replacementstrings[8]
		$tmp.CallerProcessID = $line.replacementstrings[9]
		$tmp.TransitedServices = $line.replacementstrings[10]
		$tmp.SourceNetworkAddress = $line.replacementstrings[11]
		$tmp.SourcePort = $line.replacementstrings[12]
		$out += $tmp
	}
}

end {
	$out | export-csv -notypeinformation ($computername + "-failures.csv")
}
