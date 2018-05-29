#!/bin/bash

az vm create --resource-group $resourceGroupName \
    --name $vmName \
    --location $location \
    --size $vmSize \
    --subnet $subnetName \
    --vnet-name $vnetName \
    --public-ip-address "" \
    --image RHEL \
    --storage-account $storageAccountName \
    --use-unmanaged-disk \
    --availability-set infraPoolSet \
    --admin-username $adminUserName \
    --authentication-type password \
    --admin-password $adminPassword

az vm unmanaged-disk attach --resource-group $resourceGroupName --vm-name $vmName --new --size-gb 30

