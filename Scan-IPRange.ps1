
function Scan-IPRange {
  <#
  .SYNOPSIS
      Returns a hastable of all IP addresses that ping within a given range else reutnrs $null
  .EXAMPLE
      Scan-IPRange -Start 192.168.100.1 -End 192.168.100.150
  #>
    param(
      [Parameter(Mandatory=$true, Position=0)][String]$Start,
      [Parameter(Mandatory=$true, Position=1)][String]$End
    )
  
    # Validate Addresses
    if (!(Validate-IPAddress -IP $Start)) { return $null }
    if (!(Validate-IPAddress -IP $End))   { return $null }
  
    # Validate Range
    if (!(Validate-IPRange -Start $Start -End $End)) { return $null }
  
    # Get IP Range
    $ipRange = Get-IPRange -Start $Start -End $End
  
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
  #Export-ModuleMember -Function Scan-IPRange
  
  