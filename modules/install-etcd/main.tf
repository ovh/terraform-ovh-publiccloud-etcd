resource "null_resource" "post_install_etcd" {
  count = "${var.count}"

  triggers {
    trigger = "${element(var.triggers, count.index)}"
  }

  connection {
    host                = "${element(var.ipv4_addrs, count.index)}"
    user                = "${var.ssh_user}"
    bastion_host        = "${var.ssh_bastion_host}"
    bastion_user        = "${var.ssh_bastion_user}"
  }

  provisioner "remote-exec" {
    inline = ["mkdir -p /tmp/install-etcd"]
  }

  provisioner "file" {
    source      = "${path.module}/"
    destination = "/tmp/install-etcd"
  }

  provisioner "remote-exec" {
    inline = [
      "/bin/bash /tmp/install-etcd/system-upgrade.sh",
      "/bin/sh /tmp/install-etcd/install-etcd --path ${var.install_dir} --version ${var.etcd_version} --sha256sum ${var.etcd_sha256sum}",
      "echo start etcd; sudo systemctl restart etcd.service || true"
    ]
  }
}

output "install_ids" {
  value = ["${null_resource.post_install_etcd.*.id}"]
}
