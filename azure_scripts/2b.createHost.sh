#!/bin/bash

az vm create --resource-group $resourceGroupName \
    --name $vmName \
    --location $location \
    --size $vmSize \
    --subnet $subnetName \
    --vnet-name $vnetName \
    --public-ip-address "" \
    --image RHEL \
    --data-disk-sizes-gb 20 \
    --admin-username $adminUserName \
    --authentication-type password \
    --admin-password $adminPassword
