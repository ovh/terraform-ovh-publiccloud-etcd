locals {
  scheme = "${var.cfssl ? "https" : "http"}"
}

module "cfssl" {
  source  = "ovh/publiccloud-cfssl/ovh//modules/cfssl-userdata"
  version = ">= 0.1.13"

  ignition_mode        = "${var.ignition_mode}"
  cidr                 = "${var.cidr}"
  ssh_authorized_keys  = ["${var.ssh_authorized_keys}"]
  ipv4_addr            = "${element(var.ipv4_addrs,0)}"
  cacert               = "${var.cacert}"
  cacert_key           = "${var.cacert_key}"
  ca_validity_period   = "${var.cfssl_ca_validity_period}"
  cert_validity_period = "${var.cfssl_cert_validity_period}"
  cn                   = "${var.domain}"
  c                    = "${var.datacenter}"
  o                    = "${var.name}"
  key_algo             = "${var.cfssl_key_algo}"
  key_size             = "${var.cfssl_key_size}"
  bind                 = "${var.cfssl_bind}"
  port                 = "${var.cfssl_port}"
}

data "template_file" "etcd_names" {
  count    = "${var.count}"
  template = "${element(split(",", replace(join(",",var.ipv4_addrs), ".", "_")), count.index)}"
}

data "template_file" "conf" {
  count = "${var.count}"

  template = <<CONTENT
DOMAIN=${var.domain}
ETCD_NAME=${element(data.template_file.etcd_names.*.rendered, count.index)}
ETCD_INITIAL_CLUSTER_TOKEN=etcd_${var.name}
ETCD_INITIAL_CLUSTER=${var.etcd_initial_cluster != "" ? var.etcd_initial_cluster : join(",", formatlist("%s=%s://%s:2380", data.template_file.etcd_names.*.rendered, local.scheme,var.ipv4_addrs))}
ETCD_INITIAL_ADVERTISE_PEER_URLS=${local.scheme}://${element(var.ipv4_addrs, count.index)}:2380
ETCD_LISTEN_CLIENT_URLS=${local.scheme}://0.0.0.0:2379
ETCD_ADVERTISE_CLIENT_URLS=${local.scheme}://${element(var.ipv4_addrs, count.index)}:2379
ETCD_LISTEN_PEER_URLS=${local.scheme}://0.0.0.0:2380
ETCD_TRUSTED_CA_FILE=${var.cfssl ? "/opt/etcd/certs/ca.pem" : ""}
ETCD_CERT_FILE=${var.cfssl ? "/opt/etcd/certs/peer.pem" : ""}
ETCD_KEY_FILE=${var.cfssl ? "/opt/etcd/certs/peer-key.pem" : ""}
ETCD_CLIENT_CERT_AUTH=${var.cfssl ? "true" : "false"}
ETCD_PEER_TRUSTED_CA_FILE=${var.cfssl ? "/opt/etcd/certs/ca.pem" : ""}
ETCD_PEER_CERT_FILE=${var.cfssl ? "/opt/etcd/certs/peer.pem" : ""}
ETCD_PEER_KEY_FILE=${var.cfssl ? "/opt/etcd/certs/peer-key.pem" : ""}
ETCD_PEER_CLIENT_CERT_AUTH=${var.cfssl ? "true" : "false"}
ETCD_PEER_CERT_ALLOWED_CN=${var.cfssl ? var.domain : ""}

PRIVATE_NETWORK=${var.cidr}
CFSSL_ENDPOINT=${var.cfssl_endpoint == "" ? module.cfssl.endpoint : var.cfssl_endpoint }
CONTENT
}
