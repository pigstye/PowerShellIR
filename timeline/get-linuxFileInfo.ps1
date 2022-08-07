<#

.SYNOPSIS

Retrieves information about the files on a linux filesystem mounted in windows.

.DESCRIPTION

Retrieves information about the files on a linux filesystem mounted in windows.
It get LastAccessTime, LastWriteTime, Path, FileType, SHA1, Size for each file.

.EXAMPLE

ps> .\get-linuxFileInfo.ps1  G:\


Retrieves information about all the files on the mounted linux file system at g:

.EXAMPLE

.\get-linuxFileInfo.ps1 G:\ | export-csv -notype files.csv

Retrieves the information about the files on the mounted linux file system at g: and exports to files.csv

.EXAMPLE

.\get-linuxFileInfo.ps1 G:\ | .\convert-linuxfileinfo-to-timeline.ps1 | export-csv -notype files.csv

Retrieves the information about the files on the mounted linux file system at g: converts it to timeline format and exports to files.csv

.NOTES

Author: Tom Willett 
Date: 3/6/2015

#>

param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$DriveSpec)
process {
	$ErrorActionPreference = "SilentlyContinue"
	$files = Get-ChildItem $DriveSpec -Recurse
	$sha1 = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
	ForEach($file in $files) { 
		$fi = "" | Select LastAccessTime, LastWriteTime, Path, FileType, SHA1, Size
		$fi.Path = $file.FullName
		$fi.FileType = If($file.PSIsContainer) {'Dir'} Else {'File'}
		$fi.LastAccessTime = $file.LastAccessTime
		if ($LastAccessTime -eq "12/31/1600 6:00:00 PM") { $LastAccessTime = "" }
		$fi.LastWriteTime = $file.LastWriteTime
		if ($LastWriteTime -eq "12/31/1600 6:00:00 PM") { $LastWriteTime = "" }
		$fi.Size = $file.length
		$fi.SHA1 = ([System.BitConverter]::ToString( $sha1.ComputeHash([System.IO.File]::ReadAllBytes($fi.path)))).replace("-","")
		write-output $fi
	}
}