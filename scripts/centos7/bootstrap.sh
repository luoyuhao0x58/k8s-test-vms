#! /bin/bash

set -uexo pipefail

# config repo
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
# yum -y install epel-release
yum makecache
yum -y update
yum -y install yum-utils tmux git
swapoff -a
rm -f /swapfile
sed -i "/swap/d" /etc/fstab

cat >> /etc/security/limits.conf << EOF

* soft  nofile  1024000
* hard  nofile  1024000
* soft  nproc 1024000
* hard  nproc 1024000
EOF

cat > /etc/security/limits.d/20-nproc.conf << EOF
* soft  nproc 1024000
* hard  nproc 1024000
EOF

cat > /usr/lib/sysctl.d/00-system.conf << EOF
vm.swappiness = 0

net.ipv4.ip_forward = 1

net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

net.ipv4.tcp_syncookies = 1

kernel.sysrq = 0
kernel.core_uses_pid = 1

kernel.msgmnb = 65536
kernel.msgmax = 65536

kernel.shmmax = 68719476736
kernel.shmall = 4294967296

net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1

net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304

net.core.wmem_default = 8388608
net.core.rmem_default = 8388608

net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

net.core.netdev_max_backlog = 262144
net.ipv4.tcp_max_orphans = 3276800

net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0

net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1

net.ipv4.tcp_tw_recycle = 1

net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000

net.ipv4.tcp_fin_timeout = 1

net.ipv4.tcp_keepalive_time = 30

net.ipv4.ip_local_port_range = 1024 65000

net.netfilter.nf_conntrack_max=655350
net.netfilter.nf_conntrack_tcp_timeout_established=1200
EOF

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
