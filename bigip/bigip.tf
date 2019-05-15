data "aws_ami" "f5_ami" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "product-code"
    values = ["${var.bigip_ami_prod_code}"]
  }

  filter {
    name   = "name"
    values = ["${var.bigip_ami_name_filt}"]
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
    Lab  = "Containers"
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
    Lab  = "Containers"
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  tags = {
    Name = "bigip_internal_sg"
    Lab  = "Containers"
  }
}

resource "aws_network_interface" "mgmt" {
  count           = "${var.bigip_count}"
  subnet_id       = "${var.vpc_subnet[0]}"
  security_groups = ["${aws_security_group.bigip_mgmt_sg.id}"]

  tags = {
    Name = "bigip${count.index + 1}_mgmt"
    Lab  = "Containers"
  }
}

resource "aws_network_interface" "external" {
  count           = "${var.bigip_count}"
  subnet_id       = "${var.vpc_subnet[1]}"
  security_groups = ["${aws_security_group.bigip_external_sg.id}"]

  tags = {
    Name = "bigip${count.index + 1}_external"
    Lab  = "Containers"
  }
}

resource "aws_network_interface" "internal" {
  count           = "${var.bigip_count}"
  subnet_id       = "${var.vpc_subnet[2]}"
  security_groups = ["${aws_security_group.bigip_internal_sg.id}"]

  tags = {
    Name = "bigip${count.index + 1}_internal"
    Lab  = "Containers"
  }
}

resource "aws_eip" "mgmt" {
  vpc               = true
  depends_on        = ["aws_network_interface.mgmt", "aws_instance.bigip"]
  count             = "${var.bigip_count}"
  network_interface = "${element(aws_network_interface.mgmt.*.id, count.index)}"

  tags = {
    Name = "bigip${count.index + 1}_mgmt_eip"
    Lab  = "Containers"
  }
}

resource "aws_eip" "external" {
  vpc               = true
  depends_on        = ["aws_network_interface.external", "aws_instance.bigip"]
  count             = "${var.bigip_count}"
  network_interface = "${element(aws_network_interface.external.*.id, count.index)}"

  tags = {
    Name = "bigip${count.index + 1}_external_eip"
    Lab  = "Containers"
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

resource "aws_instance" "bigip" {
  ami           = "${data.aws_ami.f5_ami.id}"
  instance_type = "${var.instance_type}"
  count         = "${var.bigip_count}"
  key_name      = "${var.key_name}"

  user_data = "${data.template_file.cloudinit_data.rendered}"

  network_interface {
    network_interface_id = "${element(aws_network_interface.mgmt.*.id, count.index)}"
    device_index         = 0
  }

  network_interface {
    network_interface_id = "${element(aws_network_interface.external.*.id, count.index)}"
    device_index         = 1
  }

  network_interface {
    network_interface_id = "${element(aws_network_interface.internal.*.id, count.index)}"
    device_index         = 2
  }

  tags = {
    Name = "bigip${count.index + 1}"
    Lab  = "Containers"
  }
}

data "template_file" "do_data" {
  count    = "${var.bigip_count}"
  template = "${file("${path.module}/do_data.tpl")}"

  vars {
    host_name   = "bigip${count.index + 1}.f5demos.com"
    external_ip = "${element(aws_network_interface.external.*.private_ip, count.index)}/24"
    internal_ip = "${element(aws_network_interface.internal.*.private_ip, count.index)}/24"
  }
}

resource "null_resource" "onboard" {
  depends_on = ["aws_eip.mgmt", "aws_network_interface.mgmt", "aws_instance.bigip"]
  count      = "${var.bigip_count}"

  provisioner "local-exec" {
    command = <<-EOF
    aws ec2 wait instance-status-ok --region ${var.aws_region} --profile ${var.aws_profile} --instance-ids ${element(aws_instance.bigip.*.id, count.index)}
    until $(curl -ku ${var.bigip_admin}:${random_string.password.result} -o /dev/null --silent --fail https://${element(aws_eip.mgmt.*.public_ip, count.index)}/mgmt/shared/declarative-onboarding/example);do sleep 10;done
    curl -k -X POST https://${element(aws_eip.mgmt.*.public_ip, count.index)}/mgmt/shared/declarative-onboarding \
            --retry 10 \
            --retry-connrefused \
            --retry-delay 30 \
            -H "Content-Type: application/json" \
            -u ${var.bigip_admin}:${random_string.password.result} \
            -d '${data.template_file.do_data.*.rendered[count.index]} '
    EOF
  }
}

#-------- bigip output --------

resource "null_resource" "host-ip" {
  depends_on = ["aws_instance.bigip"]
  count      = "${var.bigip_count}"

  triggers {
    value = "${element(aws_instance.bigip.*.tags.Name, count.index)}=${element(aws_instance.bigip.*.public_ip, count.index)}"
  }
}

resource "null_resource" "host-dns" {
  depends_on = ["aws_instance.bigip"]
  count      = "${var.bigip_count}"

  triggers {
    value = "${element(aws_instance.bigip.*.tags.Name, count.index)}=${element(aws_instance.bigip.*.public_dns, count.index)}"
  }
}

output "public_dns" {
  value = "${join(" ; ", null_resource.host-dns.*.triggers.value)}"
}

output "public_ip" {
  value = "${join(" ; ", null_resource.host-ip.*.triggers.value)}"
}

output "password" {
  value = "${random_string.password.result}"
}
