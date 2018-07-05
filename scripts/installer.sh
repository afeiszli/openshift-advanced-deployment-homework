#!/bin/bash

#Master installer file for OpenShift Advanced Deployment Homework

# Based upon the steps in lab 02 - HA Deployment Lab from the OCP Advanced Deployment Class
# Script Author: Jason Smith
# Author Email: jasosmit@redhat.com
# Date: 03JUL18 08:30


# Prepare the environment with the GUID for this installation.
GUID=`hostname | cut -d"." -f2`
echo "GUID idenfied as $GUID"
export GUID=$GUID
echo "export GUID=$GUID" >> $HOME/.bashrc
echo "Setting the GUID environment variable in the .bashrc on each of the hosts"
#ansible all -m shell -a 'export GUID=`hostname | cut -d"." -f2`; echo "export GUID=$GUID" >> $HOME/.bashrc'

#Ensure that atomic-openshift-utils and atomic-openshift-clients are installed
#yum -y install atomic-openshift-utils atomic-openshift-clients

#Download the CA certificate from the shared ldap server. Will need it for the installation of the cluster.
#wget http://ipa.shared.example.opentlc.com/ipa/config/ca.crt -O /root/ipa-ca.crt

#Ask yum to update all packages on the server.
echo "Yum update all packages to their latest version"
ansible-playbook -i inventory/hosts files/ansible_yum_update.yml

#Kick off the ansible-playbook that will check the pre-requisites
echo "Executing ansible-playbook prerequisites.yml"
ansible-playbook -f 20 /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml

#Deploy the cluster using the /etc/ansible/hosts inventory file. This will take a long time to complete.
echo "Executing ansible-playbook deploy_cluster.yml"
echo "This will take 30+ minutes. Go get some coffee"
ansible-playbook -f 20 /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

#Copy the .kube directory to the bastion host
ansible masters[0] -b -m fetch -a "src=/root/.kube/config dest=/root/.kube/config flat=yes"

#Create the PVs on support1 for use with nfs
echo "Creating nfs exports on support1"
ansible nfs -b -m copy -a "src=/root/openshift-advanced-deployment-homework/scripts/create_support_pvs.sh dest=/root/create_support_pvs.sh"
ansible nfs -m shell -a "sh /root/create_support_pvs.sh"


#Create PVs on bastion host. A set of 5G and a set of 10G
echo "Creating PVs on bastion host"
sh ./create_bastion_pvs.sh


#Fix NFS Persistent Volume Recycling
echo "Installing ose-recycler image on all of the nodes"
ansible nodes -m shell -a "docker pull registry.access.redhat.com/openshift3/ose-recycler:latest"
ansible nodes -m shell -a "docker tag registry.access.redhat.com/openshift3/ose-recycler:latest registry.access.redhat.com/openshift3/ose-recycler:v3.9.27"

#Change the network type from subnet to multitenant
#echo "Changing the network from subnet to multitenant"
#ansible-playbook -i /etc/ansible/hosts file/ansible_change_network_policy.yml


#Create the PVs on the support host, and then create PVs on bastion.
ansible-playbook -i /etc/ansible/hosts /root/openshift_advanced_deployment_homework/file/ansible_create_pvs.yml
