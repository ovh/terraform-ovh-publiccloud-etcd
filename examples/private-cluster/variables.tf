variable "os_region_name" {
  description = "The Openstack region name"
  default     = ""
}

variable "os_tenant_id" {
  description = "The id of the openstack project"
  default     = ""
}

variable "os_auth_url" {
  description = "The OpenStack auth url"
  default     = "https://auth.cloud.ovh.net/v2.0/"
}

variable "os_flavor_name" {
  description = "Flavor to use"
  default     = "s1-2"
}

variable "cidr" {
  description = "The cidr of the network for hosts (namely openstack instances)"
  default     = "10.137.0.0/16"
}

variable "name" {
  description = "The name of the cluster. This attribute will be used to name openstack resources"
  default     = "myetcd"
}

variable "count" {
  description = "Number of nodes in the etcd cluster"
  default     = 3
}

variable "public_sshkey" {
  description = "Key to use to ssh connect"
  default     = "~/.ssh/id_rsa.pub"
}
