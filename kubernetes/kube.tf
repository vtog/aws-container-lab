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

resource "aws_instance" "kube-master1" {
  ami                    = "${data.aws_ami.ubuntu_ami.id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.kube_sg.id}"]
  subnet_id              = "${var.vpc_subnet}"

  tags = {
    Name = "kube-master1"
  }
}

resource "aws_instance" "kube-node1" {
  ami                    = "${data.aws_ami.ubuntu_ami.id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.kube_sg.id}"]
  subnet_id              = "${var.vpc_subnet}"

  tags = {
    Name = "kube-node1"
  }
}

resource "aws_instance" "kube-node2" {
  ami                    = "${data.aws_ami.ubuntu_ami.id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.kube_sg.id}"]
  subnet_id              = "${var.vpc_subnet}"

  tags = {
    Name = "kube-node2"
  }
}

resource "aws_security_group" "kube_sg" {
  name   = "kube_sg"
  vpc_id = "${var.vpc_id}"

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
    cidr_blocks = ["${var.vpc_cidr}"]
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
ansible_python_interpreter=/usr/bin/python3
EOF
}

resource "local_file" "save_inventory" {
  depends_on = ["data.template_file.inventory"]
  content    = "${data.template_file.inventory.rendered}"
  filename   = "./kubernetes/ansible/inventory.ini"
}

#----- Run Ansible Playbook -----
resource "null_resource" "ansible" {
  provisioner "local-exec" {
    command = "aws ec2 wait instance-running --instance-ids ${aws_instance.kube-master1.id} ${aws_instance.kube-node1.id} ${aws_instance.kube-node2.id} --profile default && cd ./kubernetes/ansible && ansible-playbook ./playbooks/deploy-kube.yaml"
  }
}
