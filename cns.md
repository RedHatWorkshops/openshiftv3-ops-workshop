# Container Native Storage
You can install GlusterFS in a container and run it on OpenShift. Furthermore you can use `heketi` to dynamically create volumes to use.

[Official Docs](https://access.redhat.com/documentation/en-us/red_hat_gluster_storage/3.3/html-single/container-native_storage_for_openshift_container_platform/)

## Prereqs

1) A fully functioning OCP v3.6 environment
2) At least 3 nodes (minimum) with at least 100GB raw/unformated disc attached to them
3) If you have a POC env with one master and two nodes; you're going to __*need*__ to use the master as a node
4) Fully functioning DNS (forward AND reverse)
5) Access to the entitlement that provides `rh-gluster-3-for-rhel-7-server-rpms`

Thigs to keep in mind (*DO NOT SKIP OVER THIS; PLEASE READ*)

* Ensure that the Trusted Storage Pool is not scaled beyond 100 volumes per 3 nodes per 32G of RAM.
* A trusted storage pool consists of a minimum of 3 nodes/peers.
* Distributed-Three-way replication is the only supported volume type. 

## Ansible Users

Included in this repo is a playbook that will prepare your nodes using your existing ansible host file.

```
ansible-playbook ./resources/cns-host-prepare.yaml
```

*NOTE:* If you're using your `master` as a CNS node, it needs to be in the `[node]` section of your ansible host file (e.g. `/etc/ansible/hosts`)

## Create OpenShift Project

Create a project for your gluster node

*IF* you have 3 nodes run:

```
oc adm new-project glusterfs
oc project glusterfs
```

If you only have 2 nodes and *need* to use your master as a node; run:

```
oc adm manage-node ose3-master.example.com --schedulable
oc adm new-project glusterfs --node-selector=""
oc project glusterfs
```

Next, enable privileged containers on this project

```
oc adm policy add-scc-to-user privileged -z default -n glusterfs
```


## Deploying Container-Native Storage

You must first provide a topology file for heketi which describes the topology of the Red Hat Gluster Storage nodes and their attached storage devices.
A sample, formatted topology file (topology-sample.json) is installed with the `heketi-client` package in the `/usr/share/heketi/` directory.

This is the config I used on my AWS instance (I'm using my master as a node) saved as `cns.json`:

```json
{
    "clusters": [
        {
            "nodes": [
                {
                    "node": {
                        "hostnames": {
                            "manage": [
                                "node1.example.com"
                            ],
                            "storage": [
                                "172.31.19.167"
                            ]
                        },
                        "zone": 1
                    },
                    "devices": [
                        "/dev/xvdf"
                    ]
                },
                {
                    "node": {
                        "hostnames": {
                            "manage": [
                                "node2.example.com"
                            ],
                            "storage": [
                                "172.31.19.240"
                            ]
                        },
                        "zone": 2
                    },
                    "devices": [
                        "/dev/xvdf"
                    ]
                },
                {
                    "node": {
                        "hostnames": {
                            "manage": [
                                "node3.example.com"
                            ],
                            "storage": [
                                "172.31.24.220"
                            ]
                        },
                        "zone": 3
                    },
                    "devices": [
                        "/dev/xvdf"
                    ]
                }
            ]
        }
    ]
}
```

__Things to note__

* The `manage` is the hostname (REQUIRED) that openshift sees (i.e. `oc get nodes`) and the `storage` is the ip of that host (REQUIRED)
* The device `/dev/xvdf` is a *RAW* storage deviced attached and unformated (no partitions, no LVM flags, nothing). 
* I've ran into trouble with drives less than 100GB...the ones I used are 250GB each. If you're going to use block. You'll need the 250GB.
* Remeber to increment your `zone` number in the json or you're going to have a bad time

Install with

```
cns-deploy -n glusterfs -g -y -c oc \
--object-account object-vol --object-user object-admin --object-password itsmine \
--block-host 100 cns.json
```

Command options are

* `-n` : namespace/project name
* `-g` : Deploy GlusterFS nodes
* `-y` : Assume "yes" to questions
* `-c` : The command line utility to use (you can use `oc` or `kubectl`)
* `cns.json` : Path to the topology JSON file
* `--object-*` : These options (self explanitory) set up configurations specific to object storage
* `--block-host`: This sets up a "pool" of storage, in GB, to use for block storage (i.e. This is how much storage you're allocating for block storage).

## Configure Heketi CLI

Export `HEKETI_CLI_SERVER` with the route so you can connect to the API

```
export  HEKETI_CLI_SERVER=http://$(oc get routes heketi --no-headers -n glusterfs | awk '{print $2}')
```

I would save this in `/etc/bashrc`

Run the following command to see if everything is working

```
heketi-cli topology info
```

## Dynamically Creating PVs from PVCs

You need to first create a `storageClass` (it might be different now - look [here](https://docs.openshift.com/container-platform/latest/install_config/storage_examples/gluster_dynamic_example.html#create-a-storage-class-for-your-glusterfs-dynamic-provisioner) )

```yaml
apiVersion: storage.k8s.io/v1beta1
kind: StorageClass
metadata:
  name: gluster-container
provisioner: kubernetes.io/glusterfs
parameters:
  resturl: "http://heketi-glusterfs.apps.example.com"
  restuser: "admin"
  secretNamespace: "default"
  secretName: "heketi-secret"
  volumetype: "replicate:3"
```

Things to note

* `resturl`  : The route you exported earlier (this can be the `svc` ip address if you want)
* `restuser` : The user to hit the API with (by default it's `admin` so stick with that)
* `secretNamespace` : Namespace where your secret is (more on that below)
* `secretName` : The name of that secret
* `volumetype` : It specifies the volume type that is being used. Distributed-Three-way replication is the only supported volume type. You can also put `volumetype: none` for testing purposes
* If you'd like to make this a default storage class; add an annotation. Here's an [example](resources/gluster-default-storageclass.yaml)

Now, create a secret; by default heketi uses "My Secret" as the password so run...

```
echo -n "My Secret" | base64
TXkgU2VjcmV0
```

Now use that output to create the secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: heketi-secret
  namespace: default
data:
  key: TXkgU2VjcmV0
type: kubernetes.io/glusterfs
```

Load both of these files

```
oc create -f glusterfs-secret.yaml
oc create -f glusterfs-storageclass.yaml
```

If you want to use your CNS installation as the default storage provider; annotate accordingly!
```
oc annotate storageclass gluster-container storageclass.beta.kubernetes.io/is-default-class="true"
```

## Setting up block storage provisioner

CNS uses `iscsi` for it's block storage. You need to prepare *all* your masters/nodes to use `iscsi`. I have included an ansible playbook to do most of this work for you.

```
ansible-playbook ./resources/host-prepare-block.yaml
```

Create a secret file to use the provisioner REST url (similar to what you did above).

```
echo -n "mypassword" | base64
bXlwYXNzd29yZA==
```

Now create the secret YAML file

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: heketi-secret-block
  namespace: default
data:
  key: bXlwYXNzd29yZA==
type: gluster.org/glusterblock
```

After that, create the `storageClass` similar to what you created above.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
 name: gluster-block
provisioner: gluster.org/glusterblock
parameters:
 resturl: "http://heketi-storage-project.apps.example.com"
 restuser: "admin"
 restsecretnamespace: "default"
 restsecretname: "heketi-secret-block"
 hacount: "3"
 clusterids: "7ec3fb839bb0488a3377621c7112b39e"
 chapauthenabled: "true"
```

NOTE: You get your `clusterid` from the heketi cli

```
$ heketi-cli cluster list
Clusters:
Id:7ec3fb839bb0488a3377621c7112b39e [file][block]
```

Once, you have both of these YAML files ready, you can import them in.

```
$ oc create -f block-secret.yaml
secret "heketi-secret-block" created

$ oc create -f glusterfs-block-sc.yaml
storageclass "gluster-block" created
```

## Conclusion

You should now be setup for file, block, and object storage

```
$ oc get storageclass
NAME                TYPE
gluster-block       gluster.org/glusterblock
gluster-container   kubernetes.io/glusterfs
glusterfs-for-s3    kubernetes.io/glusterfs
```
