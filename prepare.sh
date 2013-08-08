#!/bin/bash
cloud_user=${CLOUD_USER:-ec2-user}
chkconfig iptables off

if ! which ec2metadata; then
	rpm -Uvh http://ftp.neowiz.com/fedora-epel/5/i386/epel-release-5-4.noarch.rpm
	yum install cloud-init
fi

useradd -m -s `which bash` ${cloud_user}

cat > /etc/sudoers.d/${cloud_user} << EOF
${cloud_user} ALL=(ALL) NOPASSWD:ALL
EOF

chmod 0660 /etc/sudoers.d/${cloud_user}

cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=dhcp
EOF

rm rm /etc/udev/rules.d/70-persistent-net.rules
rm /etc/ssh/ssh_host*

if ! grep 'NOZEROCONF=yes' /etc/sysconfig/network; then
	echo "NOZEROCONF=yes" >> /etc/sysconfig/network
fi

rm rm /etc/resolv.conf
yum clean all

dd if=/dev/zero of=file
rm file

rm -f ~/.bash_history
history -c

