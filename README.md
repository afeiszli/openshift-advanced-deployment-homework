<!-- TITLE: Openshift Ha Deployment Homework -->
<!-- SUBTITLE: Git Repository for my Open Shift HA Deployment Homework -->


# OpenShift Advanced Deployment Homework
This is the repository to store all of the artifacts required for the Open Shift Advanced Deployment Homework Assignment.  Upon completion, this repository will contain everything required to do the following.

* Setup and label the nodes.
* Configure logging and metrics.
* Configure persistent storage for the logging and metrics.
* Setup resource limits
* Deploy jenkins and configure the openshift pipeline for CICD workflow.
* Setup security for two companies, and two users within each company.
* Setup dedicated node for each company.
* Setup the network to isolate each company.
* Setup and configure a loadbalancer across the masters.
* Setup and configure a wildcard domain \*.apps.GUID.DOMAIN
* Setup and configure a service and router for a sample application
* Create resource limits for all new projects
* All items above must be completed in an automated fashion with minimal user intervention required.
* Provide documentation around all of the above.

# Installation instructions
1. `$ ssh -i ~/.ssh/your_private_key_name <OPENTLC Username>@bastion.<GUID>.example.opentlc.com`
2. `git clone https://github.com/rallour/openshift-advanced-deployment-homework.git`
3. `cd openshift-advanced-deployment-homework`
4. `sh scripts/installer.sh -g <GUID>`
5. Get comfortable.  The entire installation will take approximately 45 minutes to complete.

# Disclaimer
This repository and all of the artifacts inside of it are the result of the classes I just attended. All items in this repository are **NOT** officially (or unofficially) produced by Red Hat in any manner.  Almost all of this content is based upon other people's work, the documentation, or notes taken during the class.  All mistakes, errors and omissions are my own.  I strongly urge you not to use the contents of this repository for anything you care about in the slightest.  There are bound to be mistakes of one kind or another, and your entire cluster may burst into flames if you use the inventory, templates, or any playbooks contained in this repository.  You have been warned.
