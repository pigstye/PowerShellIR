<#

.SYNOPSIS

Converts the output from get-linuxFileInfo.ps1 and converts it to the timeline format.

.DESCRIPTION

Takes the output from get-linuxFileInfo.ps1 and converts it to the following timeline format:
DateTime,MACB,User,Machine,SHA1,ShortEvent,Event,LogSource,LogSourceType,Inode,Notes

.Parameter LastAccessTime

.Parameter LastWriteTime

.Parameter Path

.Parameter FileType

.Parameter SHA1

.Parameter Size

.PARAMETER $Machine

 Required can be entered on commandline.


.EXAMPLE

 .\get-linuxFileInfo.ps1 G:\ | .\convert-linuxfileinfo-to-timeline.ps1 | export-csv -notype files.csv

Retrieves the information about the files on the mounted linux file system at g: converts it to timeline format and exports to files.csv
 
.NOTES

Author: Tom Willett 
Date: 3/6/2015

#>

#DateTime,MACB,User,Machine,SHA1,ShortEvent,Event,LogSource,LogSourceType,Inode,Notes
Param([Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)][string]$LastAccessTime,
	[Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)][string]$LastWriteTime,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Path,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$FileType,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$SHA1,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Size,
	[Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$False)][string]$Machine)

process {
	$tmp = "" | Select DateTime,MACB,User,Machine,SHA1,ShortEvent,Event,LogSource,LogSourceType,Inode,Notes
	$tmp.Machine = $Machine
	$tmp.SHA1 = $SHA1
	$pth = $Path.substring(2).replace("\","/")
	$tmp.ShortEvent = $pth
	$tmp.LogSource = "FileSystem"
	$tmp.LogSourceType = $FileType
	$tmp.DateTime = $LastWriteTime
	$tmp.MACB = "M"
	if ( $LastWriteTime -eq $LastAccessTime) {
		$tmp.MACB += "A"
		$tmp.Event = "LastWrite/Last Access: " + $tmp.DateTime + " - " + $pth
		write-output $tmp
	} else {
		$tmp.Event = "LastWrite: " + $tmp.DateTime + " - " + $pth
		write-output $tmp
		$tmp.DateTime = $LastAccessTime
		$tmp.MACB = "A"
		$tmp.Event = "Last Access: " + $tmp.DateTime + " - " + $pth
		Write-output $tmp
	}
}