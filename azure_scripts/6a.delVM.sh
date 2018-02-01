#!/bin/bash

function usage {
	echo "Deletes a VM with all its associated resouces, except Data disks."
	echo "Usage:"
	echo "	delvm.sh <virtual machine name> <resource group>"
	echo ""
	echo "Arguments"
	echo "	<Virtual machine name>	The name of the Virtual machine to delete."
	echo "	<resource group>	The name of the resource group to search."
	echo ""
	echo "Example:"
	echo "	delvm.sh myvm01 mygroup"
	exit
}

# Check to see if we have two arguments at least
if [[ $1 = "" ]] | [[ $2 = "" ]]; then 
usage 
fi

echo "Gathering information for VM" $1 "in Resource Group" $2
# Get VM ID
vmID=$(az vm show -n $1 -g $2 --query "id" -o tsv)

# Did we find the VM?
if [[ $vmID = "" ]]; then
	echo Could not find VM $1
	exit
fi

# Get OS Disk
echo "Seeking Disk."
osDisk=$(az vm show -n $1 -g $2 --query "storageProfile.osDisk.name" -o tsv)
dataDiskArray=$(az vm show -n $1 -g $2 --query "storageProfile.dataDisks[].managedDisk.id" --output tsv)

# Get a list of public UP addresses
echo "Sniffing IPs.."
ipArray=$(az vm list-ip-addresses -n $1 -g $2 --query "[].virtualMachine.network.publicIpAddresses[].id" -o tsv)

# Get a list of NICs 
echo "Getting NICs.."
nicArray=$(az vm nic list --vm-name $1 -g $2 --query "[].id" -o tsv)

# Get a list of NSGs
nsgQry="[?virtualMachine.id=='"
nsgQry+=$vmID
nsgQry+="'].networkSecurityGroup[].id"
echo "Discovering NSGs.."
nsgArray=$(az network nic list -g $2 --query $nsgQry -o tsv)

echo Deleting VM $1
az vm delete -n $1 -g $2 --yes

echo Deleting Disk ID $osDisk
az disk delete -n $osDisk -g $2 --yes

echo Deleting Data Disks $dataDiskArray
az disk delete --ids $dataDiskArray --yes

echo Deleting Network cards $nicArray
az network nic delete --ids $nicArray

echo Deleting IPs $ipArray
az network public-ip delete --ids $ipArray

echo Deleting NSG $nsgArray
az network nsg delete --ids $nsgArray

echo Done with $1.
