<#

.SYNOPSIS

Get users from a computer.

.DESCRIPTION

Gets users from a computer by reading the directory names in c:\users or c:\documents and settings.  It then gets the lastwritetime and lastaccess time from ntuser.dat

.PARAMETER $computername

The $computername paramater is required

.INPUTS

One or more computer names to get the users from

.OUTPUTS

Powershell object(s) containing the computer, user, lastwritetime, lastaccesstime 

.EXAMPLE

ps> .\get-ComputerUsers.ps1  computername

Gets the users from computername

.EXAMPLE

type names.txt | .\get-ComputerUsers.ps1

Gets users from multiple computers listed in names.txt (one computer per line)

.EXAMPLE

type names.txt | .\get-ComputerUsers.ps1 | export-csv -notypeinformation users.csv

Gets users from multiple computers listed in names.txt (one computer per line).  Returns output in the users.csv file

.NOTES

Author: Tom Willett 
Date: 10/9/2014

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$computername)

begin {
	$out = @()
	#$ErrorActionPreference = "SilentlyContinue"
}

process {
	$userPath = "\\" + $computername + "\c$\Documents and Settings\"
	if (test-path("\\" + $computername + "\c$\users\")) {
		$userPath = "\\" + $computername + "\c$\users\"
	}
	$temp = "" | Select Computer, User, LastLogOut, LastAccess
	$temp.Computer = $computername
	write-host "Checking $computername"
	if (test-connection -count 1 -quiet $computername) {
		if (test-path("\\" + $computername + "\c$\")) {
			$users = get-childitem $userPath
			foreach($user in $users) {
				$temp = "" | Select Computer, User, LastWrite, LastAccess
				$temp.Computer = $computername
				$temp.User = $user.name
				$t = $userPath + $user.name.tostring() + "\ntuser.dat"
				$prop = get-itemproperty $t -ErrorAction SilentlyContinue
				if ($prop) {
					$temp.LastWrite = $prop.lastwritetime
					$temp.lastAccess = $prop.lastaccesstime
				}
				$out += $temp
			}
		} else {
			$temp.user = "No Admin Share"
			$out += $temp
		}	
	} else {
		$temp.User = "Not Online"
		$out += $temp
	}
}

end {
	$out
}