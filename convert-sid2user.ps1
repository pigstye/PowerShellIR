<#

.SYNOPSIS

Given a SID return the user

.DESCRIPTION

Converts SID to user.  Both Local and Domain

.NOTES

 Author: Tom Willett
 Date: 7/9/2014
 © 2014 Oink Software

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string[]]$sid)
process {
	$objSID = New-Object System.Security.Principal.SecurityIdentifier($sid)
	$objUser = $objSID.Translate( [System.Security.Principal.NTAccount]) 
	$objUser.Value 
}