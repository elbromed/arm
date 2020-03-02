# Define variables 
$ResourceGroup    = "RG-HUB"
$Location         = "canadacentral"

$vNetName         = "VNet-HUB"
$PrefixHUB        = "192.168.0.0/16"

$SubAZFWName      = "AzureFirewallSubnet"
$SubPrefixAZFW    = "192.168.1.0/26"
$SubCorpName      = "CorpSubnet"
$SubPrefixCorp    = "192.168.10.0/24"
$SubInfraName     = "InfraSubnet"
$SubPrefixInfra   = "192.168.20.0/24"
$SubAGName        = "AGSubnet"
$SubPrefixAG      = "192.168.50.0/24"
$SubVPNName       = "VPNSubnet"
$SubPrefixVPN     = "192.168.60.0/24"

$VMName           = "VMCorp01"
$osDiskName       = "$VMName-OsDisk"
$osDiskSize       = "130"
$osDiskType       = "Standard_LRS"

# variables to store the storage account name and the storage account SKU information
# Name must be unique. Name availability can be check using PowerShell command Get-AzStorageAccountNameAvailability -Name ""
$StorageAccountName = "hubstacc001"
$SkuName            = "Standard_LRS"

# Create variables to store the location and resource group names.
write-host "Create Resource Group"
New-AzResourceGroup -Name $ResourceGroup -Location $Location

# Create variables to store the storage account name and the storage account SKU information
write-host "Create Storage Account"
$StorageAccountName = "hubstacc002"
$SkuName = "Standard_GRS"

# Create a new storage account
$StorageAccount = New-AzStorageAccount -Location $location -ResourceGroupName $ResourceGroup -Type $SkuName -Name $StorageAccountName
Set-AzCurrentStorageAccount -StorageAccountName $StorageAccountName  -ResourceGroupName $ResourceGroup

# Create the virtual network RG-HUB.
write-host "Create Network HUB"
$FWsub = New-AzVirtualNetworkSubnetConfig -Name $SubAZFWName -AddressPrefix $SubPrefixAZFW
$CORPsub = New-AzVirtualNetworkSubnetConfig -Name $SubCorpName -AddressPrefix $SubPrefixCorp 
$INFRAsub = New-AzVirtualNetworkSubnetConfig -Name $SubInfraName  -AddressPrefix $SubPrefixInfra
$AGsub = New-AzVirtualNetworkSubnetConfig -Name $SubAGName  -AddressPrefix $SubPrefixAG 
$VPNsub = New-AzVirtualNetworkSubnetConfig -Name $SubVPNName -AddressPrefix $SubPrefixVPN
$VNetHUB = New-AzVirtualNetwork -Name $vNetName -ResourceGroupName $ResourceGroup -Location $Location -AddressPrefix $PrefixHUB  -Subnet $FWsub, $CORPsub, $AGsub, $VPNsub, $INFRAsub

write-host "Create VM HUB"
# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig `
  -Name NSGRuleRDP `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 3389 `
  -Access Allow

# Create an inbound network security group rule for port 80
$nsgRuleWeb = New-AzNetworkSecurityRuleConfig `
  -Name NSGRuleWWW `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1001 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access Allow

# Create a network security group
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Location $location -Name "$VMName-NSG" -SecurityRules $nsgRuleRDP,$nsgRuleWeb


## Create a public IP address and specify a DNS name
#$pip = New-AzPublicIpAddress -ResourceGroupName $RG -Location $location -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "mypublicdns$(Get-Random)"
# Create a virtual network card and associate it with public IP address and NSG
#$nic = New-AzNetworkInterface -Name myNic -ResourceGroupName $RG -Location $location -SubnetId $VNetHUB.Subnets[1].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Create a virtual network card and associate it with private  IP address and NSG
$Subnet = Get-AzVirtualNetworkSubnetConfig -Name $CorpSub.Name -VirtualNetwork $VNetHUB
$IpConfigName1 = "IPConfig-1"
$IpConfig1 = New-AzNetworkInterfaceIpConfig -Name $IpConfigName1 -Subnet $Subnet -PrivateIpAddress 192.168.10.50 -Primary
$NIC = New-AzNetworkInterface -Name "$VMName-NIC" -ResourceGroupName $ResourceGroup -Location $Location -IpConfiguration $IpConfig1 -NetworkSecurityGroupId $nsg.Id
##$VNetHUB
##$NIC = New-AzNetworkInterface -Name ip-VM01 -ResourceGroupName $RG -Location $Location  -Subnetid $VNetHUB.Subnets[1].Id 



# create user
# Define a credential object to store the username and password for the VM
$UserName='azureuser'
$Password='Azure123456!'| ConvertTo-SecureString -Force -AsPlainText
$Credential=New-Object PSCredential($UserName,$Password)



#Define the virtual machine
# Set VM Configuration
$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize Standard_D3_v2
# Set VM operating system parameters
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
# Set boot diagnostic storage account
$VirtualMachine = Set-AzVMBootDiagnostic -Enable -ResourceGroupName $ResourceGroup -VM $VirtualMachine -StorageAccountName $StorageAccountName
# Add NIC
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
# Set virtual machine source image
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter' -Version latest
# Set OsDisk configuration
$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -Name $osDiskName -DiskSizeInGB $osDiskSize -StorageAccountType $osDiskType -CreateOption fromImage


#Create the virtual machine
New-AzVM -ResourceGroupName $ResourceGroup -Location $Location -VM $VirtualMachine -Verbose

#mstsc /v <IpAddress>
#Install-WindowsFeature -name Web-Server -IncludeManagementTools

## Delete the ResourceGroup
#Remove-AzResourceGroup -Name RG-HUB -Force
