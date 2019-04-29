provider "aws" {
  profile = "${var.aws_profile}"
  region  = "${var.aws_region}"
}

#----- Create VPC -----
resource "aws_vpc" "lab_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name = "lab_vpc"
  }
}

resource "aws_internet_gateway" "lab_internet_gateway" {
  vpc_id = "${aws_vpc.lab_vpc.id}"

  tags {
    Name = "lab_igw"
  }
}

resource "aws_route_table" "lab_public_rt" {
  vpc_id = "${aws_vpc.lab_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.lab_internet_gateway.id}"
  }

  tags {
    Name = "lab_public"
  }
}

resource "aws_default_route_table" "lab_private_rt" {
  default_route_table_id = "${aws_vpc.lab_vpc.default_route_table_id}"

  tags {
    Name = "lab_private"
  }
}

resource "aws_subnet" "mgmt_subnet" {
  vpc_id                  = "${aws_vpc.lab_vpc.id}"
  cidr_block              = "${var.cidrs["mgmt"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "lab_mgmt"
  }
}

resource "aws_subnet" "external_subnet" {
  vpc_id                  = "${aws_vpc.lab_vpc.id}"
  cidr_block              = "${var.cidrs["external"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "lab_external"
  }
}

resource "aws_subnet" "internal_subnet" {
  vpc_id                  = "${aws_vpc.lab_vpc.id}"
  cidr_block              = "${var.cidrs["internal"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "lab_internal"
  }
}

resource "aws_route_table_association" "lab_mgmt_assoc" {
  subnet_id      = "${aws_subnet.mgmt_subnet.id}"
  route_table_id = "${aws_route_table.lab_public_rt.id}"
}

resource "aws_route_table_association" "lab_external_assoc" {
  subnet_id      = "${aws_subnet.external_subnet.id}"
  route_table_id = "${aws_route_table.lab_public_rt.id}"
}

resource "aws_route_table_association" "lab_internal_assoc" {
  subnet_id      = "${aws_subnet.internal_subnet.id}"
  route_table_id = "${aws_default_route_table.lab_private_rt.id}"
}

#----- Set default SSH key pair -----
resource "aws_key_pair" "lab_auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

#----- Deploy Big-IP -----
#module "bigip" {
#  source        = "./bigip"
#  myIP          = "${chomp(data.http.myIP.body)}/32"
#  key_name      = "${var.key_name}"
#  instance_type = "${var.bigip_instance_type}"
#}

#----- Deploy Kubernetes -----
module "kube" {
  source        = "./kubernetes"
  myIP          = "${chomp(data.http.myIP.body)}/32"
  key_name      = "${var.key_name}"
  instance_type = "${var.kube_instance_type}"
  vpc_id        = "${aws_vpc.lab_vpc.id}"
  vpc_cidr      = "${var.vpc_cidr}"
  vpc_subnet    = "${aws_subnet.external_subnet.id}"
}

#----- Deploy OpenShift -----
#module "okd" {
#  source        = "./openshift"
#  myIP          = "${chomp(data.http.myIP.body)}/32"
#  key_name      = "${var.key_name}"
#  instance_type = "${var.okd_instance_type}"
#}

