# Managing Security Context Constraints

In this lab you will learn how to control what a user can do in OpenShift. OpenShift provides security context constraints (SCCs) that control the actions that a pod can perform and what it has the ability to access.

Per https://docs.openshift.com/container-platform/3.6/admin_guide/manage_scc.html, Security context constraints (SCCs) allow administrators to control permissions for pods. SCCs allow addministrator to control the following:

1. Running of privileged containers.

2. Capabilities a container can request to be added.

3. Use of host directories as volumes.

4. The SELinux context of the container.

5. The user ID.

6. The use of host namespaces and networking.

7. Allocating an FSGroup that owns the pod’s volumes

8. Configuring allowable supplemental groups

9. Requiring the use of a read only root file system

10. Controlling the usage of volume types

11. Configuring allowable seccomp profiles


## Step #1

you can view the list of SCC via the following command

```
$ssh -i ocp-aws-key.pem ec2-user@<master-public-ip>
$sudo -i
$oc get scc
[root@ip-10-0-0-180 ~]# oc get scc
NAME               PRIV      CAPS      SELINUX     RUNASUSER          FSGROUP     SUPGROUP    PRIORITY   READONLYROOTFS   VOLUMES
anyuid             false     []        MustRunAs   RunAsAny           RunAsAny    RunAsAny    10         false            [configMap downwardAPI emptyDir persistentVolumeClaim projected secret]
hostaccess         false     []        MustRunAs   MustRunAsRange     MustRunAs   RunAsAny    <none>     false            [configMap downwardAPI emptyDir hostPath persistentVolumeClaim projected secret]
hostmount-anyuid   false     []        MustRunAs   RunAsAny           RunAsAny    RunAsAny    <none>     false            [configMap downwardAPI emptyDir hostPath nfs persistentVolumeClaim projected secret]
hostnetwork        false     []        MustRunAs   MustRunAsRange     MustRunAs   MustRunAs   <none>     false            [configMap downwardAPI emptyDir persistentVolumeClaim projected secret]
nonroot            false     []        MustRunAs   MustRunAsNonRoot   RunAsAny    RunAsAny    <none>     false            [configMap downwardAPI emptyDir persistentVolumeClaim projected secret]
privileged         true      [*]       RunAsAny    RunAsAny           RunAsAny    RunAsAny    <none>     false            [*]
restricted         false     []        MustRunAs   MustRunAsRange     MustRunAs   RunAsAny    <none>     false            [configMap downwardAPI emptyDir persistentVolumeClaim projected secret]
```

*You must have cluster-admin privileges to manage SCCs.*
More information on SCC https://docs.openshift.com/container-platform/3.6/architecture/additional_concepts/authorization.html#security-context-constraints

## Step #2

Explore the one of the scc

```
$ oc export scc restricted
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegedContainer: false
allowedCapabilities: []
apiVersion: v1
defaultAddCapabilities: []
fsGroup:
  type: MustRunAs
groups:
- system:authenticated
kind: SecurityContextConstraints
metadata:
  annotations:
    kubernetes.io/description: restricted denies access to all host features and requires
      pods to be run with a UID, and SELinux context that are allocated to the namespace.  This
      is the most restrictive SCC and it is used by default for authenticated users.
  creationTimestamp: null
  name: restricted
priority: null
readOnlyRootFilesystem: false
requiredDropCapabilities:
- KILL
- MKNOD
- SYS_CHROOT
- SETUID
- SETGID
runAsUser:
  type: MustRunAsRange
seLinuxContext:
  type: MustRunAs
supplementalGroups:
  type: RunAsAny
volumes:
- configMap
- downwardAPI
- emptyDir
- persistentVolumeClaim
- projected
- secret
```

## Step #3
You may modify the exported scc yaml to what you need and create a new Security Context Constraints. Here is an example of SCC as scc-test and save as scc-test.yaml.

```
kind: SecurityContextConstraints
apiVersion: v1
metadata:
  name: scc-test
allowPrivilegedContainer: true
requiredDropCapabilities:
- KILL
- MKNOD
- SYS_CHROOT
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: RunAsAny
fsGroup:
  type: RunAsAny
supplementalGroups:
  type: RunAsAny
users:
- admin
```

Now, you will run the following to create scc on the platform

```
oc create -f scc-test.yaml
```

Verify with `oc get scc scc=-test` and you should see the new scc is listed.

```
scc-test           true      []        RunAsAny    RunAsAny           RunAsAny    RunAsAny    <none>     false            [awsElasticBlockStore azureDisk azureFile cephFS cinder configMap downwardAPI emptyDir fc flexVolume flocker gcePersistentDisk gitRepo glusterfs iscsi nfs persistentVolumeClaim photonPersistentDisk portworxVolume projected quobyte rbd scaleIO secret vsphere]
```

## Step #4

Common use case will be to run the container as a privileged container. The default SCC for any pod running on OpenShift is using restricted SCC.

You can grant access to the default service account for the project.

```
oc adm policy add-scc-to-group anyuid -z default
```


Or, you will enable container images that runs as any uid that the images defined.

```
oc create serviceaccount mytestsa

oc adm policy add-scc-to-group anyuid -z mytestsa

oc patch dc/welcome -p '{"spec":{"template":{"spec":{"serviceAccountName": "mytestsa"}}}}'
```

