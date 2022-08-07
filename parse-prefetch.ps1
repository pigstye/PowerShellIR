<#

.SYNOPSIS

Get information about prefetch files

.DESCRIPTION

Parses the prefetch file(s) and returns the result in a ps object so it can be exported
to csv or xml.

.PARAMETER PreFetchFile

This is either the directory of prefetch files or one file to process.  It is not mandatory
and if ommitted the script will parse all the prefetch files in the c:\windows\prefetch directory.

.EXAMPLE

 .\parse-prefetch.ps1

 Parses the prefetch files in the c:\windows\prefetch directory
 
.EXAMPLE

 .\parse-prefetch.ps1 | export-csv -notypeinformation prefetch.csv

 Parses the prefetch files in the c:\windows\prefetch directory and outputs them to prefetch.csv
 
.EXAMPLE

 .\parse-prefetch.ps1 c:\windows\prefetch\CALC.EXE-0FE8F3A9.pf 
 
 Parses CALC.EXE-0FE8F3A9.pf
 
.NOTES

Author: Tom Willett 
Date: 1/1/2015

#>

Param([Parameter(Mandatory=$False,ValueFromPipeline=$false,ValueFromPipelinebyPropertyName=$false)][string]$preFetchFile="c:\windows\prefetch")

function toHex {
	Param([Parameter(Mandatory=$True)][byte[]]$byte)
	$hx = "0x"
	switch ($byte.length) {
		1 { $hx += "{0:X2}" -f $byte }
		2 { $hx += "{0:X4}" -f [bitconverter]::touint16($byte,0) }
		4 { $hx += "{0:X8}" -f [bitconverter]::touint32($byte,0) }
		default { $hx += "00" }
	}
	$hx
}
$ver = @{"0x00000011" = "Windows XP";"0x00000017" = "Windows 7";"0x0000001A" = "Windows 8"}

$pf = get-item $preFetchFile
if ($pf.PSIsContainer) {
	$pFiles = get-childItem "$pf\*.pf"
} else {
	$pFiles = @()
	$pFiles += (get-item $pf)
}
foreach($fname in $pfiles) {
	$pfile = get-content $fname.fullname -encoding byte
	$ptr = 0
	
	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Format Version"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
	$tmp.Notes = $ver.get_item($tmp.Value)
	$version = [bitconverter]::touint32($pfile,$ptr)
	write-output $tmp
	$ptr += 4
	
	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Magic Number"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	$tmp.Value = [System.Text.Encoding]::ASCII.GetString($pfile[$ptr..($ptr + 3)])
	$tmp.Notes = ""
	write-output $tmp
	$ptr += 8

	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "File Size"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
	$tmp.Notes = [convert]::tostring([bitconverter]::touint32($pfile,$ptr))
	write-output $tmp
	$ptr += 4
	
	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "PF File Creation Time"
	$tmp.Offset = "0x{0:X4}" -f 0
	$tmp.Value = $fname.creationtime
	$tmp.Notes = ""
	write-output $tmp

	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "PF File Modify Time"
	$tmp.Offset = "0x{0:X4}" -f 0
	$tmp.Value = $fname.LastWriteTime
	$tmp.Notes = ""
	write-output $tmp

	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "PF File Access Time"
	$tmp.Offset = "0x{0:X4}" -f 0
	$tmp.Value = $fname.LastAccessTime
	$tmp.Notes = ""
	write-output $tmp
	
	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Name of executable"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	for($i = $ptr; $i -lt ($ptr + 60); $i += 2 ) { if ($pfile[$i] -eq 0) { break }}
	$i--
	$tmp.Value = [System.Text.Encoding]::Unicode.GetString($pfile[$ptr..$i])
	$tmp.Notes = ""
	write-output $tmp
	$ptr += 60
	
	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Checksum"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
	$tmp.Notes = [convert]::tostring([bitconverter]::touint32($pfile,$ptr))
	write-output $tmp
	$ptr += 8

	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Offset to Section A"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
	$tmp.Notes = [convert]::tostring([bitconverter]::touint32($pfile,$ptr))
	$aOffset = [bitconverter]::touint32($pfile,$ptr)
	#write-output $tmp
	$ptr += 4

	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Number of Entries in Section A"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
	$tmp.Notes = [convert]::tostring([bitconverter]::touint32($pfile,$ptr))
	$aNum = [bitconverter]::touint32($pfile,$ptr)
	#write-output $tmp
	$ptr += 4

	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Offset to Section B"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
	$tmp.Notes = [convert]::tostring([bitconverter]::touint32($pfile,$ptr))
	$bOffset = [bitconverter]::touint32($pfile,$ptr)
	#write-output $tmp
	$ptr += 4

	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Number of Entries in Section B"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
	$tmp.Notes = [convert]::tostring([bitconverter]::touint32($pfile,$ptr))
	$bNum = [bitconverter]::touint32($pfile,$ptr)
	#write-output $tmp
	$ptr += 4

	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Offset to Section C"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
	$tmp.Notes = [convert]::tostring([bitconverter]::touint32($pfile,$ptr))
	$cOffset = [bitconverter]::touint32($pfile,$ptr)
	#write-output $tmp
	$ptr += 4

	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Length of Section C"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
	$tmp.Notes = [convert]::tostring([bitconverter]::touint32($pfile,$ptr))
	$cLen = [bitconverter]::touint32($pfile,$ptr)
	#write-output $tmp
	$ptr += 4

	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Offset to Section D"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
	$tmp.Notes = [convert]::tostring([bitconverter]::touint32($pfile,$ptr))
	$dOffset = [bitconverter]::touint32($pfile,$ptr)
	#write-output $tmp
	$ptr += 4

	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Number of Section D"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
	$tmp.Notes = [convert]::tostring([bitconverter]::touint32($pfile,$ptr))
	$dNum = [bitconverter]::touint32($pfile,$ptr)
	#write-output $tmp
	$ptr += 4

	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Length of Section D"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
	$tmp.Notes = [convert]::tostring([bitconverter]::touint32($pfile,$ptr))
	$dLen = [bitconverter]::touint32($pfile,$ptr)
	#write-output $tmp

	if ($version -eq 0x11) {
		$ptr += 4
		$lastRun = [bitconverter]::touint64($pfile,$ptr)
		$tmp = "" | Select PfFile, Data, Offset, Value, Notes
		$tmp.PfFile = $fname.name
		$tmp.Data = "Last Run Time"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = [datetime]::fromfiletime($lastRun)
		$tmp.Notes = [bitconverter]::touint64($pfile,$ptr)
		write-output $tmp
		$ptr += 32

		$tmp = "" | Select PfFile, Data, Offset, Value, Notes
		$tmp.PfFile = $fname.name
		$tmp.Data = "Execution Counter"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
		$tmp.Notes = [bitconverter]::touint32($pfile,$ptr)
		write-output $tmp
		$ptr += 8
	} elseif ($version -lt 0x1a) {
		$ptr += 12
		$lastRun = [bitconverter]::touint64($pfile,$ptr)
		$tmp = "" | Select PfFile, Data, Offset, Value, Notes
		$tmp.PfFile = $fname.name
		$tmp.Data = "Last Run Time"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = [datetime]::fromfiletime($lastRun)
		$tmp.Notes = [bitconverter]::touint64($pfile,$ptr)
		write-output $tmp
		$ptr += 24

		$tmp = "" | Select PfFile, Data, Offset, Value, Notes
		$tmp.PfFile = $fname.name
		$tmp.Data = "Execution Counter"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
		$tmp.Notes = [bitconverter]::touint32($pfile,$ptr)
		write-output $tmp
		$ptr += 8

	} else {
		$ptr += 12
		$lastRun = [bitconverter]::touint64($pfile,$ptr)
		$tmp = "" | Select PfFile, Data, Offset, Value, Notes
		$tmp.PfFile = $fname.name
		$tmp.Data = "Last Run Time"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = [datetime]::fromfiletime($lastRun)
		$tmp.Notes = [bitconverter]::touint64($pfile,$ptr)
		write-output $tmp
		$ptr += 8
		
		for ($i = 0; $i -lt 8; $i++) {
			$lastRun = [bitconverter]::touint64($pfile,$ptr)
			$tmp = "" | Select PfFile, Data, Offset, Value, Notes
			$tmp.PfFile = $fname.name
			$tmp.Data = "Previous Run Time"
			$tmp.Offset = "0x{0:X4}" -f $ptr
			$tmp.Value = [datetime]::fromfiletime($lastRun)
			$tmp.Notes = [bitconverter]::touint64($pfile,$ptr)
			write-output $tmp
			$ptr += 8
		}
		
		$ptr = 0xd4
		$tmp = "" | Select PfFile, Data, Offset, Value, Notes
		$tmp.PfFile = $fname.name
		$tmp.Data = "Execution Counter"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
		$tmp.Notes = [bitconverter]::touint32($pfile,$ptr)
		write-output $tmp
		$ptr += 8

	}
	$ptr = $cOffset
	while($ptr -lt $dOffset) {
		$tmp = "" | Select PfFile, Data, Offset, Value, Notes
		$tmp.PfFile = $fname.name
		$tmp.Data = "File Used"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$i = $ptr
		while($pfile[$i] -ne 0x0) { $i+=2 }
		$i--
		$tmp.Value = [System.Text.Encoding]::Unicode.GetString($pfile[$ptr..$i])
		$tmp.Notes = ""
		if ($tmp.value -ne "") {write-output $tmp}
		[uint32]$ptr = ($i + 3)
	}
	$ptr = $dOffset
	$volID = [bitconverter]::touint32($pfile,$ptr)
	$volID += $dOffset
	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Volume Name"
	$tmp.Offset = "0x{0:X4}" -f $volID
	$i = $volID
	while($pfile[$i] -ne 0x0) { $i+=2 }
	$i--
	$tmp.Value = [System.Text.Encoding]::Unicode.GetString($pfile[$volID..$i])
	$tmp.Notes = ""
	write-output $tmp
	$ptr += 8
	$cts = [bitconverter]::touint64($pfile,$ptr)
	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Volume Creation TimeStamp"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	$tmp.Value = [datetime]::fromfiletime($cts)
	$tmp.Notes = [bitconverter]::touint64($pfile,$ptr)
	write-output $tmp
	$ptr += 8
	
	$tmp = "" | Select PfFile, Data, Offset, Value, Notes
	$tmp.PfFile = $fname.name
	$tmp.Data = "Volume Serial Number"
	$tmp.Offset = "0x{0:X4}" -f $ptr
	$tmp.Value = toHex($pFile[$ptr..($ptr + 3)])
	$tmp.Notes = [bitconverter]::touint32($pfile,$ptr)
	write-output $tmp
	$ptr += 12
	$dsa = [bitconverter]::touint32($pfile,$ptr)
	$dsa += $dOffset
	$ptr += 4
	$dsaEnt = [bitconverter]::touint32($pfile,$ptr)
	$ptr = $dsa
	for ($j = 0; $j -lt $dsaent; $j++) {
		$tmp = "" | Select PfFile, Data, Offset, Value, Notes
		$tmp.PfFile = $fname.name
		$tmp.Data = "Directory Used"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$ptr += 2
		$i = $ptr
		while($pfile[$i] -ne 0x0) { $i+=2 }
		$i--
		$tmp.Value = [System.Text.Encoding]::Unicode.GetString($pfile[$ptr..$i])
		$tmp.Notes = ""
		if ($tmp.value -ne "") {write-output $tmp}
		[uint32]$ptr = ($i + 3)	
	}
}

$out
