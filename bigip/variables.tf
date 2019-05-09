variable "myIP" {}
variable "aws_region" {}
variable "aws_profile" {}
variable "key_name" {}
variable "instance_type" {}
variable "vpc_id" {}
variable "vpc_cidr" {}

variable "vpc_subnet" {
  type = "list"
}

variable "bigip_admin" {}
variable "bigip_count" {}
variable "do_rpm_url" {}
variable "as3_rpm_url" {}
