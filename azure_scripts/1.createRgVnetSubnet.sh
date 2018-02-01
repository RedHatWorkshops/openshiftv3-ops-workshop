echo "setting environment variables"
source env.sh

echo "creating resource group"
az group create --location $location --resource-group $resourceGroupName

echo "creating vnet and subnet"
az network vnet create \
  --resource-group $resourceGroupName  \
  --location $location \
  --name $vnetName \
  --address-prefix $vnetAddressPrefix \
  --subnet-name $subnetName \
  --subnet-prefix $subnetAddressPrefix
