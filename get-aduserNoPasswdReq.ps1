<#

.SYNOPSIS

Checks all domain user accounts to see if the PasswordNotReq flag is set.

.DESCRIPTION

Checks all domain user accounts to see if the PasswordNotReq flag is set.  This requires that the AD module be loaded.

.EXAMPLE

ps> .\get-aduserNoPasswdReg.ps1  servername


Checks all domain user accounts to see if the PasswordNotReq flag is set.

.NOTES

Author: Tom Willett 
Date: 9/26/2014

#>

$out = @()

$users = get-aduser -filter * -properties useraccountcontrol

foreach ($user in $users) {
	$tmp = "" | Select User, UserAccountControl
	if (($user.useraccountcontrol -band 32) -eq 32) {
		$tmp.User = $user.SamAccountName
		$tmp.useraccountcontrol = $user.useraccountcontrol
		$out += $tmp
	}
}

$out