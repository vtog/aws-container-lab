data "aws_ami" "f5-v14_ami" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["F5 BIGIP-14.1* PAYG-Best 25M*"]
  }
}

#data "aws_ami" "f5-v14_ami" {
#  most_recent = true
#  owners      = ["679593333241"]
#
#  filter {
#    name   = "name"
#    values = ["F5 Networks BIGIP-14.0* PAYG - Best 25M*"]
#  }
#}

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
  depends_on        = ["aws_network_interface.mgmt"]
  network_interface = "${aws_network_interface.mgmt.id}"

  tags = {
    Name = "bigip_mgmt_eip"
  }
}

resource "aws_eip" "external" {
  vpc               = true
  depends_on        = ["aws_network_interface.external"]
  network_interface = "${aws_network_interface.external.id}"

  tags = {
    Name = "bigip_external_eip"
  }
}

resource "random_string" "password" {
  length           = 16
  special          = true
  override_special = "@"
}

data "template_file" "cloudinit_data" {
  template = "${file("${path.module}/cloudinit_data.tpl")}"

  vars {
    admin_username = "${var.bigip_admin}"
    admin_password = "${random_string.password.result}"
    do_rpm_url     = "${var.do_rpm_url}"
    as3_rpm_url    = "${var.as3_rpm_url}"
  }
}

resource "aws_instance" "bigip1" {
  ami           = "${data.aws_ami.f5-v14_ami.id}"
  instance_type = "${var.instance_type}"
  count         = "${var.bigip_count}"
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

  user_data = "${data.template_file.cloudinit_data.rendered}"

  tags = {
    Name = "bigip1"
  }
}

data "template_file" "do_data" {
  template = "${file("${path.module}/do_data.tpl")}"

  vars {
    external_ip = "${aws_network_interface.external.private_ip}/24"
    internal_ip = "${aws_network_interface.internal.private_ip}/24"
  }
}

resource "null_resource" "onboard" {
  provisioner "local-exec" {
    command = <<-EOF
    aws ec2 wait instance-status-ok --instance-ids ${aws_instance.bigip1.id}
    until $(curl -k -u ${var.bigip_admin}:${random_string.password.result} -o /dev/null --silent --fail https://${aws_instance.bigip1.public_ip}/mgmt/shared/declarative-onboarding/example);do sleep 10;done
    curl -k -X POST https://${aws_instance.bigip1.public_ip}/mgmt/shared/declarative-onboarding \
            --retry 60 \
            --retry-connrefused \
            --retry-delay 120 \
            -H "Content-Type: application/json" \
            -u ${var.bigip_admin}:${random_string.password.result} \
            -d '${data.template_file.do_data.rendered} '
    EOF
  }
}

