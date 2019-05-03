aws_profile         = "default"
aws_region          = "us-east-1"
vpc_cidr            = "10.0.0.0/16"

cidrs               = {
  mgmt              = "10.0.0.0/24"
  external1         = "10.0.1.0/24"
  external2         = "10.0.2.0/24"
  internal1         = "10.0.3.0/24"
  internal2         = "10.0.4.0/24"
}

myIP                = "1.1.1.1"
key_name            = "corp-dev-key"
public_key_path     = "~/.ssh/id_rsa.pub"
kube_instance_type  = "t2.medium"
okd_instance_type   = "t2.medium"
bigip_instance_type = "m5.large"
bigip_admin         = "admin"
bigip_count         = 1
do_rpm_url          = "https://github.com/F5Networks/f5-declarative-onboarding/raw/master/dist/f5-declarative-onboarding-1.3.0-4.noarch.rpm"
as3_rpm_url         = "https://github.com/F5Networks/f5-appsvcs-extension/raw/master/dist/latest/f5-appsvcs-3.10.0-5.noarch.rpm"
