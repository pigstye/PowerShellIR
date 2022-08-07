<#

.SYNOPSIS

Run common volatility commands on a memory image

.DESCRIPTION

The following commands are run against a memory image: hivelist, userassist, pslist, psscan, pstree, psxview, 
modscan, ldrmodules, driverscan, driverirp, devicetree, unloadedmodules, envars, dlllist, getsids, getservicesids, 
handles, filescan, svcscan, connections, connscan, sockscan, sockets, netscan, cmdscan, consoles, and strings.

A directory is created in the same directory that the image file is in called "VolatilityOutput" where the 
output of all the commands is placed.  If the command extracts images from memory (malfind, dlldump, moddump, 
procdump) the images are put in a directory under VolatilityOutput-(ImageName) named after the command.  The output 
from the timeliner script is exported in body format.  By default the script runs imageinfo on the image first
to determine the image type and presents you with a menu of options to choose from.  If you know you image type 
you can enter it on the command line and skip this step.  The script accepts pipeline input so you can feed it 
a csv of images and image types and it will run on each image in turn.

If you cancel the process by ^c you can restart it and the scan will pick up where it left off.

To process a hyberfil.sys volatility.exe -f hiberfil.sys imagecopy -O hyberfil.raw

.PARAMETER image

Image file to run volatility on. (required)

.PARAMETER volimage

Image type to use (not required)

.EXAMPLE     
    .\vol.ps1 c:\image.mem
    Runs the script against c:\images\image.mem, checks what kind of image it is and allows you to choose.  
	It puts the output in c:\images\VolatilityOutput-image.mem

.EXAMPLE     
    .\vol.ps1 c:\image.mem WinXPSP3x86
    Runs the script against c:\images\image.mem and uses WinXPSP3x86 as the image type.  
	It puts the output in c:\images\VolatilityOutput-image.mem

.EXAMPLE     
    input-csv .\images.csv |.\vol.ps1
	Takes input from .\images.csv in the format image,volimage and feeds it to the .\vol.ps1 script one at a time.  
    It puts the output in a directory starting with VolatilityOutput in the directory where each image is located.

.NOTES
	
 Author: Tom Willett
 Date: 10/27/2014

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$image,[Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$volType="")

process {
	#commands to run with just text output
	$VolOptions = @("hivelist","userassist","pslist","psscan","pstree","psxview","modscan","mftparser","ldrmodules","driverscan","driverirp","devicetree","unloadedmodules","envars","dlllist","getsids","handles","filescan","svcscan","cmdscan","consoles")
	#XP Server 2003 specific options
	$VolOptionsXP = @("connections","connscan","sockscan","sockets")
	#Vista and later options
	$VolOptionsV = @("netscan","getservicesids")
	#commands to run which dump from memory
	$VolDump = @("malfind","dlldump","moddump","procdump")

	if (test-path $image) {
		write-host "==========================================================="
		#Path to image where results will be found
		$imageName = split-path $image -leaf
		$path = (split-path $image) + "\VolatilityOutput-$imageName\"
		(mkdir $path) 2>&1 > $null
		$Cachepath = $path + "\VolCache"
		(mkdir $Cachepath) 2>&1 > $null
		Write-host "Putting output in $path"
		$VolOut = $path + "ImageType.txt"
		if (test-path $VolOut) {
			$volType = get-content $VolOut
		}
		if ($volType.length -eq 0) {
			# Get possible image type
			write-host "Determining Image Type for image: $image"
			$volimage = .\volatility.exe --cache-directory=$Cachepath --cache imageinfo -f $image
			$voltmp = $volimage | select-string "Suggested Profile"
			$voltmp = $voltmp.tostring()
			$voltmp = $voltmp.replace("Suggested Profile(s) : ","")
			$voltmp = $voltmp.trim()
			$volimages = $voltmp.split(",")
			for($i=0;$i -lt $volimages.length;$i++) { 
				$volimages[$i]=$volimages[$i].trim()
				if ($volimages[$i].split(" ").length -gt 1) { 
					$volimages[$i] = ($volimages[$i].split(" ")[0]).trim()
				}
			}
			#Display possible image types
			write-host "Possible Image Types:"
			$v = ""
			for ($i = 0; $i -lt $volimages.length; $i++) {
				$v = $volimages[$i]
				write-host "$i : $v"
			}
			$i = read-host "Select Image type to use by #"
			$volType=$volimages[$i]
		}
		if (($volType.startswith("WinXP")) -or ($volType.startswith("Win2003"))) {
			$VolOptions = $VolOptions + $VolOptionsXP
		} else {
			$VolOptions = $VolOptions + $VolOptionsV
		}
		$VolOut = $path + "ImageType.txt"
		Set-Content -Path $VolOut -Value $volType
		write-host "Image type being used: $volType"
		foreach($command in $VolOptions) {
			$VolOut = $path + "$imageName-$command.txt"
			if (test-path $VolOut) {
				write-host "$command already run -- skipping"
			} else {
				write-host "Running $command command now.  Writing output to $VolOut"
				.\volatility.exe --cache-directory=$Cachepath --cache  $command -f $image --profile $volType > $VolOut
			}
		}
		foreach($command in $VolDump) {
			$VolDir = $path + "$imageName-$command" + "\"
			(mkdir $VolDir) 2>&1 > $null
			$VolOut = $path + "$imageName-$command.txt"
			if (test-path $VolOut) {
				write-host "$command already run -- skipping"
			} else {
				write-host "Running $command command now.  Writing output to $VolOut"
				.\volatility.exe --cache-directory=$Cachepath --cache  $command -f $image --profile $volType --dump-dir=$VolDir > $VolOut
				$FNS = get-childitem $VolDir
				foreach ($FN in $FNS) {
					write-host "Running stings on $FN.Fullname"
					$VolOut1 = $FN.FullName + "-Strings.txt"
					.\strings.exe -o -n 6 $FN.FullName > $VolOut1
				}
			}
		}
		$VolOut = $path + "$imageName-orphanThread.txt"
		if (test-path $VolOut) {
			write-host "OrphanThreads already run -- skipping"
		} else {
			write-host "Looking for orphan strings putting output in $VolOut"
			.\volatility.exe --cache-directory=$Cachepath --cache  threads -f $image -F OrphanThread --profile $volType > $VolOut
		}
		$VolOut = $path + "$imageName-strings.txt"
		if (test-path $VolOut) {
			write-host "Strings already run -- skipping"
		} else {
			write-host "Running Strings on the memory image writing output to $VolOut"
			.\strings.exe -o -n 6 $image > $VolOut
			.\split.ps1 $VolOut
		}
		#$VolOut = $path + "$imageName-timeline.txt"
		#if (test-path $VolOut) {
		#	write-host "Timeline already created -- skipping"
		#} else {
		#	write-host "Creating Timeline Now. Writing output to $VolOut"
		#	.\volatility.exe --cache-directory=$Cachepath --cache  timeliner -f $image --profile $volType --output=body --output-file=$VolOut
		#}
	} else {
		"Image $image not found"
	}
}
