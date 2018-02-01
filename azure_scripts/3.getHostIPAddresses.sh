for i in $(az vm list --resource-group $resourceGroupName --query "[].name" -o tsv); do \
   export privIP=$(az vm show -d --name $i --resource-group $resourceGroupName --query "privateIps" -o tsv); \
   export publIP=$(az vm show -d --name $i --resource-group $resourceGroupName --query "publicIps" -o tsv); \
   printf "%s PrivateIP: %s PublicIP: %s\n" $i $privIP $publIP; \
done
