provider "aws" {
  region = "${var.aws_region}"
}

# Get My Public IP
data "http" "myIP" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_instance" "kube-master1" {
  ami             = "ami-0a313d6098716f372" # Ubuntu 18.04 LTS AMD64
  instance_type   = "t2.medium"
  key_name        = "${aws_key_pair.corp-deb-key.key_name}"
  security_groups = ["${aws_security_group.kube_sg.name}"]
  tags = {
    Name = "kube-master1"
  }
}

resource "aws_instance" "kube-node1" {
  ami             = "ami-0a313d6098716f372" # Ubuntu 18.04 LTS AMD64
  instance_type   = "t2.medium"
  key_name        = "${aws_key_pair.corp-deb-key.key_name}"
  security_groups = ["${aws_security_group.kube_sg.name}"]
  tags = {
    Name = "kube-node1"
  }
}

resource "aws_instance" "kube-node2" {
  ami             = "ami-0a313d6098716f372" # Ubuntu 18.04 LTS AMD64
  instance_type   = "t2.medium"
  key_name        = "${aws_key_pair.corp-deb-key.key_name}"
  security_groups = ["${aws_security_group.kube_sg.name}"]
  tags = {
    Name = "kube-node2"
  }
}

resource "aws_key_pair" "corp-deb-key" {
  key_name   = "corp-deb-key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
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

# write out host file
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

output "kube-master1__public_dns" {
    value = "${aws_instance.kube-master1.public_dns}"
}
output "kube-node1__public_dns" {
    value = "${aws_instance.kube-node1.public_dns}"
}
output "kube-node2__public_dns" {
    value = "${aws_instance.kube-node2.public_dns}"
}

