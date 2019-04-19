provider "aws" {
  region = "${var.aws_region}"
}

# Get My Public IP
data "http" "myIP" {
  url = "http://ipv4.icanhazip.com"
}

data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
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
  instance_type   = "t2.medium"
  key_name        = "${aws_key_pair.corp-deb-key.key_name}"
  security_groups = ["${aws_security_group.bigip_sg.name}"]
  tags = {
    Name = "bigip1"
  }
}

resource "aws_instance" "kube-master1" {
  ami             = "${data.aws_ami.ubuntu_ami.id}"
  instance_type   = "t2.medium"
  key_name        = "${aws_key_pair.corp-deb-key.key_name}"
  security_groups = ["${aws_security_group.kube_sg.name}"]
  tags = {
    Name = "kube-master1"
  }
}

resource "aws_instance" "kube-node1" {
  ami             = "${data.aws_ami.ubuntu_ami.id}"
  instance_type   = "t2.medium"
  key_name        = "${aws_key_pair.corp-deb-key.key_name}"
  security_groups = ["${aws_security_group.kube_sg.name}"]
  tags = {
    Name = "kube-node1"
  }
}

resource "aws_instance" "kube-node2" {
  ami             = "${data.aws_ami.ubuntu_ami.id}"
  instance_type   = "t2.medium"
  key_name        = "${aws_key_pair.corp-deb-key.key_name}"
  security_groups = ["${aws_security_group.kube_sg.name}"]
  tags = {
    Name = "kube-node2"
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

resource "aws_key_pair" "corp-deb-key" {
  key_name   = "corp-deb-key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_security_group" "bigip_sg" {
  name = "bigip_sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
  }
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    ="tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
  }
  name = "bigip_sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
  }
  name = "bigip_sg"
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
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

resource "aws_security_group" "kube_sg" {
  name = "kube_sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
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
    Name = "kube_sg"
  }
}
resource "aws_security_group" "okd_sg" {
  name = "okd_sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
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

# write out kube inventory
data "template_file" "inventory" {
template = <<EOF
[kube-all]
${aws_instance.kube-master1.tags.Name} ansible_host=${aws_instance.kube-master1.public_ip} private_ip=${aws_instance.kube-master1.private_ip}
${aws_instance.kube-node1.tags.Name} ansible_host=${aws_instance.kube-node1.public_ip} private_ip=${aws_instance.kube-node1.private_ip}
${aws_instance.kube-node2.tags.Name} ansible_host=${aws_instance.kube-node2.public_ip} private_ip=${aws_instance.kube-node2.private_ip}

[kube-masters]
${aws_instance.kube-master1.tags.Name} ansible_host=${aws_instance.kube-master1.public_ip}

[kube-nodes]
${aws_instance.kube-node1.tags.Name} ansible_host=${aws_instance.kube-node1.public_ip}
${aws_instance.kube-node2.tags.Name} ansible_host=${aws_instance.kube-node2.public_ip}

[all:vars]
ansible_user=ubuntu
ansible_become=true
ansible_python_interpreter=/usr/bin/python3
EOF
}

resource "local_file" "save_inventory" {
  depends_on = ["data.template_file.inventory"]
  content = "${data.template_file.inventory.rendered}"
  filename = "./kubernetes/ansible/inventory.ini"
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

output "bigip1__public_dns" {
  value = "${aws_instance.bigip1.public_dns}"
}
output "kube-master1__public_dns" {
  value = "${aws_instance.kube-master1.public_dns}"
}
output "kube-node1__public_dns" {
  value = "${aws_instance.kube-node1.public_dns}"
}
output "kube-node2__public_dns" {
  value = "${aws_instance.kube-node2.public_dns}"
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
