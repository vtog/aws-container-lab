provider "aws" {
  region = "${var.aws_region}"
}

# Get My Public IP
data "http" "myIP" {
    url = "http://ipv4.icanhazip.com"
}

# Deploy Big-IP
module "bigip" {
  source = "./bigip"
  myIP   = "${chomp(data.http.myIP.body)}/32"
}

# Deploy Kubernetes
module "kube" {
  source = "./kubernetes"
  myIP   = "${chomp(data.http.myIP.body)}/32"
}

# Deploy OpenShift
module "okd" {
  source = "./openshift"
  myIP   = "${chomp(data.http.myIP.body)}/32"
}
