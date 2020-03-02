# Define variables 
$ResourceGroupHUB    = "RG-HUB"
$ResourceGroupPROD   = "RG-PROD"
$ResourceGroupSTG    = "RG-STG"
$ResourceGroupDEV    = "RG-DEV"

$vNetNameHUB      = "HUB-VNet"
$vNetNameDEV      = "DEV-VNET"
$vNetNameSTG      = "STG-VNet"
$vNetNamePROD     = "PROD-VNet"

#Get-AzVirtualNetwork -name HUB-VNet -ResourceGroupName RG-HUB | Get-AzVirtualNetworkSubnetConfig | select name
$VNetHUB = Get-AzVirtualNetwork -name $vNetNameHUB -ResourceGroupName $ResourceGroupHUB
$VNetPRD = Get-AzVirtualNetwork -name $vNetNamePROD -ResourceGroupName $ResourceGroupPROD
$VNetSTG = Get-AzVirtualNetwork -name $vNetNameSTG -ResourceGroupName $ResourceGroupSTG
$VNetDEV = Get-AzVirtualNetwork -name $vNetNameDEV -ResourceGroupName $ResourceGroupDEV

# Network peering
# Peering DEV-VNet avec HUB-VNet.
Add-AzVirtualNetworkPeering -Name $vNetNameDEV-$vNetNameHUB -VirtualNetwork $VNetDEV -RemoteVirtualNetworkId $VNetHUB.Id
Add-AzVirtualNetworkPeering -Name $vNetNameHUB-$vNetNameDEV -VirtualNetwork $VNetHUB -RemoteVirtualNetworkId $VNetDEV.Id

# Peering HUB-VNet avec PRD-VNet..
Add-AzVirtualNetworkPeering -Name $vNetNameHUBt-$vNetNamePROD -VirtualNetwork $VNetHUB -RemoteVirtualNetworkId $VNetPRD.Id
Add-AzVirtualNetworkPeering -Name $vNetNamePROD-$vNetNameHUB -VirtualNetwork $VNetPRD -RemoteVirtualNetworkId $VNetHUB.Id

# Peering HUB-VNet avec STG-VNet..
Add-AzVirtualNetworkPeering -Name $vNetNameHUB-$vNetNameSTG -VirtualNetwork $VNetHUB -RemoteVirtualNetworkId $VNetSTG.Id
Add-AzVirtualNetworkPeering -Name $vNetNameSTG-$vNetNameHUB -VirtualNetwork $VNetSTG -RemoteVirtualNetworkId $VNetHUB.Id

## Peering DEV-VNet avec HUB-VNet.
#Add-AzVirtualNetworkPeering -Name DEV-VNet-PRD-VNet -VirtualNetwork $VNetDEV -RemoteVirtualNetworkId $VNetPRD.Id
#Add-AzVirtualNetworkPeering -Name PRD-VNet-DEV-VNet -VirtualNetwork $VNetPRD -RemoteVirtualNetworkId $VNetDEV.Id

# check Peering state
Get-AzVirtualNetworkPeering -ResourceGroupName  RG-HUB -VirtualNetworkName $vNetNameHUB  | Select PeeringState
Get-AzVirtualNetworkPeering -ResourceGroupName  RG-DEV -VirtualNetworkName $vNetNameDEV  | Select PeeringState
Get-AzVirtualNetworkPeering -ResourceGroupName  RG-STG -VirtualNetworkName $vNetNameSTG  | Select PeeringState
Get-AzVirtualNetworkPeering -ResourceGroupName  RG-PRD -VirtualNetworkName $vNetNamePROD | Select PeeringState