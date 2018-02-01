#!/bin/bash

echo "creating network security group and network security rules"
source 2c.createNetworkSecurityGroup.sh

echo "creating Master VM with two extra disks"
az vm create --resource-group $resourceGroupName \
    --name $vmName \
    --location $location \
    --size $vmSize \
    --subnet $subnetName \
    --vnet-name $vnetName \
    --nsg $networkSecurityGroup \
    --image RHEL \
    --data-disk-sizes-gb 20 60 \
    --admin-username $adminUserName \
    --ssh-key-value ~/.ssh/id_rsa.pub \
    --public-ip-address-allocation static \
    --public-ip-address $publicIPName 
      
