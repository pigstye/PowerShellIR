Function ConvertTo-BinaryIP {  
	<#    
		.Synopsis      
			Converts a Decimal IP address into a binary format.    
		.Description      
			ConvertTo-BinaryIP uses System.Convert to switch between decimal and binary format. The output from this function is dotted binary.    
		.Parameter IPAddress      
			An IP Address to convert.  
	#>   
	
	[CmdLetBinding()]  
	Param(    
		[Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]    
		[Net.IPAddress]$IPAddress  
	)   
	
	Process {    
		Return [String]::Join('.', $( $IPAddress.GetAddressBytes() | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') } ))  
	}
}

Function get-IP2Long {  
	<#    
		.Synopsis      
			Converts a Decimal IP address into a 32-bit unsigned integer.    
		.Description      
			get-IP2Long takes a decimal IP, uses a shift-like operation on each octet and returns a single UInt32 value.    
		.Parameter IPAddress      
			An IP Address to convert.  
	#>   
	
	[CmdLetBinding()]  
	Param(    
		[Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]    
		[Net.IPAddress]$IPAddress  
	)   
	Process {    
		$i = 3; $DecimalIP = 0;    
		$IPAddress.GetAddressBytes() | ForEach-Object { $DecimalIP += $_ * [Math]::Pow(256, $i); $i-- }     
		Return [UInt32]$DecimalIP  
	}
}

Function get-Long2IP {  
	<#    
		.Synopsis      
			Returns a dotted decimal IP address from either an unsigned 32-bit integer or a dotted binary string.    
		.Description      
			get-Long2IP uses a regular expression match on the input string to convert to an IP address.    
		.Parameter IPAddress      
			A string representation of an IP address from either UInt32 or dotted binary.  
	#>   
	[CmdLetBinding()]  
	Param(    
		[Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]    
		[String]$IPAddress  
	)   
	Process {    
		Switch -RegEx ($IPAddress) {      
			"([01]{8}\.){3}[01]{8}" {        
			Return [String]::Join('.', $( $IPAddress.Split('.') | ForEach-Object { [Convert]::ToUInt32($_, 2) } ))      
		}      
		"\d" {        
			$IPAddress = [UInt32]$IPAddress        
			$DottedIP = $( For ($i = 3; $i -gt -1; $i--) {          
				$Remainder = $IPAddress % [Math]::Pow(256, $i)          
				($IPAddress - $Remainder) / [Math]::Pow(256, $i)          
				$IPAddress = $Remainder         
			} )         
			Return [String]::Join('.', $DottedIP)      
		}      
		default {        
			Write-Error "Cannot convert this format"      
		}    
		}  
	}
}

Function get-Mask2Cidr {  
	<#    
		.Synopsis      
			Returns the length of a subnet mask.    
		.Description      
			get-Mask2Cidr accepts any IPv4 address as input, however the output value      
			only makes sense when using a subnet mask.    
		.Parameter SubnetMask      
			A subnet mask to convert into length  
	#>   
	[CmdLetBinding()]  
	Param(    
		[Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]    
		[Alias("Mask")]    
		[Net.IPAddress]$SubnetMask  
	)   
	Process {    
		$Bits = "$( $SubnetMask.GetAddressBytes() | ForEach-Object { [Convert]::ToString($_, 2) } )" -Replace '[\s0]'     
		Return $Bits.Length  
	}
}

Function get-CIDR2Mask {  
	<#    
		.Synopsis      
			Returns a dotted decimal subnet mask from a mask length.    
		.Description      
			get-CIDR2Mask returns a subnet mask in dotted decimal format from an integer value ranging      
			between 0 and 32. get-CIDR2Mask first creates a binary string from the length, converts      
			that to an unsigned 32-bit integer then calls get-Long2IP to complete the operation.    
		.Parameter MaskLength      
			The number of bits which must be masked.  
	#>   
	[CmdLetBinding()]  
	Param(    
		[Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]    
		[Alias("Length")]    
		[ValidateRange(0, 32)]    
		$MaskLength  
	)   
	Process {    
		Return get-Long2IP ([Convert]::ToUInt32($(("1" * $MaskLength).PadRight(32, "0")), 2))  
	}
}

Function get-Network {  
	<#    
		.Synopsis      
			Takes an IP address and subnet mask then calculates the network address for the range.    
		.Description      
			get-Network returns the network address for a subnet by performing a bitwise AND      
			operation against the decimal forms of the IP address and subnet mask. get-Network      
			expects both the IP address and subnet mask in dotted decimal format.    
		.Parameter IPAddress      
			Any IP address within the network range.    
		.Parameter SubnetMask      
			The subnet mask for the network.  
	#>   
	[CmdLetBinding()]  
	Param(    
		[Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]    
		[String]$IPAddr,     
		
		[Parameter(Mandatory = $False, Position = 1)]    
		[Alias("Mask")]    
		[Net.IPAddress]$SubnetMask  
	)   
	Process {  	
		if ($IPAddr.Contains("/")) {
			$temp = $IPAddr.Split("/")
			[Net.IPAddress]$IPAddr=$temp[0]
			[Net.IPAddress]$SubnetMask=get-CIDR2Mask $temp[1]
		}
  		Return get-Long2IP ((get-IP2Long $IPAddr) -BAnd (get-IP2Long $SubnetMask))  
	}
}

Function get-Broadcast {
  <#
    .Synopsis
      Takes an IP address and subnet mask then calculates the broadcast address for the range.
    .Description
      get-Broadcast returns the broadcast address for a subnet by performing a bitwise AND
      operation against the decimal forms of the IP address and inverted subnet mask.
      get-Broadcast expects both the IP address and subnet mask in dotted decimal format.
    .Parameter IPAddress
      Any IP address within the network range. Will also take cidr notation.
    .Parameter SubnetMask
      The subnet mask for the network.
  #>
 
  [CmdLetBinding()]
  Param(
    [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
    [String]$IPAddress, 
 
    [Parameter(Mandatory = $False, Position = 1)]
    [Alias("Mask")]
    [Net.IPAddress]$SubnetMask
  )
 
  Process {
	if ($IPAddress.Contains("/")) {
		$temp = $IPAddress.Split("/")
		[Net.IPAddress]$IPAddress=$temp[0]
		[Net.IPAddress]$SubnetMask=get-CIDR2Mask $temp[1]
	}
    Return get-Long2IP $((get-IP2Long $IPAddress) -BOr `
      ((-BNot (get-IP2Long $SubnetMask)) -BAnd [UInt32]::MaxValue))
  }
}

Function Get-NetworkSummary ( [String]$IP, [String]$Mask ) {  
	If ($IP.Contains("/"))  
	{    
		$Temp = $IP.Split("/")    
		$IP = $Temp[0]    
		$Mask = $Temp[1]  
	}   
	If (!$Mask.Contains("."))  {    
		$Mask = get-CIDR2Mask $Mask  
	}   
	$DecimalIP = get-IP2Long $IP  
	$DecimalMask = get-IP2Long $Mask   
	$Network = $DecimalIP -BAnd $DecimalMask  
	$Broadcast = $DecimalIP -BOr ((-BNot $DecimalMask) -BAnd [UInt32]::MaxValue)  
	$NetworkAddress = get-Long2IP $Network  
	$RangeStart = get-Long2IP ($Network + 1)  
	$RangeEnd = get-Long2IP ($Broadcast - 1)  
	$BroadcastAddress = get-Long2IP $Broadcast  
	$MaskLength = get-Mask2Cidr $Mask   
	$BinaryIP = ConvertTo-BinaryIP $IP; $Private = $False  
	Switch -RegEx ($BinaryIP)  
	{    
		"^1111"  { $Class = "E"; $SubnetBitMap = "1111" }    
		"^1110"  { $Class = "D"; $SubnetBitMap = "1110" }    
		"^110"   {      
			$Class = "C"      
			If ($BinaryIP -Match "^11000000.10101000") { $Private = $True } 
		}    
		"^10"    {      
			$Class = "B"      
			If ($BinaryIP -Match "^10101100.0001") { $Private = $True } 
		}    
		"^0"     {      
			$Class = "A"      
			If ($BinaryIP -Match "^00001010") { $Private = $True } 
		}   
	}      
	$NetInfo = New-Object Object  
	Add-Member NoteProperty "Network" -Input $NetInfo -Value $NetworkAddress  
	Add-Member NoteProperty "Broadcast" -Input $NetInfo -Value $BroadcastAddress  
	Add-Member NoteProperty "Range" -Input $NetInfo -Value "$RangeStart - $RangeEnd"  
	Add-Member NoteProperty "Mask" -Input $NetInfo -Value $Mask  
	Add-Member NoteProperty "MaskLength" -Input $NetInfo -Value $MaskLength  
	Add-Member NoteProperty "Hosts" -Input $NetInfo -Value $($Broadcast - $Network - 1)  
	Add-Member NoteProperty "Class" -Input $NetInfo -Value $Class  
	Add-Member NoteProperty "IsPrivate" -Input $NetInfo -Value $Private   
	Return $NetInfo
}

Function Get-NetworkRange( [String]$IP, [String]$Mask ) {  
	If ($IP.Contains("/"))  {    
		$Temp = $IP.Split("/")    
		$IP = $Temp[0]    
		$Mask = $Temp[1]  
	}   
	If (!$Mask.Contains("."))  {    
		$Mask = get-CIDR2Mask $Mask  
	}   
	$DecimalIP = get-IP2Long $IP  
	$DecimalMask = get-IP2Long $Mask   
	$Network = $DecimalIP -BAnd $DecimalMask  
	$Broadcast = $DecimalIP -BOr ((-BNot $DecimalMask) -BAnd [UInt32]::MaxValue)   
	For ($i = $($Network + 1); $i -lt $Broadcast; $i++) {    
		get-Long2IP $i  
	}
}

Function Get-NumIPS ($strNetwork){
	$StrNetworkAddress = ($strNetwork.split("/"))[0]
	[int]$NetworkLength = ($strNetwork.split("/"))[1]
	$IPLength = 32-$NetworkLength
	$NumberOfIPs = ([System.Math]::Pow(2, $IPLength))
	Return $NumberofIPs
}


function get-ping($ipAddr) {
	$ping = New-Object System.Net.NetworkInformation.Ping
	return $ping.send($ipAddr,3000)
}

function get-nslookup ($ipAddr) {
	return [System.Net.Dns]::GetHostEntry($ipAddr)
}

function get-OS ($ipAddr) {
	$objWMI = Get-WmiObject Win32_OperatingSystem -computer $ipAddr
	return $objWMI.Caption
}