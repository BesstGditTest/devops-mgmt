# devops-mgmt
A Project for automating the dev-ops infrastructure accross multiple ADOs

## How it Works
The "devops-mgmt.yaml" file under /cloudformation is the cloudformation script used to automate everything from one command/run. As of now, this script creates three ec2 instance. One for Jenkins, one for SonarQube and one for Nexus. It also creates an EBS volume which it attaches to the Jenkins ec2 instance.

The Jenkins ec2 instance uses user-data to clone this repo from a remote source and then run the /setup_scripts/bootstrap.sh script. The bootstrap.sh script setups the ebs volume, installs ansible, and runs the chosen ansible playbooks. 

The goal is for the ADO teams to be given the bootstrap.yml script and automatically create everything from there. 

## Setup  
### Github
Create personal access token for the jenkins service account **Settings > Personal access tokens > Generate new token**

### AWS Console 
Create jeknins-master-key key pair. **EC2 > Key Pairs**  
Create jenkins-deploy-key key pair. **EC2 > Key Pairs**  
Create Encryption key to secure param store. Set desired key admin and user. **IAM > Encryption Keys**  
Create Paramerts to be used by the scripts **AWS Systems Manager > Parameter store > Create parameter**
> **Parameters**: JenkinsDeployKey, GithubToken  
> **Type**:  SecureString  
> **KMS key source**: My current account  
> **KMS keys ID**: "choose Encryption key alias created for param store"  
> **Value**: Respective values for the two params

Generate the cloudformation script **CloudFormation > Create Stack** :
- choose to upload the template from file. 
- name the stack "devops-mgmt"
- update the parameters accordingly for the ADO environment
- Continue until "Create" is an option. Check the radio button to acknowledge IAM resources.



 ## Notes
 ### Thirparty Sources:
 - Jenkins: https://github.com/geerlingguy/ansible-role-jenkins
 - Java: https://github.com/geerlingguy/ansible-role-java
 - Apache: https://github.com/geerlingguy/ansible-role-apache
 - SonarQube: https://github.com/Hylke1982/ansible-role-sonar
- Nexus: https://github.com/savoirfairelinux/ansible-nexus3-oss
> Change made: added ansible resource to update permissions on install directory  
> task: nexus_install.yml  
> - name: Update permissions on nexus install dir
  file:
    dest: "{{ nexus_installation_dir }}/nexus-{{ nexus_version }}"
    owner: "{{ nexus_os_user }}"
    group: "{{ nexus_os_group }}"
    recurse: yes
 
- MySql: https://github.com/geerlingguy/ansible-role-mysql
> Change made: account for SELINUX issue.  
> task: configure.yml  
>  - -name: Change context on error log file  (if configured).
  command: chcon system_u:object_r:mysqld_log_t:s0 "{{ mysql_log_error }}"
  when: mysql_log == "" and mysql_log_error != "" 

### To Do:
- DNS
- User / SSH management
- Fortify
- Gradle / Maven bootstrap
- Automated testing framework/s
- HA / CloudWatch
- Please add any more ideas below...
 ### Potential Changes:
- **Ansible Galaxy**: The thirdparty ansible roles have been manually downloaded from Ansible Galaxy. We may want to consider using Ansible Galaxy versioning/pulling instead of manually updating these roles.
- **Docker**: maintain creation of Jenkins, nexus, sonarqube, etc... through containers.
	- Run jenkins agents as docker containers on sonarqube ec2-instance. This better utilizes existing resources
- **OWASP Dependency Checker / ZAP**