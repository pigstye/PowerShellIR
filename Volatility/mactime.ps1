<#

.SYNOPSIS

Convert a file in the sleuthkit body format to csv

.DESCRIPTION

The script accepts input from the pipeline convert the dates and creates output line the sleuthkit mactime script.  
The dates are converted from epoch time to the current timezone.
This is intended to be run in conjuction with the voltimeline.ps1 script.

.OUTPUTS

A powershell object containing DateTime, MACB, MD5, name, inode, mode_as_string, UID, GID, Size.

.EXAMPLE

PS D:\> import-csv -path timeline.txt -delimiter "|" -header 'MD5','name','inode','mode_as_string','UID','GID','size','atime','mtime','ctime','crtime' | .\mactime.ps1 | Export-Csv -notypeinformation timeline.csv
This command imports a file in body format with the import-csv commandlet pipes it to the mactime.ps1 script and the
outputs it to csv format with the export-csv commandlet.

.NOTES

 Author: Tom Willett 
 Date: 11/27/2014

.LINK

vol.ps1
voltimeline.ps1

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$MD5,
	[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$name,
	[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$inode,
	[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$mode_as_string,
	[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$UID,
	[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$GID,
	[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$size,
	[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$atime,
	[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$mtime,
	[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$ctime,
	[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$crtime)

begin {
	#$txt = import-csv -path $filename -delimiter "|" -header 'MD5','name','inode','mode_as_string','UID','GID','size','atime','mtime','ctime','crtime' 
	[datetime]$origin = '1970-01-01 00:00:00'
	$n = 1
}

process {
	$ErrorActionPreference = "SilentlyContinue"
	$atime = $origin.addseconds($atime)
	$mtime = $origin.addseconds($mtime)
	$ctime = $origin.addseconds($ctime)
	$crtime = $origin.addseconds($crtime)
	$ErrorActionPreference = "Stop"
	$temp = "" | Select DateTime, MACB, MD5, name, inode, mode_as_string, UID, GID, Size
	$temp.MD5 = $MD5
	$temp.name = $name
	$temp.inode = $inode
	$temp.mode_as_string = $mode_as_string
	$temp.UID = $UID
	$temp.GID = $GID
	$temp.Size = $Size
	$tm = $true
	$tc = $true
	$tcr = $true
	$temp.MACB = "M"
	$temp.DateTime = $mtime
	if ($mtime -eq $atime) {
		$temp.MACB += "A"
		$tm = $false
	}
	if ($mtime -eq $ctime) {
		$temp.MACB += "C"
		$tc = $false
	}
	if ($mtime -eq $crtime) {
		$temp.MACB += "B"
		$tcr = $false
	}
	if (-not (($temp.DateTime -eq $origin) -or ($temp.DateTIme -eq "-"))) { write-output $temp }
	if ($temp.MACB -ne "MACB") {
		if ($tm) {
			$temp = "" | Select DateTime, MACB, MD5, name, inode, mode_as_string, UID, GID, Size
			$temp.MD5 = $MD5
			$temp.name = $name
			$temp.inode = $inode
			$temp.mode_as_string = $mode_as_string
			$temp.UID = $UID
			$temp.GID = $GID
			$temp.Size = $Size
			$temp.MACB = "A"
			$temp.DateTime = $atime
			if ($atime -eq $ctime) {
				$temp.MACB += "C"
				$tc = $false
			}
			if ($atime -eq $crtime) {
				$temp.MACB += "B"
				$tcr = $false
			}
			if (-not (($temp.DateTime -eq $origin) -or ($temp.DateTIme -eq "-"))) { write-output $temp }
		}
		if ($tc) {
			$temp = "" | Select DateTime, MACB, MD5, name, inode, mode_as_string, UID, GID, Size
			$temp.MD5 = $MD5
			$temp.name = $name
			$temp.inode = $inode
			$temp.mode_as_string = $mode_as_string
			$temp.UID = $UID
			$temp.GID = $GID
			$temp.Size = $Size
			$temp.MACB = "C"
			$temp.DateTime = $ctime
			if ($ctime -eq $crtime) {
				$temp.MACB += "B"
				$tcr = $false
			}
			if (-not (($temp.DateTime -eq $origin) -or ($temp.DateTIme -eq "-"))) { write-output $temp }
		}
		if ($tcr) {
			$temp = "" | Select DateTime, MACB, MD5, name, inode, mode_as_string, UID, GID, Size
			$temp.MD5 = $MD5
			$temp.name = $name
			$temp.inode = $inode
			$temp.mode_as_string = $mode_as_string
			$temp.UID = $UID
			$temp.GID = $GID
			$temp.Size = $Size
			$temp.MACB = "B"
			$temp.DateTime = $crtime
			if (-not (($temp.DateTime -eq $origin) -or ($temp.DateTIme -eq "-"))) { write-output $temp }
		}
	}
	if (($n % 1000) -eq 0) { 
		write-host "$n records processed by Mactime.ps1"
	}
	$n += 1
}

end {
	$n -= 1
	write-host "$n total records processed by Mactime.ps1"
}
