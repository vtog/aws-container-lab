#--------root/outputs.tf--------
output "Admin_URL" {
  value = module.bigip.public_dns
}

output "Mgmt_IP" {
  value = module.bigip.public_ip
}

output "Admin_Password" {
  value = module.bigip.password
}

output "Kube_Cluster_IPs" {
  value = module.kube.public_ip
}

