<#

.SYNOPSIS

Given a user name return the SID

.DESCRIPTION

Converts user to SID.  Both Local and Domain

.NOTES

 Author: Tom Willett
 Date: 7/9/2014
 © 2014 Oink Software

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string[]]$username)
process {
	$objUser = New-Object System.Security.Principal.NTAccount("tomw") 
	$strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier]) 
	$strSID.Value
}
