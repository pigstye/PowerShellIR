<#

.SYNOPSIS

Enable USB Write Blocking

.DESCRIPTION

This enables USB write blocking by setting the registry key 
HKLM\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies\WriteProtect

This only works if the usb device is not connected.  If it is connected the
current state will continue.

.EXAMPLE

 .\enable-usbwriteblock.ps1

 enables usb write blocking.
 
.NOTES

Author: Tom Willett 
Date: 9/22/2015
© 2015 Oink Software

#>

$key = "HKLM\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies"
reg add $key /v WriteProtect /t REG_DWORD /d 00000001 /f
