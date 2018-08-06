#!/bin/bash

#Master installer file for OpenShift Advanced Deployment Homework

# Based upon the steps in lab 02 - HA Deployment Lab from the OCP Advanced Deployment Class
# Script Author: Jason Smith
# Author Email: jasosmit@redhat.com
# Date: 24JUL18 12:29

echo "Copy inventory file to the correct place"
cp inventory/hosts /etc/ansible/hosts

# Prepare the environment with the GUID for this installation.
GUID=`hostname | cut -d"." -f2`
echo "GUID idenfied as $GUID"
export GUID=$GUID
echo "export GUID=$GUID" >> $HOME/.bashrc
echo "Setting the GUID environment variable in the .bashrc on each of the hosts"
#ansible all -m shell -a 'export GUID=`hostname | cut -d"." -f2`; echo "export GUID=$GUID" >> $HOME/.bashrc'

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

#Copy the .kube directory to the bastion host
ansible masters[0] -b -m fetch -a "src=/root/.kube/config dest=/root/.kube/config flat=yes"

#Copy the .kube directory to my work installation (Only needed after environment rebuild)
#cp -r ~/.kube/config /home/jasosmit*/
#scp jasosmit-redhat.com@bastion.ae9d.example.opentlc.com:~/.kube/config ~/.kube/config

#Create the PVs on support1 for use with nfs
#echo "Creating nfs exports on support1"
#ansible nfs -b -m copy -a "src=/root/openshift-advanced-deployment-homework/scripts/create_support_pvs.sh dest=/root/create_support_pvs.sh"
#ansible nfs -m shell -a "sh /root/create_support_pvs.sh"


#Fix NFS Persistent Volume Recycling
echo "Installing ose-recycler image on all of the nodes"
ansible nodes -m shell -a "docker pull registry.access.redhat.com/openshift3/ose-recycler:latest"
ansible nodes -m shell -a "docker tag registry.access.redhat.com/openshift3/ose-recycler:latest registry.access.redhat.com/openshift3/ose-recycler:v3.9.27"

#Change the network type from subnet to multitenant
#echo "Changing the network from subnet to multitenant"
#ansible-playbook -i /etc/ansible/hosts file/ansible_change_network_policy.yml


#Create the PVs on the support host, and then create PVs on bastion.
ansible-playbook -i /etc/ansible/hosts /root/openshift-advanced-deployment-homework/file/ansible_create_pvs.yml


#Update the default project template to have limits
oc create -f applier/templates/default_project_template.yaml -n default

#Remove the ability for users to provision their own projects.
oc patch clusterrolebinding.rbac self-provisioners -p '{"subjects": null}'

#Create customer user groups, and add the users to each group.
ansible-playbook applier/apply.yml -i applier/inventory/ -e target=ocp-homework

#Make sure that alpha can create applications inside of alpha Namespace
#and the same thing for beta client
oc adm policy add-role-to-group admin alpha -n alpha-project
oc adm policy add-role-to-group admin beta -n beta-project



# Login as user admin1
# oc login -u admin1 -p r3dh4t1!

################################################################################
############################ NEXUS #############################################
################################################################################

#Create a project for nexus
# oc new-project $GUID-nexus --display-name "Nexus"
#oc new-app sonatype/nexus3:latest
#oc expose svc nexus3
#oc rollout pause dc nexus3
#oc patch dc nexus3 --patch='{ "spec": { "strategy": { "type": "Recreate" }}}'
#oc set resources dc nexus3 --limits=memory=2Gi --requests=memory=1Gi
#oc process -f applier/templates/nexus3_pvc.yml -l app=nexus3 -n $GUID-nexus | oc create -f -
#oc set volume dc/nexus3 --add --overwrite --name=nexus3-volume-1 --mount-path=/nexus-data/ --type persistentVolumeClaim --claim-name=nexus-pvc
#oc set probe dc/nexus3 --liveness --failure-threshold 3 --initial-delay-seconds 60 -- echo ok
#oc set probe dc/nexus3 --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8081/repository/maven-public/
#oc rollout resume dc nexus3
#curl -o setup_nexus3.sh -s https://raw.githubusercontent.com/wkulhanek/ocp_advanced_development_resources/master/nexus/setup_nexus3.sh
#chmod +x setup_nexus3.sh
#./setup_nexus3.sh admin admin123 http://$(oc get route nexus3 --template='{{ .spec.host }}')
#rm setup_nexus3.sh
#oc expose dc nexus3 --port=5000 --name=nexus-registry
# oc create route edge nexus-registry --service=nexus-registry --port=5000

#### Ansible Applier Method ####
###  cd ocp-39-adv-deployment-homework directory ###
# ansible-playbook applier/apply.yml -i applier/inventory/ -e target=nexus -e GUID=ae9d
# curl -o setup_nexus3.sh -s https://raw.githubusercontent.com/wkulhanek/ocp_advanced_development_resources/master/nexus/setup_nexus3.sh
# chmod +x setup_nexus3.sh
# ./setup_nexus3.sh admin admin123 http://$(oc get route nexus3 --template='{{ .spec.host }}')
# rm setup_nexus3.sh
# oc expose dc nexus3 --port=5000 --name=nexus-registry
# oc create route edge nexus-registry --service=nexus-registry --port=5000


################################################################################
############################ SONARQUBE #########################################
################################################################################

### Will deploy both sonarqube and postgresql in the same namespace and hook them
# together.

#ansible-playbook applier/apply.yml -i applier/inventory/ -e target=cicd-sonarqube -e GUID=ae9d





################################################################################
############################ JENKINS ###########################################
################################################################################

oc new-project ${GUID}-jenkins --display-name "Jenkins"
ansible-playbook applier/apply.yml -i applier/inventory/ -e target=cicd-jenkins -e GUID=$GUID
oc new-project project-openshift-tasks --display-name "Open Shift Tasks Project"
oc policy add-role-to-user edit system:serviceaccount:${GUID}-jenkins:jenkins -n project-openshift-tasks
ansible-playbook applier/apply.yml -i applier/inventory/ -e target=cicd-template-jenkins -e GUID=$GUID
oc start-build bc/openshift-tasks-pipeline
oc autoscale dc/tasks --min=1 --max=5 --cpu-percent=75 -n project-openshift-tasks


#oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi
#mkdir $HOME/jenkins-slave-appdev
#cd  $HOME/jenkins-slave-appdev

#docker build . -t docker-registry-default.apps.${GUID}.example.opentlc.com/jenkins/jenkins-slave-maven-appdev:v3.9
#docker login -u admin1 -p $(oc whoami -t) docker-registry-default.apps.${GUID}.example.opentlc.com
