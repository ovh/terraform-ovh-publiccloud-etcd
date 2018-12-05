output "rendered" {
  description = "The representation of the userdata according to `var.ignition_mode`"
  value = ["${coalescelist(data.ignition_config.coreos.*.rendered, data.template_cloudinit_config.config.*.rendered)}"]
}

output "conf" {
  description = "The configuration to be installed in /etc/sysconfig/etcd.conf"
  value = ["${data.template_file.conf.*.rendered}"]
}

output "etcd_initial_cluster" {
  description = "The etcd initial cluster that can be used to join the cluster"
  value = "${var.etcd_initial_cluster != "" ? var.etcd_initial_cluster : join(",", formatlist("%s=https://%s:2380", data.template_file.etcd_names.*.rendered, var.ipv4_addrs))}"
}

output "etcd_endpoints" {
  description = "The etcd client endpoints that can be used to interact with the cluster"
  value = "${join(",", formatlist("https://%s:2379", var.ipv4_addrs))}"
}

output "cfssl_endpoint" {
  description = "The cfssl endpoint"
  value       = "${var.cfssl_endpoint == "" ? (var.cfssl ? module.cfssl.endpoint : "") : var.cfssl_endpoint}"
}
