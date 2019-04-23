provider "aws" {
  region = "${var.aws_region}"
}

# Get My Public IP
data "http" "myIP" {
  url = "http://ipv4.icanhazip.com"
}

# Set default SSH Key
resource "aws_key_pair" "corp-deb-key" {
  key_name   = "corp-deb-key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

# Deploy Big-IP
module "bigip" {
  source  = "./bigip"
  myIP    = "${chomp(data.http.myIP.body)}/32"
  ssh_key = "${aws_key_pair.corp-deb-key.key_name}"
}

# Deploy Kubernetes
module "kube" {
  source  = "./kubernetes"
  myIP    = "${chomp(data.http.myIP.body)}/32"
  ssh_key = "${aws_key_pair.corp-deb-key.key_name}"
}

# Deploy OpenShift
module "okd" {
  source  = "./openshift"
  myIP    = "${chomp(data.http.myIP.body)}/32"
  ssh_key = "${aws_key_pair.corp-deb-key.key_name}"
}
