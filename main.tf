provider "aws" {
  region     = "us-east-1"
}

resource "aws_instance" "kube-master1" {
  ami             = "ami-0a313d6098716f372" # Ubuntu 18.04 LTS AMD64
  instance_type   = "t2.medium"
  key_name        = "${aws_key_pair.corp-deb-key.key_name}"
  security_groups = ["${aws_security_group.kube_sg.name}","${aws_security_group.allow_ssh.name}"]

  tags = {
    Name = "kube-master1"
  }
}

resource "aws_instance" "kube-node1" {
  ami             = "ami-0a313d6098716f372" # Ubuntu 18.04 LTS AMD64
  instance_type   = "t2.micro"
  key_name        = "${aws_key_pair.corp-deb-key.key_name}"
  security_groups = ["${aws_security_group.kube_sg.name}","${aws_security_group.allow_ssh.name}"]

  tags = {
    Name = "kube-node1"
  }
}

resource "aws_instance" "kube-node2" {
  ami             = "ami-0a313d6098716f372" # Ubuntu 18.04 LTS AMD64
  instance_type   = "t2.micro"
  key_name        = "${aws_key_pair.corp-deb-key.key_name}"
  security_groups = ["${aws_security_group.kube_sg.name}","${aws_security_group.allow_ssh.name}"]

  tags = {
    Name = "kube-node2"
  }
}

resource "aws_key_pair" "corp-deb-key" {
  key_name   = "corp-deb-key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["99.36.4.190/32"]
  }
}

resource "aws_security_group" "kube_sg" {
  name = "kube_sg"
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

