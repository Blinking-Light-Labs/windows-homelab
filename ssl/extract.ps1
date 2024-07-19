# Author: Joshua Ross
# Github: https://github.com/ColoredBytes 
# Purpose: PFX extraction script

# Variables
$appName = "graylog"  # Replace with your actual application name
$currentDate = Get-Date -Format "yyyy-MM-dd"
$pfxFile = "./pfx/graylog.pfx"  # Replace with the actual path to your PFX file
$outputDir = "./$appName"

# Ensure the output directory exists
if (-Not (Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Prompt for the PFX password securely
$pfxPassword = Read-Host "Enter the PFX password" -AsSecureString
$pfxPasswordPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pfxPassword))

# Generate filenames with app name and date
$privKeyFile = "$outputDir/$appName-$currentDate-priv.key"
$pubCrtFile = "$outputDir/$appName-$currentDate-pub.crt"
$caCrtFile = "$outputDir/$appName-$currentDate-ca.crt"

# Extract the private key
openssl pkcs12 -in $pfxFile -nocerts -nodes -out $privKeyFile -passin pass:$pfxPasswordPlainText
# Extract the public key
openssl pkcs12 -in $pfxFile -clcerts -nokeys -out $pubCrtFile -passin pass:$pfxPasswordPlainText
# Extract the CA cert chain
openssl pkcs12 -in $pfxFile -cacerts -nokeys -chain -out $caCrtFile -passin pass:$pfxPasswordPlainText

Write-Output "Private key saved to: $privKeyFile"
Write-Output "Public key saved to: $pubCrtFile"
Write-Output "CA cert chain saved to: $caCrtFile"

Write-Output "Extraction and conversion completed."
