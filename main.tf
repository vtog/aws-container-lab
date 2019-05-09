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

# Internet gateway

resource "aws_internet_gateway" "lab_internet_gateway" {
  vpc_id = "${aws_vpc.lab_vpc.id}"

  tags {
    Name = "lab_igw"
  }
}

# Route tables

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

# Subnets

resource "aws_subnet" "mgmt_subnet" {
  vpc_id                  = "${aws_vpc.lab_vpc.id}"
  cidr_block              = "${var.cidrs["mgmt"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "lab_mgmt"
  }
}

resource "aws_subnet" "external1_subnet" {
  vpc_id                  = "${aws_vpc.lab_vpc.id}"
  cidr_block              = "${var.cidrs["external1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "lab_external1"
  }
}

resource "aws_subnet" "external2_subnet" {
  vpc_id                  = "${aws_vpc.lab_vpc.id}"
  cidr_block              = "${var.cidrs["external2"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags {
    Name = "lab_external2"
  }
}

resource "aws_subnet" "internal1_subnet" {
  vpc_id                  = "${aws_vpc.lab_vpc.id}"
  cidr_block              = "${var.cidrs["internal1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "lab_internal1"
  }
}

resource "aws_subnet" "internal2_subnet" {
  vpc_id                  = "${aws_vpc.lab_vpc.id}"
  cidr_block              = "${var.cidrs["internal2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags {
    Name = "lab_internal2"
  }
}

resource "aws_route_table_association" "lab_mgmt_assoc" {
  subnet_id      = "${aws_subnet.mgmt_subnet.id}"
  route_table_id = "${aws_route_table.lab_public_rt.id}"
}

resource "aws_route_table_association" "lab_external1_assoc" {
  subnet_id      = "${aws_subnet.external1_subnet.id}"
  route_table_id = "${aws_route_table.lab_public_rt.id}"
}

resource "aws_route_table_association" "lab_external2_assoc" {
  subnet_id      = "${aws_subnet.external2_subnet.id}"
  route_table_id = "${aws_route_table.lab_public_rt.id}"
}

resource "aws_route_table_association" "lab_internal1_assoc" {
  subnet_id      = "${aws_subnet.internal1_subnet.id}"
  route_table_id = "${aws_default_route_table.lab_private_rt.id}"
}

resource "aws_route_table_association" "lab_internal2_assoc" {
  subnet_id      = "${aws_subnet.internal2_subnet.id}"
  route_table_id = "${aws_default_route_table.lab_private_rt.id}"
}

#----- Set default SSH key pair -----
resource "aws_key_pair" "lab_auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

#----- Deploy Big-IP -----
module "bigip" {
  source        = "./bigip"
  myIP          = "${chomp(data.http.myIP.body)}/32"
  key_name      = "${var.key_name}"
  instance_type = "${var.bigip_instance_type}"
  bigip_count   = "${var.bigip_count}"
  bigip_admin   = "${var.bigip_admin}"
  do_rpm_url    = "${var.do_rpm_url}"
  as3_rpm_url   = "${var.as3_rpm_url}"
  vpc_id        = "${aws_vpc.lab_vpc.id}"
  vpc_cidr      = "${var.vpc_cidr}"
  vpc_subnet    = ["${aws_subnet.mgmt_subnet.id}", "${aws_subnet.external1_subnet.id}", "${aws_subnet.internal1_subnet.id}"]
}

#----- Deploy Kubernetes -----
module "kube" {
  source        = "./kubernetes"
  aws_region    = "${var.aws_region}"
  myIP          = "${chomp(data.http.myIP.body)}/32"
  key_name      = "${var.key_name}"
  instance_type = "${var.kube_instance_type}"
  vpc_id        = "${aws_vpc.lab_vpc.id}"
  vpc_cidr      = "${var.vpc_cidr}"
  vpc_subnet    = ["${aws_subnet.external1_subnet.id}", "${aws_subnet.external2_subnet.id}"]
}

#----- Deploy OpenShift -----
module "okd" {
  source        = "./openshift"
  aws_region    = "${var.aws_region}"
  myIP          = "${chomp(data.http.myIP.body)}/32"
  key_name      = "${var.key_name}"
  instance_type = "${var.okd_instance_type}"
  vpc_id        = "${aws_vpc.lab_vpc.id}"
  vpc_cidr      = "${var.vpc_cidr}"
  vpc_subnet    = ["${aws_subnet.external1_subnet.id}", "${aws_subnet.external2_subnet.id}"]
}
