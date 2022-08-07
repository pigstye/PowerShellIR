<#

.SYNOPSIS

Get the domain controllers in current domain.

.DESCRIPTION

Get the domain controllers in current domain.  This uses .net and does not rely on the AD extensions.

.OUTPUTS

List of domain controllers

.EXAMPLE

PS D:\> .\get-domaincontrollers.ps1

Get the domain controllers in current domain.

.NOTES

 Author: Tom Willett 
 Date: 9/29/2014

#>

$out = @()
$dmn = [system.directoryservices.activedirectory.domain]::GetCurrentDomain()
ForEach ($ctrl in $dmn.DomainControllers) {
	 $out += $ctrl.Name
}
$out
