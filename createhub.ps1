$Location="canadacentral"
$RG="RG-HUB"

# Create variables to store the location and resource group names.
write-host "Create Resource Group"
New-AzResourceGroup -Name $RG -Location $Location

# Create variables to store the storage account name and the storage account SKU information
write-host "Create Storage Account"
$StorageAccountName = "hub01storageacc"
$SkuName = "Standard_LRS"

# Create a new storage account
$StorageAccount = New-AzStorageAccount -Location $location -ResourceGroupName $RG -Type $SkuName -Name $StorageAccountName
Set-AzCurrentStorageAccount -StorageAccountName $StorageAccountName  -ResourceGroupName $RG


# Virtual network
# Create the virtual network RG-HUB.
write-host "Create Network HUB"
$FWsub = New-AzVirtualNetworkSubnetConfig -Name AzureFirewallSubnet -AddressPrefix 192.168.1.0/26
$CORPsub = New-AzVirtualNetworkSubnetConfig -Name CorpSubnet -AddressPrefix 192.168.10.0/24
$INFRAsub = New-AzVirtualNetworkSubnetConfig -Name InfraSubnet -AddressPrefix 192.168.20.0/24
$AGsub = New-AzVirtualNetworkSubnetConfig -Name AGSubnet -AddressPrefix 192.168.50.0/24
#$BackendAGsub = New-AzVirtualNetworkSubnetConfig -Name BackendAGSubnet -AddressPrefix 192.168.60.0/24
$VPNsub = New-AzVirtualNetworkSubnetConfig -Name VPNSubnet -AddressPrefix 192.168.70.0/24
$VNetHUB = New-AzVirtualNetwork -Name VNet-HUB -ResourceGroupName $RG -Location $Location -AddressPrefix 192.168.0.0/16 -Subnet $FWsub, $CORPsub, $AGsub, $VPNsub, $INFRAsub
# Get-AzVirtualNetwork -name VNet-HUB -ResourceGroupName RG-HUB | Get-AzVirtualNetworkSubnetConfig | select name

write-host "Create VM HUB"

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig `
  -Name myNetworkSecurityGroupRuleRDP `
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
  -Name myNetworkSecurityGroupRuleWWW `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1001 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access Allow

# Create a network security group
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $RG -Location $location -Name myNetworkSecurityGroup -SecurityRules $nsgRuleRDP,$nsgRuleWeb


## Create a public IP address and specify a DNS name
#$pip = New-AzPublicIpAddress -ResourceGroupName $RG -Location $location -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "mypublicdns$(Get-Random)"
# Create a virtual network card and associate it with public IP address and NSG
#$nic = New-AzNetworkInterface -Name myNic -ResourceGroupName $RG -Location $location -SubnetId $VNetHUB.Subnets[1].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Create a virtual network card and associate it with private  IP address and NSG

$Subnet = Get-AzVirtualNetworkSubnetConfig -Name $CorpSub.Name -VirtualNetwork $VNetHUB
$IpConfigName1 = "IPConfig-1"
$IpConfig1 = New-AzNetworkInterfaceIpConfig -Name $IpConfigName1 -Subnet $Subnet -PrivateIpAddress 192.168.10.50 -Primary
#$IpConfig1 = New-AzNetworkInterfaceIpConfig -Name $IpConfigName1 -Subnet $Subnet -PrivateIpAddress 192.168.10.50 -Primary -NetworkSecurityGroupId $nsg.Id
$NIC = New-AzNetworkInterface -Name VMCorp01-NIC -ResourceGroupName $RG -Location $Location -IpConfiguration $IpConfig1 -NetworkSecurityGroupId $nsg.Id
#Create the NIC
##$VNetHUB
##$NIC = New-AzNetworkInterface -Name ip-VM01 -ResourceGroupName $RG -Location $Location  -Subnetid $VNetHUB.Subnets[1].Id 

$VMName="VMCorp01"
# create user
# Define a credential object to store the username and password for the VM
$UserName='azureuser'
$Password='Azure123456!'| ConvertTo-SecureString -Force -AsPlainText
$Credential=New-Object PSCredential($UserName,$Password)

#Define the virtual machine
$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize Standard_D3_v2
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -CreateOption FromImage | Set-AzVMBootDiagnostics -ResourceGroupName $RG -StorageAccountName $StorageAccountName -Enable
#-Enable |` Add-AzureRmVMNetworkInterface -Id $nic.Id
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2016-Datacenter' -Version latest

#Create the virtual machine
New-AzVM -ResourceGroupName $RG -Location $Location -VM $VirtualMachine -Verbose
Install-WindowsFeature -name Web-Server -IncludeManagementTools
#mstsc /v <IpAddress>