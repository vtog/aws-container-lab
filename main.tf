provider "aws" {
  profile = "${var.aws_profile}"
  region  = "${var.aws_region}"
}

# Set default SSH key pair
resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

# Deploy Big-IP
module "bigip" {
  source        = "./bigip"
  myIP          = "${chomp(data.http.myIP.body)}/32"
  key_name      = "${var.key_name}"
  instance_type = "${var.bigip_instance_type}"
}

# Deploy Kubernetes
module "kube" {
  source        = "./kubernetes"
  myIP          = "${chomp(data.http.myIP.body)}/32"
  key_name      = "${var.key_name}"
  instance_type = "${var.kube_instance_type}"
}

# Deploy OpenShift
module "okd" {
  source        = "./openshift"
  myIP          = "${chomp(data.http.myIP.body)}/32"
  key_name      = "${var.key_name}"
  instance_type = "${var.okd_instance_type}"
}
