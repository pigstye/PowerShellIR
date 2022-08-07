<#

.SYNOPSIS

Gets the name of the Local Admin by RID.

.DESCRIPTION

Gets the name of the Local Admin by RID using WMI

.EXAMPLE

ps> .\get-localadmin.ps1  servername

Get the Local Admin account name on servername

.EXAMPLE

type names.txt | .\get-localadmin.ps1

Gets the local admin name on multiple computers listed in names.txt (one server per line)

.NOTES

Author: Tom Willett 
Date: 9/24/2014

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$computername)

begin {
	$out = @()
}

process { 
	$wmi = gwmi -computername $computername -filter "LocalAccount='$true'" -class win32_useraccount
	foreach ($usr in $wmi) { 
		if ($usr.sid.startswith("S-1-5-") -and $usr.sid.endswith("-500")) {
			$temp = "" | Select Computer, Admin
			$temp.Computer = $computername
			$temp.Admin = $usr.name
			$out += $temp
		}
	}	
}

end {
	$out
}