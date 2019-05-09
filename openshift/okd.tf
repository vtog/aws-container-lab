data "aws_ami" "centos_ami" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "product-code"
    values = ["aw0evgkw8e5c1q413zgy5pjce"]
  }

  filter {
    name   = "name"
    values = ["CentOS Linux 7*"]
  }
}

resource "aws_instance" "okd-master1" {
  ami                    = "${data.aws_ami.centos_ami.id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.okd_sg.id}"]
  subnet_id              = "${var.vpc_subnet[0]}"

  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name = "okd-master1"
    Lab  = "Containers"
  }
}

resource "aws_instance" "okd-node1" {
  ami                    = "${data.aws_ami.centos_ami.id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.okd_sg.id}"]
  subnet_id              = "${var.vpc_subnet[0]}"

  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name = "okd-node1"
    Lab  = "Containers"
  }
}

resource "aws_instance" "okd-node2" {
  ami                    = "${data.aws_ami.centos_ami.id}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.okd_sg.id}"]
  subnet_id              = "${var.vpc_subnet[1]}"

  root_block_device {
    delete_on_termination = true
  }

  tags = {
    Name = "okd-node2"
    Lab  = "Containers"
  }
}

resource "aws_security_group" "okd_sg" {
  name   = "okd_sg"
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
    Name = "okd_sg"
    Lab  = "Containers"
  }
}

# write out centos inventory
data "template_file" "inventory" {
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
ansible_python_interpreter=/usr/bin/python2
EOF
}

# write out okd inventory
data "template_file" "inventory-okd" {
  template = <<EOF
[OSEv3:children]
masters
nodes
etcd

[masters]
${aws_instance.okd-master1.tags.Name}

[etcd]
${aws_instance.okd-master1.tags.Name}

[nodes]
${aws_instance.okd-master1.tags.Name} openshift_public_hostname=${aws_instance.okd-master1.tags.Name} openshift_schedulable=true openshift_node_group_name="node-config-master-infra"
${aws_instance.okd-node1.tags.Name} openshift_public_hostname=${aws_instance.okd-node1.tags.Name} openshift_schedulable=true openshift_node_group_name="node-config-compute"
${aws_instance.okd-node2.tags.Name} openshift_public_hostname=${aws_instance.okd-node2.tags.Name} openshift_schedulable=true openshift_node_group_name="node-config-compute"

[OSEv3:vars]
ansible_ssh_user=centos
ansible_become=true
enable_excluders=false
enable_docker_excluder=false
ansible_service_broker_install=false

containerized=true
openshift_disable_check=disk_availability,memory_availability,docker_storage,docker_image_ava

deployment_type=origin
openshift_deployment_type=origin

openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider'}]

openshift_master_api_port=8443
openshift_master_console_port=8443

openshift_metrics_install_metrics=false
openshift_logging_install_logging=false
EOF
}

resource "local_file" "save_inventory" {
  depends_on = ["data.template_file.inventory"]
  content    = "${data.template_file.inventory.rendered}"
  filename   = "./openshift/ansible/inventory.ini"
}

resource "local_file" "save_inventory-okd" {
  depends_on = ["data.template_file.inventory-okd"]
  content    = "${data.template_file.inventory-okd.rendered}"
  filename   = "./openshift/ansible/inventory-okd.ini"
}

#----- Run Ansible Playbook -----
resource "null_resource" "ansible" {
  provisioner "local-exec" {
    working_dir = "./openshift/ansible/"
    command     = "aws ec2 wait instance-status-ok --region ${var.aws_region} --profile ${var.aws_profile} --instance-ids ${aws_instance.okd-master1.id} ${aws_instance.okd-node1.id} ${aws_instance.okd-node2.id} --profile vtog && ansible-playbook ./playbooks/deploy-okd.yaml"
  }
}
