<#
 
.SYNOPSIS
 
Parse Windows Shortcut Files
 
.DESCRIPTION

Parses the binary format of Windows Shortcut files.  Shortcut files provide a wealth of information about file usage.


.EXAMPLE
 
.\parse-shortcut.ps1 somefile.txt.lnk

Parses the binary contents of somefile.txt.lnk and displays it on the console.
 
.EXAMPLE
 
dir c:\users\SomeOne\appdata\roaming\microsoft\windows\recent\*.lnk | .\parse-shortcut.ps1 | export-csv -notypeinformation recent.csv

Parses the contents of all the recent links for user SomeOne and outputs it to recent.csv for analysis.
 
 
.NOTES

Author: Tom Willett 
Date: 1/14/2015
© 2015 Oink Software

#>
 
 Param([Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string]$lnkFile)

begin {
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
	function getFlags {
		Param([Parameter(Mandatory=$True)][uint32]$Data)
		$f = ""
		if ($data -band 0x1) { $f = "HasLinkTargetIDList " }
		if ($data -band 0x2) { $f += "HasLinkInfo " }
		if ($data -band 0x4) { $f += "HasName " }
		if ($data -band 0x8) { $f += "HasRelativePath " }
		if ($data -band 0x10) { $f += "HasWorkingDir " }
		if ($data -band 0x20) { $f += "HasArguments " }
		if ($data -band 0x40) { $f += "HasIconLocation " }
		if ($data -band 0x80) { $f += "IsUnicode " }
		if ($data -band 0x100) { $f += "ForceNoLinkInfo " }
		if ($data -band 0x200) { $f += "HasExpString " }
		if ($data -band 0x400) { $f += "RunInSeparateProcess " }
		if ($data -band 0x800) { $f += "Unused1 " }
		if ($data -band 0x1000) { $f += "HasDarwinID " }
		if ($data -band 0x2000) { $f += "RunAsUser " }
		if ($data -band 0x4000) { $f += "HasExpIcon " }
		if ($data -band 0x8000) { $f += "NoPidlAlias " }
		if ($data -band 0x10000) { $f += "Unused2 " }
		if ($data -band 0x20000) { $f += "RunWithShimLayer " }
		if ($data -band 0x40000) { $f += "ForceNoLinkTrack " }
		if ($data -band 0x80000) { $f += "EnableTargetMetadata " }
		if ($data -band 0x100000) { $f += "DisableLinkPathTracking " }
		if ($data -band 0x200000) { $f += "DisableKnownFolderTracking " }
		if ($data -band 0x400000) { $f += "DisableKnownFolderAlias " }
		if ($data -band 0x800000) { $f += "AllowLinkToLink " }
		if ($data -band 0x1000000) { $f += "UnaliasOnSave " }
		if ($data -band 0x2000000) { $f += "PreferEnvironmentPath " }
		if ($data -band 0x4000000) { $f += "KeepLocalIDListForUNCTarget" }
		$f
	}

	function getfileAttributes {
		Param([Parameter(Mandatory=$True)][uint32]$Data)
		$f = ""
		if ($data -band 0x1) { $f = "READONLY " }
		if ($data -band 0x2) { $f += "HIDDEN " }
		if ($data -band 0x4) { $f += "SYSTEM " }
		if ($data -band 0x10) { $f += "DIRECTORY " }
		if ($data -band 0x20) { $f += "ARCHIVE " }
		if ($data -band 0x80) { $f += "NORMAL " }
		if ($data -band 0x100) { $f += "TEMPORARY " }
		if ($data -band 0x200) { $f += "SPARSE_FILE " }
		if ($data -band 0x400) { $f += "REPARSE_POINT " }
		if ($data -band 0x800) { $f += "COMPRESSED " }
		if ($data -band 0x1000) { $f += "OFFLINE " }
		if ($data -band 0x2000) { $f += "CONTENT_NOT_INDEXED " }
		if ($data -band 0x4000) { $f += "ENCRYPTED" } 
		$f
	}
	
	function getWindow {
		Param([Parameter(Mandatory=$True)][uint32]$Data)
		$f = "Normal"
		if ($data -eq 0x1) { $f = "Normal" }
		if ($data -eq 0x3) { $f = "Maximized" }
		if ($data -eq 0x7) { $f = "Hidden" }
		$f
	}

	function hotKey {
		Param([Parameter(Mandatory=$True)][uint32]$Data)
		$chr = @{"0x70" = "'F1' key"; "0x71" = "'F2' key";"0x72" = "'F3' key";"0x73" = "'F4' key";"0x74" = "'F5' key";"0x75" = "'F6' key";"0x76" = "'F7' key";"0x77" = "'F8' key";"0x78" = "'F9' key";"0x79" = "'F10' key";"0x7A" = "'F11' key";"0x7B" = "'F12' key";"0x7C" = "'F13' key";"0x7D" = "'F14' key";"0x7E" = "'F15' key";"0x7F" = "'F16' key";"0x80" = "'F17' key";"0x81" = "'F18' key";"0x82" = "'F19' key";"0x83" = "'F20' key";"0x84" = "'F21' key";"0x85" = "'F22' key";"0x86" = "'F23' key";"0x87" = "'F24' key";"0x90" = "'NUM LOCK' key";"0x91" = "'SCROLL LOCK' key"}
		$f = ""
		$k = [bitconverter]::getbytes($Data)
		$mod = $k[1]
		$key = $k[0]
		if ($mod -band 0x1) { $f = "Shift " }
		if ($mod -band 0x2) { $f += "Ctl " }
		if ($mod -band 0x4) { $f += "Alt " }
		if (($key -ge 0x30) -and ($key -le 0x51)) {$f += [System.Text.Encoding]::ASCII.GetString($key[0])}
		$ka = toHex($key)
		if (($key -ge 0x70) -and ($key -le 0x91)) {$f += $chr.get_item($ky) }
		$f
	}
	
	$driveType = @("DRIVE_UNKNOWN","DRIVE_NO_ROOT_DIR","DRIVE_REMOVABLE","DRIVE_FIXED","DRIVE_REMOTE","DRIVE_CDROM","DRIVE_RAMDISK")
	$NetworkProviderType = @{"0x001A0000" = "WNNC_NET_AVID";"0x001B0000" = "WNNC_NET_DOCUSPACE";"0x001C0000" = "WNNC_NET_MANGOSOFT";"0x001D0000" = "NNC_NET_SERNET";"0X001E0000" = "WNNC_NET_RIVERFRONT1";"0x001F0000" = "WNNC_NET_RIVERFRONT2";"0x00200000" = "WNNC_NET_DECORB";"0x00210000" = "WNNC_NET_PROTSTOR";"0x00220000" = "WNNC_NET_FJ_REDIR";"0x00230000" = "WNNC_NET_DISTINCT";"0x00240000" = "WNNC_NET_TWINS";"0x00250000" = "WNNC_NET_RDR2SAMPLE";"0x00260000" = "WNNC_NET_CSC";"0x00270000" = "WNNC_NET_3IN1";"0x00290000" = "WNNC_NET_EXTENDNET";"0x002A0000" = "WNNC_NET_STAC";"0x002B0000" = "WNNC_NET_FOXBAT";"0x002C0000" = "WNNC_NET_YAHOO";"0x002D0000" = "WNNC_NET_EXIFS";"0x002E0000" = "WNNC_NET_DAV";"0x002F0000" = "WNNC_NET_KNOWARE";"0x00300000" = "WNNC_NET_OBJECT_DIRE";"0x00310000" = "WNNC_NET_MASFAX";"0x00320000" = "WNNC_NET_HOB_NFS";"0x00330000" = "WNNC_NET_SHIVA";"0x00340000" = "WNNC_NET_IBMAL";"0x00350000" = "WNNC_NET_LOCK";"0x00360000" = "WNNC_NET_TERMSRV";"0x00370000" = "WNNC_NET_SRT";"0x00380000" = "WNNC_NET_QUINCY";"0x00390000" = "WNNC_NET_OPENAFS";"0X003A0000" = "WNNC_NET_AVID1";"0x003B0000" = "WNNC_NET_DFS";"0x003C0000" = "WNNC_NET_KWNP";"0x003D0000" = "WNNC_NET_ZENWORKS";"0x003E0000" = "WNNC_NET_DRIVEONWEB";"0x003F0000" = "WNNC_NET_VMWARE";"0x00400000" = "WNNC_NET_RSFX";"0x00410000" = "WNNC_NET_MFILES";"0x00420000" = "WNNC_NET_MS_NFS";"0x00430000" = "WNNC_NET_GOOGLE"}

	function GUID {
		Param([Parameter(Mandatory=$True)][byte[]]$byte)
		$g = "{0:X8}" -f [bitconverter]::touint32($byte,0)
		$g += "-"
		$g += "{0:X4}" -f [bitconverter]::touint16($byte,4)
		$g += "-"
		$g += "{0:X4}" -f [bitconverter]::touint16($byte,6)
		$g += "-"
		$byte[8..9] | Foreach-Object {$g += ($_.ToString("X2")) }
		$g += "-"
		$byte[10..15] | Foreach-Object {$g +=  ($_.ToString("X2")) }
		$g
	}
}
	
process {
	$ptr = 0
	$fname = (Resolve-Path $lnkFile).Path
	if ($fname.length -gt 0) {
		$lnk = get-content "$fname" -encoding byte
		####
		$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
		$tmp.lnkFile = $fname
		$tmp.Data = "Size of Header"
		$tmp.Offset = "0x00"
		$tmp.Value = toHex($lnk[0..3])
		$tmp.Notes = "This value MUST be 0x0000004C."
		write-output $tmp
		$ptr += 4
		####
		$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
		$tmp.lnkFile = $fname
		$tmp.Data = "GUID of shortcut files"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = GUID($lnk[$ptr..($ptr+15)])
		$tmp.Notes = "This value MUST be 00021401-0000-0000-C000-000000000046."
		write-output $tmp
		$ptr += 16
		####
		$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
		$tmp.lnkFile = $fname
		$tmp.Data = "Flags"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
		$tmp.Notes = getFlags([bitconverter]::touint32($lnk,$ptr))
		$flags = [bitconverter]::touint32($lnk,$ptr)
		write-output $tmp
		$ptr += 4
		####
		$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
		$tmp.lnkFile = $fname
		$tmp.Data = "File Attributes"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
		$tmp.Notes = getFileAttributes([bitconverter]::touint32($lnk,$ptr))
		write-output $tmp
		$ptr += 4
		####
		$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
		$tmp.lnkFile = $fname
		$tmp.Data = "Create Time"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = [datetime]::fromfiletime([bitconverter]::touint64($lnk,$ptr))
		$tmp.Notes = [bitconverter]::touint64($lnk,$ptr)
		write-output $tmp
		$ptr += 8
		####
		$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
		$tmp.lnkFile = $fname
		$tmp.Data = "Access Time"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = [datetime]::fromfiletime([bitconverter]::touint64($lnk,$ptr))
		$tmp.Notes = [bitconverter]::touint64($lnk,$ptr)
		write-output $tmp
		$ptr += 8
		####
		$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
		$tmp.lnkFile = $fname
		$tmp.Data = "Write Time"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = [datetime]::fromfiletime([bitconverter]::touint64($lnk,$ptr))
		$tmp.Notes = [bitconverter]::touint64($lnk,$ptr)
		write-output $tmp
		$ptr += 8
		####
		$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
		$tmp.lnkFile = $fname
		$tmp.Data = "File Size"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = [bitconverter]::touint32($lnk,$ptr)
		$tmp.Notes = "The low DWord of the file size"
		write-output $tmp
		$ptr += 4
		####
		$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
		$tmp.lnkFile = $fname
		$tmp.Data = "Icon Index"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = [bitconverter]::toint32($lnk,$ptr)
		$tmp.Notes = ""
		write-output $tmp
		$ptr += 4
		####
		$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
		$tmp.lnkFile = $fname
		$tmp.Data = "Show Window Value"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
		$tmp.Notes = getWindow([bitconverter]::touint32($lnk,$ptr))
		write-output $tmp
		$ptr += 4
		####
		$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
		$tmp.lnkFile = $fname
		$tmp.Data = "HotKey"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = toHex($lnk[$ptr..($ptr+1)])
		$tmp.Notes = hotKey([bitconverter]::touint32($lnk,$ptr))
		write-output $tmp
		$ptr += 12
		####
		$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
		$tmp.lnkFile = $fname
		$tmp.Data = "Start of Optional Data Area"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = ""
		$tmp.Notes = ""
		write-output $tmp
		## LinkTargetIDList ##
		if (([bitconverter]::touint32($lnk,0x0014)) -band 0x1) { 
			####
			$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
			$tmp.lnkFile = $fname
			$tmp.Data = "LinkTargetIDList Length"
			$tmp.Offset = "0x{0:X4}" -f $ptr
			$IDListLen = [bitconverter]::touint16($lnk,$ptr)
			$tmp.Value = toHex($lnk[$ptr..($ptr+1)])
			$tmp.Notes = [bitconverter]::touint16($lnk,$ptr)
			write-output $tmp
			####
			$ptr += 2
			$IDListLen += $ptr
			While($ptr -lt $IDListLen) {
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "ItemID"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$IDLen = [bitconverter]::touint16($lnk,$ptr)
				if ($IDLen -gt 0) {
					$str = "0x"
					$lnk[($ptr+2)..($ptr+$IDLen-1)] | Foreach-Object { $str += ($_.ToString("X2")) }
					$tmp.Value = $str
					$str = ""
					$lnk[($ptr+2)..($ptr+$IDLen-1)] | Foreach-Object { $str += ([char]$_ -replace"[^ -x7e]",".") }
					$tmp.Notes = $str
				} else {
					$tmp.Value = ""
					$tmp.Notes = ""
					$IDlen = 2
				}
				write-output $tmp
				$ptr += $IDLen
			}
		}
		## Link Info ##
		if (([bitconverter]::touint32($lnk,0x0014)) -band 0x2) { 
			####
			$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
			$tmp.lnkFile = $fname
			$tmp.Data = "LinkInfo Length"
			$tmp.Offset = "0x{0:X4}" -f $ptr
			$LinkInfoLen = [bitconverter]::touint32($lnk,$ptr)
			$LinkInfoBase = $ptr
			$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
			$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
			write-output $tmp
			$ptr += 4
			####
			$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
			$tmp.lnkFile = $fname
			$tmp.Data = "LinkInfoHeader Length"
			$tmp.Offset = "0x{0:X4}" -f $ptr
			$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
			$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
			$LinkInfoHeaderLen = [bitconverter]::touint32($lnk,$ptr)
			write-output $tmp
			$ptr += 4
			####
			$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
			$tmp.lnkFile = $fname
			$tmp.Data = "LinkInfo Flags"
			$tmp.Offset = "0x{0:X4}" -f $ptr
			$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
			$tmp.Notes = "0b" + [convert]::tostring([bitconverter]::touint32($lnk,$ptr),2)
			$LinkInfoFlgs = [bitconverter]::touint32($lnk,$ptr)
			write-output $tmp
			$ptr += 4
			####
			$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
			$tmp.lnkFile = $fname
			$tmp.Data = "VolumeID Offset"
			$tmp.Offset = "0x{0:X4}" -f $ptr
			$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
			$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
			$VolIdOffset = [bitconverter]::touint32($lnk,$ptr)
			write-output $tmp
			$ptr += 4
			####
			$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
			$tmp.lnkFile = $fname
			$tmp.Data = "Local Base Path Offset"
			$tmp.Offset = "0x{0:X4}" -f $ptr
			$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
			$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
			$LocalBaseOffset = [bitconverter]::touint32($lnk,$ptr)
			write-output $tmp
			$ptr += 4
			####
			$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
			$tmp.lnkFile = $fname
			$tmp.Data = "Common Network Relative Link Offset"
			$tmp.Offset = "0x{0:X4}" -f $ptr
			$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
			$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
			$NetRelativeOffset = [bitconverter]::touint32($lnk,$ptr)
			write-output $tmp
			$ptr += 4
			####
			$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
			$tmp.lnkFile = $fname
			$tmp.Data = "Common Path Suffix Offset"
			$tmp.Offset = "0x{0:X4}" -f $ptr
			$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
			$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
			$PathSuffixOffset = [bitconverter]::touint32($lnk,$ptr)
			write-output $tmp
			$ptr += 4
			####
			if ($LinkInfoHeaderLen -ge 0x24) {
				####
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "Local Base Path Offset Unicode"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
				$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
				$PathSuffixOffset = [bitconverter]::touint32($lnk,$ptr)
				write-output $tmp
				$ptr += 4
				####
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "Common Path Suffix Offset Unicode"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
				$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
				$PathSuffixOffset = [bitconverter]::touint32($lnk,$ptr)
				write-output $tmp
				$ptr += 4
			}
			if ($LinkInfoFlgs -band 0x1) {
				#VolumeIDAndLocalBasePath 
				## VolumeID
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "VolumeID Structure"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$tmp.Value = ""
				$tmp.Notes = ""
				$VolId = $ptr
				write-output $tmp
				##########
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "VolumeID Size"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
				$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
				write-output $tmp
				$ptr += 4
				#####
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "DriveType"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
				$tmp.Notes = $driveType[[bitconverter]::touint32($lnk,$ptr)]
				write-output $tmp
				$ptr += 4
				######
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "Drive Serial Number"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
				$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
				write-output $tmp
				$ptr += 4
				######
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "Volume Label Offset"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
				$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
				$VolLabOffset = [bitconverter]::touint32($lnk,$ptr)
				write-output $tmp
				$ptr += 4
				If ($VolLabOffset -eq 0x00000014) {
					$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
					$tmp.lnkFile = $fname
					$tmp.Data = "Volume Label Offset Unicode"
					$tmp.Offset = "0x{0:X4}" -f $ptr
					$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
					$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
					$VolLabOffset = [bitconverter]::touint32($lnk,$ptr)
					write-output $tmp
					$ptr += 4
				}
				#####
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "Volume Label"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$VolID += $VolLabOffset
				$VolEnd = $VolId
				If ($VolLabOffset -eq 0x00000014) {
					While($lnk[$VolEnd] -ne 0x0) { $VolEnd += 2 }
					$tmp.Value = [System.Text.Encoding]::Unicode.GetString($lnk[$VolID..($VolEnd-2)])
				} else {
				While($lnk[$VolEnd] -ne 0x0) { $VolEnd += 1 }
					$tmp.Value = [System.Text.Encoding]::ASCII.GetString($lnk[$VolID..($VolEnd-1)])
				}
				$tmp.Notes = ""
				write-output $tmp
				$ptr = $VolEnd +1
				#####
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "Local Base Path"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$VolEnd = $ptr
				While($lnk[$VolEnd] -ne 0x0) { $VolEnd += 1 }
				$tmp.Value = [System.Text.Encoding]::ASCII.GetString($lnk[$ptr..($VolEnd-1)])
				$tmp.Notes = ""
				write-output $tmp
				$ptr = $VolEnd

			}
			if ($LinkInfoFlgs -band 0x2) {
				#PathSuffix
				##########
				$ptr = $PathSuffixOffset + $LinkInfoBase
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "Common Path Suffix"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$NNEnd = $ptr
				While($lnk[$NNEnd] -ne 0x0) { $NNEnd += 1 }
				if ($NNEnd -gt $ptr) {
					$tmp.Value = [System.Text.Encoding]::ASCII.GetString($lnk[$ptr..($NNEnd-1)])
				} else {
					$tmp.Value = ""
				}
				$tmp.Notes = ""
				write-output $tmp
				$ptr = $NNEnd
				#CommonNetworkRelativeLink
				$ptr = $NetRelativeOffset + $LinkInfoBase
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "Common Network Relative Link Size"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
				$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
				write-output $tmp
				$ptr += 4
				If ($tmp.Notes -gt 0) {
					##########
					$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
					$tmp.lnkFile = $fname
					$tmp.Data = "Common Network RelativeLink Flags"
					$tmp.Offset = "0x{0:X4}" -f $ptr
					$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
					$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
					write-output $tmp
					$ptr += 4
					##########
					$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
					$tmp.lnkFile = $fname
					$tmp.Data = "Net Name Offset"
					$tmp.Offset = "0x{0:X4}" -f $ptr
					$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
					$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
					$NetNameOffset = [bitconverter]::touint32($lnk,$ptr)
					write-output $tmp
					$ptr += 4
					##########
					$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
					$tmp.lnkFile = $fname
					$tmp.Data = "Device Name Offset"
					$tmp.Offset = "0x{0:X4}" -f $ptr
					$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
					$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
					write-output $tmp
					$ptr += 4
					##########
					$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
					$tmp.lnkFile = $fname
					$tmp.Data = "Network Provider Type"
					$tmp.Offset = "0x{0:X4}" -f $ptr
					$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
					$tmp.Notes = $NetworkProviderType.get_Item($tmp.Value)
					write-output $tmp
					$ptr += 4
					##########
					if ($NetNameOffset -gt 0x00000014) {
						$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
						$tmp.lnkFile = $fname
						$tmp.Data = "Net Name Offset Unicode"
						$tmp.Offset = "0x{0:X4}" -f $ptr
						$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
						$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
						write-output $tmp
						$ptr += 4
						##########
						$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
						$tmp.lnkFile = $fname
						$tmp.Data = "Device Name Offset Unicode"
						$tmp.Offset = "0x{0:X4}" -f $ptr
						$tmp.Value = toHex($lnk[$ptr..($ptr+3)])
						$tmp.Notes = [bitconverter]::touint32($lnk,$ptr)
						write-output $tmp
						$ptr += 4
					}
					##########
					$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
					$tmp.lnkFile = $fname
					$tmp.Data = "Net Name"
					$tmp.Offset = "0x{0:X4}" -f $ptr
					$NNEnd = $ptr
					While($lnk[$NNEnd] -ne 0x0) { $NNEnd += 1 }
					$tmp.Value = [System.Text.Encoding]::ASCII.GetString($lnk[$ptr..($NNEnd-1)])
					$tmp.Notes = ""
					write-output $tmp
					$ptr = $NNEnd
					if ($lnk[$ptr] -eq 0) { $ptr += 1 }
					##########
					$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
					$tmp.lnkFile = $fname
					$tmp.Data = "Device Name"
					$tmp.Offset = "0x{0:X4}" -f $ptr
					$NNEnd = $ptr
					While($lnk[$NNEnd] -ne 0x0) { $NNEnd += 1 }
					if ($NNEnd -gt $ptr) {
						$tmp.Value = [System.Text.Encoding]::ASCII.GetString($lnk[$ptr..($NNEnd-1)])
					}
					$tmp.Notes = ""
					write-output $tmp
					$ptr = $NNEnd
					if ($NetNameOffset -gt 0x00000014) {
						##########
						$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
						$tmp.lnkFile = $fname
						$tmp.Data = "Net Name"
						$tmp.Offset = "0x{0:X4}" -f $ptr
						$NNEnd = $ptr
						While($lnk[$NNEnd] -ne 0x0) { $NNEnd += 2 }
						$tmp.Value = [System.Text.Encoding]::UNICODE.GetString($lnk[$ptr..($NNEnd-1)])
						$tmp.Notes = ""
						write-output $tmp
						$ptr = $NNEnd
						##########
						$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
						$tmp.lnkFile = $fname
						$tmp.Data = "Device Name"
						$tmp.Offset = "0x{0:X4}" -f $ptr
						$NNEnd = $ptr
						While($lnk[$NNEnd] -ne 0x0) { $NNEnd += 2 }
						$tmp.Value = [System.Text.Encoding]::UNICODE.GetString($lnk[$ptr..($NNEnd-1)])
						$tmp.Notes = ""
						write-output $tmp
						$ptr = $NNEnd
					}
				}
			}
			##########
			if (($LinkInfoFlgs -band 0x2) -and ($LinkInfoHeaderLen -ge 0x24)) {
				##########
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "Local Base Path Unicode"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$NNEnd = $ptr
				While($lnk[$NNEnd] -ne 0x0) { $NNEnd += 2 }
				$tmp.Value = [System.Text.Encoding]::UNICODE.GetString($lnk[$ptr..($NNEnd-1)])
				$tmp.Notes = ""
				write-output $tmp
				$ptr = $NNEnd
				##########
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "Common Path Suffix Unicode"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$NNEnd = $ptr
				While($lnk[$NNEnd] -ne 0x0) { $NNEnd += 2 }
				$tmp.Value = [System.Text.Encoding]::UNICODE.GetString($lnk[$ptr..($NNEnd-1)])
				$tmp.Notes = ""
				write-output $tmp
				$ptr = $NNEnd
			}
		}
		while ($lnk[$ptr] -eq 0) { $ptr += 1 }
		## String data ##
		if ($Flags -band 0x4) {
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "Name String"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$SEnd = [bitconverter]::touint16($lnk,$ptr)
				$SEnd *= 2
				$ptr += 2
				$tmp.Value = [System.Text.Encoding]::UNICODE.GetString($lnk[$ptr..($ptr + $SEnd - 1)])
				$tmp.Notes = ""
				write-output $tmp
				$ptr += $SEnd		
		}
		if ($Flags -band 0x8) {
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "Relative Path"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$SEnd = [bitconverter]::touint16($lnk,$ptr)
				$SEnd *= 2
				$ptr += 2
				$tmp.Value = [System.Text.Encoding]::UNICODE.GetString($lnk[$ptr..($ptr + $SEnd - 1)])
				$tmp.Notes = ""
				write-output $tmp
				$ptr += $SEnd		
		}
		if ($Flags -band 0x10) {
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "Working Directory"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$SEnd = [bitconverter]::touint16($lnk,$ptr)
				$SEnd *= 2
				$ptr += 2
				$tmp.Value = [System.Text.Encoding]::UNICODE.GetString($lnk[$ptr..($ptr + $SEnd - 1)])
				$tmp.Notes = ""
				write-output $tmp
				$ptr += $SEnd		
		}
		if ($Flags -band 0x20) {
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "Command Args"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$SEnd = [bitconverter]::touint16($lnk,$ptr)
				$SEnd *= 2
				$ptr += 2
				$tmp.Value = [System.Text.Encoding]::UNICODE.GetString($lnk[$ptr..($ptr + $SEnd - 1)])
				$tmp.Notes = ""
				write-output $tmp
				$ptr += $SEnd		
		}
		if ($Flags -band 0x40) {
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$tmp.lnkFile = $fname
				$tmp.Data = "Icon Location"
				$tmp.Offset = "0x{0:X4}" -f $ptr
				$SEnd = [bitconverter]::touint16($lnk,$ptr)
				$SEnd *= 2
				$ptr += 2
				$tmp.Value = [System.Text.Encoding]::UNICODE.GetString($lnk[$ptr..($ptr + $SEnd - 1)])
				$tmp.Notes = ""
				write-output $tmp
				$ptr += $SEnd		
		}
		### Extra Data  ###
		$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
		$tmp.lnkFile = $fname
		$tmp.Data = "Extra Data Area"
		$tmp.Offset = "0x{0:X4}" -f $ptr
		$tmp.Value = ""
		$tmp.Notes = ""
		write-output $tmp
		$ctr = 1
		while (($ptr -lt $lnk.length) -and ($ctr -lt 10)) {
			$ctr += 1
			$lenData = [bitconverter]::touint32($lnk,$ptr)
			if ($lenData -gt 0x0) {
				$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
				$BSig = [bitconverter]::touint32($lnk,($ptr+4))
				$tmp.lnkFile = $fname
				$tmp.Offset = "0x{0:X4}" -f $ptr
				if ($BSig -eq  2684354562) {
					$tmp.Data = "Console Data Block"
					$str = "0x"
					$lnk[($ptr+8)..($ptr+$lenData-1)] | Foreach-Object { $str += ($_.ToString("X2")) }
					$tmp.Value = $str
					$str = ""
					$lnk[($ptr+8)..($ptr+$lenData-1)] | Foreach-Object { $str += ([char]$_ -replace"[^ -x7e]",".") }
					$tmp.Notes = $str
					write-output $tmp
					$ptr += $lenData
				}
				if ($BSig -eq  2684354564) {
					$tmp.Data = "Console FE Data Block"
					$tmp.value = [bitconverter]::touint32($lnk,($ptr+8))
					$tmp.Notes = "CodePage"
					write-output $tmp
					$ptr += $lenData
				}
				if ($BSig -eq  2684354566) {
					$tmp.Data = "Darwin Data Block"
					$NNEnd = $ptr + 268
					While($lnk[$NNEnd] -ne 0x0) { $NNEnd += 2 }
					$tmp.Value = [System.Text.Encoding]::UNICODE.GetString($lnk[($ptr+268)..($ptr + $NNEnd - 1)])
					$tmp.Notes = ""
					write-output $tmp
					$ptr += $lenData
				}
				if ($BSig -eq  2684354561) {
					$tmp.Data = "Environment Variable Data Block"
					$NNEnd = $ptr + 8
					While($lnk[$NNEnd] -ne 0x0) { $NNEnd += 1 }
					$tmp.Value = [System.Text.Encoding]::ASCII.GetString($lnk[($ptr+8)..($ptr + $NNEnd - 1)])
					$NNEnd = $ptr + 268
					While($lnk[$NNEnd] -ne 0x0) { $NNEnd += 2 }
					$tmp.Notes = [System.Text.Encoding]::UNICODE.GetString($lnk[($ptr+268)..($ptr + $NNEnd - 1)])
					write-output $tmp
					$ptr += $lenData
				}
				if ($BSig -eq  2684354567) {
					$tmp.Data = "Icon Environment Data Block"
					$NNEnd = $ptr + 8
					While($lnk[$NNEnd] -ne 0x0) { $NNEnd += 1 }
					$tmp.Value = [System.Text.Encoding]::ASCII.GetString($lnk[($ptr+8)..($ptr + $NNEnd - 1)])
					$NNEnd = $ptr + 268
					While($lnk[$NNEnd] -ne 0x0) { $NNEnd += 2 }
					$tmp.Notes = [System.Text.Encoding]::UNICODE.GetString($lnk[($ptr+268)..($ptr + $NNEnd - 1)])
					write-output $tmp
					$ptr += $lenData
				}
				if ($BSig -eq  2684354571) {
					$tmp.Data = "Known Folder Data Block"
					$tmp.Value = "GUID "
					$tmp.Value += GUID($lnk[($ptr+8)..($ptr+23)])
					$tmp.Notes =  "Offset into IDList " + [bitconverter]::touint32($lnk,($ptr+0x18))
					write-output $tmp
					$ptr += $lenData
				}
				if ($BSig -eq  2684354569) {
					$tmp.Data = "Property Store Data Block"
					$tmp.Value = "Seralized Property Storage"
					$tmp.Notes = ""
					write-output $tmp
					$ptr += 8
				}
				if ($BSig -eq  1397773105) {
					$tmp.Data = "Serialized Property Storage"
					$str = "GUID "
					$str += GUID($lnk[($ptr+8)..($ptr+23)])
					$tmp.Notes = $str
					$str = ""
					$lnk[($ptr+0x18)..($ptr+$lenData-1)] | Foreach-Object { $str += ($_.ToString("X2")) }
					$tmp.Value = $str
					write-output $tmp
					$ptr += $lenData
				}
				if ($BSig -eq  2684354568) {
					$tmp.Data = "Shim Data Block"
					$tmp.value = [System.Text.Encoding]::UNICODE.GetString($lnk[($ptr+8)..($ptr + $lenData - 1)])
					$tmp.Notes = ""
					write-output $tmp
					$ptr += $lenData
				}
				if ($BSig -eq  2684354565) {
					$tmp.Data = "Special Folder Data Block"
					$tmp.value = "Folder ID " + [bitconverter]::touint32($lnk,($ptr+8))
					$tmp.Notes =  "Offset into IDList " + [bitconverter]::touint32($lnk,($ptr+0x0c))
					write-output $tmp
					$ptr += $lenData
				}
				if ($BSig -eq  2684354563) {
					$tmp.Data = "Tracker Data Block"
					$tLen = [bitconverter]::touint32($lnk,($ptr+8))
					$tEnd = $ptr + 16
					While($lnk[$tEnd] -ne 0x0) { $tEnd += 1 }
					$tmp.value = "MachineID: " + [System.Text.Encoding]::ASCII.GetString($lnk[($ptr+16)..($tEnd)])
					$str = "Droid Values "
					$str += GUID($lnk[$tend..($tend+15)])
					$str += " "
					$str += GUID($lnk[($tend+16)..($tend+31)])
					$str += " "
					$str += GUID($lnk[($tend+32)..($tend+47)])
					$str += " "
					$str += GUID($lnk[($tend+48)..($tend+63)])
					$tmp.Notes = $str
					write-output $tmp
					$ptr += $lenData
				}
				if ($BSig -eq  2684354572) {
					$tmp.Data = "Vista and Above ID List Data Block "
					$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
					$tmp.lnkFile = $fname
					$tmp.Data = "Vista and Above ID List Length"
					$tmp.Offset = "0x{0:X4}" -f $ptr
					$IDListLen = [bitconverter]::touint16($lnk,$ptr)
					$tmp.Value = toHex($lnk[$ptr..($ptr+1)])
					$tmp.Notes = [bitconverter]::touint16($lnk,$ptr)
					write-output $tmp
					####
					$IDListLen += $ptr
					$ptr += 8
					While($ptr -lt $IDListLen) {
						$tmp = "" | Select lnkFile, Data, Offset, Value, Notes
						$tmp.lnkFile = $fname
						$tmp.Data = "ItemID"
						$tmp.Offset = "0x{0:X4}" -f $ptr
						$IDLen = [bitconverter]::touint16($lnk,$ptr)
						if ($IDLen -gt 0) {
							$str = "0x"
							$lnk[($ptr+2)..($ptr+$IDLen-1)] | Foreach-Object { $str += ($_.ToString("X2")) }
							$tmp.Value = $str
							$str = ""
							$lnk[($ptr+2)..($ptr+$IDLen-1)] | Foreach-Object { $str += ([char]$_ -replace"[^ -x7e]",".") }
							$tmp.Notes = $str
						} else {
							$tmp.Value = ""
							$tmp.Notes = ""
							$IDlen = 2
						}
						write-output $tmp
						$ptr += $IDLen
					}
				}
			} else {
				$ptr += 4
			}
		}
	}
}

end {
}
