# Idling Applications

In this lab you will learn how to idle applications in order to save unused resources.

## Step 1
Create a new project named idling:
```
# oc new-project idling
```
```
Now using project "idling" on server "https://ocp.thelinuxshack.com:8443".

You can add applications to this project with the 'new-app' command. For example, try:

    oc new-app centos/ruby-22-centos7~https://github.com/openshift/ruby-ex.git

to build a new example application in Ruby.
```

## Step 2
Create an application in your new project:
```
# oc new-app openshift/hello-openshift
```
```
--> Found Docker image 61a97af (43 minutes old) from Docker Hub for "openshift/hello-openshift"

    * An image stream will be created as "hello-openshift:latest" that will track this image
    * This image will be deployed in deployment config "hello-openshift"
    * Ports 8080/tcp, 8888/tcp will be load balanced by service "hello-openshift"
      * Other containers can access this service through the hostname "hello-openshift"

--> Creating resources ...
    imagestream "hello-openshift" created
    deploymentconfig "hello-openshift" created
    service "hello-openshift" created
--> Success
    Run 'oc status' to view your app.
```

## Step 3
Expose the application:
```
# oc expose svc hello-openshift
```
```
route "hello-openshift" exposed
```
Now you can access the application via your browser or curl and you should see the message:
```
Hello OpenShift!
```

## Step 4
Here's the moment you've been waiting for. Now we're going to idle the application:
```
# oc idle hello-openshift
```
```
The service "hello/hello-openshift" has been marked as idled 
The service will unidle DeploymentConfig "hello/hello-openshift" to 1 replicas once it receives traffic 
DeploymentConfig "hello/hello-openshift" has been idled 
```
Once successfully idled, you'll notice that the pod has disappeared. The ouput of the `oc get pods` command will return nothing:
```
# oc get pods -n idle
```

## Step 5
You can now unidle the application. Applications will unidle if once traffic is detected. Now simply open a browser and hit the application.


You'll notice a slight delay on the response. This depends on how long the pod and the application within the container take to start up. In this case, it should be a second or two:
```
Hello OpenShift!
```
Now if you take a look at your pods again, you'll see the newly spawed pod Running:
```
# oc get pods
```
```
NAME                      READY     STATUS    RESTARTS   AGE
hello-openshift-1-8lvjg   1/1       Running   0          5s
```

## Conclusion

In this lab you learned how to idle an application. This can be a powerful feature to ultimately save precious unused resources. These unused resources can then be distributed to other active workloads.
