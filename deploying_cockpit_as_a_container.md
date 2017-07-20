# Deploying Cockpit As A Container

In this lab you will learn how to deploy cockpit as a container. This is useful for when you have an installation (like a cloud based install) where the 'root' user is locked, does not have a password, or is otherwise unavailable.

## Step 1 - Create An Admin User

This step has two outcomes. It gives you a user that you can view information about your cluster, and it has the side effect of giving you an "admin" user (i.e. like a "root" user).

If you already have a user in mind or are going to be using an LDAP user you can skip the below command. Otherwise, create the `ocp-admin` using the below command.

```
htpasswd /etc/origin/openshift-passwd ocp-admin
```

Next (whether you are using LDAP or this `ocp-admin` user), grant the `cluster-admin` role to this user for the entire cluster.

```
oc adm policy add-cluster-role-to-user cluster-admin ocp-admin
```

## Step 2

Now that we have our user; we will create a project to house the `cockpit` interface.

```
oc new-project cockpit
oc project cockpit
```

Next, we will be using the [official cockpit](https://github.com/charlesrichard/cockpit/tree/master/containers) repoistory to create our application. This repo provides an [OpenShift Template](https://github.com/cockpit-project/cockpit/blob/master/containers/openshift-cockpit.template) for us to use. We will process this template using customer parameters.

```
cd ~
curl -O https://raw.githubusercontent.com/cockpit-project/cockpit/master/containers/openshift-cockpit.template
oc process --param="COCKPIT_KUBE_URL=https://cockpit.apps.example.com/" \
--param="OPENSHIFT_OAUTH_PROVIDER_URL=https://ocp.example.com:8443" \
--param=COCKPIT_KUBE_INSECURE="false" \
-f openshift-cockpit.template | oc create -f -
```

Few things to note

	* `COCKPIT_KUBE_INSECURE` - I am setting this to `false` because I want this to go through SSL
	* `COCKPIT_KUBE_URL` - This is the URL for the cockpit route I want to use (note the use of `https://` since I set `COCKPIT_KUBE_INSECURE="false"`)
	* `OPENSHIFT_OAUTH_PROVIDER_URL` - This should be set to your master console URL. 

## Step X

## Step X

## Conclusion
