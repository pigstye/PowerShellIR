<#

.SYNOPSIS

Run common volatility commands on a memory image

.DESCRIPTION

The following commands are run against a memory image: linux_pslist, linux_psaux, linux_pstree, linux_pslist_cache, 
linux_pidhashtable, linux_psxview, linux_lsof, linux_memmap, linux_proc_maps, linux_bash, linux_lsmod, 
linux_check_afinfo, linux_check_tty, linux_keyboard_notifier, linux_check_creds, linux_check_fop, 
linux_check_idt, linux_check_syscall, linux_check_modules, linux_check_creds, Networking, linux_arp, 
linux_ifconfig, linux_route_cache, linux_netstat, linux_pkt_queues, linux_sk_buff_cache, linux_mount, 
linux_tmpfs, linux_moddump and strings.

A directory is created in the same directory that the image file is in called "VolatilityOutput" where the 
output of all the commands is placed.  If the command extracts images from memory (linux_moddump) the images 
are put in a directory under VolatilityOutput-(ImageName) named after the command.  

It is assumed that you have a profile for the Linux type and have placed it in a directory under the current
directory called "profiles".  Thus if you have the script in c:\powershell\you would put your profiles in 
c:\powershell\profiles.  See https://code.google.com/p/volatility/wiki/LinuxMemoryForensics for information
about profiles.

If you cancel the process by ^c you can restart it and the scan will pick up where it left off.  Or if there is 
one command that is taking longer than you would like, you can cancel it by hitting ^c once and the script will
start with the next command in the list.

.PARAMETER image

Image file to run volatility on. (required)

.PARAMETER volimage

Image type to use required

.EXAMPLE     
    .\vollinux.ps1 c:\image.mem LinuxUbuntu1204x64
    Runs the script against c:\images\image.mem and uses LinuxUbuntu1204x64 as the image type.  
	It puts the output in c:\images\VolatilityOutput-image.mem

.EXAMPLE     
    input-csv .\images.csv |.\vollinux.ps1
	Takes input from .\images.csv in the format image,volimage and feeds it to the .\vollinux.ps1 script one at a time.  
    It puts the output in a directory starting with VolatilityOutput in the directory where each image is located.

.NOTES
	
 Author: Tom Willett
 Date: 2/22/2015
 © 2015 Oink Software

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$image,[Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$volType="")

process {
	#commands to run with just text output
	$VolOptions = @("linux_pslist", "linux_psaux", "linux_pstree", "linux_pslist_cache", "linux_pidhashtable", "linux_psxview", "linux_lsof", "linux_proc_maps", "linux_bash", "linux_lsmod", "linux_check_afinfo", "linux_check_tty", "linux_keyboard_notifier", "linux_check_creds", "linux_check_fop", "linux_check_idt", "linux_check_syscall", "linux_check_modules", "linux_check_creds", "Networking", "linux_arp", "linux_ifconfig", "linux_route_cache", "linux_netstat", "linux_pkt_queues", "linux_sk_buff_cache", "linux_mount", "linux_tmpfs -L", "linux_memmap")
	#commands to run which dump from memory
	$VolDump = @("linux_moddump")

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
			write-host "You must provide the image type"
			exit
		}
		Set-Content -Path $VolOut -Value $volType
		write-host "Image type being used: $volType"
		foreach($command in $VolOptions) {
			$VolOut = $path + "$imageName-$command.txt"
			if (test-path $VolOut) {
				write-host "$command already run -- skipping"
			} else {
				write-host "Running $command command now.  Writing output to $VolOut"
				.\volatility.exe --plugins=profiles --cache-directory=$Cachepath --cache  $command -f $image --profile $volType > $VolOut
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
				.\volatility.exe --plugins=profiles --cache-directory=$Cachepath --cache  $command -f $image --profile $volType --dump-dir=$VolDir > $VolOut
				$FNS = get-childitem $VolDir
				foreach ($FN in $FNS) {
					write-host "Running stings on $FN.Fullname"
					$VolOut1 = $FN.FullName + "-Strings.txt"
					strings -o -n 6 $FN.FullName > $VolOut1
				}
			}
		}
		$VolOut = $path + "$imageName-strings.txt"
		if (test-path $VolOut) {
			write-host "Strings already run -- skipping"
		} else {
			write-host "Running Strings on the memory image writing output to $VolOut"
			strings -o -n 6 $image > $VolOut
			.\split.ps1 $VolOut
		}
	} else {
		"Image $image not found"
	}
}
