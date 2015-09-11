<#

.SYNOPSIS     
    Retrieves the Time Zones on your computer and displays them in a Grid View.
     
.DESCRIPTION   
    This uses the built in .net routines to display the timezones on your computer.
	It outputs it in GridView
      
	
.NOTES     
	Author: Tom Willett
	Date: 8/28/2014
	© 2014 Oink Software

.EXAMPLE     
    .\list-timezones.ps1
	Lists the timezones on your computer.

#>

[system.timezoneinfo]::getsystemtimezones() | out-gridview