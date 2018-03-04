# Etcd Install Script

This folder contains a script for installing Etcd and its dependencies. Use this script to create a Etcd [an Openstack Glance Image](https://docs.openstack.org/glance/latest/) that can be deployed in [OVH Public Cloud](https://www.ovh.com/fr/public-cloud/instances/) across a Server Group using the [etcd-cluster example](../../examples/public-cluster).

This script has been tested on CoreOS & CentOS 7 operating system.

There is a good chance it will work on other flavors of CentOS and RHEL as well.

## Quick start

<!-- TODO: update the clone URL to the final URL when this Module is released -->

To install Etcd, use `git` to clone this repository at a specific tag (see the [releases page](../../../../releases) 
for all available tags) and run the `install-etcd` script:

```
git clone --branch <VERSION> https://github.com/ovh/terraform-ovh-publiccloud-etcd.git
terraform-ovh-publiccloud-etcd/modules/install-etcd/install-etcd --version 3.3.0 ...
```

The `install-etcd` script will install Etcd and its dependencies.
It contains a script and an associated systemd service definition which can be used to start Etcd and configure it to automatically join other nodes to form a cluster when the server is booting.

We recommend running the `install-etcd` script as part of a [Packer](https://www.packer.io/) template to create a Etcd [Glance Image](https://docs.openstack.org/glance/latest/) (see the [etcd-glance-image example](../../examples/etcd-glance-image) for a fully-working sample code). You can then deploy the image across a Server Group using the [etcd-cluster example](../../examples/public-cluster).

## Command line Arguments

The `install-etcd` script accepts the following arguments:

* `version VERSION`: Install Etcd version VERSION. Required. 
* `path DIR`: Install Etcd into folder DIR. Optional.
* `user USER`: The install dirs will be owned by user USER. Optional.

Example:

```
install-etcd --version 3.3.0 --sha256sum d91efb17ab0813039e24863a1af154b153d4b1a009181d6faa18e8ab681676dc
```

## How it works

The `install-etcd` script does the following:

1. [Create a user and folders for Etcd](#create-a-user-and-folders-for-etcd)
1. [Install Etcd binaries and scripts](#install-etcd-binaries-and-scripts)
1. [Disables Firewalld](#disable-firewalld)
1. [Follow-up tasks](#follow-up-tasks)


### Create a user and folders for Etcd

Create an OS user named `etcd`. Create the following folders, all owned by user `etcd`:

* `/opt/etcd`: base directory for Etcd data (configurable via the `--path` argument).
* `/opt/etcd/bin`: directory for Etcd binaries.
* `/opt/etcd/data`: directory where the Etcd agent can store state.
* `/opt/etcd/certs`: directory where the Etcd agent looks up tls certs.


### Install Etcd binaries and scripts

Install the following:

* `etcd`: Download the Etcd zip file from the [downloads page](https://github.com/coreos/etcd/releases/download/) (the version number is configurable via the `--version` argument), and extract the `etcd` binary into `/opt/etcd/bin`.
* `manage scripts`: Copy manage scripts into `/opt/etcd/bin`
* `etcd.service`: Install associated systemd services into `/etc/systemd/system/`. 

### Disables Firewalld

As of today, firewalld is disabled. The etcd setup for firewalld hasn't been implemented. You should be aware of this and have a proper setup of your security group rules.

### Using this script as a terraform module

The install script can also be post provisionned using this folder as a terraform module.

Here's a usage example:


```hcl

module "provision_etcd" {
  source                  = "github.com/ovh/terraform-ovh-publiccloud-etcd//modules/install-etcd"
  count                   = N
  etcd_version            = "3.3.0"
  etcd_sha256sum          = "d91efb17ab0813039e24863a1af154b153d4b1a009181d6faa18e8ab681676dc"
  triggers                = ["A list of trigger values"]
  ipv4_addrs              = ["192.168.1.200", "..."]
  ssh_user                = "centos"
  ssh_bastion_host        = "34.234.13.XX"
  ssh_bastion_user        = "core"
}
```


### Follow-up tasks

After the `install-etcd` script finishes running, you may wish to do the following:

1. If you have custom Etcd config (`.json`) files, you may want to copy them into the config directory (default: `/opt/etcd/config`).
1. If `/usr/local/bin` isn't already part of `PATH`, you should add it so you can run the `etcd` command without specifying the full path.
