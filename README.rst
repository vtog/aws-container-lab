AWS Container Lab
=================

The purpose of this repo is to give a set of scripts that will deploy several
AWS EC2 instances:

- 1x F5 Big-IP (PAYG)
- 3x Kubernetes Cluster (1x Master 2x Node)
- 3x OpenShift Cluster (1x Master 2x Node)

Several assumptions are required:

- AWS Account
- Linux CLI (For my testing I used Debian)

  #. ~/.aws/credentials
  #. ~/.ssh/id_rsa & id_rsa.pub
  #. git installed
  #. terraform installed
  #. ansible installed

Setup:

.. code-block:: bash

   git clone https://github.com/vtog/aws-container-lab.git
   cd aws-container-lab
   terraform apply
   cd kubernetes/ansible
   ansible-playbook playbooks/deploy-kube.yaml
   cd ../../openshift/ansible
   ansible-playbook playbooks/deploy-okd.yaml
    