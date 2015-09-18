<#

.SYNOPSIS

Reads all the users from the current domain and returns information about them

.DESCRIPTION

This reads all the users from the current domain and returns name, scriptpath, 
pwdlastset, lastlogontimestamp, memberof, whencreated, lastlogon, homedirectory, 
samaccountname, and mail.  It uses .net routines not the AD extensions.

LastLogonTimestamp is more accurate than lastlogon.

This only returns a small portion of the properties available.  At least the following
properties are available: givenname, codepage, objectcategory, scriptpath, dscorepropagationdata, 
adspath, usnchanged, instancetype, homedrive, logoncount, mailnickname, name, pwdlastset, 
objectclass, samaccounttype, lastlogontimestamp, usncreated, sn, proxyaddresses, msexchversion, 
objectguid, memberof, whencreated, homemta, mdbusedefaults, useraccountcontrol, cn, countrycode, 
primarygroupid, whenchanged, legacyexchangedn, lockouttime, lastlogon, showinaddressbook, 
distinguishedname, protocolsettings, admincount, homedirectory, samaccountname, objectsid, 
mail, displayname, homemdb, accountexpires, userprincipalname. Exchange also adds a lot of properties. 


.EXAMPLE

 .\get-linuxFileInfo.ps1 G:\ | .\convert-linuxfileinfo-to-timeline.ps1 | export-csv -notype files.csv

Retrieves the information about the files on the mounted linux file system at g: converts it to timeline format and exports to files.csv
 
.NOTES

Author: Tom Willett 
Date: 2/13/2012
© 2012 Oink Software

#>

$strCategory = "user"

$objDomain = New-Object System.DirectoryServices.DirectoryEntry
 
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.Filter = "(objectCategory=$strCategory)"
$objSearcher.PageSize = 1000
$colResults = $objSearcher.FindAll()
$ErrorActionPreference = "SilentlyContinue"
$objUsers = @()
foreach ($objResult in $colResults)
	{
		$temp = "" | Select name, scriptpath, pwdlastset, lastlogontimestamp, memberof, whencreated, lastlogon, homedirectory, samaccountname, mail
		$temp.name = $objResult.properties.name
		$temp.scriptpath = $objResult.properties.scriptpath
		$temp.pwdlastset = [datetime]::fromfiletime($objResult.properties.pwdlastset[0])
		$temp.lastlogontimestamp = [datetime]::fromfiletime($objResult.properties.lastlogontimestamp[0])
		$temp.memberof = $objResult.properties.memberof
		$temp.whencreated = $objResult.properties.whencreated
		$temp.lastlogon = [datetime]::fromfiletime($objResult.properties.lastlogon[0])
		$temp.homedirectory = $objResult.properties.homedirectory
		$temp.samaccountname = $objResult.properties.samaccountname
		$temp.mail = $objResult.properties.mail
		$objUsers += $temp
	}
$objUsers