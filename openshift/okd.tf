
resource "aws_key_pair" "corp-deb-key" {
  key_name   = "corp-deb-key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

data "aws_ami" "centos_ami" {
  most_recent = true
  owners      = ["679593333241"]
  filter {
    name   = "name"
    values = ["CentOS Linux 7*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "okd-master1" {
  ami             = "${data.aws_ami.centos_ami.id}"
  instance_type   = "t2.micro"
  key_name        = "${aws_key_pair.corp-deb-key.key_name}"
  security_groups = ["${aws_security_group.okd_sg.name}"]
  tags = {
    Name = "okd-master1"
  }
}
resource "aws_instance" "okd-node1" {
  ami             = "${data.aws_ami.centos_ami.id}"
  instance_type   = "t2.micro"
  key_name        = "${aws_key_pair.corp-deb-key.key_name}"
  security_groups = ["${aws_security_group.okd_sg.name}"]
  tags = {
    Name = "okd-node1"
  }
}
resource "aws_instance" "okd-node2" {
  ami             = "${data.aws_ami.centos_ami.id}"
  instance_type   = "t2.micro"
  key_name        = "${aws_key_pair.corp-deb-key.key_name}"
  security_groups = ["${aws_security_group.okd_sg.name}"]
  tags = {
    Name = "okd-node2"
  }
}

resource "aws_security_group" "okd_sg" {
  name = "okd_sg"
  ingress {
    from_port   = 22
    to_port     = 22
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
    Name = "okd_sg"
  }
}

# write out okd inventory
data "template_file" "okd-inventory" {
template = <<EOF
[okd-all]
${aws_instance.okd-master1.tags.Name} ansible_host=${aws_instance.okd-master1.public_ip} private_ip=${aws_instance.okd-master1.private_ip}
${aws_instance.okd-node1.tags.Name} ansible_host=${aws_instance.okd-node1.public_ip} private_ip=${aws_instance.okd-node1.private_ip}
${aws_instance.okd-node2.tags.Name} ansible_host=${aws_instance.okd-node2.public_ip} private_ip=${aws_instance.okd-node2.private_ip}

[okd-masters]
${aws_instance.okd-master1.tags.Name} ansible_host=${aws_instance.okd-master1.public_ip}

[okd-nodes]
${aws_instance.okd-node1.tags.Name} ansible_host=${aws_instance.okd-node1.public_ip}
${aws_instance.okd-node2.tags.Name} ansible_host=${aws_instance.okd-node2.public_ip}

[all:vars]
ansible_user=centos
ansible_become=true
ansible_python_interpreter=/usr/bin/python3
EOF
}

resource "local_file" "save_okd-inventory" {
  depends_on = ["data.template_file.okd-inventory"]
  content = "${data.template_file.okd-inventory.rendered}"
  filename = "./openshift/ansible/inventory.ini"
}

output "okd-master1__public_dns" {
  value = "${aws_instance.okd-master1.public_dns}"
}
output "okd-node1__public_dns" {
  value = "${aws_instance.okd-node1.public_dns}"
}
output "okd-node2__public_dns" {
  value = "${aws_instance.okd-node2.public_dns}"
}
