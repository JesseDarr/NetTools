function Validate-IPAddress {
<#
.SYNOPSIS
    Returns true if the given string is a valid IP address, else returns $null
.EXAMPLE
    Validate-IPAddress -IP 192.168.1.1
#>
  param(
    [Parameter(Mandatory=$true, Position=0)][String]$IP
  )

  # Regex to validate IP address
  $regex = "^([0-9]{1,3}\.){3}[0-9]{1,3}$"

  # Test if IP matches regex
  if ($IP -match $regex) {
    # Split into octets
    $octets = $IP.Split(".")

    # Test if each octet is between 0 and 255
    foreach ($octet in $octets) {
      if ([int]$octet -lt 0 -or [int]$octet -gt 255) { 
        Write-Error "Octet $octet is not between 0 and 255"
        return $null 
      }
    }

    return $true # If we made it here, we have a valid IP address
  } else { 
    Write-Error "Invalid IP address: $IP"
    return $null 
  }
}

function Validate-IPRange {
<#
.SYNOPSIS
    Returns true if the given start IP address is less than the given end IP address, else returns $null
.EXAMPLE
    Validate-IPRange -Start 192.168.0.1 -End 192.168.100.1
#>
  param(
    [Parameter(Mandatory=$true, Position=0)][String]$Start,
    [Parameter(Mandatory=$true, Position=1)][String]$End
  )

  # Split into Octets
  $sOcts = $Start.Split(".")
  $eOcts = $End.Split(".")

  # Test at least one octest in eOcts is larger than the corresponding octet in sOcts
  for ($i = 0; $i -lt 4; $i++) {
    if ($sOcts[$i] -lt $eOcts[$i]) { return $true }
  }

  Write-Error "Start IP address is greater than end IP address"
  return $null
}

function Get-IPRange {
<#
.SYNOPSIS
    Returns an array of all IP addresses between the given start and end IP addresses, else returns $null
.EXAMPLE
    Get-IPRange -Start 192.168.2.1 -End 192.168.3.1
#>
  param(
    [Parameter(Mandatory=$true, Position=0)][String]$Start,
    [Parameter(Mandatory=$true, Position=1)][String]$End
  )
  
  # Split into Octets
  $sOcts = $Start.Split(".")
  $eOcts = $End.Split(".")
  
  # Reverse the Octets
  [array]::Reverse($sOcts)
  [array]::Reverse($eOcts)
  
  # Convert Octets to Integer Values
  $sInt = [bitconverter]::ToUInt32([byte[]]$sOcts,0)
  $eInt = [bitconverter]::ToUInt32([byte[]]$eOcts,0)
  
  # Loop through the range of integers, convert into octets, reverse them, join them, and add them to ipRange
  $ipRange = [System.Collections.ArrayList]@() # Arraylist b/c it's super fast
  for ($ip = $sInt; $ip -le $eInt; $ip++)
  {   
      $cOcts = [bitconverter]::getbytes($ip) # Convert Integer to Octets - these are in reverse order
      [array]::Reverse($cOcts)               # Reverse the Octets
      $null = $ipRange.Add($cOcts -join ".") # Join into String and add to ipRange - $null avoids output that would otherwise be returned
  }

  return $ipRange
}

function Scan-IPRange {
<#
.SYNOPSIS
    Returns a hastable of all IP addresses that ping within a given range, else reutnrs $null.

    Count defaults to 1 if not specified.
.EXAMPLE
    Scan-IPRange -Start 192.168.100.1 -End 192.168.100.150
.EXAMPLE
    Scan-IPRange -Start 192.168.100.1 -End 192.168.100.150 -Count 4
#>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true,  Position=0)][String]$Start,
    [Parameter(Mandatory=$true,  Position=1)][String]$End,
    [Parameter(Mandatory=$false, Position=2)][Int16]$Count
  )

  # Set count if not specified
  if($Count -eq 0) { $Count = 1 }
  # Write error and return null if count greater than 10
  if($Count -gt 10) {
    Write-Error "Count must not be greater than 10"
    return $null
  }

  # Validate Addresses
  if (!(Validate-IPAddress -IP $Start)) { return $null }
  if (!(Validate-IPAddress -IP $End))   { return $null }

  # Validate Range
  if (!(Validate-IPRange -Start $Start -End $End)) { return $null }

  # Get IP Range
  $ipAddresses = Get-IPRange -Start $Start -End $End

  # Loop through IP Range, ping each IP, and add to results
  $results = $ipAddresses | ForEach-Object -Parallel {
    $ip = $_
    # Test connection for IP
    $count = $using:Count # get access to count
    $ping = Test-Connection -Count $count -Quiet $ip
  
    # Build result hash table and add to results
    $result = @{} | Select-Object Address, Pings
    $result.Address = $ip
    $result.Pings   = $ping
    return $result
  
  } -ThrottleLimit 254
    
  return ($results | Where-Object { $_.Pings -eq $true } )
}
#Export-ModuleMember -Function Scan-IPRange

function Scan-Ports {
<#
.SYNOPSIS
    Returns a hastable of all ports that are open on a given IP address or hostname, else returns null
.EXAMPLE
    Scan-Ports -IP 192.168.0.100
#>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true, Position=0)][String]$IP
  )
  # 1-1024 - well known
  # 1-65535 - all
  # 20-80 - range
  # verbose output flag
  # TCP or UDP or Both

  # Validate IP
  if (!(Validate-IPAddress -IP $IP)) { return $null }

  # Loop through through the ports, test connection, and add to results
  $results = 1..1024 | ForEach-Object -Parallel {
    $port = $_
    $ip   = $using:IP

    # Build result hash table
    $result = @{} | Select-Object Port, TCP, UDP
    $result.Port = $port

    # Create a new TcpClient object
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    # Try to connect to the port
    try { $tcpClient.Connect($IP, $port) } # returns null on success
    catch {}                               # and errors on failure
    # Set result.TCP and close the tcpClient
    $result.TCP = $tcpClient.Connected
    $tcpClient.Close()

    # Create a new UdpClient object
    $udpClient = New-Object System.Net.Sockets.UdpClient
    # Try to connect to the port
    try { $udpClient.Connect($IP, $port) } # returns null on success
    catch {}                               # and errors on failure
    # Set result.UDP and close the tcpClient
    $result.UDP = $tcpClient.Connected
    $tcpClient.Close()

    return $result
  } -ThrottleLimit 256

  return ($results | Where-Object { $_.TCP -eq $true -or $_.UDP -eq $true} )
  #return $results
}
#Export-ModuleMember -Function Scan-Ports

Scan-Ports -IP 192.168.20.254


# For Scan-IPRange and Scan-Ports add some kind of verbose output
# Setup progress bar for both of them

# Find something to test on to make sure UDP is working ok