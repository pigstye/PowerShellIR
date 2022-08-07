<#

.SYNOPSIS

Xor two strings

.DESCRIPTION

Xor two strings

.PARAMETER $InString

String to convert (required)

.PARAMETER $XorKey

String to xor with

.EXAMPLE     
    .\convert-xor.ps1 "asdfasdf" "sdf"
    Xors "asdfasdf" "sdf"  the second string is repeated as needed

.NOTES
	
 Author: Tom Willett
 Date: 11/13/2014

#>

Param([Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string[]]$InString, [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)][string[]]$XorKey)

begin {
	$NewString = ""
}
process {
	$xorLength = $XorKey.length
	$ctr = 0
	Foreach($Char in $InString.ToCharArray())
	{
		$NewString += $char -bxor $XorKey[$ctr]
		$ctr++
		if ($ctr -eq $xorLength) { $ctr = 0 }
	} 
}
end {
	$newString
}
