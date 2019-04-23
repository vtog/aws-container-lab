AWS Container Lab
=================

The purpose of this repo is to give a set of scripts that will deploy several
AWS EC2 instances:

- 1x F5 Big-IP (PAYG)
- 3x Kubernetes Cluster (1x Master 2x Node)
- 3x OpenShift Cluster (1x Master 2x Node)

Several required assumptions are made:

- AWS Account
- Linux CLI (For my testing I used Debian)

  #. ~/.aws/credentials (properly configured)
  #. ~/.ssh/id_rsa & id_rsa.pub
  #. git, terraform, and ansible installed

The following steps build the AWS EC2 instances and the kubernetes cluster.

.. code-block:: bash

   git clone https://github.com/vtog/aws-container-lab.git
   cd aws-container-lab
   terraform apply
   cd kubernetes/ansible
   ansible-playbook playbooks/deploy-kube.yaml
   cd ../../openshift/ansible
   ansible-playbook playbooks/deploy-okd.yaml

Additional steps are required for OpenShift. Once the playbooks from the
previous steps are finished connect to **okd-master1** and run the following
commands:

.. code-block:: bash

   ansible-playbook -i $HOME/agilitydocs/openshift/ansible/inventory.ini $HOME/openshift-ansible/playbooks/prerequisites.yml
   ansible-playbook -i $HOME/agilitydocs/openshift/ansible/inventory.ini $HOME/openshift-ansible/playbooks/deploy_cluster.yml

   sudo htpasswd -b /etc/origin/master/htpasswd centos centos
   oc adm policy add-cluster-role-to-user cluster-admin centos
