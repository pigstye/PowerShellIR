<#

.SYNOPSIS

Reads and converts the output of "ipconfig /displaydns" to PowerShell objects

.DESCRIPTION

Reads and converts the output of "ipconfig /displaydns" to a series of PowerShell objects suitable to export to csv.

.EXAMPLE

ps> .\get-dnsCache.ps1

Gets dns cache from the local machine

.EXAMPLE

.\get-dnsCache.ps1 | export-csv -notype dns.csv

Gets dns cache from the local machine and exports to dns.csv

.NOTES

Author: Tom WIllett
Date: 9/11/2015
© 2015 Oink Software

#>

$dns = ipconfig /displaydns
#/\s{5}(.+):\s(\S+)/
$out = @()
$ctr = 1
foreach ($line in $dns) {
	if ($line -match '\s{4}(.+):\s(\S+)') {
		$field = ($matches[1].replace(" .","")).trim()
		if ($field -eq "Record Name") {
			$temp = "" | Select RecordName, RecordType,TypeName,TTL,DataLength,Section,Value
			$ctr = 1
		}
		switch ($ctr) {
			1 {$temp.RecordName = $matches[2]}
			2 {$temp.RecordType = $matches[2]}
			3 {$temp.TTL = $matches[2]}
			4 {$temp.DataLength = $matches[2]}
			5 {$temp.Section = $matches[2]}
			6 {$temp.Value = $matches[2]; $temp.TypeName = $field; $out += $temp}
		}
		$ctr = $ctr + 1
	}
}
$out