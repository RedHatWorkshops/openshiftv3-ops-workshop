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
```
ssh to master

ssh -i ~/.ssh/ocp-aws-key.pem ec2-user@$PUBLIC_IP

become root
sudo bash

Run
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

Get your public key
# cat ~/.ssh/id_rsa.pub

Copy the results (ctrl+c)

#exit

Now ssh to each node and do the following
$ ssh -i ocp-aws-key.pem ec2-user@10.0.0.152
Last login: Thu Sep 14 03:48:56 2017 from 10.0.0.86
$ sudo bash
# vi ~/.ssh/authorized_keys
append your id_rsa.pub value from the master to this file
Now it will allow you to ssh as root from master

To verify exit and go back to master
become root 
ssh to your node

Repeat on all hosts including master.
You should be able to SSH from Master to Master as root with no password.

Verify by logging onto each host
# ssh <<ipaddress>>

Become root on master again
```

### Host Preparation

#### Subscribe your hosts and enable repos
```
# export RHN_USER=your username
# export RHN_PASSWORD=your password

# cat hosts.txt
10.0.0.86
10.0.0.44
10.0.0.66
10.0.0.157



# for i in $(cat hosts.txt); do echo $i; ssh $i "subscription-manager register --username=$RHN_USER --password=$RHN_PASSWORD"; done

subscription-manager list --available
Find the pool id for "Red Hat OpenShift Container Platform"

for i in $(cat hosts.txt); do echo $i; ssh $i "subscription-manager attach --pool 8a85f9815b5e42d9015b5e4afa4e0661"; done

Ensure all the attachments are successful. Sometimes, same pool id may not work on all the boxes. In such a case, you have to log into the box, find pool id and attach

for i in $(cat hosts.txt); do echo $i; ssh $i "subscription-manager repos --disable="*""; done

for i in $(cat hosts.txt); do echo $i; ssh $i "subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-ose-3.6-rpms" \
    --enable="rhel-7-fast-datapath-rpms""; done
```

#### Install tools and utilities

```
for i in $(cat hosts.txt); do echo $i; ssh $i "yum install wget git net-tools bind-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct -y"; done

for i in $(cat hosts.txt); do echo $i; ssh $i "yum update -y"; done

for i in $(cat hosts.txt); do echo $i; ssh $i "yum install atomic-openshift-utils -y"; done
```

#### Install Docker and Setup Docker Storage

```
for i in $(cat hosts.txt); do echo $i; ssh $i "yum install docker-1.12.6 -y"; done

for i in $(cat hosts.txt); do echo $i; ssh $i "sed -i '/OPTIONS=.*/c\OPTIONS="--selinux-enabled --insecure-registry 172.30.0.0/16"' \
/etc/sysconfig/docker"; done

On Master

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


## Installing OpenShift
*to be added*

## Post Installation Checks
*to be added*
