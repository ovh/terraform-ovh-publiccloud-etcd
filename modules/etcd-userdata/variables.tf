variable "count" {
  description = "Specifies the number of nodes in the cluster"
  default     = 1
}

variable "ignition_mode" {
  description = "Defines if main output is in ignition or cloudinit format"
  default     = true
}

variable "name" {
  type        = "string"
  description = "Cluster name"
}

variable "domain" {
  description = "The domain of the cluster."
  default     = "local"
}

variable "region" {
  description = "The region of the cluster."
}

variable "datacenter" {
  description = "The datacenter of the cluster."
  default     = ""
}

variable "ipv4_addrs" {
  description = "list of nodes ipv4 addrs"
  type = "list"
}

variable "etcd_initial_cluster" {
  description = "etcd initial cluster. Useful to join an existing cluster."
  default = ""
}

variable "ssh_authorized_keys" {
  type        = "list"
  description = "SSH public keys"
  default     = []
}

variable "cidr" {
  description = "CIDR IPv4 of the control network of the nodes. If left blank, the default network will be used."
  type        = "string"
  default     = ""
}

variable "cacert" {
  description = "Optional ca certificate to add to the server nodes."
  default     = ""
}

variable "cacert_key" {
  description = "Optional ca certificate to use in conjunction with `cacert` for generating certs with cfssl."
  default     = ""
}

variable "cfssl" {
  description = "Defines if cfssl shall be started and used a pki. If no cacert with associated private key is given as argument, cfssl will generate its own self signed ca cert."
  default     = false
}

variable "cfssl_endpoint" {
  description = "If `cfssl` is set to `true`, this argument can be used to specify a target cfssl endpoint. Otherwise the first ipv4 given as argument in `ipv4_addrs` will be used as the cfssl endpoint in instances userdata."
  default     = ""
}

variable "cfssl_ca_validity_period" {
  description = "validity period for generated CA"
  default     = "43800h"
}

variable "cfssl_cert_validity_period" {
  description = "default validity period for generated certs"
  default     = "8760h"
}

variable "cfssl_key_algo" {
  description = "generated certs key algo"
  default     = "rsa"
}

variable "cfssl_key_size" {
  description = "generated certs key size"
  default     = "2048"
}

variable "cfssl_bind" {
  description = "cfssl service bind addr"
  default     = "0.0.0.0"
}

variable "cfssl_port" {
  description = "cfssl service bind port"
  default     = "8888"
}
