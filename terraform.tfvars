aws_profile = "vtog"
aws_region  = "us-east-2"
vpc_cidr    = "10.1.0.0/16"

cidrs = {
  mgmt1     = "10.1.1.0/24"
  external1 = "10.1.2.0/24"
  internal1 = "10.1.3.0/24"
}

key_name            = "container-lab-key"
public_key_path     = "~/.ssh/id_rsa.pub"
kube_instance_type  = "t2.medium"
kube_count          = 3
okd_instance_type   = "t3.medium"
okd_count           = 3
bigip_instance_type = "m5.large"
bigip_count         = 2

# BYOL
#bigip_ami_prod_code  = "6h6xg9ndbxsrp5iyuotryhl0q"
#bigip_ami_name_filt = "F5 BIGIP-14.1* BYOL-LTM 2Boot*"

# PAYG
bigip_ami_prod_code = "3ouya04g99e5euh4vbxtao1jz"
#bigip_ami_name_filt = "F5 BIGIP-14.1* PAYG-Best 25M*"
bigip_ami_name_filt  = "F5 Networks BIGIP-14.0* PAYG - Best 25M*"
#bigip_ami_name_filt  = "F5 Networks BIGIP-13.1* PAYG - Best 25M*"
#bigip_ami_name_filt  = "F5 Networks Licensed Hourly BIGIP-12.1* Best 25M*"

bigip_admin = "admin"
do_rpm      = "f5-declarative-onboarding-1.5.0-11.noarch.rpm"
as3_rpm     = "f5-appsvcs-3.12.0-5.noarch.rpm"

