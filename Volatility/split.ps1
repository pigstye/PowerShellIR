<#

.SYNOPSIS

Split a file into smaller sized files

.DESCRIPTION

Split a file. This uses the .net file routines.  By default it splits it into 200mb chuncks.  You can change the size by altering the $bufSize variable.
The parts are named by adding 1 2 3 etc to the file name.

.PARAMETER inFile

The file to split (required)

.EXAMPLE     
    .\split.ps1 c:\image.mem
    Splits c:\image.mem into 200MB chuncks c:\image1.mem, c:\image2.mem, c:\image3.mem

.NOTES
	
 Author: Tom Willett
 Date: 12/15/2014

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string]$inFile)
$bufSize = 200000000
$stream = [System.IO.File]::OpenRead($inFile)
$chunkNum = 1
$barr = New-Object byte[] $bufSize
$basename = $inFile.substring(0,$inFile.lastindexof("."))
$ext = $inFile.substring($inFile.lastindexof("."))
while( $bytesRead = $stream.Read($barr,0,$bufsize)){
	$outFile = "$basename$chunkNum$ext"
	$ostream = [System.IO.File]::OpenWrite($outFile)
	$ostream.Write($barr,0,$bytesRead);
	$ostream.close();
	write-host "wrote $outFile"
	$chunkNum += 1
}

