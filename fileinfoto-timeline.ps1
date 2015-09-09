<#

.SYNOPSIS

Takes the output from get-fileinfo.ps1 and converts it to timeline format.

.DESCRIPTION

Takes the output from get-fileinfo.ps1 and converts it to the following timeline format:
DateTime,MACB,User,Machine,SHA1,ShortEvent,Event,LogSource,LogSourceType,Inode,Notes

.PARAMETER CreationTime

.PARAMETER LastAccessTime

.PARAMETER LastWriteTime

.PARAMETER Path

.PARAMETER FileType

.PARAMETER SHA1

.PARAMETER Owner

.PARAMETER Group

.PARAMETER Identity

.PARAMETER Inherited

.PARAMETER InheritanceFlags

.PARAMETER PropagationFlags

.PARAMETER AccessControlType

.PARAMETER AccessMasks

.PARAMETER Atrributes

.PARAMETER Size

.PARAMETER Machine

Required can be entered on commandline.


.EXAMPLE

 .\get-files.ps1 d:\ | fileinfoto-timeline.ps1 | export-csv -notypeinformation files.csv

 Gets all the files on the d: drive converts them to my timeline format and exports them to files.csv
 
.NOTES

Author: Tom Willett 
Date: 12/29/2014
© 2014 Oink Software

#>

Param([Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$True)][string]$CreationTime,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$LastAccessTime,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$LastWriteTime,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Path,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$FileType,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$SHA1,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Owner,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Group,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Identity,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Inherited,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$InheritanceFlags,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$PropagationFlags,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$AccessControlType,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$AccessMasks,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Atrributes,
	[Parameter(Mandatory=$False,ValueFromPipelinebyPropertyName=$True)][string]$Size,
	[Parameter(Mandatory=$True,ValueFromPipelinebyPropertyName=$False)][string]$Machine)


process {
	$tmp = "" | Select DateTime,MACB,User,Machine,SHA1,ShortEvent,Event,LogSource,LogSourceType,Inode,Notes
	$tmp.User = $User
	$tmp.Machine = $Machine
	$tmp.SHA1 = $SHA1
	$tmp.ShortEvent = $Path
	$tmp.Event = $Path
	$tmp.notes = "Owner = " + $Owner + " - Group = " + $Group + " - AccessType = " + $AccessControlType + " - AccessMasks = " + $AccessMasks
	$tmp.LogSource = "FileSystem"
	$tmp.LogSourceType = $FileType
	$tmp.DateTime = $LastWriteTime
	$tmp.MACB = "M"
	if ($LastWriteTime -eq $LastAccessTime) { 
		$tmp.MACB += "A"
		if ($LastWriteTime -eq $CreationTime) {
			$tmp.MACB += "B"
			$tmp.Event =  $path + " -- Modified, Accessed, Created"
			write-output $tmp
		} else {
			$tmp.event += " -- Modified, Accessed"
			write-output $tmp
			$tmp.MACB = "B"
			$tmp.event =  $path + " -- Created"
			$tmp.DateTime = $CreationTime
			write-output $tmp
		}
	} elseif ($LastWriteTime -eq $CreationTime) {
		$tmp.MACB += "B"
		$tmp.event =  $path + " -- Created"
		write-output $tmp
	} else {
		$tmp.event =  $path + " -- Modified"
		write-output $tmp
		$tmp.DateTime = $LastAccessTime
		$tmp.MACB = "A"
		if ($LastAccessTime -eq $CreationTime) {
			$tmp.MACB += "B"
			$tmp.event =  $path + " -- Accessed, Created"
			write-output $tmp
		} else {
			$tmp.event =  $path + " -- Accesed"
			write-output $tmp
			$tmp.MACB = "B"
			$tmp.DateTime = $CreationTime
			$tmp.event =  $path + " -- Created"
			Write-Output $tmp
		}
	}
}	
