locals {
  getcert_command= "CFSSL_ENDPOINT=${module.etcd.cfssl_endpoint} ETCD_TRUSTED_CA_FILE=/opt/etcd/certs/ca.pem /opt/etcd/bin/etcd-get-cert test"
  test_command =  "/opt/etcd/bin/etcdctl --ca-file /opt/etcd/certs/ca.pem --cert-file ./test.pem --key-file ./test-key.pem --endpoints https://${module.etcd.public_ipv4_addrs[0]}:2379 member list"
}

output "tf_test" {
  value = <<TEST
ssh -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    centos@${module.etcd.public_ipv4_addrs[0]}  bash -c '"${local.getcert_command} && [ \$(${local.test_command} | wc -l) == ${var.count} ] && ${local.test_command} | grep -q isLeader=true"'
TEST
}
