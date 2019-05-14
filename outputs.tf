#--------root/outputs.tf--------
output "DNS Info" {
  value = "${module.bigip.public_dns}"
}

output "IP Info" {
  value = "${module.bigip.public_ip}"
}

output "Password" {
  value = "${module.bigip.password}"
}
