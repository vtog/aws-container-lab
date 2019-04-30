data "aws_ami" "f5-v14.1_ami" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["F5 BIGIP-14.1* PAYG-Best 25M*"]
  }
}

data "aws_ami" "f5-v13.1_ami" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["F5 Networks BIGIP-13.1* PAYG - Best 25M*"]
  }
}

data "aws_ami" "f5-v12.1_ami" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["F5 Networks Licensed Hourly BIGIP-12.1* Best 25M*"]
  }
}

resource "aws_instance" "bigip1" {
  ami                    = "${data.aws_ami.f5-v14.1_ami.id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.bigip_sg.id}"]
  subnet_id              = "${var.vpc_subnet[1]}"

  tags = {
    Name = "bigip1"
  }
}

resource "aws_security_group" "bigip_sg" {
  name = "bigip_sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.myIP}"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["${var.myIP}"]
  }

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
    Name = "bigip_sg"
  }
}
