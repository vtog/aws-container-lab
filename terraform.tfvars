aws_profile         = "default"
aws_region          = "us-east-1"
vpc_cidr            = "10.0.0.0/16"

cidrs               = {
  private1          = "10.0.0.0/24"
  public1           = "10.0.1.0/24"
}

myIP                = "1.1.1.1"
key_name            = "corp-dev-key"
public_key_path     = "~/.ssh/id_rsa.pub"
kube_instance_type  = "t2.micro"
okd_instance_type   = "t2.micro"
bigip_instance_type = "t2.medium"
