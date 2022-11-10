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
      if ($octet -lt 0 -or $octet -gt 255) { 
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

  # create an array of ip addresses between start and end

  # Convert IP addresses to integer
  $startIP = [System.Net.IPAddress]::Parse($Start).Address
  $endIP = [System.Net.IPAddress]::Parse($End).Address

  # convert ip addresses to byte array
  $startIP = [System.BitConverter]::GetBytes($startIP)



  # Loop through each IP address between start and end
  $ipRange = @()
  for ($i = $startIP; $i -le $endIP; $i++) {
    $ipRange += [System.Net.IPAddress]($i).ToString()
  }

  return $ipRange
}
