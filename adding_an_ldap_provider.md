# Adding an LDAP Provider

In this lab you will learn how to...

## Step 1

## Step 2

## Step X

## Step X

## Conclusion

# Apendix A - IPA On OpenShift

If you do not have an LDAP server (or cannot get access to one) you can deploy IPA on OpenShift

This assumes the following

* DNS for the domain is pointed at the OCP router
* Dynamic storage and/or a PV is available
* You have admin access to OCP

## Install FreeIPA  Template

Import the community version of FreeIPA template into OpenShift.

```
oc login -u system:admin
oc create -f https://raw.githubusercontent.com/freeipa/freeipa-container/master/freeipa-server-openshift.json -n openshift
```

Next, import the image as the user you will be deploying IPA as (example below)

```
oc login -u developer
oc import-image freeipa-server:latest --from=freeipa/freeipa-server:centos-7 --confirm
```

## Deploy FreeIPA

Now that you have the template and image imported; install FreeIPA on OpenShift.

First Create Service Account to run the image as root (yes it needs root to run)

```
oc project myproject
oc create serviceaccount useroot 
oc adm policy add-scc-to-user anyuid -z useroot
```

Next, login to your webconsole and create your ipa server with the following parameters. The defaults should be fine.

![freeipa-parameters](images/freeipa-parameters.png)

Once you are sure of the parameters; click "Create"

FreeIPA generates certificates/keys for itself so you might need to generate some activity on your system, if you look at the deployment logs and see the following

```
Configuring Kerberos KDC (krb5kdc). Estimated time: 30 seconds
  [1/9]: adding kerberos container to the directory
  [2/9]: configuring KDC
  [3/9]: initialize kerberos container
WARNING: Your system is running out of entropy, you may experience long delays
```

Just run this to speed it along (run ^c after a minute or two)
```
while true; do find /; done 
```

## Add LDAP User(s)

The fastest way to add ldap users is with `oc rsh`; so find out your pod name.

```
[root@ocp-aio ]# oc get pods
NAME                     READY     STATUS    RESTARTS   AGE
freeipa-server-1-dp1sv   1/1       Running   0          2h
```

Now `oc rsh` into this pod

```
[root@ocp-aio ]# oc rsh freeipa-server-1-dp1sv
sh-4.2#
```

Obtain a Kerberos ticket

```
sh-4.2# echo $PASSWORD | kinit admin@$(echo ${IPA_SERVER_HOSTNAME#*.} | tr '[:lower:]' '[:upper:]')
```

You should be able to show your IPA config now

```
sh-4.2# ipa config-show
  Maximum username length: 32
  Home directory base: /home
  Default shell: /bin/sh
  Default users group: ipausers
  Default e-mail domain: example.test
  Search time limit: 2
  Search size limit: 100
  User search fields: uid,givenname,sn,telephonenumber,ou,title
  Group search fields: cn,description
  Enable migration mode: FALSE
  Certificate Subject base: O=EXAMPLE.TEST
  Password Expiration Notification (days): 4
  Password plugin features: AllowNThash
  SELinux user map order: guest_u:s0$xguest_u:s0$user_u:s0$staff_u:s0-s0:c0.c1023$unconfined_u:s0-s0:c0.c1023
  Default SELinux user: unconfined_u:s0-s0:c0.c1023
  Default PAC types: nfs:NONE, MS-PAC
  IPA masters: ipa.example.test
  IPA CA servers: ipa.example.test
  IPA NTP servers: 
  IPA CA renewal master: ipa.example.test
```


Add a user using the following example

```
sh-4.2# ipa user-add homer --first=Homer --last=Simpson --gecos="Homer J. Simposon"  --email=homerj@mailinator.com --homedir=/home/homer --password
Password: 
Enter Password again to verify: 
------------------
Added user "homer"
------------------
  User login: homer
  First name: Homer
  Last name: Simpson
  Full name: Homer Simpson
  Display name: Homer Simpson
  Initials: HS
  Home directory: /home/homer
  GECOS: Homer J. Simposon
  Login shell: /bin/sh
  Principal name: homer@EXAMPLE.TEST
  Principal alias: homer@EXAMPLE.TEST
  Email address: homerj@mailinator.com
  UID: 50800003
  GID: 50800003
  Password: True
  Member of groups: ipausers
  Kerberos keys available: True
```

You should be able to list the users attributes

```
sh-4.2# ipa user-find homer
--------------
1 user matched
--------------
  User login: homer
  First name: Homer
  Last name: Simpson
  Home directory: /home/homer
  Login shell: /bin/sh
  Principal name: homer@EXAMPLE.TEST
  Principal alias: homer@EXAMPLE.TEST
  Email address: homerj@mailinator.com
  UID: 50800003
  GID: 50800003
  Account disabled: False
----------------------------
Number of entries returned 1
----------------------------

```

## Node Port Creation

Create a `nodePort` so I can access the LDAP server outside of the sdn network.

```yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: freeipa-server
    template: freeipa-server
  name: freeipa-server-np
spec:
  ports:
  - name: ldap-np
    nodePort: 32389
    port: 389
    protocol: TCP
    targetPort: 389
  selector:
    deploymentconfig: freeipa-server
  sessionAffinity: None
  type: LoadBalancer
```

Now run `oc create -f freeipa-nodeport.yaml` to create the service and the listener. A nodePort is basically a socket that all hosts in the cluster listen on and route trafic to the specified service. (NOTE: This is also handy for databases that live inside of OpenShift)

Next you can run `ldapsearch` to any node in the cluster on the specified port. I use the master for consistency.

```
ldapsearch -x -h ocp.example.com -p 32389 -b uid=homer,cn=users,cn=accounts,dc=example,dc=test
```
