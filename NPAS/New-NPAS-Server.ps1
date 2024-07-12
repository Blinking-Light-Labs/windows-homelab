# ---------------------------------------------------
# Title: Setup New Network Policy and Access Services Server
# By: Michael Sepanik
# Date Modified: 07/12/2024
# ---------------------------------------------------

# Ensure the script is run with administrator privileges
if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "You need to have Administrator rights to run this script."
    exit
}

$domainName = Read-Host -Prompt "What is the FQDN of your Active Directory Domain?"

# Install NPAS role
if (!(Get-WindowsFeature -Name NPAS).Installed) {
    Write-Host "Installing Network Policy and Access Services role..."
    Install-WindowsFeature NPAS -IncludeManagementTools
} if ((Get-WindowsFeature -Name NPAS).Installed) {
    Write-Host "Network Policy and Access Services is already installed."
    exit
}

# Check if the installation was successful
if (!(Get-WindowsFeature -Name NPAS).Installed) {
    Write-Host "Failed to install NPAS role. Exiting..."
    exit
}
Write-Host "NPAS role installed successfully."

# Prompt for the shared RADIUS Client Secret.
$radiusClientSecret = Read-Host -Prompt 'Please enter your RADIUS secret.'
# Prompt the user for the number of RADIUS Clients.
$NumberOfClients = [int](Read-Host -Prompt 'Input the number of RADIUS Clients.')

# Loop to create and configure each network interface.
for ($i = 1; $i -lt $NumberOfClients; $i++) {
    # Add a RADIUS client
    $radiusClientName = Read-Host -Prompt 'Please enter the name of your #$i RADIUS client.'
    $radiusClientAddress = Read-Host -Prompt 'Please enter the IP Address or DNS Name of your RADIUS client.'
    New-NpsRadiusClient -Name $radiusClientName -Address $radiusClientAddress -SharedSecret $radiusClientSecret
}
# Configure NPS server

Write-Host "Configuring NPS server..."

# Import NPAS Config
Import-NpsConfiguration -Path \\$domainName\NETLOGON\NPAS-Config.xml

Write-Host "NPS server configuration completed."
