Add-Type -AssemblyName System.Windows.Forms

# Function to prompt the user to select a drive or folder
function Select-DriveOrFolder {
    [System.Windows.Forms.OpenFileDialog]$folderDialog = New-Object System.Windows.Forms.OpenFileDialog
    $folderDialog.ValidateNames = $false
    $folderDialog.CheckFileExists = $false
    $folderDialog.CheckPathExists = $true
    $folderDialog.FileName = "Select folder or drive"
    $folderDialog.Title = "Select the drive, folder, or network share to scan"
    
    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedPath = [System.IO.Path]::GetDirectoryName($folderDialog.FileName)
        return $selectedPath
    } else {
        Write-Output "No drive or folder selected. Exiting script."
        exit
    }
}

# Define the patterns to search for
$filePatterns = "*.txt", "*.csv", "*.xlsx", "*.conf"
$keywordPatterns = "password", "username", "login", "credentials", "secret", "account"
$fileNamePatterns = "*backup*", "*config*", "*passwords*", "*accounts*", "*show run*", "*show startup*", "*startup*", "*show-run*"

# Function to check file content for keywords
function Check-FileContent {
    param (
        [string]$filePath
    )

    $content = Get-Content -Path $filePath -Raw
    foreach ($pattern in $keywordPatterns) {
        if ($content -match $pattern) {
            Write-Output "    Potential credential keyword found in file content: $pattern"
            break
        }
    }
}

# Function to scan for files and check their names and content
function Scan-DriveOrFolder {
    param (
        [string]$path,
        [string[]]$filePatterns,
        [string[]]$fileNamePatterns
    )

    foreach ($pattern in $filePatterns) {
        $files = Get-ChildItem -Path $path -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            foreach ($namePattern in $fileNamePatterns) {
                if ($file.Name -like $namePattern) {
                    Write-Output "File with potential credential-related name found:"
                    Write-Output "  Path: $($file.FullName)"
                    Write-Output "  Name: $($file.Name)"
                    Check-FileContent -filePath $file.FullName
                    Write-Output "" # Blank line for better readability
                    break
                }
            }
        }
    }
}

# Prompt the user to select a drive or folder
$selectedPath = Select-DriveOrFolder

# Start the scan
Write-Output "Starting scan on path: $selectedPath"
Write-Output "--------------------------------------------------"
Scan-DriveOrFolder -path $selectedPath -filePatterns $filePatterns -fileNamePatterns $fileNamePatterns
Write-Output "--------------------------------------------------"
Write-Output "Scan completed."
