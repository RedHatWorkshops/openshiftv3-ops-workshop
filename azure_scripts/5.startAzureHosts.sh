#!/bin/bash
  
source 0.env.sh

while read -r line;
    do
      declare $line;
      printf "Starting VM %s \n" $vmName;
        az vm start --no-wait --name $vmName --resource-group $resourceGroupName
    done < hostsinfo.txt

az vm list --resource-group $resourceGroupName -d --query '[].[name,powerState]' -o tsv
