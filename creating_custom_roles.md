# Creating Custom Roles

In this lab you will learn how to create a custom role. As you saw in the previous lab; operators can customize the level of access that are granted to each user of the platform. Access can be granted at a local (project) or cluster level. Several default roles are provided by the platform and include:

* admin

* basic-user

* cluster-admin

* cluster-status

* edit

* self-provisioner

* view

A full description of these roles and the concepts provided by roles can be found in the [Roles section of the documentation](https://docs.openshift.com/container-platform/latest/architecture/additional_concepts/authorization.html#roles).

In this lab we will be doing the most common requested role.

> "I do not want a user to be able to remote shell into their container"

## Step 1

The easiest way to creating a custom role, is to find an existing role that closely matches what you want, and edit it. In the case of "not being able to rsh", the role `edit` is a good canidate.

Export this role

```
oc export clusterrole edit > edit_role.yaml
```

If you take a look at this file, you will see the following resource defined

```
  - pods/exec
```

This means that this role allows you execute commands (i.e. `exec /bin/bash`) into a container.

## Step 2

Make a copy of this exported role

```
cp edit_role.yaml edit_no_rsh_role.yaml
```

There is really only two things to change in the file. The first is the `name`; make sure it is unique to the environment; I named mine `name: edit_no_rsh`. Next is to remove the `- pods/exec`. 

Once you have made those changes; run `diff` on the files; it should look like this

```
diff --side-by-side --suppress-common-lines edit_role.yaml edit_no_rsh_role.yaml 

  name: edit						      |	  name: edit_no_rsh
  - pods/exec						      <
```

Load this into OpenShift

```
oc create -f edit_no_rsh_role.yaml 
clusterrole "edit_no_rsh" created
```

## Step 3

Now you can assign this new role to a user. Test this by assigning `user-1` to a project using this role (create one if you do not have one).


```
oc policy add-role-to-user edit_no_rsh user-1 -n myproject
role "edit_no_rsh" added: "user-1"
```

Login to the webui and try and run terminal commands to test that it is working.

![image](images/user1-norsh.png)

## Conclusion

In this lab you learned how to create a custom role and assigned it to a user.
