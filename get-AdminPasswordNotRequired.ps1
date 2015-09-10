<#

.SYNOPSIS

Gets whether the local admin account requires a password.

.DESCRIPTION

Get the local admin name (checks by sid).  Then gets whether the local admin account requires a password

.EXAMPLE

ps> .\get-AdminPasswordNotRequired.ps1  servername


Gets whether the local admin account requires a password on one server.  Use localhost for current computer.

.EXAMPLE

type names.txt | .\get-AdminPasswordNotRequired.ps1

Gets whether the local admin account requires a password on multiple servers listed in names.txt (one server per line)

.NOTES

Author: Tom Willett 
Date: 9/25/2014
© 2014 Oink Software

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$computername)

begin {
	$out = @()
}

process { 
	$adminName = "Error"
	$error.clear()
	$wmi = gwmi -computername $computername -filter "LocalAccount='$true'" -class win32_useraccount
	foreach ($usr in $wmi) { 
		if ($usr.sid.startswith("S-1-5-") -and $usr.sid.endswith("-500")) {
			$adminName = $usr.name
		}
	}
	$Admin=[adsi]("WinNT://" + $computername + "/" + $adminName + ", user")                
	$tmp = "" | select Computername, AdminName, PassWordNotRequired
	$tmp.Computername = $computername
	$tmp.AdminName = $adminName
	$tmp.PassWordNotRequired = $false
	if (([int]$Admin.UserFlags.tostring() -band 32) -eq 32) {
		$tmp.PassWordNotRequired = $true
	}
	$out += $tmp
}

end {
	$out
}