data "aws_ami" "f5-v14_ami" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["F5 BIGIP-14.1* PAYG-Best 25M*"]
  }
}

#data "aws_ami" "f5-v13_ami" {
#  most_recent = true
#  owners      = ["679593333241"]
#
#  filter {
#    name   = "name"
#    values = ["F5 Networks BIGIP-13.1* PAYG - Best 25M*"]
#  }
#}

#data "aws_ami" "f5-v12_ami" {
#  most_recent = true
#  owners      = ["679593333241"]
#
#  filter {
#    name   = "name"
#    values = ["F5 Networks Licensed Hourly BIGIP-12.1* Best 25M*"]
#  }
#}

resource "aws_network_interface" "mgmt" {
  subnet_id       = "${var.vpc_subnet[0]}"
  security_groups = ["${aws_security_group.bigip_mgmt_sg.id}"]

  tags = {
    Name = "mgmt"
  }
}

resource "aws_network_interface" "external" {
  subnet_id       = "${var.vpc_subnet[1]}"
  security_groups = ["${aws_security_group.bigip_external_sg.id}"]

  tags = {
    Name = "external"
  }
}

resource "aws_network_interface" "internal" {
  subnet_id       = "${var.vpc_subnet[2]}"
  security_groups = ["${aws_security_group.bigip_internal_sg.id}"]

  tags = {
    Name = "internal"
  }
}

resource "aws_eip" "mgmt" {
  vpc               = true
  network_interface = "${aws_network_interface.mgmt.id}"

  tags = {
    Name = "bigip_mgmt_eip"
  }
}

resource "aws_eip" "external" {
  vpc               = true
  network_interface = "${aws_network_interface.external.id}"

  tags = {
    Name = "bigip_external_eip"
  }
}

resource "aws_instance" "bigip1" {
  ami           = "${data.aws_ami.f5-v14_ami.id}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"

  network_interface {
    network_interface_id = "${aws_network_interface.mgmt.id}"
    device_index         = 0
  }

  network_interface {
    network_interface_id = "${aws_network_interface.external.id}"
    device_index         = 1
  }

  network_interface {
    network_interface_id = "${aws_network_interface.internal.id}"
    device_index         = 2
  }

  tags = {
    Name = "bigip1"
  }
}

resource "aws_security_group" "bigip_mgmt_sg" {
  name   = "bigip_mgmt_sg"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.myIP}"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.myIP}"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bigip_mgmt_sg"
  }
}

resource "aws_security_group" "bigip_external_sg" {
  name   = "bigip_external_sg"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.myIP}"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.myIP}"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bigip_external_sg"
  }
}

resource "aws_security_group" "bigip_internal_sg" {
  name   = "bigip_internal_sg"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  tags = {
    Name = "bigip_internal_sg"
  }
}
