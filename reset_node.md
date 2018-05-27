# Removing a node
In this lab you will reset a node in the Openshift Cluster.

## Run the following command to mark the node as unschedulable:
$ oc adm manage-node <node> --schedulable=false

## Run the following command to shut down Docker and the atomic-openshift-node service:
$ systemctl stop docker atomic-openshift-node

## Run the following command to remove the local volume directory:
$ rm -rf /var/lib/origin/openshift.local.volumes

## Remove the /var/lib/docker directory:
$ rm -rf /var/lib/docker

## Run the following command to reset the Docker storage:
$ docker-storage-setup --reset

## Run the following command to recreate the Docker storage:
$ docker-storage-setup

## Recreate the /var/lib/docker directory:
$ mkdir /var/lib/docker

## Run the following command to restart Docker and the atomic-openshift-node service:
$ systemctl start docker atomic-openshift-node

## Run the following command to mark the node as schedulable:
$ oc adm manage-node <node> --schedulable=true
