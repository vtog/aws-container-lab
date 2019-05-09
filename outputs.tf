#--------root/outputs.tf--------
output "BIGIP Public DNS" {
  value = "${module.bigip.public_dns}"
}

output "BIGIP Public IP" {
  value = "${module.bigip.public_ip}"
}

output "BIGIP Password" {
  value = "${module.bigip.password}"
}
