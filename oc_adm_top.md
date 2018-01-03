# Using `oc adm top` to Present Platform Usage Statistics

The `oc adm top` command analyzes resources managed by the platform and presents current usage statistics. The information provided by this command gives operations valueable insight into cluster capacity.

## Step 1

Ensure that you're logged into the cluster with the cluster-admin cluster role.

```# oc login -u system:admin ```

## Step 2

Now lets see what `oc adm top` has to offer by listing it's `--help` output

``` # oc adm top --help ```
``` 
Show usage statistics of resources on the server 

This command analyzes resources managed by the platform and presents current usage statistics.

Usage:
  oc adm top [options]

Available Commands:
  images       Show usage statistics for Images
  imagestreams Show usage statistics for ImageStreams
  node         Display Resource (CPU/Memory/Storage) usage of nodes
  pod          Display Resource (CPU/Memory/Storage) usage of pods

Use "oc adm <command> --help" for more information about a given command.
Use "oc adm options" for a list of global command-line options (applies to all commands).
```

## Step 3

Now lets see how our all our nodes are doing.

```# oc adm top nodes ```
```
NAME                            CPU(cores)   CPU%      MEMORY(bytes)   MEMORY%   

master.example.com    600m         30%       11560Mi         73%       
node1.example.com     98m          2%        10306Mi         65%       
node2.example.com     287m         7%        6495Mi          41%  
node3.example.com     100m         2%        9515Mi          60%       

```

## Step 4

Next lets look at what sort of capacity our pods are using in our logging project.

```# oc adm top pods -n logging ```
```
NAME                                      CPU(cores)   MEMORY(bytes)   
logging-fluentd-2mcgk                     11m          115Mi           
logging-fluentd-nqlsk                     40m          108Mi           
logging-es-data-master-vprbj3wm-1-zrcwp   205m         5117Mi          
logging-kibana-1-rg7rr                    8m           104Mi           
logging-fluentd-8ltfv                     11m          88Mi            
logging-curator-1-txd6r                   0m           17Mi            
logging-fluentd-k9g7m                     11m          126Mi           
```

You can also list all the pods in your whole cluster by using the `--all-namespaces` switch.

```# oc adm top pods --all-namesapaces ```


## Conclusion

In this lab you learned how to use `oc adm top` to analyze resources managed by the platform and present current usage statistics.
