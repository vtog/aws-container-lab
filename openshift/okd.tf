
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
  instance_type   = "${var.instance_type}"
  key_name        = "${var.ssh_key}"
  security_groups = ["${aws_security_group.okd_sg.name}"]
  tags = {
    Name = "okd-master1"
  }
}
resource "aws_instance" "okd-node1" {
  ami             = "${data.aws_ami.centos_ami.id}"
  instance_type   = "${var.instance_type}"
  key_name        = "${var.ssh_key}"
  security_groups = ["${aws_security_group.okd_sg.name}"]
  tags = {
    Name = "okd-node1"
  }
}
resource "aws_instance" "okd-node2" {
  ami             = "${data.aws_ami.centos_ami.id}"
  instance_type   = "${var.instance_type}"
  key_name        = "${var.ssh_key}"
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
  content = "${data.template_file.inventory.rendered}"
  filename = "./openshift/ansible/inventory.ini"
}

resource "local_file" "save_inventory-okd" {
  depends_on = ["data.template_file.inventory-okd"]
  content = "${data.template_file.inventory-okd.rendered}"
  filename = "./openshift/ansible/inventory-okd.ini"
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