# ---------------------------------------------------
# Title: Deploy New Hyper-V Virtual Machine
# By: Michael Sepanik
# Date Modified: 07/12/2024
# ---------------------------------------------------

# Prompt the user for VM name, processor count and maximum memory
$VMName = Read-Host -Prompt 'Input the name of the VM'
$ProcessorCount = [int](Read-Host -Prompt 'Input the number of processors')
$MaximumMemory = [int](Read-Host -Prompt 'Input the maximum memory in GB')
$OSType = (Read-Host -Prompt 'What OS does this VM run?')

# Output the user input
Write-Host "You have entered VM Name: $VMName, Processor Count: $ProcessorCount, Maximum Memory: $MaximumMemory GB, and Running $OSType as it's OS."

# Convert the maximum memory to bytes
$MaximumMemoryBytes = $MaximumMemory * 1GB

# Set the hard coded Hyper-V parameters
$SwitchName = "Access Switch"  # Name of the switch to be used
$VMStorage = "C:\ClusterStorage\S2D_LUN0\Hyper-V" # Default location for Hyper-V storage
$StartupMemory = 1GB  # Startup memory
$MinimumMemory = 512MB  # Minimum memory

# Setup VM folder
$SetupFolderPath = "$VMStorage\$VMName"

if (Test-Path $SetupFolderPath) {
    $DeleteFolder = Read-Host -Prompt "The setup folder already exists. Do you want to delete it and its contents? (Y/N)"
    if ($DeleteFolder -eq 'Y' -or $DeleteFolder -eq 'y') {
        Remove-Item -Path $SetupFolderPath -Recurse -Force
    } else {
        Write-Host "Skipping folder deletion. Exiting script."
        Exit
    }
}
$VHDPath = New-Item -ItemType "directory" -Path "$VMStorage\$VMName\Virtual Hard Disks"

# Create new VM
New-VM -Name $VMName -Path $VMStorage -MemoryStartupBytes $StartupMemory -Generation 2 # Create VM & VHDX
Set-VMProcessor -VMName $VMName -Count $ProcessorCount # Set VM Processors
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes $MinimumMemory -MaximumBytes $MaximumMemoryBytes # Set VM memory
Enable-VMIntegrationService -Name "Guest Service Interface",Heartbeat,"Key-Value Pair Exchange",Shutdown,"Time Synchronization",VSS -VMName $VMName # Set all VM integration services.
Remove-VMNetworkAdapter -VMName $VMName -VMNetworkAdapterName "Network Adapter" #Removes default network adapter

If ($OSType -eq "Windows") {
    # Set the hard coded Hyper-V parameters
    $InstallImagePath = "$VMStorage\Virtual Hard Disks\Windows2022-Gold.vhdx"  # Path to your golden image file
    
    # Copy gold image & map vhdx
    Copy-Item $InstallImagePath -Destination $VHDPath
    Rename-Item -Path "$VHDPath\Windows2022-Gold.vhdx" -NewName "$VMName-OS.vhdx"
    Add-VMHardDiskDrive -VMName $VMName -Path "$VHDPath\$VMName-OS.vhdx"
    $VHD = Get-VMHardDiskDrive -VMName $VMName | Where-Object {$_.Path -like "*vhdx"}
    Set-VMFirmware -VMName $VMName -FirstBootDevice $VHD # Set the boot order to boot from Hard drive first

} Else {
    # Set the hard coded Hyper-V parameters
    $InstallISOPath = "$VMStorage\ISOs\Ubuntu24.04LTS.iso"  # Path to your ISO file
    $VMSecureBoot = "Off" #Set if the VM uses secure boot
    $VHDSizeGB = 100  # Size of the VHD in GB

    # Create new VM
    Set-VMFirmware -VMName $VMName -EnableSecureBoot $VMSecureBoot # Set secure boot setting.
    New-VHD -Path "$VHDPath\$VMName-OS.vhdx" -SizeBytes ($VHDSizeGB * 1GB) -Dynamic
    Add-VMHardDiskDrive -VMName $VMName -Path "$VHDPath\$VMName-OS.vhdx"

    # Add DVD drive to VM
    Add-VMDvdDrive -VMName $VMName
    Set-VMDvdDrive -VMName $VMName -Path $InstallISOPath
    $DVDDrive = Get-VMDvdDrive -VMName $VMName
    Set-VMFirmware -VMName $VMName -FirstBootDevice $DVDDrive
}

# Prompt the user for the number of network interfaces
$NumberOfNICs = [int](Read-Host -Prompt 'Input the number of network interfaces')

# Loop to create and configure each network interface
for ($i = 1; $i -lt $NumberOfNICs; $i++) {
    $VLANID = [int](Read-Host -Prompt "Input the VLAN ID for NIC $i")
    $NICName = "NIC$i-$VLANID"
    Add-VMNetworkAdapter -VMName $VMName -Name $NICName -SwitchName $SwitchName
    Set-VMNetworkAdapterVlan -VMName $VMName -VMNetworkAdapterName $NICName -Access -VlanId $VLANID
}
# Ask for the number of additional disks
$NumberOfDisks = [int](Read-Host -Prompt 'Input the number of additional disks')

# Loop to create additional disks
for ($i = 1; $i -le $NumberOfDisks; $i++) {
    $DiskSizeGB = [int](Read-Host -Prompt "Input the size of disk $i in GB")
    $DiskPath = "$VHDPath\$VMName-Disk$i.vhdx"
    New-VHD -Path $DiskPath -SizeBytes ($DiskSizeGB * 1GB) -Dynamic
    Add-VMHardDiskDrive -VMName $VMName -Path $DiskPath
}

# Start the VM
Start-VM -Name $VMName