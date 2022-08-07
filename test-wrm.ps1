<#

.SYNOPSIS     
    Tests whether a computer has WinRM running.   
     
.DESCRIPTION   
    Tests whether a computer either local or remote has WinRM running.    
	It returns a powershell object with the computername and whether 
	or not WinRm is running.
      
.PARAMETER computername   
    Name of computer to test.
       
.EXAMPLE     
    .\Test-wrm.ps1
    Checks whether WinRM is running on local computer

.EXAMPLE     
    .\Test-wrm.ps1 -computername 'servername'
    Checks whether WinRM is running on computer 'servername'

.EXAMPLE     
    type computers.txt | .\Test-wrm.ps1 | export-csv -notypeinformation winrm.csv
    Checks whether WinRM is running on the computers listed (one per line) in the file
	computers.txt and outputs the results to a csv file called winrm.csv

	.NOTES     
	Author: Tom Willett
	Date: 8/28/2014

#>

Param([Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$computername = "")

begin {
	$report = @()
}

process {
	$error.clear()
	if ($computername -eq "") {
		$wrm = test-wsman -EA SilentlyContinue
		$computername = $env:computername
		$pingable = $True
	} else {
		$Pingable = ""
		$temp = $null
		$ping = New-Object System.Net.NetworkInformation.Ping
		$temp = $ping.send($computername,3000)
		$Pingable= $temp.Status.toString()
		if ($Pingable -eq "Success") {
			$wrm = test-wsman $computername -EA SilentlyContinue
			$Pingable = $True
		} else {
			$Pingable = $False
		}
	}
	$tmp = "" | Select Computername, Pingable, WSMANEnabled
	$tmp.Computername = $computername
	$tmp.Pingable = $Pingable
	if ($error.count -gt 0) {
		$tmp.WSMANEnabled = "False"
	} else {
		$tmp.WSMANEnabled = "True"
	}
	$report += $tmp
}

end {
	$report
}
