variable "myIP" {}
variable "aws_region" {}
variable "key_name" {}
variable "instance_type" {}
variable "vpc_id" {}
variable "vpc_cidr" {}

variable "vpc_subnet" {
  type = "list"
}
