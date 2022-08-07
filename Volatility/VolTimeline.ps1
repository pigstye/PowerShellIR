<#

.SYNOPSIS

Run the volatility timeliner, shellbags and mftparser against a memory image to create a complete timeline

.DESCRIPTION

Create a memory timeline by running the volatility timliner, shellbags and mftparser modules against a memory image.
All these are put into one timeline and then run through mactime.ps1 to create a csv timeline.  The TimeZone is required,
one of the standard timezones.

Note: it is assumed that volatility.exe and mactime.ps1 are in the current directory.

.PARAMETER image

The path to the memory image, required.

.PARAMETER TZ

Time Zone of Image to convert UTC times.  Standard TimeZones are expected.

.PARAMETER VolType

The memory image type as defined by volatility.  If the vol.ps1 script has been run against the image
already then the type is used from that run.  If the image type is not known then the volatility imageinfo
plugin is run and the a menu of imagetype choices is presented to choose from.  This is then saved for 
future runs.  The $VolType is not required.

.OUTPUTS

The script produces two outputs.  A timeline.txt file which contains the output from the volatility plugins
in body format and the timeline.txt converted to csv format.

.EXAMPLE

PS D:\> .\VolTimeline.ps1 d:\image.mem
Produce a memory timeline for d:\image.mem.  If the vol.ps1 script has been run the the image type from that
run is used otherwise the imageinfo plugin is run against the image.  The image type is saved for future use.

.EXAMPLE

PS D:\> .\VolTimeline.ps1 d:\image.mem WinXPsp2
Produce a memory timeline for d:\image.mem using the type of WinXPSP2.  The image type is saved for future use.

.NOTES

 Author: Tom Willett 
 Date: 11/27/2014

.LINK

vol.ps1
mactime.ps1

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$image,
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelinebyPropertyName=$true)][string]$TZ,
	[Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$volType="")

process {
	#commands to run with just text output
	$VolOptions = @("timeliner","shellbags","mftparser")

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
		write-host "Voltype = $volType  Path = $VolOut"
		if ($volType.length -eq 0) {
			# Get possible image type
			write-host "Determining Image Type for image: $image"
			$volimage = .\volatility.exe --cache-directory=$Cachepath --cache imageinfo -f $image --tz=$TZ
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
		$VolOut = $path + "ImageType.txt"
		Set-Content -Path $VolOut -Value $volType
		write-host "Image type being used: $volType"
		$VolCSV = $path + "$imageName-Timeline.csv"
		$VolOut = $path + "$imageName-Timeline.txt"
		if (test-path $VolOut) {
			write-host "Timeline Already run -- skipping"
		} else {
			echo "" > $VolOut
			foreach($command in $VolOptions) {
				write-host "Running $command command now.  Writing output to $VolOut"
				.\volatility.exe --cache-directory=$Cachepath --cache  $command -f $image --profile $volType --output=body >> $VolOut
			}
			import-csv -path $VolOut -delimiter "|" -header 'MD5','name','inode','mode_as_string','UID','GID','size','atime','mtime','ctime','crtime' | .\mactime.ps1 | Export-Csv -notypeinformation $VolCSV
		}
	} else {
		"Image $image not found"
	}
}
