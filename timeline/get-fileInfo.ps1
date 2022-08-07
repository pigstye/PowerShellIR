<#

.SYNOPSIS

Get information about files

.DESCRIPTION

Gets the following information about all files in a path and under that path: CreationTime, LastAccessTime, LastWriteTime, 
Path, Type, Owner, Group, Identity, Inherited, InheritanceFlags, PropagationFlags, AccessControlType, AccessMasks, Atrributes,  Size
Output is a powershell object which can be output to csv or xml.

.PARAMETER DriveSpec

The DriveSpec is required and is the path where the files are that will be examined

.EXAMPLE

 .\get-files.ps1 . 

 Gets the files in the current directory and below.
 
.EXAMPLE

 .\get-files.ps1 d:\ | export-csv -notypeinformation files.csv

 Gets all the files on the d: drive and exports them to files.csv
 
.EXAMPLE

 .\get-files.ps1 d:\ | convert-fileinfo-to-timeline.ps1 | export-csv -notypeinformation files.csv

 Gets all the files on the d: drive converts them to my timeline format and exports them to files.csv
 
.EXAMPLE

 type .\drives.txt | .\get-files.ps1 | export-csv -notypeinformation files.csv

 Gets the files from the drives contained in drives.txt (one per line) and exports them to files.csv
 
.NOTES

Author: Tom Willett 
Date: 12/29/2014

Win32 ACE (Access Control Entry) definition for directories -- bit flags
1 = LIST_DIRECTORY Grants the right to list the contents of the directory.
2 = ADD_FILE Grants the right to create a file in the directory.
4 = ADD_SUBDIRECTORY Grants the right to create a subdirectory.
8 = READ_EA Grants the right to read extended attributes.
16 = WRITE_EA Grants the right to write extended attributes.
32 = TRAVERSE The directory can be traversed.
64 = DELETE_CHILD Grants the right to delete a directory and all the files it contains (its children), even if the files are read-only.
128 = READ_ATTRIBUTES Grants the right to read file attributes.
256 = WRITE_ATTRIBUTES Grants the right to change file attributes.
65536 = DELETE Grants delete access.
131072 = READ_CONTROL Grants read access to the security descriptor and owner.
262144 = WRITE_DAC Grants write access to the discretionary access control list (ACL).
524288 = WRITE_OWNER Assigns the write owner.
1048576 = SYNCHRONIZE Synchronizes access and allows a process to wait for an object to enter the signaled state.
268435456 = FullControl

Note there are other more complicated combinations for which there are no easy descriptions.

#>

param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$DriveSpec)
process {
	$dr = @("LIST_DIRECTORY","ADD_FILE","ADD_SUBDIRECTORY","READ_EA","WRITE_EA","TRAVERSE","DELETE_CHILD","READ_ATTRIBUTES","WRITE_ATTRIBUTES","","","","","","","","DELETE","READ_CONTROL","WRITE_DACL","WRITE_OWNER","SYNCHRONIZE","","","","","","","","FullControl","")
	$files = Get-ChildItem $DriveSpec -Recurse -Force
	$sha1 = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
	ForEach($file in $files) { 
	  $ac = $file.GetAccessControl()
	  foreach($a in $ac.access) {
		$fi = "" | Select CreationTime, LastAccessTime, LastWriteTime, Path, FileType, SHA1, Owner, Group, Identity, Inherited, InheritanceFlags, PropagationFlags, AccessControlType, AccessMasks, Atrributes, Size
		$fi.Path = $file.FullName
		If($file.PSIsContainer) {
			$fi.Type = 'Dir'
			[int]$i = $a.FileSystemRights
			$AccessMasks = ""
			for($j = 0; $j -lt 30; $j++) {
				if ($i -band 0x1) {
					if ($AccessMasks.length -gt 0) {
						$AccessMasks += ", "
					}
					$AccessMasks += $dr[$j]
				}
				$i = [math]::floor($i/2)  # shr 1
			}
			$fi.AccessMasks = $AccessMasks
		} Else {
			$fi.FileType = 'File'
			$fi.AccessMasks = $a.FileSystemRights
		} 
		$fi.FileType = If($file.PSIsContainer) {'Dir'} Else {'File'} 
		$fi.Owner = $ac.Owner 
		$fi.Group = $ac.Group
		$fi.Identity = $a.IdentityReference 
		$fi.Inherited = $a.IsInherited 
		$fi.InheritanceFlags = $a.InheritanceFlags 
		$fi.PropagationFlags = $a.PropagationFlags 
		$fi.AccessControlType = $a.AccessControlType 
		$fi.Atrributes = $file.Attributes
		$fi.CreationTime = $file.CreationTime
		$fi.LastAccessTime = $file.LastAccessTime
		$fi.LastWriteTime = $file.LastWriteTime
		$fi.Size = $file.length
		$fi.SHA1 = ([System.BitConverter]::ToString( $sha1.ComputeHash([System.IO.File]::ReadAllBytes($fi.path)))).replace("-","")
		}
		write-output $fi
	}
}