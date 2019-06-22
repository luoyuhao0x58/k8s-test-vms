#! /bin/bash

set -uexo pipefail

# config repo
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
# yum -y install epel-release
yum makecache
yum -y update
yum -y install yum-utils
swapoff -a
rm -f /swapfile
sed -i "/swap/d" /etc/fstab

# easy for debug
echo vagrant:vagrant | chpasswd

rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
yum -y install https://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
yum -y --enablerepo=elrepo-kernel install kernel-lt
grub2-set-default 0
grub2-mkconfig -o /boot/grub2/grub.cfg
package-cleanup -y --oldkernels --count=1

cat /vagrant/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
sudo -u vagrant cp /vagrant/id_rsa /home/vagrant/.ssh/
chmod 600 /home/vagrant/.ssh/id_rsa

# config boot command line
grubby --args="user_namespace.enable=1" --update-kernel="$(grubby --default-kernel)"
