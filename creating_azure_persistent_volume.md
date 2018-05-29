# Creating Persistent Volume on Azure

In this lab you will learn how to create persistent volume (PV) using Azure Disk storage.

## Step 1
Before creating PV on openshift, you will have make sure the Azure storageclass is setup.
The StorageClass resource object is created by cluster-admin. It provides a mean to pass parameter for dynamic provision storage on demand.

Here is an example Azure unmanaged disk storageclass YAML file.
Create a storageclass.yaml file with the following information:

```
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: azure-storageclass
provisioner: kubernetes.io/azure-disk
parameters:
  storageAccount: pocadmin
```
Note:
pocadmin is the storage account on Azure

## Step 2
Run the follow command with the file that was created in the previous step.

```
oc create -f storageclass.yaml
```

## Step 3

```
oc annotate storageclass azure-storageclass storageclass.beta.kubernetes.io/is-default-class="true"
```

## Step 4
Create PVC from OpenShift Web UI
- 1. Login to WebUI https://master:8443
- 2. Create Project
- 3. Create PVC via `Storage` on the left navigation --> create PVC --> select RWO, enter 1G --> click `Create`

## Step 5
Update deployment config to use PVC
- 1. Under the same Project
- 2. Click `catalog` --> enter PHP
- 3. Select PHP builder image
- 4. Enter https://github.com/RedHatWorkshops/welcome-php.git
- 5. Deploy the application
- 6. Click `Application` --> `Deployments`
- 7. Click `Action` --> `Add Storage` --> select pvc and add path.
- 8. Save.
