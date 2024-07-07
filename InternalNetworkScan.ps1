# Get the network information for the Ethernet Adapter Ethernet
$adapter = Get-NetIPAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4

# Extract the IP address and prefix length
$ipAddress = $adapter.IPAddress
$prefixLength = $adapter.PrefixLength

# Convert the prefix length to a subnet mask
function ConvertTo-SubnetMask($prefixLength) {
    $subnetMask = @()
    for ($i = 0; $i -lt 4; $i++) {
        $octet = 0
        for ($bit = 7; $bit -ge 0; $bit--) {
            if ($prefixLength -gt 0) {
                $octet += [math]::Pow(2, $bit)
                $prefixLength--
            }
        }
        $subnetMask += $octet
    }
    $subnetMask -join '.'
}

$subnetMask = ConvertTo-SubnetMask -prefixLength $prefixLength

# Convert IP address and subnet mask to bytes
$ipBytes = [System.Net.IPAddress]::Parse($ipAddress).GetAddressBytes()
$maskBytes = [System.Net.IPAddress]::Parse($subnetMask).GetAddressBytes()

# Calculate the network ID
$networkIDBytes = [byte[]]::new(4)
for ($i = 0; $i -lt 4; $i++) {
    $networkIDBytes[$i] = $ipBytes[$i] -band $maskBytes[$i]
}

# Convert the network ID bytes back to an IP address
$networkID = [System.Net.IPAddress]::new($networkIDBytes)

# Output the network ID with the subnet mask appended
Write-Output "IP Address: $ipAddress"
Write-Output "Subnet Mask: $subnetMask"
Write-Output "Network ID: $($networkID.IPAddressToString)/$subnetMask"

# Define the ports to scan
$ports = @(20, 21, 22, 23, 25, 53, 137, 139, 445, 80, 443, 8080, 8443, 1433, 1434, 3306, 3389)

# Perform Nmap scan on specified ports
$scan = Invoke-PSNmap $networkRange -Port $ports -Dns #-Verbose

# Filter scan results
$filteredScan = $scan | where {$_.Ping }

# Ensure the directory exists
$directory = "C:\Temp"
if (-Not (Test-Path -Path $directory)) {
    New-Item -ItemType Directory -Path $directory
}

# Export scan results to CSV
$filteredScan | Export-Csv -Path "$directory\internal_scan_results.csv" -NoTypeInformation

# Output scan results
$filteredScan | Format-Table -AutoSize
