#-------- bigip output --------
output "public_dns" {
  value = "${join(", ", aws_instance.bigip1.*.public_dns)}"
}

output "public_ip" {
  value = "${join(", ", aws_instance.bigip1.*.public_ip)}"
}

output "password" {
  value = "${random_string.password.result}"
}
