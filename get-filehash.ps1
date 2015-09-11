<#
 
.SYNOPSIS
 
Get the hash of an input file.

.DESCRIPTION
 Using the built in cryptographic routines in .net the hash of a file is returned.
 By default the SHA1 is returned but you can specify "MD5", "SHA1", "SHA256", "SHA384", "SHA512"
 
.EXAMPLE
 
.\Get-FileHash.ps1 .\myFile.txt
Gets the hash of a specific file
 
.EXAMPLE
 
dir | .\Get-FileHash.ps1
Gets the hash of all files in current directory
 
.EXAMPLE
 
dir -recurse | .\Get-FileHash.ps1 -algorithm sha256
Gets the sha256 hash of all files in current diretory and subdirectories 
 
.EXAMPLE
 
.\Get-FileHash.ps1 myFile.txt -Hash SHA256
Gets the hash of myFile.txt, using the SHA256 hashing algorithm
 
 .NOTES

Author: Tom Willett 
Date: 1/5/2015
© 2014 Oink Software

#>
 
param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]$Path,
	[Parameter(Mandatory=$False,ValueFromPipeline=$false,ValueFromPipelinebyPropertyName=$false)][ValidateSet("MD5", "SHA1", "SHA256", "SHA384", "SHA512")][string]$Algorithm = "SHA1"
)
 
begin {
	$hashType = [Type] "System.Security.Cryptography.$Algorithm"
	$hasher = $hashType::Create()
}

Process {
	if ($path.gettype().name -eq "FileInfo") {
		$file = $path.fullname
	} else {
		$file = (Resolve-Path $path).Path
	}
	If(!((get-item $file).PSIsContainer)) {
	$inputStream = New-Object IO.StreamReader $file
	$hashBytes = $hasher.ComputeHash($inputStream.BaseStream)
	$inputStream.Close()
 
	## Convert the result to hexadecimal
	$builder = New-Object System.Text.StringBuilder
	$hashBytes | Foreach-Object { [void] $builder.Append($_.ToString("X2")) }
 
	$output = "" | Select ($Algorithm), File
	$output.file = $file
	$output.($Algorithm) = $builder.ToString()
	 
	$output
	}
}
