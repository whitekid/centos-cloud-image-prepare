#!/bin/bash
user=${1:-ec2-user}
chkconfig iptables off

if ! which ec2metadata; then
	rpm -Uvh http://ftp.neowiz.com/fedora-epel/5/i386/epel-release-5-4.noarch.rpm
	yum install cloud-init
fi

useradd -m -s `which bash` ${user}

cat > /etc/sudoers.d/${user} << EOF
${user} ALL=(ALL) NOPASSWD:ALL
EOF

chmod 0660 /etc/sudoers.d/${user}

cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=dhcp
EOF

rm rm /etc/udev/rules.d/70-persistent-net.rules
rm /etc/ssh/ssh_host*

if ! grep 'ZEROCONF=yes' /etc/sysconfig/network; then
	echo "ZEROCONF=yes\n" >> /etc/sysconfig/network
fi

rm rm /etc/resolv.conf
yum clean all

dd if=/dev/zero of=file
rm file

rm -f ~/.bash_history
history -c

