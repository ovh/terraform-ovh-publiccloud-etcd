variable "count" {
  description = "The number of resource to post provision"
  default     = 1
}

variable "ipv4_addrs" {
  type        = "list"
  description = "The list of IPv4 addrs to provision"
}

variable "triggers" {
  type        = "list"
  description = "The list of values which can trigger a provisionning"
}

variable "ssh_user" {
  description = "The ssh username of the image used to boot the etcd cluster."
  default     = "core"
}

variable "install_dir" {
  description = "Directory where to install etcd"
  default     = "/opt/etcd"
}

variable "ssh_bastion_host" {
  description = "The address of the bastion host used to post provision the etcd cluster. This may be required if `post_install_module` is set to `true`"
  default     = ""
}

variable "ssh_bastion_user" {
  description = "The ssh username of the bastion host used to post provision the etcd cluster. This may be required if `post_install_module` is set to `true`"
  default     = ""
}

variable "etcd_version" {
  description = "The version of etcd to install with the post installation script if `post_install_module` is set to true"
  default     = "3.3.1"
}

variable "etcd_sha256sum" {
  description = "The sha256 checksum of the etcd binary to install with the post installation script if `post_install_module` is set to true"
  default     = "dc6d74e364ece87c34c86a997b90016ab6ea8845fd13fdf8c520afdf796b000d"
}
