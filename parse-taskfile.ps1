<#
 
.SYNOPSIS
 
Parse Windows Task Files on Windows 7 and newer machines with xml task files
 
.DESCRIPTION

Parse Windows Task Files on Windows 7 and newer machines with xml task files found at 
c:\windows\system32\tasks.  See parse-jobfile.ps1 for the older job files found at 
c:\windows\tasks.


.EXAMPLE
 
.\parse-taskfile.ps1 c:\windows\system32\tasks\GoogleUpdateTaskMachineCore

Parses the contents of c:\windows\system32\tasks\GoogleUpdateTaskMachineCore and displays it on the console.
 
.NOTES

Author: Tom Willett 
Date: 3/24/2015
© 2015 Oink Software

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$fullname)

process {
	[xml]$x = get-content $fullname
	$tmp = "" | Select TaskName, Description, Action
	$tmp.TaskName = (get-childitem $fullname).name
	$tmp.Description = $x.task.RegistrationInfo.Description
	$x.task.actions | gm -membertype property | foreach {
		if  ($_.name -ne "Context") {
			$task = $_.name
			$x.task.actions.$task | gm -membertype property | foreach {
				$n = $_.name
				$tmp.action += $n + " => " + $x.task.actions.$task.$n + " "
			}
		}
	}
	#$tmp.Action = $x.task.actions.exec.command + " " + $x.task.actions.exec.arguments
	write-output $tmp
}