locals {
  test_command = "/opt/etcd/bin/etcdctl --ca-file /opt/etcd/certs/ca.pem --cert-file /opt/etcd/certs/cert.pem --key-file /opt/etcd/certs/cert-key.pem --endpoints https://${module.etcd.public_ipv4_addrs[0]}:2379 member list"
}

output "tf_test" {
  value = <<TEST
ssh -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    ubuntu@${module.etcd.public_ipv4_addrs[0]} bash -c '"[ \$(${local.test_command} | wc -l) == ${var.count} ] && ${local.test_command} | grep -q isLeader=true"'
TEST
}
