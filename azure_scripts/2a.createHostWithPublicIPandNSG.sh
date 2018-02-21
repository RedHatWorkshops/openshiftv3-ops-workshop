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
    --storage-account $storageAccountName \
    --use-unmanaged-disk \
    --admin-username $adminUserName \
    --ssh-key-value ~/.ssh/id_rsa.pub \
    --public-ip-address-allocation static \
    --public-ip-address $publicIPName 

az vm unmanaged-disk attach --resource-group $resourceGroupName --vm-name $vmName --new --size-gb 20
az vm unmanaged-disk attach --resource-group $resourceGroupName --vm-name $vmName --new --size-gb 60
