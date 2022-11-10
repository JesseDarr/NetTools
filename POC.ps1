# $start = "192.168.2.1"
# $end = "192.168.3.10"

# # Split into Octets
# $sOcts = $start.Split(".")
# $eOcts = $end.Split(".")

# # Convert values to integers
# $sOcts = $sOcts | ForEach-Object { [int]$_ }
# $eOcts = $eOcts | ForEach-Object { [int]$_ }

$sOcts = @(168, 2, 1)
$eOcts = @(168, 3, 10)

$results = @()

while ( $sOcts[1] -le $eOcts[1]) {
  $results += [string]$sOcts[0] + "." + [string]$sOcts[1] + "." + [string]$sOcts[2]
  
  $sOcts[2]++
  if ($sOcts[2] -gt 10) {
      $sOcts[1]++
      $sOcts[2] = 1
  }
}

$results
