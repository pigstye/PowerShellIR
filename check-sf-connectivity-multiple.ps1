<#

.SYNOPSIS     
    Tests whether multiple computers connectivity to the SourceFire hosts.   
     
.DESCRIPTION   
    Tests whether multiple computers have connectivity to the SourceFire hosts.    
	It returns a powershell object with the computername, the SourceFire host
	and port and whether or not there is connectvity.
	
	It first checks for WinRM access and if that fails uses psexec.exe.
      
.PARAMETER computername   
    Name of computers to test from pipeline
       
.NOTES     
	Author: Tom Willett
	Date: 8/29/2014
	© 2014 Oink Software

	It requires that check-sf-connectivity.ps1 and psexec.exe be in the same directory as
	this script.
	
.EXAMPLE     
    type .\computer.txt | .\check-sf-connectivity-multiple.ps1
    Checks whether the computers listed in computer.txt (one per line) have connectivity

.EXAMPLE     
    type .\computer.txt | .\check-sf-connectivity-multiple.ps1
    Checks whether the computers listed in computer.txt (one per line) have connectivity

.EXAMPLE     
    type .\computer.txt | .\check-sf-connectivity-multiple.ps1 | export-csv -notypeinformation sf.csv
    Checks whether the computers have connectivity and outputs the results to sf.csv

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$computername)

begin {
	$report = @()
}

process {
	$ErrorActionPreference = "SilentlyContinue"
	$tmp = "" | select Host, SFhost, Port, Connected
	$tmp.Host = "$computername"
	$Pingable = ""
	$temp = $null
	$ping = New-Object System.Net.NetworkInformation.Ping
	$temp = $ping.send($computername,3000)
	$Pingable= $temp.Status.toString()
	if ($Pingable -eq "Success") {
		$error.clear()
		$wrm = test-wsman "$computername"
		if ($error.count -eq 0) {
			invoke-command -computername $computername -filepath .\check-sf-connectivity.ps1
		} else {
			$path= "\\$computername\C$\windows\System32\WindowsPowerShell\v1.0\powershell.exe"
			if(test-path $path){
				copy .\check-sf-connectivity.ps1 \\$computername\c$\
				$tmp = .\PsExec.exe \\$computername cmd /c "echo . | %windir%\System32\WindowsPowerShell\v1.0\powershell.exe -Output XML -executionpolicy remotesigned c:\check-sf-connectivity.ps1"
				del \\$computername\c$\check-sf-connectivity.ps1
			} else {
				$tmp.SFHost = "PowerShell not installed"
			}
		}
	} else {
		$tmp.SFhost = "Not Pingable"
	}
	$report += $tmp
}

end {
	$report
}
