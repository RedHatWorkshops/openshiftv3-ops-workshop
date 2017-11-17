# Using OOTB Cockpit 
In this lab you will learn how to access OOTB cockpit.
By default, cockpit is installed as part of advance installation. The default ansible hosts file for enabling cockpit is `osm_use_cockpit=true`.

## Step 1
You will need to create a system user on master node to access the cockpit.

````
$ sudo -i
$ useradd -g wheel cockpituser
$ passwd cockpituser
$ cp -r /root/.kube /home/cockpituser/.kube
$ chown -R cockpituser:wheel /home/cockpituser/.kube

````
## Step 2
You can now login as cockpituser from cockpit console

1. Open broswer location: https://<master_fqdn>:9090/
2. login using the username and password created in step 1
