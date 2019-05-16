#--------root/outputs.tf--------
output "Admin URL" {
  value = "${module.bigip.public_dns}"
}

output "Mgmt IP" {
  value = "${module.bigip.public_ip}"
}

output "Admin Password" {
  value = "${module.bigip.password}"
}
