<#

.SYNOPSIS

Gather forensic info from a remote computer

.DESCRIPTION

This creates a seperate folder with the computer name and date-time and in this folder places
general information about the computer, autoruns, netstat, processes, and services in different files.

.OUTPUTS

Creates a directory with computer forensic information.

.EXAMPLE

PS>.\computerforensicinfo.ps1 x03758

.NOTES

 Author: Tom Willett 
 Date:  6/27/2013
 © Oink Software
 Ver 1.0

#>

Param([parameter(Mandatory = $true, ValueFromPipeline = $true)]$computer)

$ErrorActionPreference = "SilentlyContinue"

function Format-HumanReadable {
	param ($size)
	if ($size -ge 1PB) {
		$hsize = [string][math]::round(($size/1PB),0) + "P"
	} elseif ($size -ge 1TB) {
		$isize=[math]::round(($size/1TB),0)
		$hsize=[string]$isize + "T"
	} elseif ($size -ge 1GB) {
		$isize=[math]::round(($size/1GB),0)
		$hsize=[string]$isize + "G"
	} elseif ($size -ge 1MB) {
		$isize=[math]::round(($size/1MB),0)
		$hsize=[string]$isize + "M"
	} elseif ($size -ge 1KB) {
		$isize=[math]::round(($size/1KB),0)
		$hsize=[string]$isize + "K"
	}
	$hsize += "B"
	return $hsize
}

function get-OS([Parameter(Mandatory = $True, Position = 0)][string] $comp) {
<#
	.Synopsis
		Checks Windows OS Version
	.Description
		get-os returns an integer designating the OS version
	.Parameter comp
		A computer name or ip
	.NOTES
		Author: Tom Willett
		Date: 6/14/2013
		© 2013 Oink Software
	.Outputs
		Returns
		0 if unknown
		1 Windows 2000
		2 Windows XP
		3 Windows XP 64bit
		4 Windows Server 2003 (R2)
		5 Windows Vista
		6 Windows Server 2008
		7 Windows 7
		8 Windows Server 2008 R2
		9 Windows 8
		10 Windows Server 2012
	.Inputs
		A computer name or ip
#>
	[int]$os = 0
	#first check if it is server 2003 (XP) or server 2008 (Win 7) for paths
	$Version = gwmi win32_OperatingSystem -computername $comp -ErrorAction SilentlyContinue

	# if Error return 0
	if ($Version -eq $null) {
		$os = 0
	}
	else
	{
		if ($Version.version.startswith("5.0")) {
			$os = 1
		}
		if ($Version.version.startswith("5.1")) {
			$os = 2
		}
		if ($Version.version.startswith("5.2")) {
			$os = 3
			if ($Version.Caption.Contains("Server")) {
				$os = $os + 1
			}
		}
		if ($Version.version.startswith("6.0")) {
			$os = 5
			if ($Version.Caption.Contains("Server")) {
				$os = $os + 1
			}
		}
		if ($Version.version.startswith("6.1")) {
			$os = 7
			if ($Version.Caption.Contains("Server")) {
				$os = $os + 1
			}
		}
		if ($Version.version.startswith("6.2")) {
			$os = 9
			if ($Version.Caption.Contains("Server")) {
				$os = $os + 1
			}
		}
	}
	return $os
}

if (test-connection -count 1 -quiet $computer) {
	"---------- Getting General Information ------------------"
	$objWmi = gwmi "Win32_operatingSystem" -computerName $computer
	$uptime = [Management.ManagementDateTimeConverter]::ToDateTime($objWmi.LastBootUpTime)
	$os = $objWmi.Caption
	$memwmi = gwmi -query "Select * from Win32_Computersystem" -computerName $computer
	$memory = format-humanreadable($memwmi.TotalPhysicalMemory)
	$procwmi = gwmi -query "Select * from Win32_Processor" -computerName $computer
	$objWMI = get-WMIObject Win32_ComputerSystem -computerName $computer
	$body = "Information about " + $objWMI.Caption + " - " + $objWmi.Manufacturer + " " + $objWmi.Model + "`r`n" 
	$body += "Operation System: " + $os + "`r`n"
	$body += "Memory: " + $memory  + "`r`n"
	$body += "Processor: " + $procwmi.Name + "`r`n"
	$body += "Time: " + (get-date) + "`r`n"
	$body += "Last boot Time: $uptime `r`nUser: " + $objWMI.username + "`r`n"
	$adapters = gwmi -query "Select * from Win32_NetworkAdapter where netConnectionStatus=2" -computerName $computer
	$body += "`r`nActive Network Adapter(s):`r`n"
	echo "one - " + $body
	foreach($adapt in $adapters) {
		$body += $adapt.name + " -- Mac Address: " + $adapt.MACAddress + "`r`n"
	}
	$wmiq = "Select * From Win32_LogicalDisk Where Size != Null And DriveType=2 Or DriveType=3 Or DriveType=4 Or DriveType=5"
	$body += "`r`nDisk Space ----------------------------------`r`n"
	$objWMI = Get-WmiObject -Query $wmiq -computerName $computer
	foreach ($obj in $objWMI) {
		$body += "Drive: " + $obj.DeviceID + "`r`n"
		$body += "Size: "
		$body += Format-HumanReadable($obj.Size)
		$body += "`r`nFree: "
		$body += Format-HumanReadable($obj.FreeSpace) 
		$body += "`r`n"
	}
	if ((get-os($computer)) -gt 5) {
		$userPath = "\\" + $computer + "\c$\users\"
	} else {
		$userPath = "\\" + $computer + "\c$\Documents and Settings\"
	}
	$users = get-childitem $userPath | sort-object lastwritetime -descending
	$body += "------- Users ---------`r`n"
	foreach ($user in $users) { $body += $user.name + " -- " + $user.lastwritetime + "`r`n" }
	$compDir = $computer + "-ForensicInfo-" + (get-date -uformat "%Y%m%d-%H%M").tostring()
	mkdir $compDir > $null
	$outFile = $compDir + "\" + $computer + "-Info.txt"
	$body > $outfile
	"-------------------- Getting IE Extensions (BHO Etc) -----------------"
	$outFile = $compDir + "\" + $computer + "-IEExtensions.txt"
	copy autorunsc.exe \\$computer\c$
	psexec \\$computer c:\autorunsc.exe -accepteula -i > $outFile
	 $outFile = $compDir + "\" + $computer + "-AutoRuns.txt"
	"-------------------- Getting Autoruns ------------------"
	psexec \\$computer c:\autorunsc.exe -accepteula -a -m -v > $outFile
 	del \\$computer\c$\autorunsc.exe
	"---------------------- Doing Remote Netstat ------------------"
	$outFile = $compDir + "\" + $computer + "-netstat.txt"
	psexec \\$computer netstat.exe -anob > $outFile
	"-------------------- Getting Services ------------------------"
	$wmiq = "Select * from win32_service"
	$outFile = $compDir + "\" + $computer + "-serviceInfo.txt"
	gwmi -query $wmiq -computername $computer | format-list -property * > $outFile
	"---------------------- Getting Processes --------------------------"
	$wmiq = "Select * from win32_process" 
	$outFile = $compDir + "\" + $computer + "-processInfo.txt"
	gwmi -query $wmiq -computername $computer | format-list -property * > $outFile
}
else
{
	"Not Online"
}
