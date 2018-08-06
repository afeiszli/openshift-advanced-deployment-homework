#!/usr/bin/env bash

# Script to uninstall the environment back to pristine state for testing of
# installer script.


# Use the ansible playbook to uninstall openshift

ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/adhoc/uninstall.yml
ansible nodes -a "rm -rf /etc/origin"
ansible nfs -a "rm -rf /srv/nfs/*"
ansible nfs -a "rm /etc/exports.d/openshift-uservols.exports"
rm /etc/ansible/hosts
rm -rf /root/pvs

echo "Environment has been reset."
