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
ansible all -m shell -a 'export GUID=`hostname | cut -d"." -f2`; echo "export GUID=$GUID" >> $HOME/.bashrc'

#Ensure that atomic-openshift-utils and atomic-openshift-clients are installed
yum -y install atomic-openshift-utils atomic-openshift-clients

#Download the CA certificate from the shared ldap server. Will need it for the installation of the cluster.
wget http://ipa.shared.example.opentlc.com/ipa/config/ca.crt -O /root/ipa-ca.crt


#Kick off the ansible-playbook that will check the pre-requisites
echo "Executing ansible-playbook prerequisites.yml"
ansible-playbook -f 20 /usr/share/ansible/openshift-ansible/playbooks/prerequisites.yml

#Deploy the cluster using the /etc/ansible/hosts inventory file. This will take a long time to complete.
echo "Executing ansible-playbook deploy_cluster.yml"
echo "This will take 30+ minutes. Go get some coffee"
ansible-playbook -f 20 /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml
