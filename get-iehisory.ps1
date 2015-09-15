<#

.SYNOPSIS

Get IE history from local computer.

.DESCRIPTION

This retrieves the IE history from the local computer by retrieving it from the Shell NameSpace

.EXAMPLE     
    .\get-iehistory.ps1
	
    Returns the IE History

.NOTES
	
 Author: Tom Willett
 Date: 3/27/2015
 © 2015 Oink Software

#>

function get-iehistory {            
[CmdletBinding()]            
param ()            
            
$shell = New-Object -ComObject Shell.Application            
$hist = $shell.NameSpace(34)            
$folder = $hist.Self            
            
$hist.Items() |             
foreach {            
 if ($_.IsFolder) {            
   $siteFolder = $_.GetFolder            
   $siteFolder.Items() |             
   foreach {            
     $site = $_            
             
     if ($site.IsFolder) {            
        $pageFolder  = $site.GetFolder            
        $pageFolder.Items() |             
        foreach {            
           $visit = New-Object -TypeName PSObject -Property @{            
               Site = $($site.Name)            
               URL = $($pageFolder.GetDetailsOf($_,0))            
               Date = $( $pageFolder.GetDetailsOf($_,2))            
           }            
           $visit            
        }            
     }            
   }            
 }            
}            
}
get-iehistory
