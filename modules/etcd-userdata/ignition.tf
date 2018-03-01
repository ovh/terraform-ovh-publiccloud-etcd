locals {
  network_route_tpl = "[Route]\nDestination=%s\nGatewayOnLink=yes\nRouteMetric=3\nScope=link\nProtocol=kernel"
}

data "ignition_file" "etcd-conf" {
  count    = "${var.count}"
  filesystem = "root"
  mode       = "0644"
  path       = "/etc/sysconfig/etcd.conf"

  content {
    content = "${element(data.template_file.conf.*.rendered, count.index)}"
  }
}

data "ignition_file" "cacert" {
  count      = "${var.cacert != "" ? 1 : 0}"
  filesystem = "root"
  path       = "/etc/ssl/certs/cacert.pem"
  mode       = "0644"

  content {
    content = "${var.cacert}"
  }
}

data "ignition_file" "cfssl-cacert" {
  filesystem = "root"
  path       = "/opt/cfssl/cacert/ca.pem"
  mode       = "0644"

  content {
    content = "${var.cacert}"
  }
}

data "ignition_file" "cfssl-cakey" {
  filesystem = "root"
  path       = "/opt/cfssl/cacert/ca-key.pem"
  mode       = "0600"
  uid        = "1011"

  content {
    content = "${var.cacert_key}"
  }
}

data "ignition_file" "cfssl-conf" {
  count      = "${var.count}"
  filesystem = "root"
  mode       = "0644"
  path       = "/etc/sysconfig/cfssl.conf"

  content {
    content = "${module.cfssl.conf}"
  }
}

data "ignition_networkd_unit" "eth0" {
  name = "10-eth0.network"

  content = <<IGNITION
[Match]
Name=eth0
[Network]
DHCP=ipv4
${format(local.network_route_tpl, var.cidr)}
[DHCP]
RouteMetric=2048
IGNITION
}

data "ignition_networkd_unit" "eth1" {
  name = "10-eth1.network"

  content = <<IGNITION
[Match]
Name=eth1
[Network]
DHCP=ipv4
[DHCP]
RouteMetric=2048
IGNITION
}

data "ignition_user" "core" {
  name                = "core"
  ssh_authorized_keys = ["${var.ssh_authorized_keys}"]
}

data "ignition_config" "coreos" {
  count = "${var.ignition_mode ? var.count : 0 }"
  users = ["${data.ignition_user.core.id}"]

  networkd = [
    "${data.ignition_networkd_unit.eth0.id}",
    "${data.ignition_networkd_unit.eth1.id}",
  ]

  files = [
    "${data.ignition_file.cacert.*.id}",
    "${element(data.ignition_file.etcd-conf.*.id, count.index)}",
    "${var.cfssl && var.cfssl_endpoint == "" && count.index == 0 ? data.ignition_file.cfssl-cacert.id : ""}",
    "${var.cfssl && var.cfssl_endpoint == "" && count.index == 0 ? data.ignition_file.cfssl-cakey.id : ""}",
    "${var.cfssl && var.cfssl_endpoint == "" && count.index == 0 ? element(data.ignition_file.cfssl-conf.*.id, 0) : ""}",
  ]
}
