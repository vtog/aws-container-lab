provider "aws" {
  region     = "us-east-1"
}

resource "aws_instance" "example" {
  ami             = "ami-0a313d6098716f372" # Ubuntu 18.04 LTS AMD64
  instance_type   = "t2.micro"
  key_name        = "${aws_key_pair.my-key.key_name}"
  security_groups = ["${aws_security_group.allow_ssh.name}"]
}

resource "aws_instance" "kube-master1" {
    ami             = "ami-0a313d6098716f372" # Ubuntu 18.04 LTS AMD64
    instance_type   = "t2.micro"
    key_name        = "${aws_key_pair.my-key.key_name}"
    security_groups = ["${aws_security_group.allow_ssh.name}"]
}

resource "aws_key_pair" "my-key" {
  key_name   = "my-key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "example_public_dns" {
  value = "${aws_instance.example.public_dns}"
}

output "kube-master1__public_dns" {
    value = "${aws_instance.kube-master1.public_dns}"
}

