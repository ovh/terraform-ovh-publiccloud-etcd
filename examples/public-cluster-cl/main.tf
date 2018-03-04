provider "openstack" {
  version   = "~> 1.2.0"
  region    = "${var.os_region_name}"
  tenant_id = "${var.os_tenant_id}"
  auth_url  = "${var.os_auth_url}"
}

provider "local" {
  version = "~> 1.0"
}

provider "null" {
  version = "~> 1.0"
}

provider "template" {
  version = "~> 1.0"
}

provider "tls" {
  version = "~> 1.0"
}

provider "ignition" {
  version = "~> 1.0"
}

data "http" "myip" {
  url = "https://api.ipify.org/"
}

resource "openstack_networking_secgroup_v2" "sg" {
  name        = "${var.name}_ssh_sg"
  description = "${var.name} security group for cfssl provisionning"
}

resource "openstack_networking_secgroup_rule_v2" "in_traffic_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "${data.http.myip.body}/32"
  port_range_min    = 22
  port_range_max    = 22
  security_group_id = "${openstack_networking_secgroup_v2.sg.id}"
}

module "etcd" {
  source                    = "../.."
  name                      = "${var.name}"
  count                     = "${var.count}"
  region                    = "${var.os_region_name}"
  ssh_authorized_keys       = ["${file(var.public_sshkey)}"]
  image_name                = "CoreOS Stable"
  flavor_name               = "${var.os_flavor_name}"
  ignition_mode             = true
  public_security_group_ids = ["${openstack_networking_secgroup_v2.sg.id}"]
  ssh_user                  = "core"
  post_install_modules      = true
  associate_public_ipv4     = true
  associate_private_ipv4    = false
  cfssl                     = true
}
