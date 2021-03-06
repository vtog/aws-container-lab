AWS Container Lab
=================

The purpose of this repo is to give a set of scripts that deploy several AWS
EC2 instances:

- 1x F5 Big-IP (PAYG)
- 3x Kubernetes Cluster (1x Master 2x Node)
- 3x OpenShift Cluster (1x Master 2x Node)

Several assumptions are made:

- An active AWS Account, with proper IAM configuration.
- Linux CLI (For my testing I used Debian)

  #. ~/.aws/credentials & config (properly configured)
  #. ~/.ssh/id_rsa & id_rsa.pub
  #. git, awscli, terraform, and ansible installed

- Familiarity with

  #. Terraform (updated for .12)
  #. Ansible
  #. AWS CLI
  #. Big-IP
  #. Kubernetes
  #. OpenShift

- Example to show how to find an AMI via AWS CLI. The filter variables can be
  found in tfvars:

  .. code-block:: bash

     aws ec2 describe-images --owners aws-marketplace --filters "Name=product-code,Values=3ouya04g99e5euh4vbxtao1jz" "Name=name,Values=F5 BIGIP-15.1* PAYG-Best 25M*"

The following steps build the AWS EC2 instances, the kubernetes cluster, and
preps the OpenShift nodes.

.. code-block:: bash

   git clone https://github.com/vtog/aws-container-lab.git
   cd aws-container-lab
   terraform apply

After completion you can lookup the bigip1 mgmt url and passwd.

.. code-block:: bash

   terraform refresh
   terraform output

To completly remove the AWS instances and supporting objects, change directory
to the root of this cloned repo and run the following command:

.. code-block:: bash

   terraform destroy
