# Simple etcd cluster


- [Simple etcd cluster](#simple-etcd-cluster)
    - [Configuration](#configuration)
    - [Run it](#run-it)

## Configuration
1. Copy variable file

There is an example of var file `terraform.tfvars.sample`.

Copy it under the name `terraform.tfvars` (this allow terraform to autoload those variables)

2. Create a public cloud project on OVH

Follow the [official documentation](https://docs.ovh.com/gb/en/public-cloud/getting_started_with_public_cloud_logging_in_and_creating_a_project/).

You can add the `os_tenant_id` in `terraform.tfvars` or source your `openrc` credentials file.

3. Create or reuse ssh key pair. Carreful this keypair should not be using passphrase !

```bash
# Generate a new keypair without passphrase
$ ssh-keygen -f terraform_ssh_key -q -N ""
```

If you generate a new keypair, put its path in `terraform.tfvars` undar variables `private_sshkey` and `public_sshkey`.

## Run it

```bash
$ terraform init
Initializing modules...
...
[...]
Terraform has been successfully initialized!

$ terraform apply -var os_region_name=BHS3
[...]
```

This should give you an infra with 3 etcd hosts with public ipv4 addrs.

To connect to a etcd host through the nat host you can use :

```bash
ssh centos@<public_ip>
/opt/etcd/bin/etcdctl --ca-file /opt/etcd/certs/ca.pem --cert-file /opt/etcd/certs/cert.pem --key-file /opt/etcd/certs/cert-key.pem --endpoints https://127.0.0.1:2379 member list
```
