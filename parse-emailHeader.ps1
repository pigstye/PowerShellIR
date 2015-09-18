<#

.SYNOPSIS

Parse Email Headers

.DESCRIPTION

This script parses email headers and returns them in csv format.
Date headers are converted to UTC -- Headers are reversed so oldest is first and numbered.

.PARAMETER $headerFile

The $headerFile paramater is required

.EXAMPLE

 .\parse-emailHeader.ps1 .\headers.txt

 Parses the headers in .\headers.txt and outputs them in object format
 
.EXAMPLE

 .\parse-emailHeader.ps1 .\headers.txt | export-csv -notypeinformation emailheaders.csv

 Parses headers and exports them to emailheaders.csv in csv format
 
.EXAMPLE

type headers.txt | .\parse-emailHeader.ps1 | export-csv -notypeinformation emailheaders.csv

Parses the list of header files in headers.txt (format one file per line) and exports them
to emailheaders.csv

.NOTES

Author: Tom Willett 
Date: 11/8/2014
© 2014 Oink Software

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$headerFile)

begin {
	$report = @()
}

process {
	function ParseDate {
		Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$dt)
		# Parse date and convert to utc
		$rawDate = $dt.Split(" ")
		$offset = [double]$rawDate[5].substring(0,3)
		$emailDate =[datetime]::parseexact($rawDate[1] + " " + $rawDate[2] + " " + $rawDate[3] + " " + $rawDate[4],"d MMM yyyy HH:mm:ss",$null)
		$emailDate = $emailDate.addhours($offset)
		return $emailDate.tostring()
	}
	$rawHeader = get-content $headerFile
	$from = ""
	$emailDate = ""
	$to = ""
	$subject = ""
	for ($i=0;$i -lt $rawHeader.length;$i++) {
		if ($rawHeader[$i].startswith("To:")) { $to = $rawHeader[$i].remove(0,3).trim().replace("<","").replace(">","") }
		if ($rawHeader[$i].startswith("Date:")) { $emailDate = ParseDate($rawHeader[$i].remove(0,5).trim()) }
		if ($rawheader[$i].startswith("Subject:")) { $subject = $rawHeader[$i].remove(0,8).trim() }
		if ($rawheader[$i].startswith("From:")) { $from = $rawHeader[$i].remove(0,5).trim() }
	}
	# now put them in the right order and parse out the headers	
	$tmp = ""
	$j = 1
	for ($i = $rawHeader.length; $i -gt 0; $i--) {
		if ($rawHeader[$i].length -gt 0) {
			$header = "" | select emailDate,Sequence,From,To,Subject,HeaderType,Body
			# continuation lines
			if (($rawHeader[$i].startswith(" ")) -or ($rawHeader[$i].startswith("`t"))) {
				$tmp = $tmp + " " + $rawHeader[$i].trim()
			} else {
				$header.emailDate = $emailDate
				$header.Sequence = $j
				$j++
				$header.From = $from
				$header.To = $to
				$header.Subject = $subject
				$header.HeaderType = $rawHeader[$i].substring(0,$rawHeader[$i].indexof(":"))
				$header.Body = $rawHeader[$i].substring($rawHeader[$i].indexof(":") + 1).trim()
				if (($header.HeaderType.endswith("Date")) -or ($header.HeaderType.endswith("date"))) { $header.Body = parseDate($header.Body) }
				$header.Body = $header.Body + " " + $tmp
				$tmp = ""
				$report += $header
			}
		}
	}
}

end {
	$report
}