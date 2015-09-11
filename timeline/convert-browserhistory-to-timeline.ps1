<#

.SYNOPSIS

Takes the csv output from Nirsoft's browsinghistoryview and converts it to timeline format.

.DESCRIPTION

Takes the output from Nirsoft's browsinghistoryview and converts it to the following timeline format:
DateTime,MACB,User,Machine,SHA1,ShortEvent,Event,LogSource,LogSourceType,Inode,Notes

.PARAMETER URL

.PARAMETER Title

.PARAMETER {Visit Time}

.PARAMETER {Visit Count}

.PARAMETER {Visited From}

.PARAMETER {Web Browser}

.PARAMETER {User Profile}

.PARAMETER $Machine

 Required can be entered on commandline.


.EXAMPLE

 import-csv .\bhistory.csv | convert-browserhistory-to-timeline.ps1 | export-csv -notypeinformation logs.csv -append

 Gets browser history from bhistory.csv and converts it to my timeline format and appends it to logs.csv
 
.NOTES

Author: Tom Willett 
Date: 2/26/2015
© 2015 Oink Software

#>

#DateTime,MACB,User,Machine,SHA1,ShortEvent,Event,LogSource,LogSourceType,Inode,Notes
Param([Parameter(Mandatory=$True,ValueFromPipeline=$True)][string]$URL,
	[Parameter(Mandatory=$True,ValueFromPipeline=$True)][string]$Title,
	[Parameter(Mandatory=$True,ValueFromPipeline=$True)][string]${Visit Time},
	[Parameter(Mandatory=$True,ValueFromPipeline=$True)][string]${Visit Count},
	[Parameter(Mandatory=$True,ValueFromPipeline=$True)][string]${Visited From},
	[Parameter(Mandatory=$True,ValueFromPipeline=$True)][string]${Web Browser},
	[Parameter(Mandatory=$True,ValueFromPipeline=$True)][string]${User Profile},
	[Parameter(Mandatory=$True,ValueFromPipeline=$False)][string]$Machine)
process {
	$tmp = "" | Select DateTime,MACB,User,Machine,SHA1,ShortEvent,Event,LogSource,LogSourceType,Inode,Notes
	$tmp.DateTime = $_.{Visit Time}
	$tmp.User = $_.{User Profile}
	$tmp.MACB = "B"
	$tmp.Machine = $Machine
	$tmp.ShortEvent = $_.URL
	$tmp.Event = $_.URL + " - Visits: " + $_.{Visit Count} + "- Browser: " + $_.{Web Browser} + " - Title: " + $_.Title
	$tmp.LogSource = "Browser History"
	$tmp.LogSourceType = $_.{Web Browser}
	write-output $tmp
}