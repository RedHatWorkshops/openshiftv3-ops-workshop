az network nsg create --resource-group $resourceGroupName \
      --name $networkSecurityGroup \
      --location $location

az network nsg rule create --resource-group $resourceGroupName \
    --nsg-name $networkSecurityGroup \
    --name allow-https \
    --description "Allow access to port 443 for HTTPS" \
    --protocol Tcp \
    --source-address-prefix \* \
    --source-port-range \* \
    --destination-address-prefix \* \
    --destination-port-range 443 \
    --access Allow \
    --priority 102 \
    --direction Inbound
az network nsg rule create --resource-group $resourceGroupName \
    --nsg-name $networkSecurityGroup \
    --name allow-http \
    --description "Allow access to port 80 for HTTP" \
    --protocol Tcp \
    --source-address-prefix \* \
    --source-port-range \* \
    --destination-address-prefix \* \
    --destination-port-range 80 \
    --access Allow \
    --priority 112 \
    --direction Inbound
az network nsg rule create --resource-group $resourceGroupName \
    --nsg-name $networkSecurityGroup \
    --name allow-master-api \
    --description "Allow access to port 8443" \
    --protocol Tcp \
    --source-address-prefix \* \
    --source-port-range \* \
    --destination-address-prefix \* \
    --destination-port-range 8443 \
    --access Allow \
    --priority 122 \
    --direction Inbound
az network nsg rule create --resource-group $resourceGroupName \
    --nsg-name $networkSecurityGroup \
    --name allow-etcd \
    --description "Allow access to port 2379" \
    --protocol Tcp \
    --source-address-prefix \* \
    --source-port-range \* \
    --destination-address-prefix \* \
    --destination-port-range 2379 \
    --access Allow \
    --priority 132 \
    --direction Inbound
az network nsg rule create --resource-group $resourceGroupName \
    --nsg-name $networkSecurityGroup \
    --name allow-cockpit \
    --description "Allow access to port 9090" \
    --protocol Tcp \
    --source-address-prefix \* \
    --source-port-range \* \
    --destination-address-prefix \* \
    --destination-port-range 9090 \
    --access Allow \
    --priority 142 \
    --direction Inbound
az network nsg rule create --resource-group $resourceGroupName \
    --nsg-name $networkSecurityGroup \
    --name default-allow-ssh \
    --description "Allow access to port 22" \
    --protocol Tcp \
    --source-address-prefix \* \
    --source-port-range \* \
    --destination-address-prefix \* \
    --destination-port-range 22 \
    --access Allow \
    --priority 152 \
    --direction Inbound
