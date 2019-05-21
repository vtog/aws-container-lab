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
  count             = "${var.bigip_count}"
  subnet_id         = "${var.vpc_subnet[2]}"
  security_groups   = ["${aws_security_group.bigip_external_sg.id}"]
  private_ips_count = 1

  tags = {
    Name = "bigip${count.index + 1}_external"
    Lab  = "Containers"
  }
}

resource "aws_network_interface" "internal" {
  count             = "${var.bigip_count}"
  subnet_id         = "${var.vpc_subnet[4]}"
  security_groups   = ["${aws_security_group.bigip_internal_sg.id}"]
  private_ips_count = 1

  tags = {
    Name = "bigip${count.index + 1}_internal"
    Lab  = "Containers"
  }
}

resource "aws_eip" "mgmt" {
  vpc               = true
  depends_on        = ["aws_network_interface.mgmt"]
  count             = "${var.bigip_count}"
  network_interface = "${element(aws_network_interface.mgmt.*.id, count.index)}"

  tags = {
    Name = "bigip${count.index + 1}_mgmt_eip"
    Lab  = "Containers"
  }
}

resource "aws_eip" "external" {
  vpc               = true
  depends_on        = ["aws_network_interface.external"]
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

resource "aws_instance" "bigip" {
  ami           = "${data.aws_ami.f5_ami.id}"
  instance_type = "${var.instance_type}"
  depends_on    = ["aws_network_interface.mgmt", "aws_network_interface.external","aws_network_interface.internal" ]
  count         = "${var.bigip_count}"
  key_name      = "${var.key_name}"

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

#----- Setup DO & AS3 -----
resource "null_resource" "tmsh" {
  depends_on = ["aws_eip.mgmt", "aws_network_interface.mgmt", "aws_instance.bigip"]
  count      = "${var.bigip_count}"

  provisioner "local-exec" {
    command = <<EOF
    aws ec2 wait instance-status-ok --region ${var.aws_region} --profile ${var.aws_profile} --instance-ids ${element(aws_instance.bigip.*.id, count.index)}

    CREDS=${var.bigip_admin}:${random_string.password.result}
    IP=${element(aws_eip.mgmt.*.public_ip, count.index)}

    ssh -o StrictHostKeyChecking=no ${var.bigip_admin}@$IP 'modify auth user ${var.bigip_admin} password ${random_string.password.result}'
    ssh -o StrictHostKeyChecking=no ${var.bigip_admin}@$IP 'save sys config'
    until $(curl -ku $CREDS -o /dev/null --silent --fail https://$IP/mgmt/shared/iapp/package-management-tasks);do sleep 10;done

    wget -q https://raw.githubusercontent.com/F5Networks/f5-declarative-onboarding/master/dist/${var.do_rpm}
    wget -q https://raw.githubusercontent.com/F5Networks/f5-appsvcs-extension/master/dist/latest/${var.as3_rpm}
    do_LEN=$(wc -c ${var.do_rpm} | cut -f 1 -d ' ')
    as3_LEN=$(wc -c ${var.as3_rpm} | cut -f 1 -d ' ')
    curl -ku $CREDS https://$IP/mgmt/shared/file-transfer/uploads/${var.do_rpm} -H 'Content-Type: application/octet-stream' -H "Content-Range: 0-$((do_LEN - 1))/$do_LEN" -H "Content-Length: $do_LEN" -H 'Connection: keep-alive' --data-binary @${var.do_rpm}
    curl -ku $CREDS https://$IP/mgmt/shared/file-transfer/uploads/${var.as3_rpm} -H 'Content-Type: application/octet-stream' -H "Content-Range: 0-$((as3_LEN - 1))/$as3_LEN" -H "Content-Length: $as3_LEN" -H 'Connection: keep-alive' --data-binary @${var.as3_rpm}

    do_DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/${var.do_rpm}\"}"
    as3_DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/${var.as3_rpm}\"}"
    curl -ku $CREDS https://$IP/mgmt/shared/iapp/package-management-tasks -H "Origin: https://$IP" -H 'Content-Type: application/json;charset=UTF-8' --data $do_DATA
    curl -ku $CREDS https://$IP/mgmt/shared/iapp/package-management-tasks -H "Origin: https://$IP" -H 'Content-Type: application/json;charset=UTF-8' --data $as3_DATA

    rm ${var.do_rpm} ${var.as3_rpm}
    EOF
  }
}

data "template_file" "do_data" {
  count    = "${var.bigip_count}"
  template = "${file("${path.module}/do_data.tpl")}"

  vars {
    host_name   = "${element(aws_instance.bigip.*.private_dns, count.index)}"
    members     = "${join(", ", aws_instance.bigip.*.private_dns)}"
    admin       = "${var.bigip_admin}"
    password    = "${random_string.password.result}" 
    mgmt_ip     = "${element(aws_network_interface.mgmt.*.private_ip, count.index)}/24"
    external_ip = "${element(aws_network_interface.external.*.private_ip, count.index)}/24"
    internal_ip = "${element(aws_network_interface.internal.*.private_ip, count.index)}/24"
  }
}

resource "null_resource" "onboard" {
  depends_on = ["null_resource.tmsh"]
  count      = "${var.bigip_count}"

  provisioner "local-exec" {
    command = <<EOF
    until $(curl -ku ${var.bigip_admin}:${random_string.password.result} -o /dev/null --silent --fail https://${element(aws_eip.mgmt.*.public_ip, count.index)}/mgmt/shared/declarative-onboarding/info);do sleep 10;done
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

output "public_dns" {
  value = "${formatlist("%s = https://%s", aws_instance.bigip.*.tags.Name, aws_instance.bigip.*.public_dns)}"
}

output "public_ip" {
  value = "${formatlist("%s = %s ", aws_instance.bigip.*.tags.Name, aws_instance.bigip.*.public_ip)}"
}

output "password" {
  value = "${random_string.password.result}"
}
