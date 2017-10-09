# Creating Persistent Volume

In this lab you will learn how to create persistent volume ()PV) using NFS storage.

##Option 1
There are two ways to create persistent volume. One of them is via cockpit console.
You will have to have access to cockpit. If you will need to follow the instruction to setup cockpit before this lab.

1. Login in to https://<master-public-url>:9090/
2. Login as the cockpituser per the cockpit setup instruction
3. Once you login, you will click `Volumes` on the left menu
4. Click `Register New Volume` to create Persistent Volumes
5. Fill out the information for Name, Capacity, Reclaim Policy, Access Modes, NFS server, and the path to the volume. 
6. Click `Register`


##Option 2
Another way to create persistent volume is via command line

You will need to create your PV yaml file. Here is an example of a PV json file.

````
{
 "apiVersion": "v1",
 "kind": "PersistentVolume",
 "metadata": {
        "name": "3scale-volume1"
 },
 "spec": {
        "capacity": {
          "storage": "1Gi"
        },
        "accessModes": [ "ReadWriteOnce" ],
        "nfs": {
          "path": "/exports/3scaleVol1",
          "server": "<nfs-service-FQDN>"
        },
        "persistentVolumeReclaimPolicy": "Retain"
  }
}

````

Create the PV by running the following command:

```
oc create -f <name of your json file>
```
