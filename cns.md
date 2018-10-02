# Container Native Storage
You can install GlusterFS in a container and run it on OpenShift. Furthermore you can use `heketi` to dynamically create volumes to use.

[Official Docs](https://access.redhat.com/documentation/en-us/red_hat_gluster_storage/3.3/html-single/container-native_storage_for_openshift_container_platform/)

## Prereqs

1) A fully functioning OCP v3.7 environment
2) At least 3 nodes (minimum) with at least 250GB raw/unformated disc attached to them
3) If you have a POC env with one master and two nodes; you're going to __*need*__ to use the master as a node
4) Fully functioning DNS (forward AND reverse)
5) Access to the entitlements that provides the following (needed for the `heketi-cli`:
    - `rh-gluster-3-client-for-rhel-7-server-rpms`

Thigs to keep in mind (*DO NOT SKIP OVER THIS; PLEASE READ*)

* Ensure that the Trusted Storage Pool is not scaled beyond 100 volumes per 3 nodes per 32G of RAM.
* A trusted storage pool consists of a minimum of 3 nodes/peers.
* Distributed-Three-way replication is the only supported volume type. 

## Host Prep

You need to prepare the host as if it was an openshift node. More instructions can be found [here](https://docs.openshift.com/container-platform/3.10/install/host_preparation.html).

Another thing that is handy is to have the `heketi-cli` installed on one of the servers (or on a desktop somewhere). To do that run

```
subscription-manager repos  --enable=rh-gluster-3-client-for-rhel-7-server-rpms
yum -y install heketi-client
```

## Deploying Container-Native Storage

Deploying Container-Native Storage is now done via ansible. If you were used to `cns-deploy` in the past, that is now deprecated. You will need to edit the `/etc/ansible/hosts` file.

```
vi /etc/ansible/hosts
```

In this file you will need to add `glusterfs` under the `[OSEv3:children]` section. It should look something like this.

```
[OSEv3:children]
masters
nodes
etcd
glusterfs
```

Next, add the following variables under `[OSEv3:vars]` in order to setup Container Storage.

```
# CNS Storage
openshift_storage_glusterfs_namespace=glusterfs
openshift_storage_glusterfs_name=storage
openshift_storage_glusterfs_heketi_wipe=true
openshift_storage_glusterfs_wipe=true
openshift_storage_glusterfs_storageclass_default=true
openshift_storage_glusterfs_block_storageclass=true
openshift_storage_glusterfs_block_host_vol_size=50
```

More information on what these options do can be found [here](https://github.com/openshift/openshift-ansible/tree/master/roles/openshift_storage_glusterfs#role-variabless).

Pay special attention to `openshift_storage_glusterfs_block_host_vol_size`. This is how big to make the block storage pool to create block storage pvs. This value is effectively an upper limit on the size of glusterblock volumes unless you manually create larger GlusterFS block-hosting volumes.

The value (in GB) `50` is suitable for POC/testing installations.

Next, create the `[glusterfs]` section. This should include the 3 nodes that you want to be storage nodes. Here's an example.

```
[glusterfs]
app1.example.com glusterfs_ip=192.168.1.11 glusterfs_zone=1 glusterfs_devices='[ "/dev/sdc" ]'
app2.example.com glusterfs_ip=192.168.1.12 glusterfs_zone=2 glusterfs_devices='[ "/dev/sdc" ]'
app3.example.com glusterfs_ip=192.168.1.13 glusterfs_zone=3 glusterfs_devices='[ "/dev/sdc" ]'
```

Here is how the options break down

* `glusterfs_ip` - This is the IP of the node you are installing on. This is optional as the installer will, by default, take the node's IP address. This option __IS__ useful, however, if you have a "storage" network that is separate from the OpenShift SDN
* `glusterfs_zone` - These are, effectivley, "failure domains". Best practices is to have one in each zone and at least 3 zones.
* `glusterfs_devices` - These  are devices, in an array, that you want gluster to use for storage. These need to be raw devices.

**__NOTE__**: If you're using "standalone" glusterfs nodes (using nodes ONLY for storage); they STILL need to be in the `[nodes]` section!


Example...

```
# host group for nodes, includes region info
[nodes]
master1.cloud.chx openshift_node_group_name='node-config-master-infra'
app1.cloud.chx openshift_node_group_name='node-config-compute'
app2.cloud.chx openshift_node_group_name='node-config-compute'
app3.cloud.chx openshift_node_group_name='node-config-compute'
# Storage nodes still need to be in this section
storage1.example.com
storage2.example.com
storage3.example.com

[glusterfs]
storage1.example.com glusterfs_ip=192.168.1.11 glusterfs_zone=1 glusterfs_devices='[ "/dev/sdc" ]'
storage2.example.com glusterfs_ip=192.168.1.12 glusterfs_zone=2 glusterfs_devices='[ "/dev/sdc" ]'
storage3.example.com glusterfs_ip=192.168.1.13 glusterfs_zone=3 glusterfs_devices='[ "/dev/sdc" ]'
```

Next, you run the installer playbook.

```
ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/openshift-glusterfs/config.yml
```

**NOTE** If you run into trouble; run the uninstaller before attempting to install again.

```
ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/openshift-glusterfs/uninstall.yml
```

## Configure Heketi CLI

Export `HEKETI_CLI_SERVER` with the route (and admin user/password) so you can connect to the API

```
export HEKETI_CLI_SERVER=http://$(oc get routes heketi-storage --no-headers -n glusterfs | awk '{print $2}')
export HEKETI_ADMIN_KEY=$(oc get secrets heketi-storage-admin-secret -n glusterfs -o jsonpath='{.data.key}' | base64 -d)
```

I would save this in `/etc/bashrc`

Run the following command to see if everything is working

```
heketi-cli topology info
```

## Conclusion

You should now be setup for file and block storage

```
$ oc get storageclass
NAME                TYPE
gluster-block       gluster.org/glusterblock
gluster-container   kubernetes.io/glusterfs
```
