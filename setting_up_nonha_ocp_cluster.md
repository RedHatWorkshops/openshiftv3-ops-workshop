# Setting Up Non-HA OpenShift Cluster

The installation process, specially host preparation steps are deliberately manual, although the whole preparation process can be ansible-ized and made extremely simple.

These labs are intended to teach what you would do if you are doing install step-by-step. 

#### Prerequisites

1. This lab expects that you have previously setup 4 VMs. 

	* 1 VM to use as OpenShift Master
	* 3 VMs to use as OpenShift Nodes

2. You need subscriptions to OpenShift 
3. DNS entries have been made and you have `MasterURL` and `Domain Name` 

## Preparing Hosts for Installation

*TBD: add explanations and cleanup*

### Setup SSH access for all the hosts from the Master

OpenShift installation is run using ansible playbook. You will have to select a host to run ansible playbook from and install ansible on that host. For this installation we will run ansible from the host that is designated as the master.

Ansible requires ssh access to each host where OpenShift is installed. Ansible also requires root access to install openshift. We can either use `sudo` or login to each host as `root`. In this lab, we will allow master host to ssh as root to all other hosts.

Steps to achieve this:

* SSH to Master

```
ssh -i ~/.ssh/ocp-aws-key.pem ec2-user@$PUBLIC_IP
```

* Become root

```
sudo bash
```

* Generate SSH Keys

```
# ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:KsreRKJ/Ui872nTSV9ACCUw4K/YIOdhBk/a2kNLMtXo root@ip-10-0-0-86.us-east-2.compute.internal
The key's randomart image is:
+---[RSA 2048]----+
| .o=o...         |
|  *.o .. .       |
|.B B .  o .      |
|B.O +    o       |
|o+++..  S .      |
| o.+E. . .       |
|.  o=.+ .        |
| o.*++..         |
| .*+++           |
+----[SHA256]-----+
```


* Get your public key and EXIT out of the master

```
# cat ~/.ssh/id_rsa.pub

Copy the results (ctrl+c)

# exit
$ exit
```

Now perform the following steps on each node (repeat for every node)

* SSH to the host and become root

```
$ ssh -i ocp-aws-key.pem ec2-user@10.0.0.152
Last login: Thu Sep 14 03:48:56 2017 from 10.0.0.86
$ sudo bash
```

* Open `/root/.ssh/authorized_keys` and append the public key copied from the master

```
# vi ~/.ssh/authorized_keys
append your id_rsa.pub value from the master to this file
```

Repeat the above steps for each node including master host. 

You are now ready to ssh as root from the master host to all other nodes without a password. In order to verify exit the node and log back into the master, become root by running `sudo bash`, and ssh to the node from the master as follows

```
$ ssh -i ~/.ssh/ocp-aws-key.pem ec2-user@$PUBLIC_IP
$ sudo bash
# ssh <<node ip address>>
```
**NOTE** Also do the above from master to master as ansible will ssh from master to master to run the playbook.

**SUMMARY:** We will be running ansible playbook from the master. We made sure master can ssh as root to other hosts without password.

### Host Preparation

Before we run openshift installation playbook, we have to make sure the openshift subscriptions are available on all the hosts and docker is installed. This section explains the steps.

#### Subscribe your hosts and enable repos

Let us first subscribe the hosts to RHN using subscription manager. You will need the username and password to Red Hat Network, to which OpenShift subscriptions are attached.

* Create two environment variables with your username and password.

```
# export RHN_USER=your username
# export RHN_PASSWORD=your password
```

* For convenience, create a file with name `hosts.txt` and add all your private ips to each host. We will use this file to repeat commands on all the hosts. 

```
# cat hosts.txt
10.0.0.86
10.0.0.44
10.0.0.66
10.0.0.157

```

* Register your hosts using subscription manager

```
# for i in $(cat hosts.txt); do echo $i; ssh $i "subscription-manager register --username=$RHN_USER --password=$RHN_PASSWORD"; done
```

* Find the subscription pool that includes OpenShift

```
# subscription-manager list --available --matches '*OpenShift*'
```
Note the pool id for the subscription pool that has "Red Hat OpenShift Container Platform"

* Attach all the hosts to this pool

```
# for i in $(cat hosts.txt); do echo $i; ssh $i "subscription-manager attach --pool 8a85f9815b5e42d9015b5e4afa4e0661"; done
```

**NOTE** Ensure all the attachments are successful. Sometimes, same pool id may not work on all the boxes. In such a case, you have to log into the box, find pool id and attach

* Disable all the repos and enable only the ones relevant to OpenShift i.e., 
	* rhel-7-server-rpms
	* rhel-7-server-extras-rpms
	* rhel-7-server-ose-3.6-rpms
	* rhel-7-fast-datapath-rpms

**NOTE** These RPMs change with each OpenShift release.

```
# for i in $(cat hosts.txt); do echo $i; ssh $i "subscription-manager repos --disable="*""; done

# for i in $(cat hosts.txt); do echo $i; ssh $i "subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-ose-3.6-rpms" \
    --enable="rhel-7-fast-datapath-rpms""; done
```


#### Install tools and utilities

* We will now install a few pre-requisite tools on all the hosts

```
for i in $(cat hosts.txt); do echo $i; ssh $i "yum install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct -y"; done
```
* Run a `yum update` on all the hosts

```
for i in $(cat hosts.txt); do echo $i; ssh $i "yum update -y"; done
```

* Install `atomic-openshift-utils`. This will provide the oc client and ansible.

```
for i in $(cat hosts.txt); do echo $i; ssh $i "yum install atomic-openshift-utils -y"; done
```

#### Install Docker and Setup Docker Storage

* Install docker on all the hosts

```
for i in $(cat hosts.txt); do echo $i; ssh $i "yum install docker-1.12.6 -y"; done
```

Once OpenShift is installed, the playbook will install atomic registry that runs as a Pod on the cluster. This registry pod is front-ended by a service. Whenever an application container is created in OpenShift, the container image is pushed into this registry. This registry is managed by OpenShift and is trusted within the cluster. So the pods running in the cluster don't need to authenticate with this registry to push and pull the images from this registry. So we want to setup docker to allow this registry as an insecure registry. The pods in the cluster call this registry by using its Service IP. The service IPs are in the range of `172.30.0.0/16` by default. In the next step we will set up so that a registry running on OpenShift can be reached without credentials i.e, insecure-registry. Note, that if your customer chooses the Service IP address range to be different from this default, then this IP address range needs to change.

* This step edits the file `/etc/sysconfig/docker` on each host to allow registry running in the range of `172.30.0.0/16` as an insecure-registry

```
for i in $(cat hosts.txt); do echo $i; ssh $i "sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16"' \
/etc/sysconfig/docker"; done
```

On Master

```
# fdisk -l
WARNING: fdisk GPT support is currently new, and therefore in an experimental phase. Use at your own discretion.

Disk /dev/xvda: 10.7 GB, 10737418240 bytes, 20971520 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: gpt
Disk identifier: 25D08425-708A-47D2-B907-1F0A3F769A90


#         Start          End    Size  Type            Name
 1         2048         4095      1M  BIOS boot parti 
 2         4096     20971486     10G  Microsoft basic 

Disk /dev/xvdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/xvdc: 64.4 GB, 64424509440 bytes, 125829120 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

for i in $(cat hosts.txt); do echo $i; ssh $i "fdisk -l"; done

Note: Disk /dev/xvdb: 21.5 GB
This is what we want to use as docker storage
Since we mounted additional disk with the same name while spinning up the VM, all of them should be with the same name /dev/xvdb


export MY_DKR_MOUNT=/dev/xvdb
# echo $MY_DKR_MOUNT
/dev/xvdb

for i in $(cat hosts.txt); do echo $i; ssh $i "cat <<EOF > /etc/sysconfig/docker-storage-setup 
DEVS=$MY_DKR_MOUNT
VG=docker-vg
EOF"; done


# for i in $(cat hosts.txt); do echo $i; ssh $i "cat /etc/sysconfig/docker-storage-setup"; done
10.0.0.86
DEVS=/dev/xvdb
VG=docker-vg
10.0.0.44
DEVS=/dev/xvdb
VG=docker-vg
10.0.0.66
DEVS=/dev/xvdb
VG=docker-vg
10.0.0.157
DEVS=/dev/xvdb
VG=docker-vg



# for i in $(cat hosts.txt); do echo $i; ssh $i "docker-storage-setup"; done
10.0.0.86
INFO: Volume group backing root filesystem could not be determined
INFO: Device node /dev/xvdb1 exists.
  Physical volume "/dev/xvdb1" successfully created.
  Volume group "docker-vg" successfully created
  Using default stripesize 64.00 KiB.
  Rounding up size to full physical extent 24.00 MiB
  Thin pool volume with chunk size 512.00 KiB can address at most 126.50 TiB of data.
  Logical volume "docker-pool" created.
  Logical volume docker-vg/docker-pool changed.
10.0.0.44
INFO: Volume group backing root filesystem could not be determined
INFO: Device node /dev/xvdb1 exists.
  Physical volume "/dev/xvdb1" successfully created.
  Volume group "docker-vg" successfully created
  Using default stripesize 64.00 KiB.
  Rounding up size to full physical extent 24.00 MiB
  Thin pool volume with chunk size 512.00 KiB can address at most 126.50 TiB of data.
  Logical volume "docker-pool" created.
  Logical volume docker-vg/docker-pool changed.
10.0.0.66
INFO: Volume group backing root filesystem could not be determined
INFO: Device node /dev/xvdb1 exists.
  Physical volume "/dev/xvdb1" successfully created.
  Volume group "docker-vg" successfully created
  Using default stripesize 64.00 KiB.
  Rounding up size to full physical extent 24.00 MiB
  Thin pool volume with chunk size 512.00 KiB can address at most 126.50 TiB of data.
  Logical volume "docker-pool" created.
  Logical volume docker-vg/docker-pool changed.
10.0.0.157
INFO: Volume group backing root filesystem could not be determined
INFO: Device node /dev/xvdb1 exists.
  Physical volume "/dev/xvdb1" successfully created.
  Volume group "docker-vg" successfully created
  Using default stripesize 64.00 KiB.
  Rounding up size to full physical extent 24.00 MiB
  Thin pool volume with chunk size 512.00 KiB can address at most 126.50 TiB of data.
  Logical volume "docker-pool" created.
  Logical volume docker-vg/docker-pool changed.


Verify your configuration. You should have a dm.thinpooldev value in the /etc/sysconfig/docker-storage file and a docker-pool logical volume:


# for i in $(cat hosts.txt); do echo $i; ssh $i "cat /etc/sysconfig/docker-storage"; done
10.0.0.86
DOCKER_STORAGE_OPTIONS="--storage-driver devicemapper --storage-opt dm.fs=xfs --storage-opt dm.thinpooldev=/dev/mapper/docker--vg-docker--pool --storage-opt dm.use_deferred_removal=true --storage-opt dm.use_deferred_deletion=true "
10.0.0.44
DOCKER_STORAGE_OPTIONS="--storage-driver devicemapper --storage-opt dm.fs=xfs --storage-opt dm.thinpooldev=/dev/mapper/docker--vg-docker--pool --storage-opt dm.use_deferred_removal=true --storage-opt dm.use_deferred_deletion=true "
10.0.0.66
DOCKER_STORAGE_OPTIONS="--storage-driver devicemapper --storage-opt dm.fs=xfs --storage-opt dm.thinpooldev=/dev/mapper/docker--vg-docker--pool --storage-opt dm.use_deferred_removal=true --storage-opt dm.use_deferred_deletion=true "
10.0.0.157
DOCKER_STORAGE_OPTIONS="--storage-driver devicemapper --storage-opt dm.fs=xfs --storage-opt dm.thinpooldev=/dev/mapper/docker--vg-docker--pool --storage-opt dm.use_deferred_removal=true --storage-opt dm.use_deferred_deletion=true "


# for i in $(cat hosts.txt); do echo $i; ssh $i "lvs";done
10.0.0.86
  LV          VG        Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  docker-pool docker-vg twi-a-t--- <7.95g             0.00   0.15                            
10.0.0.44
  LV          VG        Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  docker-pool docker-vg twi-a-t--- <7.95g             0.00   0.15                            
10.0.0.66
  LV          VG        Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  docker-pool docker-vg twi-a-t--- <7.95g             0.00   0.15                            
10.0.0.157
  LV          VG        Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  docker-pool docker-vg twi-a-t--- <7.95g             0.00   0.15
  
  
# for i in $(cat hosts.txt); do echo $i; ssh $i "systemctl enable docker; systemctl start docker"; done
10.0.0.86
Created symlink from /etc/systemd/system/multi-user.target.wants/docker.service to /usr/lib/systemd/system/docker.service.
10.0.0.44
Created symlink from /etc/systemd/system/multi-user.target.wants/docker.service to /usr/lib/systemd/system/docker.service.
10.0.0.66
Created symlink from /etc/systemd/system/multi-user.target.wants/docker.service to /usr/lib/systemd/system/docker.service.
10.0.0.157
Created symlink from /etc/systemd/system/multi-user.target.wants/docker.service to /usr/lib/systemd/system/docker.service.

for i in $(cat hosts.txt); do echo $i; ssh $i "sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16 --log-opt max-size=1M --log-opt max-file=3"' \
/etc/sysconfig/docker"; done

for i in $(cat hosts.txt); do echo $i; ssh $i "systemctl restart docker"; done
```

#### Set up storage for NFS Persistent Volumes

On the Master Host:

```
# fdisk -l
WARNING: fdisk GPT support is currently new, and therefore in an experimental phase. Use at your own discretion.

Disk /dev/xvda: 10.7 GB, 10737418240 bytes, 20971520 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: gpt
Disk identifier: 25D08425-708A-47D2-B907-1F0A3F769A90


#         Start          End    Size  Type            Name
 1         2048         4095      1M  BIOS boot parti 
 2         4096     20971486     10G  Microsoft basic 

Disk /dev/xvdb: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x00060d83

    Device Boot      Start         End      Blocks   Id  System
/dev/xvdb1            2048    41943039    20970496   8e  Linux LVM

Disk /dev/xvdc: 64.4 GB, 64424509440 bytes, 125829120 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```
Note `/dev/xvdc` is the volume we mounted as an extra disk for Persistent Storage.

```
# pvcreate /dev/xvdc
  Physical volume "/dev/xvdc" successfully created.


# vgcreate vg-storage /dev/xvdc
  Volume group "vg-storage" successfully created  

# lvcreate -n lv-storage -l +100%FREE vg-storage
  Logical volume "lv-storage" created.

# mkfs.xfs /dev/vg-storage/lv-storage
meta-data=/dev/vg-storage/lv-storage isize=512    agcount=4, agsize=3931904 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=15727616, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=7679, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0

# mkdir /exports


# cp /etc/fstab fstab.bak

# cat /etc/fstab

#
# /etc/fstab
# Created by anaconda on Tue Jul 11 15:57:39 2017
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
UUID=de4def96-ff72-4eb9-ad5e-0847257d1866 /                       xfs     defaults        0 0


# echo "/dev/vg-storage/lv-storage /exports xfs defaults 0 0" >> /etc/fstab

# cat /etc/fstab

#
# /etc/fstab
# Created by anaconda on Tue Jul 11 15:57:39 2017
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
UUID=de4def96-ff72-4eb9-ad5e-0847257d1866 /                       xfs     defaults        0 0
/dev/vg-storage/lv-storage /exports xfs defaults 0 0
```

**Be extra careful with the above change** Test with `mount -a` after this change to make sure the mount is successful.

```
# mount -a

#  df -h
Filesystem                           Size  Used Avail Use% Mounted on
/dev/xvda2                            10G  2.1G  8.0G  21% /
devtmpfs                             7.8G     0  7.8G   0% /dev
tmpfs                                7.8G     0  7.8G   0% /dev/shm
tmpfs                                7.8G   25M  7.8G   1% /run
tmpfs                                7.8G     0  7.8G   0% /sys/fs/cgroup
tmpfs                                1.6G     0  1.6G   0% /run/user/1000
/dev/mapper/vg--storage-lv--storage   60G   33M   60G   1% /exports
```
Now we are ready to install OpenShift.

## Installing OpenShift

#### Edit the Hosts file
Use your favorite editor to open `/etc/ansible/hosts` file

* Replace the contents of this file with what is listed below
* Update PrivateIp addresses of all nodes (including master) in the [nodes] section and master in the [master]
* We will install nfs on master. So include PrivateIP of master for [nfs]
* Update the value given by the instructor for openshift_master_default_subdomain (example: apps.opsday.ocpcloud.com)
* Update the value given by the instructor for openshift_public_hostname (example: master.opsday.ocpcloud.com)

```
# Create an OSEv3 group that contains the masters and nodes groups
[OSEv3:children]
masters
nodes
nfs

# Set variables common for all OSEv3 hosts
[OSEv3:vars]
# SSH user, this user should allow ssh based auth without requiring a password
ansible_ssh_user=root

# If ansible_ssh_user is not root, ansible_sudo must be set to true
#ansible_sudo=true
#ansible_become=yes

# To deploy origin, change deployment_type to origin
deployment_type=openshift-enterprise

openshift_clock_enabled=true

# Disabling for smaller instances used for Demo purposes. Use instances with minimum disk and memory sizes required by OpenShift
openshift_disable_check=disk_availability,memory_availability

#Enable network policy plugin. This is currently Tech Preview
os_sdn_network_plugin_name='redhat/openshift-ovs-networkpolicy'

openshift_master_default_subdomain=apps.opsday.ocpcloud.com
osm_default_node_selector="region=primary"
openshift_hosted_router_selector='region=infra'
openshift_registry_selector='region=infra'

## The two parameters below would be used if you want API Server and Master running on 443 instead of 8443. 
## In this cluster 443 is used by router, so we cannot use 443 for master
#openshift_master_api_port=443
#openshift_master_console_port=443


openshift_hosted_registry_storage_nfs_directory=/exports


# Metrics
openshift_hosted_metrics_deploy=true
openshift_hosted_metrics_storage_kind=nfs
openshift_hosted_metrics_storage_access_modes=['ReadWriteOnce']
openshift_hosted_metrics_storage_nfs_directory=/exports
openshift_hosted_metrics_storage_nfs_options='*(rw,root_squash)'
openshift_hosted_metrics_storage_volume_name=metrics
openshift_hosted_metrics_storage_volume_size=10Gi
openshift_hosted_metrics_storage_labels={'storage': 'metrics'}
openshift_metrics_image_version=v3.6
openshift_hosted_metrics_public_url=https://hawkular-metrics.apps.devday.ocpcloud.com/hawkular/metrics

# Logging
openshift_hosted_logging_deploy=true
openshift_logging_install_logging=true
openshift_hosted_logging_storage_kind=nfs
openshift_hosted_logging_storage_access_modes=['ReadWriteOnce']
openshift_hosted_logging_storage_nfs_directory=/exports
openshift_hosted_logging_storage_nfs_options='*(rw,root_squash)'
openshift_hosted_logging_storage_volume_name=logging
openshift_hosted_logging_storage_volume_size=10Gi
openshift_master_logging_public_url=https://kibana.apps.devday.ocpcloud.com
openshift_hosted_logging_storage_labels={'storage': 'logging'}
openshift_hosted_logging_deployer_version=v3.6
openshift_logging_image_version=v3.6

# Registry
openshift_hosted_registry_storage_kind=nfs
openshift_hosted_registry_storage_access_modes=['ReadWriteMany']
openshift_hosted_registry_storage_nfs_directory=/exports
openshift_hosted_registry_storage_nfs_options='*(rw,root_squash)'
openshift_hosted_registry_storage_volume_name=registry
openshift_hosted_registry_storage_volume_size=10Gi

# enable htpasswd authentication
openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/openshift/openshift-passwd'}]

# host group for masters
[masters]
10.0.0.86

[nfs]
10.0.0.86

# host group for nodes, includes region info
[nodes]
10.0.0.86 openshift_hostname=10.0.0.86 openshift_node_labels="{'region': 'infra', 'zone': 'default'}"  openshift_scheduleable=true openshift_public_hostname=master.opsday.ocpcloud.com 
10.0.0.66 openshift_hostname=10.0.0.66 openshift_node_labels="{'region': 'primary', 'zone': 'east'}" 
10.0.0.157 openshift_hostname=10.0.0.157 openshift_node_labels="{'region': 'primary', 'zone': 'west'}" 
10.0.0.44 openshift_hostname=10.0.0.44 openshift_node_labels="{'region': 'primary', 'zone': 'central'}" 
```

#### Run the playbook
```
ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml
```
Playbook runs for about 15 mins and will show logs. At the end of the run you will see the results as follows

```
...

PLAY RECAP ***************************************************************************************************************************************************
10.0.0.157                 : ok=241  changed=57   unreachable=0    failed=0   
10.0.0.44                  : ok=241  changed=57   unreachable=0    failed=0   
10.0.0.66                  : ok=241  changed=57   unreachable=0    failed=0   
10.0.0.86                  : ok=961  changed=255  unreachable=0    failed=0   
localhost                  : ok=10   changed=0    unreachable=0    failed=0   
```

## Post Installation Checks

#### Add a User

```
touch /etc/openshift/openshift-passwd
```

```
htpasswd /etc/openshift/openshift-passwd veer
```

#### Run Diagnostics

```
# oadm diagnostics
```






