# Import the CSV file
$computers = Import-Csv -Path "C:\Temp\internal_scan_results.csv"

# Function to truncate long strings for readability
function Truncate-String {
    param (
        [string]$inputString,
        [int]$maxLength = 20
    )
    if ($inputString.Length -gt $maxLength) {
        return $inputString.Substring(0, $maxLength) + "..."
    }
    return $inputString
}

# Initialize an array to hold results
$results = @()

# Loop through each computer in the list
foreach ($computer in $computers) {
    # Extract values from the CSV
    $computerName = $computer.ComputerName
    $ipDns = $computer."IP/DNS"

    # Use ComputerName for scanning
    $scanTarget = $computerName

    # Create the output name
    $outputName = if ($ipDns) { "${computerName}:${ipDns}" } else { "${computerName}:<No IP/DNS>" }

    # Try to get the shares from the computer
    try {
        $shares = Get-WmiObject -Class Win32_Share -ComputerName $scanTarget -ErrorAction Stop

        # If shares are found, process them
        if ($shares) {
            foreach ($share in $shares) {
                try {
                    $acl = Get-Acl "\\$scanTarget\$($share.Name)"
                    foreach ($access in $acl.Access) {
                        $result = [PSCustomObject]@{
                            ComputerName     = $computerName
                            IP_DNS           = $ipDns
                            ShareName        = $share.Name
                            SharePath        = $share.Path
                            Identity         = Truncate-String $access.IdentityReference
                            FileSystemRights = $access.FileSystemRights
                            AccessControlType = $access.AccessControlType
                            IsInherited      = $access.IsInherited
                        }
                        $results += $result
                    }
                } catch {
                    # Skip this share if there is an error retrieving permissions
                }
            }
        }
    } catch {
        # Skip this computer if there is an error retrieving shares
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "C:\Temp\FileShareAuditResults.csv" -NoTypeInformation

Write-Output "Results have been exported to C:\Temp\FileShareAuditResults.csv"
