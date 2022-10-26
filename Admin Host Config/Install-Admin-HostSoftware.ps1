## Install and configure Admin-Host for Microsoft Teams Direct Routing Lab

<#
    .SYNOPSIS
    Configure Admin-Host for Microsoft Teams Direct Routing Lab.
    .DESCRIPTION
    This script will install and configure Admin-Host for Microsoft Teams Direct Routing Lab.
    .NOTES
    Author: Tobias Heim 
    Date: 10/24/2022
    Version: 1.0
    Disclaimer:
        This script is provided AS IS without warranty of any kind. We disclaim all implied warranties including, 
        without limitation, any implied warranties of merchantability or of fitness for a particular purpose. 
        The entire risk arising out of the use or performance remains with you. In no event the author will be liable 
        for any damages, whatsoever (including, without limitation, damages for loss of business profits, business interruption, 
        loss of business information, or other pecuniary loss) arising out of the use of or inability to use the script. 
    Assumptions:
    Limitations: 
    Known issues:
    .EXAMPLE
    .\Install-AdminHostSoftware.ps1
 #>

Write-Host "Microsoft Teams Direct Routing Lab Admin-Host Configuration - v1.0" -ForegroundColor Green

# Region Chocolatey Installation

# Install Chocolatey
if(Test-Path -Path "$env:ProgramData\Chocolatey") {
    Write-Host "Chocolatey is already installed" -ForegroundColor Yellow
}
else {
    Write-Host "Chocolatey is not installed. Chocolatey & required packages will be installed..." -ForegroundColor Green
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Install required packages      
$AdminHost_Packages = 'vscode', 'microsoft-teams'
ForEach ($Package in $AdminHost_Packages)
{
    Write-Host('Chocolatey: Installing Package {0}' -f $Package) -ForegroundColor Green
    choco install $Package -y
}

# Endregion
# Region Install Telnet

# Install Telnet client
try {
    Write-Host "Installing Telnet client..." -ForegroundColor Green
    Enable-WindowsOptionalFeature -Online -FeatureName TelnetClient -ErrorAction stop
}
catch {
    Write-Host "Telnet client failed to install. Please install Telnet client and try again." -ForegroundColor Red
}

# Endregion
# Region Install Audiocodes Syslog Viewer

# Download and install Audiocodes Syslog Viewer
Write-Host "Downloading Audiocodes Syslog Viewer..." -ForegroundColor Green
Invoke-RestMethod -Uri "http://redirect.audiocodes.com/install/syslogViewer/syslogViewer-setup.exe" -OutFile ((Get-Location).Path + "\syslogViewer-setup.exe")
try {
    Write-Host "Installing Audiocodes Syslog Viewer..." -ForegroundColor Green
    Start-Process -FilePath ((Get-Location).Path + "\syslogViewer-setup.exe") -Argument "/VERYSILENT"
}
catch {
    Write-Host "Audiocodes Syslog Viewer failed to install. Please install Audiocodes Syslog Viewer and try again." -ForegroundColor Red
}

# Endregion
# Region Install 3CX Soft-Client

Write-Host "Downloading 3CX Phone Soft-Client..." -ForegroundColor Green
Invoke-RestMethod -Uri "https://downloads.3cx.com/downloads/3CXPhone6.msi" -OutFile ((Get-Location).Path + "\3CXPhone6.msi")
try {
    Write-Host "Installing 3CX Phone Soft-Client..." -ForegroundColor Green
    Start-Process -FilePath ((Get-Location).Path + "\3CXPhone6.msi") -Argument "/quiet"
}
catch {
    Write-Host "3CX Phone failed to install. Please install 3CX Phone and try again." -ForegroundColor Red
}

# Endregion

Write-Host "Microsoft Teams Direct Routing Lab Admin-Host Configuration successfully completed" -ForegroundColor Green


