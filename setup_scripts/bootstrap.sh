#! /usr/bin/sh

# Setup EBS volume
mkfs.xfs /dev/nvme1n1;
mkdir /var/lib/jenkins;
mount /dev/nvme1n1 /var/lib/jenkins/;
cp /etc/fstab /etc/fstab.orig;
echo "/dev/nvme1n1 /var/lib/jenkins xfs defaults,noatime 0 2" >> /etc/fstab;
mount -a;

# Install ansible
echo "setting up ansible";
yum install wget -y;
http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm;
rpm -ivh epel-release-latest-7.noarch.rpm;
yum install ansible -y;

# This may need to be run if issues arise from the java install for jenkins
yum erase nss-3.28.4-12.el7_4.x86_64 -y;

# Remove require tty for ec2-user
cp /etc/sudoers /etc/sudoers.org;
echo 'Defaults:ec2-user !requiretty' >> /etc/sudoers;

#Create host list for playbooks
NEXUS_IP=`cat /home/ec2-user/nexus_ip`;
SONAR_IP=`cat /home/ec2-user/sonar_ip`''
echo "[nexus]" > /home/ec2-user/devops_hosts;
echo "$NEXUS_IP" >> /home/ec2-user/devops_hosts;
echo "[sonar]" >> /home/ec2-user/devops_hosts;
echo "$SONAR_IP" >> /home/ec2-user/devops_hosts;

chmod 700 /home/ec2-user/.ssh;
chmod 600 /home/ec2-user/.ssh/id_rsa;
chmod 600 /home/ec2-user/github-token;
chown -R ec2-user:ec2-user /home/ec2-user;

# Run playbooks to provision mgmt stack
su ec2-user -c 'ansible-playbook -i /home/ec2-user/devops_hosts /home/ec2-user/devops-mgmt/playbooks/jenkins.yml &';
su ec2-user -c 'ansible-playbook -i /home/ec2-user/devops_hosts /home/ec2-user/devops-mgmt/playbooks/sonar.yml &';
su ec2-user -c 'ansible-playbook -i /home/ec2-user/devops_hosts /home/ec2-user/devops-mgmt/playbooks/nexus.yml &';
