# Terraform version
terraform {
  required_version = ">= 0.10.4"
}

data "openstack_images_image_v2" "etcd" {
  count       = "${var.image_id == "" ? 1 : 0}"
  name        = "${var.image_name}"
  most_recent = true
}

data "openstack_networking_subnet_v2" "subnets" {
  count        = "${var.associate_private_ipv4 ? var.count : 0}"
  subnet_id    = "${length(var.subnet_ids) > 0 ? format("%s", element(var.subnet_ids, count.index)) : ""}"
  cidr         = "${length(var.subnets) > 0 && length(var.subnet_ids) < 1 ? format("%s", element(var.subnets, count.index)): ""}"
  ip_version   = 4
  dhcp_enabled = true
}

data "openstack_networking_network_v2" "ext_net" {
  name      = "Ext-Net"
  tenant_id = ""
}

resource "openstack_networking_secgroup_v2" "pub" {
  count       = "${var.associate_public_ipv4 ? 1 : 0}"
  name        = "${var.name}_pub_sg"
  description = "${var.name} security group for public ingress traffic on etcd hosts"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_etcd" {
  count             = "${var.associate_public_ipv4 ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "2379"
  port_range_max    = "2380"
  security_group_id = "${openstack_networking_secgroup_v2.pub.id}"
  remote_group_id   = "${openstack_networking_secgroup_v2.pub.id}"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_cfssl" {
  count             = "${var.associate_public_ipv4 && var.cfssl && var.cfssl_endpoint == "" ? 1 : 0}"
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = "${var.cfssl_port}"
  port_range_max    = "${var.cfssl_port}"
  security_group_id = "${openstack_networking_secgroup_v2.pub.id}"
  remote_group_id   = "${openstack_networking_secgroup_v2.pub.id}"
}

resource "openstack_networking_port_v2" "public_port_etcd" {
  count = "${var.associate_public_ipv4 ? var.count : 0}"
  name  = "${var.name}_public_${count.index}"

  network_id     = "${data.openstack_networking_network_v2.ext_net.id}"
  admin_state_up = "true"

  security_group_ids = [
    "${compact(concat(openstack_networking_secgroup_v2.pub.*.id, var.public_security_group_ids))}",
  ]
}

data "template_file" "public_ipv4_addrs" {
  count = "${var.associate_public_ipv4 ? var.count : 0}"

  # join all ips as string > remove every ipv6 > split & compact
  template = "${element(compact(split(",", replace(join(",", flatten(openstack_networking_port_v2.public_port_etcd.*.all_fixed_ips)), "/[[:alnum:]]+:[^,]+/", ""))), count.index)}"
}

resource "openstack_networking_port_v2" "port_etcd" {
  count = "${var.associate_private_ipv4 ? var.count : 0}"

  name           = "${var.name}_${count.index}"
  network_id     = "${element(data.openstack_networking_subnet_v2.subnets.*.network_id, count.index)}"
  admin_state_up = "true"

  fixed_ip {
    subnet_id = "${data.openstack_networking_subnet_v2.subnets.*.id[count.index]}"
  }
}

data "template_file" "private_ipv4_addrs" {
  count = "${var.associate_private_ipv4 ? var.count : 0}"

  # only ipv4 in address list as subnet is setup as ipv4 only
  template = "${element(flatten(openstack_networking_port_v2.port_etcd.*.all_fixed_ips), count.index)}"
}

module "userdata" {
  source               = "./modules/etcd-userdata"
  count                = "${var.count}"
  name                 = "${var.name}"
  ignition_mode        = "${var.ignition_mode}"
  domain               = "${var.domain}"
  datacenter           = "${var.datacenter}"
  cidr                 = "${var.cidr}"
  cacert               = "${var.cacert}"
  cacert_key           = "${var.cacert_key}"
  cfssl                = "${var.cfssl}"
  cfssl_endpoint       = "${var.cfssl_endpoint}"
  etcd_initial_cluster = "${var.etcd_initial_cluster}"

  # if private ipv4 addrs are set, prefer them over public addrs;
  # they will notably be used to set etcd_initial_cluster attr.
  ipv4_addrs = ["${coalescelist(data.template_file.private_ipv4_addrs.*.rendered, data.template_file.public_ipv4_addrs.*.rendered)}"]

  ssh_authorized_keys = ["${var.ssh_authorized_keys}"]
  cfssl_key_algo      = "${var.cfssl_key_algo}"
  cfssl_key_size      = "${var.cfssl_key_size}"
  cfssl_bind          = "${var.cfssl_bind}"
  cfssl_port          = "${var.cfssl_port}"
}

resource "openstack_compute_instance_v2" "multinet_etcd" {
  count    = "${var.associate_public_ipv4 && var.associate_private_ipv4 ? var.count : 0}"
  name     = "${var.name}_${count.index}"
  image_id = "${element(coalescelist(data.openstack_images_image_v2.etcd.*.id, list(var.image_id)), 0)}"

  flavor_name = "${var.flavor_name}"
  user_data   = "${element(module.userdata.rendered, count.index)}"

  network {
    port = "${element(openstack_networking_port_v2.port_etcd.*.id, count.index)}"
  }

  # Important: orders of network declaration matters because public internet interface must be eth1
  network {
    access_network = true
    port           = "${element(openstack_networking_port_v2.public_port_etcd.*.id, count.index)}"
  }

  metadata = "${var.metadata}"
}

resource "openstack_compute_instance_v2" "singlenet_etcd" {
  count    = "${! (var.associate_public_ipv4 && var.associate_private_ipv4) ? var.count : 0}"
  name     = "${var.name}_${count.index}"
  image_id = "${element(coalescelist(data.openstack_images_image_v2.etcd.*.id, list(var.image_id)), 0)}"

  flavor_name = "${var.flavor_name}"
  user_data   = "${element(module.userdata.rendered, count.index)}"

  network {
    access_network = true
    port           = "${element(coalescelist(openstack_networking_port_v2.public_port_etcd.*.id,openstack_networking_port_v2.port_etcd.*.id), count.index)}"
  }

  metadata = "${var.metadata}"
}

module "post_install_cfssl" {
  source  = "ovh/publiccloud-cfssl/ovh//modules/install-cfssl"
  version = ">= 0.1.11"

  count            = "${var.post_install_modules && var.cfssl && var.cfssl_endpoint == "" && var.count >= 1 ? 1 : 0}"
  triggers         = ["${element(concat(openstack_compute_instance_v2.singlenet_etcd.*.id, openstack_compute_instance_v2.multinet_etcd.*.id), 0)}"]
  ipv4_addrs       = ["${element(concat(openstack_compute_instance_v2.singlenet_etcd.*.access_ip_v4, openstack_compute_instance_v2.multinet_etcd.*.access_ip_v4), 0)}"]
  ssh_user         = "${var.ssh_user}"
  ssh_bastion_host = "${var.ssh_bastion_host}"
  ssh_bastion_user = "${var.ssh_bastion_user}"
}

module "post_install_etcd" {
  source           = "./modules/install-etcd"
  count            = "${var.post_install_modules ? var.count : 0}"
  triggers         = ["${concat(openstack_compute_instance_v2.singlenet_etcd.*.id, openstack_compute_instance_v2.multinet_etcd.*.id)}"]
  ipv4_addrs       = ["${concat(openstack_compute_instance_v2.singlenet_etcd.*.access_ip_v4, openstack_compute_instance_v2.multinet_etcd.*.access_ip_v4)}"]
  ssh_user         = "${var.ssh_user}"
  ssh_bastion_host = "${var.ssh_bastion_host}"
  ssh_bastion_user = "${var.ssh_bastion_user}"
}
