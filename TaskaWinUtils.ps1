# List of available scripts
$scripts = @{
    1 = "Create-PartitionAndDSTFolder"
    2 = "Set-DesktopIconsSettings"
    3 = "Script3"
    4 = "Script4"
    5 = "Script5"
}

# Function to display the list of available scripts
function Show-ScriptList {
    Write-Host "Available scripts:"
    foreach ($key in $scripts.Keys) {
        Write-Host "$key. $($scripts[$key])"
    }
}

# Function to execute selected scripts
function Execute-Scripts {
    param (
        [string]$input
    )

    $selectedScripts = $input -split ',' | ForEach-Object { $_.Trim() }
    foreach ($script in $selectedScripts) {
        if ($scripts.ContainsKey($script)) {
            Write-Host "Running $($scripts[$script])..."
            & $scripts[$script]
        } else {
            Write-Host "Script with number $script not found."
        }
    }
}

# Function to create a new partition and folder on the disk
function Create-PartitionAndDSTFolder {
    param (
        [string]$driveLetter = "D",
        [string]$folderPath = "DST"
    )

    # Ensure the script is run as administrator
    if (-not [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent().IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "This script requires administrative privileges. Please run PowerShell as an administrator."
        return
    }

    # Check if the drive already exists
    if (Test-Path -Path "$($driveLetter):\") {
        Write-Host "Drive $driveLetter already exists. Creating folder $folderPath..."

        # Create the folder on the existing drive
        $folderPath = "$($driveLetter):\$folderPath"
        New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
        Write-Host "Folder $folderPath created successfully."
    } else {
        # Get the primary disk
        $disk = Get-Disk | Where-Object { $_.PartitionStyle -eq 'MBR' } | Select-Object -First 1
        if (-not $disk) {
            Write-Host "No MBR disk found. Please check your disk configuration."
            return
        }

        # Calculate the size for the new partition (50% of the existing volume)
        $totalSize = ($disk | Get-Partition | Where-Object { $_.DriveLetter -eq 'C' }).Size
        $newSize = [math]::Floor($totalSize / 2)

        # Create a new partition on the disk
        New-Partition -DiskNumber $disk.Number -Size $newSize -AssignDriveLetter -DriveLetter $driveLetter | Out-Null
        Format-Volume -DriveLetter $driveLetter -FileSystem NTFS -Confirm:$false | Out-Null

        # Create the folder on the new partition
        $folderPath = "$($driveLetter):\$folderPath"
        New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
        Write-Host "Partition $driveLetter created and folder $folderPath created successfully."
    }
}

# Function to set desktop icons settings
function Set-DesktopIconsSettings {
    # Ensure the script is run as administrator
    if (-not [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent().IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "This script requires administrative privileges. Please run PowerShell as an administrator."
        return
    }

    # Registry path for desktop icon settings
    $registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"

    # Define the icon settings to enable (0 for showing icons)
    $icons = @{
        "DesktopComputer" = 0  # Show Computer icon
        "DesktopNetwork" = 0   # Show Network icon
        "DesktopRecycleBin" = 0  # Show Recycle Bin icon
        "DesktopRecycleBinDeleted" = 0  # Show Recycle Bin with deleted items (if applicable)
        "DesktopControlPanel" = 0  # Show Control Panel icon
    }

    foreach ($icon in $icons.Keys) {
        $valueName = $icon
        $value = $icons[$icon]

        # Set registry values
        Set-ItemProperty -Path $registryPath -Name $valueName -Value $value
    }

    # Refresh the desktop to apply changes
    Stop-Process -Name explorer -Force

    Write-Host "Desktop icons settings updated successfully."
}

# Main logic with a loop to return to the start menu
while ($true) {
    Show-ScriptList
    $userInput = Read-Host "Enter script numbers to run separated by commas, or 'exit' to quit"
    
    if ($userInput -eq 'exit') {
        Write-Host "Exiting the program..."
        break
    }

    Execute-Scripts -input $userInput

    Write-Host "All selected scripts have finished. Returning to the start menu..."
    Write-Host
}
