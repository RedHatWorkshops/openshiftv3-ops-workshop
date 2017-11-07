# Deploying Metrics

In this lab you will learn how to deploy metrics. Deployment of metrics need a backend storage for this. Please see either the [Persistant Volume Claim](creating_persistent_volume.md) or the [Container Native Storage](cns.md) labs before doing this lab.

## Step 1

Metrics needs a backend storage for the database. You'll need a `pvc` before you proceed. 

Below is an example using [cns](cns.md) as the backend storage (your `pvc` might differ).
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
 name: metrics-storage
 annotations:
  volume.beta.kubernetes.io/storage-class: gluster-block
spec:
 accessModes:
  - ReadWriteOnce
 resources:
   requests:
     storage: 20Gi
```

Create this claim.

```
$ oc create -f metrics-storage-pvc.yaml
persistentvolumeclaim "metrics-storage" created
```

Wait for it to go from "Pending" to "

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
