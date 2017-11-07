# Deploying Metrics

In this lab you will learn how to deploy metrics. This lab leverages dynamic storage provisioning, so please make sure you have a dymanic provisioner available.

## Step 1

Metrics needs a block storage system for storage, make sure you have a block storage provisioner available.

```
$ oc get storageclass
NAME                TYPE
gluster-block       gluster.org/glusterblock
gluster-container   kubernetes.io/glusterfs
glusterfs-for-s3    kubernetes.io/glusterfs
```

Annotate the block storage provisioner as the "default" `storageClass`.

```
$ oc annotate storageclass gluster-block storageclass.beta.kubernetes.io/is-default-class="true"
storageclass "gluster-block" annotated
```

Your block provisioner should be listed as the default

```
$ oc get storageclass
NAME                      TYPE
gluster-block (default)   gluster.org/glusterblock
gluster-container         kubernetes.io/glusterfs
glusterfs-for-s3          kubernetes.io/glusterfs
```

## Step 2

Using the ansible playbook provided by OpenShift, deploy the metrics stack and make you change these options to what makes sense to you.

```
ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/byo/openshift-cluster/openshift-metrics.yml \
-e openshift_metrics_install_metrics=True \
-e openshift_metrics_hawkular_hostname=hawkular.apps.example.com \
-e openshift_metrics_cassandra_storage_type=dynamic \
-e openshift_metrics_cassandra_pvc_size=25Gi
```

This will take a while.

## Step X

## Step X

## Conclusion

In this lab you learned how to ...
