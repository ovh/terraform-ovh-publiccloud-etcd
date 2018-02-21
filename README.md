# Etcd OVH Public Cloud Module

This repo contains a Module for how to deploy a [Etcd](https://coreos.com/etcd/) cluster on [OVH Public Cloud](https://ovhcloud.com/) using [Terraform](https://www.terraform.io/). Etcd is a distributed, highly-available tool that you can use for service discovery and key/value storage. A Etcd cluster typically includes a small number of server nodes.

# Usage


```hcl
module "etcd" {
  source                    = "ovh/publiccloud-etcd/ovh"
  name                      = ">= v0.1.0"
  count                     = "3""
  region                    = "BHS3"
  image_name                = "Centos 7 Etcd"
  flavor_name               = "b2-7"
  ignition_mode             = false
  associate_public_ipv4     = true
  associate_private_ipv4    = false
  cfssl                     = true
}

## Examples

This module has the following folder structure:

* [root](.): This folder shows an example of Terraform code which deploys a [Etcd](https://coreos.com/etcd/) cluster in [OVH Public Cloud](https://ovhcloud.com/).
* [modules](https://github.com/ovh/terraform-ovh-publiccloud-etcd/tree/master/modules): This folder contains the reusable code for this Module, broken down into one or more modules.
* [examples](https://github.com/ovh/terraform-ovh-publiccloud-etcd/tree/master/examples): This folder contains examples of how to use the modules.

To deploy Etcd servers using this Module:

1. (Optional) Create a Etcd Glance Image using a Packer template that references the [install-etcd module](https://github.com/ovh/terraform-ovh-publiccloud-etcd/tree/master/modules/install-etcd).
   Here is an [example Packer template](https://github.com/ovh/terraform-ovh-publiccloud-etcd/tree/master/examples/etcd-glance-image#quick-start). 
      
1. Deploy that Image using the Terraform [etcd-cluster example](https://github.com/ovh/terraform-ovh-publiccloud-etcd/tree/master/examples/public-cluster). If you prebuilt a etcd glance image with packer, you can comment the post provisionning modules arguments.

## How do I contribute to this Module?

Contributions are very welcome! Check out the [Contribution Guidelines](https://github.com/ovh/terraform-ovh-publiccloud-etcd/tree/master/CONTRIBUTING.md) for instructions.

## Authors

Module managed by [Yann Degat](https://github.com/yanndegat).

## License

The 3-Clause BSD License. See [LICENSE](https://github.com/ovh/terraform-ovh-publiccloud-etcd/tree/master/LICENSE) for full details.
