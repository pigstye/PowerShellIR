<#

.SYNOPSIS     
    Converts a date/time from one timezone to another   
     
.DESCRIPTION   
    This uses the built in .net routines to convert a date/time from one timezone to another.
	You can use the companion script list-timezones.ps1 to list the timezone names on your computer.
      
.PARAMETER DT   
    The date/time to convert

.PARAMETER ToTImeZone
	The timezone to convert to

.PARAMETER FromTimeZone
	The timezone the DT is in currently
	
.NOTES     
	Author: Tom Willett
	Date: 8/28/2014

.EXAMPLE     
    .\convert-time.ps1 "2/2/2014 12:31" "Eastern Standard Time" "Alaska Standard TIme"
	Converts "2/2/2014 12:31" from Eastern Standard Time to Alaska Standard TIme

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$DT,
      [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$ToTimeZone,
	  [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$FromTimeZone)
process {
	$FromTZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($FromTimeZone)
	$ToTZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($ToTImeZone)
	$UTC = [System.TimeZoneInfo]::ConvertTimeToUtc($DT, $FromTZ)
	$tm = [System.TimeZoneInfo]::ConvertTimeFromUtc($utc, $ToTZ)
	write-output $tm
}