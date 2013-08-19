#!/bin/bash
cloud_user=${CLOUD_USER:-ec2-user}
chkconfig iptables off
release=`cut -d ' ' -f 3 /etc/redhat-release`

use_cloud_util=yes
case $release in
	5.8)
		epel_pkg=http://ftp.jaist.ac.jp/pub/Linux/Fedora/epel/5/i386/epel-release-5-4.noarch.rpm
		use_cloud_util=no
		;;
	6.*)
		epel_pkg=http://ftp.jaist.ac.jp/pub/Linux/Fedora/epel/6/i386/epel-release-6-8.noarch.rpm
		;;
	*)
		echo "Unsupported release $release"
		exit
esac

if ! rpm -qa | grep epel; then
	rpm -Uvh $epel_pkg
fi

if [ $use_cloud_util == 'yes' ]; then
	if ! which ec2metadata; then
		yum install cloud-utils -y
	fi
fi

if ! which cloud-init; then
	yum install cloud-init -y
fi

useradd -m -s `which bash` ${cloud_user}

case $release in
	5.8)
		if ! grep "^${cloud_user} :ALL" /etc/sysconfig/network; then
			echo "${cloud_user} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
		fi
		;;
	6.*)
		echo "${cloud_user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${cloud_user}
		chmod 0660 /etc/sudoers.d/${cloud_user}
		;;
esac

cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=dhcp
EOF

rm -f /etc/udev/rules.d/70-persistent-*.rules
rm -f /etc/ssh/ssh_host*

if ! grep 'NOZEROCONF=yes' /etc/sysconfig/network; then
	echo "NOZEROCONF=yes" >> /etc/sysconfig/network
fi

rm -f /etc/resolv.conf
yum clean all

dd if=/dev/zero of=file
rm -f file

history -c
rm -f ~/.bash_history

