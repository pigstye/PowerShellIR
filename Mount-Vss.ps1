<#

.SYNOPSIS

Mount Volume Shadow Copies on a system so they can be browsed like normal file systems

.DESCRIPTION

The vssadmin command is used to list all the Volume Shadow Copies available on a system.
The script then mounts all these copies on c:\vss or a directory you provide.  If the 
mount directory is not present it is created.

You can examine evidence drives by mounting them on your system before running this command.

.PARAMETER VSSVol

The volume (n: d: etc), for which, you want to mount the shadow copies.

.EXAMPLE

 .\Mount-vss.ps1

 Mounts all the Shadow Copies available in c:\vss
 
.EXAMPLE

 .\Mount-vss.ps1 f:\vss

 Mounts all the Shadow Copies available in f:\vss
 
.EXAMPLE

.NOTES

Author: Tom Willett 
Date: 12/6/2014

#>

Param([Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$VSSVol)

$mountdir = "c:\vss"

if ((test-path $mountdir) -eq $false) {
	mkdir $mountdir
}
if ($MountDir.endswith("\") -eq $False) {
	$MountDir += "\"
}
if ($VSSVOL.length -eq 1) {
	$VSSVOL += ":"
}
if ($VSSVOL.length -gt 2) {
	$VSSVOL = $VSSVOL.substring(0,2)
}
$vss = vssadmin list shadows /for=$VSSVOL
$v1 = $vss | select-string "Shadow Copy Volume"
$tmpPath = $MountDir + "vss.txt"
$vss > $tmpPath
$v2 =@()
foreach($v in $v1) { 
	$v2 += $v.tostring().replace("Shadow Copy Volume:","").trim()
}
foreach($v in $v2) {
	$tmp = $v.split("\")
	$tmpPath = $MountDir + $tmp[5]
	"tmppath = " + $tmpPath
	$tmpVss = $v + "\"
	$tmpVSS
	cmd /c mklink /d $tmpPath $tmpVss
}