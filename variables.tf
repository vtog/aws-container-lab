variable "aws_profile" {}
variable "aws_region" {}
variable "vpc_cidr" {}

data "http" "myIP" {
  url = "http://ipv4.icanhazip.com"
}
