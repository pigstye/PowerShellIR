<#

.SYNOPSIS

Disable USB Write Blocking

.DESCRIPTION

This disables USB write blocking by setting the registry key 
HKLM\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies\WriteProtect

This only works if the usb device is not connected.  If it is connected the
current state will continue.  You may have to reboot to renable usb writes.

.EXAMPLE

 .\disable-usbwriteblock.ps1

 disables usb write blocking.
 
.NOTES

Author: Tom Willett 
Date: 9/22/2015
© 2015 Oink Software

#>

$key = "HKLM\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies"
reg add $key /v WriteProtect /t REG_DWORD /d 00000000 /f
