# Creating Persistent Volume

In this lab you will learn how to create persistent volume (PV) using NFS storage.

## Step 1
Before creating PV on NFS server, you will have to create the directory on the NFS master.

The NFS server is normally on the master server.
You can do the following to create your volume.
Update /etc/export.d/openshift-ansible.exports then add the following line to the openshift-ansible.exports file.
Each PV will need a separate directory, though we're only creating one for this lab.


```
/exports/appvol *(rw,root_squash)
```
After updating the  /etc/export.d/openshift-ansible.exports, run the following commands on NFS server.

```
$ mkdir -p /exports/appvol
$ cd /exports
$ chown -R nfsnobody:nfsnobody appvol
$ chmod -R 777 appvol
$ systemctl restart nfs-server.service
```

## Option 1

There are two ways to create persistent volumes. One of them is via cockpit console.
You will have to have access to cockpit. If you will need to follow the instruction in [Setting up access to OOTB Cockpit](using_ootb_cockpit.md) before this lab.

1. Login in to https://<master-public-url>:9090/
2. Login as the cockpituser per the cockpit setup instruction
3. Once you login, you will click `Volumes` on the left menu
4. Click `Register New Volume` to create Persistent Volumes
5. Fill out the information for Name, Capacity, Reclaim Policy, Access Modes, NFS server, and the path to the volume. 
6. Click `Register`


## Option 2

Another way to create persistent volume is via the command line.

You will need to create a PV json file. Here is an example of a PV json file.

```
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

```

Create the PV by running the following command:

```
oc create -f <name of your json file>
```
