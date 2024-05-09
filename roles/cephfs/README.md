# cephfs client

A role to install and configure a cephfs client.

*(Only tested with Debian)*

## Cephfs Client Capabilities

To mount a cephfs file system, you probably need authentication. Here's how to set it up.

You can use 

1. the `ceph fs authorize` command, or 
2. you can create the keyring file and add the capabilities. This method offers greater flexibility.

- https://docs.ceph.com/en/latest/man/8/ceph-authtool/
- https://docs.ceph.com/en/latest/man/8/mount.ceph/
- https://docs.ceph.com/en/latest/cephfs/client-auth/

### Ceph fs authorize command

> For example, to restrict a client named foo so that it can write only in the bar directory of file system cephfs_a, run the following command:
> 
> `ceph fs authorize cephfs_a client.foo / r /bar rw`

### Generating the Cephfs client keyring

```
root@cephsrv:~# ceph-authtool --create-keyring /etc/ceph/ceph.client.user1.keyring --gen-key -n client.user1
creating /etc/ceph/ceph.client.user1.keyring
```

edit `/etc/ceph/ceph.client.user1.keyring` to add some capabilities:

```
[client.user1]
        key = secret
        caps mds = "allow r fsname=cephfs_a, allow rw fsname=cephfs_a path=/user1, allow rw fsname=cephfs_a path=/group1"
        caps mon = "allow r fsname=cephfs_a"
        caps osd = "allow rw tag cephfs data=cephfs_a"
```

and import these changes into ceph: `root@cephsrv:~# ceph auth import -i /etc/ceph/ceph.client.user1.keyring`

## Create a client secret key

The client that mount cephfs required a authentication file with the `secret key` from `/etc/ceph/ceph.client.user1.keyring`.
This role will create the secret file if you add the secret key to the `cephfs_secrets` variable.

## Mounting cephfs

This role, using the `cephfs_mounts` variable, will mount and configure the mount points in `/etc/fstab`.

## Create client directory

Note that the ceph administrator must create the client directory, `/user1` in this case, on the cephfs file system.
