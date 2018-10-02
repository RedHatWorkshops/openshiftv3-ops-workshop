# Removing a node
In this lab you will safely remove a node from the Openshift Cluster.  

```  
$ oc get nodes  
```  
## determine the node you want to remove, make it unschedulable  
```  
$ oc adm manage-node NODENAME  --schedulable=false  
```  

## ensure it is correctly labeled as unschedulable  
```  
$ oc get nodes  
```  
 e.g.  
ip-172-31-38-13.us-east-2.compute.internal    Ready     compute   23h       v1.10.0+b81c8f8  



## List Pods running on your node  
```  
$ oc adm manage-node NODENAME --list-pods
```

## evacuate pods  
```  
$ oc adm drain NODENAME --ignore-daemonsets --delete-local-data --force  
```  
## check that the node has no running pods  
```  
$ oc adm manage-node NODENAME --list-pods  
```
