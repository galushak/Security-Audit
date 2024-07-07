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
