<#

.SYNOPSIS

Get the logon failures from all domain controller

.DESCRIPTION

Get the logon failures from all domain controller

.OUTPUTS

CSV File called [domain controller]failures.csv for each domain controller

.EXAMPLE

PS D:\> .\get-LogonFailures.ps1

Gets the logon failures from  all DCs

.NOTES

 Author: Tom Willett 
 Date: 9/29/2014
 © 2014 Oink Software 

#>

$out = @()
$dmn = [system.directoryservices.activedirectory.domain]::GetCurrentDomain()
ForEach ($ctrl in $dmn.DomainControllers) {
	 $out += $ctrl.Name
}

foreach ($dc in $out) {
	start-process "$pshome\powershell.exe" -argumentlist "-noprofile -command .\get-LogonFailure.ps1 $dc"
}
