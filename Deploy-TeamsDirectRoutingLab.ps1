## Deploy Microsoft Teams Direct Routing Lab Environment - Version 1.0

<#
    .SYNOPSIS
    Deploys a Microsoft Teams Direct Routing Lab with a Audiocodes SBC.
    .DESCRIPTION
    The script uses Terraform and Chocolatey to deploy a Microsoft Teams Direct Routing Lab with a Audiocodes SBC.
    .PARAMETER SbcFQDN
    The FQDN of the Audiocodes SBC.
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
    .\Deploy-TeamsDirectRoutingLab.ps1 -SbcFQDN <SBC FQDN>
 #>

 <# Valid Azure locations
DisplayName          Latitude    Longitude    Name
-------------------  ----------  -----------  ------------------
East Asia            22.267      114.188      eastasia
Southeast Asia       1.283       103.833      southeastasia
Central US           41.5908     -93.6208     centralus
East US              37.3719     -79.8164     eastus
East US 2            36.6681     -78.3889     eastus2
West US              37.783      -122.417     westus
North Central US     41.8819     -87.6278     northcentralus
South Central US     29.4167     -98.5        southcentralus
North Europe         53.3478     -6.2597      northeurope
West Europe          52.3667     4.9          westeurope
Japan West           34.6939     135.5022     japanwest
Japan East           35.68       139.77       japaneast
Brazil South         -23.55      -46.633      brazilsouth
Australia East       -33.86      151.2094     australiaeast
Australia Southeast  -37.8136    144.9631     australiasoutheast
South India          12.9822     80.1636      southindia
Central India        18.5822     73.9197      centralindia
West India           19.088      72.868       westindia
Canada Central       43.653      -79.383      canadacentral
Canada East          46.817      -71.217      canadaeast
UK South             50.941      -0.799       uksouth
UK West              53.427      -3.084       ukwest
West Central US      40.890      -110.234     westcentralus
West US 2            47.233      -119.852     westus2
Korea Central        37.5665     126.9780     koreacentral
Korea South          35.1796     129.0756     koreasouth
France Central       46.3772     2.3730       francecentral
France South         43.8345     2.1972       francesouth
Australia Central    -35.3075    149.1244     australiacentral
Australia Central 2  -35.3075    149.1244     australiacentral2
South Africa North   -25.731340  28.218370    southafricanorth
South Africa West    -34.075691  18.843266    southafricawest

NOTE: Make sure to check the Azure region availability for the services you want to use.

#>
 
 [CmdletBinding()]
 Param( 
    [Parameter(Mandatory=$true)][string]$SbcFQDN
 )
 
# Region Install Requirements

Write-Host "Microsoft Teams Phone Lab Deployment - v1.0" -ForegroundColor Green

# Install Chocolatey
if(Test-Path -Path "$env:ProgramData\Chocolatey") {
    Write-Host "Chocolatey is already installed" -ForegroundColor Yellow
}
else {
    Write-Host "Chocolatey is not installed. Chocolatey & required packages will be installed..." -ForegroundColor Green
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Install required Packages
$Client_Packages = 'terraform'#, 'vscode', 'microsoft-teams', 'powerbi'
ForEach ($Package in $Client_Packages) {
    Write-Host('Chocolatey: Installing Package {0}' -f $Package) -ForegroundColor Green
    choco install $Package -y
}

# Endregion
# Deploy Azure Infrastructure (AudioCodes SBC, Azure VMs, Azure Firewall, Azure DNS, Azure Network)

# Get current directory and set Terraform working directory
$location = (Get-Location).Path
Push-Location -Path (Join-Path -Path $location -ChildPath "Terraform")

# Connect to Azure
Write-Host "Connecting to Azure..." -ForegroundColor Green
az login

# Run Terraform Deployment
Write-Host "Deploying Components to Azure with Terraform - Please wait..." -ForegroundColor Green

Terraform init
$tfRun = [string]::Empty
Terraform apply -auto-approve 2>&1 |Tee-Object -Variable tfRun
$outPut = Terraform output -json | ConvertFrom-Json

# Endregion
# Create Audiocodes SBC Configuration (*.ini) and finalize deployment

# Check if Terraform deployment included Errors
if (!($tfRun -join "").contains("Error:")) {
    # Get Office 365 Tenant Domain-Name
    $TenantDomain = $SbcFQDN -replace ($SbcFQDN.split('.')[0] + '.'), ''

    # Create Audiocodes SBC ini file
    Write-Host "Prepare Audiocodes SBC ini file..."

    $ini = Get-content -Path (Join-Path -Path $location -ChildPath 'AC INI\lab-sbc_template.ini')
    $ini = $ini -replace "<Admin-Host-IP>", $outPut.Admin_Host_Private_IP_Address.value
    $ini = $ini -replace "<SBC-Private-IP>", $outPut.SBC_Private_IP_Address.value
    $ini = $ini -replace "<SBC-Public-IP>", $outPut.SBC_Public_IP_Address.value
    $ini = $ini -replace "<Office-365-Domain>", $TenantDomain
    $ini = $ini -replace "<SBC-FQDN>", $SbcFQDN
    $ini | Set-Content -Path (Join-Path -Path $location -ChildPath 'your-lab-sbc.ini')

    # Write configuration output
    Write-Host "Use the following information to configure your SBC and Admin-Host:" -ForegroundColor Green
    Write-Host('Admin-Host - IP Address: {0}' -f $outPut.Admin_Host_Public_IP_Address.value)
    Write-Host "Admin-Host - Username: labadmin" 
    Write-Host('Admin-Host - Password: {0}' -f $outPut.Admin_Host_Password.value)
    Write-Host('SBC - IP Address: {0}' -f $outPut.SBC_Public_IP_Address.value)
    Write-Host "SBC - Username: labadmin" 
    Write-Host('SBC - Password: {0}' -f $outPut.SBC_Password.value)
    Write-Host "Note: You now need to upload the Public Certificate and ini-file to the SBC and verify the connection to Microsoft Teams." -ForegroundColor Yellow

    Write-Host "Microsoft Teams Phone Lab Deployment successfully completed" -ForegroundColor Green
    
} else {
    Write-Host "Terraform deployment failed. Please check the error messages and re-run the deployment" -ForegroundColor Red
}

#Push back to original directory
Push-Location -Path $location

# Endregion



