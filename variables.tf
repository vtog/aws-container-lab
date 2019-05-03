variable "aws_profile" {}
variable "aws_region" {}
variable "vpc_cidr" {}
data "aws_availability_zones" "available" {}

variable "cidrs" {
  type = "map"
}

data "http" "myIP" {
  url = "http://ipv4.icanhazip.com"
}

variable "key_name" {}
variable "public_key_path" {}
variable "kube_instance_type" {}
variable "okd_instance_type" {}
variable "bigip_instance_type" {}
variable "bigip_admin" {}
variable "bigip_count" {}
variable "do_rpm_url" {}
variable "as3_rpm_url" {}
