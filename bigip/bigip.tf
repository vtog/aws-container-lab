
data "aws_ami" "f5_ami" {
  most_recent = true
  owners      = ["679593333241"]
  filter {
    name   = "name"
    values = ["F5 BIGIP-14.1* PAYG-Best 25Mbps*"]
  }
}

resource "aws_instance" "bigip1" {
  ami             = "${data.aws_ami.f5_ami.id}"
  instance_type   = "${var.instance_type}"
  key_name        = "${var.ssh_key}"
  security_groups = ["${aws_security_group.bigip_sg.name}"]
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
    protocol    ="tcp"
    cidr_blocks = ["${var.myIP}"]
  }
  name = "bigip_sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.myIP}"]
  }
  name = "bigip_sg"
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
    cidr_blocks = ["172.31.0.0/16"]
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

output "bigip1__public_dns" {
  value = "${aws_instance.bigip1.public_dns}"
}