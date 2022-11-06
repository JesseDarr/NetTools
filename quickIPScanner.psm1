function Validate-IPAddress {
<#
.SYNOPSIS
    Validates IP Address - returns $true or $null
.EXAMPLE
    Validate-IPAddress -IP 192.168.20.1
#>
  param(
    [Parameter(Mandatory=$true, Position=0)][String]$IP
  )

  $prefix = "Address is invalid:"

  # Split IP into octets
  $octs = $IP.Split(".")

  # Check if we have 4 octets
  if ($octs.Length -ne 4) {
    Write-Error "$prefix $IP does not contain 4 octets"
    return $null
  }
  
  # Check each octet for failure conditions
  foreach ($oct in $octs) {
    # Check if all characters are numbers
    if ($oct -notmatch "^\d+$") {
      Write-Error "$prefix octet $oct contains non numeric digits"
      return $null
    }

    # Check for proper length 1-3 chars long
    if ($oct.Length -gt 3 -or $oct.Length -lt 1) {
      Write-Error "$prefix octet $oct is not the correct length"
      return $null
    }

    # Check if greater than 254
    if ([int]$oct -gt 254) {
      Write-Error "$prefix octet $oct is greater than 254"
      return $null
    }
  }

  return $true # return true if we didn't fail on above checks
}

function Compare-Octets {
<#
.SYNOPSIS
    Compares octets of passed in strings - returns $true if they are the same and $null if not.

    Currently is comparing first 3 octets - this will be updated later
.EXAMPLE
    Compare-Octets -Start 192.168.100.1 -End 192.168.30.50
#>
  param(
    [Parameter(Mandatory=$true,  Position=0)][String]$Start,
    [Parameter(Mandatory=$false, Position=1)][String]$End
  )

  # Split into Octets
  $startOcts = $Start.Split(".")
  $endOcts   = $End.Split(".")

  # Loop through the first 3 octets and compare them
  for ($i = 0; $i -lt 3; $i++ ) {
    # Set values for easy writing
    $startOct = $startOcts[$i]
    $endOct   = $endOcts[$i]

    # Compare
    if (Compare-Object $startOct $endOct) {
      Write-Error "Octet $($i + 1) does not match: $startOct - $endOct"
      return $null
    }
  }

  return $true # return true if we didn't fail on above checks
}

function Compare-LastOctet {
<#
.SYNOPSIS
    Compares last octets of passed in strings - returns $true if End > Start else returns $null
.EXAMPLE
    Compare-LastOctet -Start 192.168.100.1 -End 192.168.30.50
#>
  param(
    [Parameter(Mandatory=$true,  Position=0)][String]$Start,
    [Parameter(Mandatory=$false, Position=1)][String]$End
  )

  # Split into Octets
  $startOcts = $Start.Split(".")
  $endOcts   = $End.Split(".")

  if ($endOcts[3] -le $startOcts[3]) {
    Write-Error "Last octet of End: $End must be greater than the last octet of Start: $Start"
    return $null
  }

  return $true # return true if we didn't fail on above checks
}

function Scan-IPRange {
<#
.SYNOPSIS
    Returns a hastable of all IP addresses that ping within a given range else reutnrs $null
.EXAMPLE
    Scan-IPRange -Start 192.168.100.1 -End 192.168.100.150
.EXAMPLE
    Scan-IPRange 192.168.100.1 192.168.100.150    
#>
  param(
    [Parameter(Mandatory=$true, Position=0)][String]$Start,
    [Parameter(Mandatory=$true, Position=1)][String]$End
  )

  ########################
  #### Validate Input ####
  ########################
  # Validate Addresses
  if (!(Validate-IPAddress -IP $Start)) { return $null }
  if (!(Validate-IPAddress -IP $End))   { return $null }
  
  # Compare first 3 octets
  if (!(Compare-Octets -Start $Start -End $End)) { return $null }

  # Check that End is a greater number than Start - last octet
  if (!(Compare-LastOctet -Start $Start -End $End)) { return $null } 

  #########################
  #### Setup Variables ####
  #########################
  # Split into Octets
  $startOcts = $Start.Split(".")
  $endOcts   = $End.Split(".")

  # Generate prefix string from Start octets - safe to do b/c we passed validation
  $prefixString = $startOcts[0] + "." + $startOcts[1] + "." + $startOcts[2] + "."

  # Get last octets of Start and End
  $lastStartOct = $startOcts[3]
  $lastEndOct   = $endOcts[3]

  #########################
  #### Actual Testing  ####
  #########################
  $results = $lastStartOct..$lastEndOct | ForEach-Object -Parallel { 
    $digits = $_
    while ($digits -notmatch "\d{3}") { $digits = "0" + $digits } # Add any missing leading 0s

    # Set address and test if it pings
    $prefix = $using:prefixString
    $addr = $prefix + $digits
    $ping = Test-Connection -Count 1 -Quiet $addr

    $result = @{} | Select-Object Address, Pings
    $result.Address = $addr
    $result.Pings   = $ping
    return $result

  } -ThrottleLimit 254

  return ($results | Where-Object { $_.Pings -eq $true } | Sort-Object Address)
}
Export-ModuleMember -Function Scan-IPRange
