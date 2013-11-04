#!/bin/bash
cloud_user=${CLOUD_USER:-ec2-user}

if [ -f /etc/redhat-release ]; then
	REL=`cat /etc/redhat-release | awk '{print $3}'`
	OS='CentOS'
else
	REL=`lsb_release -sr`
	OS=`lsb_release -si`
fi

# disable iptables
if [ "$OS" == "CentOS" ]; then
	chkconfig iptables off
fi

# cloud-init
case "$OS" in
	CentOS)
		use_cloud_util=yes
		case $REL in
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
		if ! rpm -qa | grep -q epel; then
			rpm -Uvh $epel_pkg
		fi
		
		if [ "$use_cloud_util" == 'yes' ]; then
			which ec2metadata || yum install cloud-utils -y
		fi

		which cloud-init || yum install cloud-init -y
		;;

	Ubuntu)
		which cloud-init || apt-get install -y cloud-init
		;;
esac

# Network settings
case "$OS" in
	CentOS)
		cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=dhcp
EOF
		if ! grep 'NOZEROCONF=yes' /etc/sysconfig/network; then
			echo "NOZEROCONF=yes" >> /etc/sysconfig/network
		fi
		;;
	Ubuntu)
		cat > /etc/network/interfaces << EOF
auto lo
iface lo inet lookback

auto eth0
iface eth0 inet dhcp
EOF
		;;
esac

# refer http://jcape.name/2009/07/17/distributing-static-routes-with-dhcp/
if [ "$OS" == "CentOS" -a "$REL" == "5.8" ]; then
	master=https://raw.github.com/whitekid/centos-cloud-image-prepare/master
	curl -s ${master}/dhclient.conf > /etc/dhclient.conf
	curl -s ${master}/dhclient-exit-hooks > /etc/dhclient-exit-hooks
fi

# remove persistents things
rm -f /etc/udev/rules.d/70-persistent-*.rules
rm -f /etc/ssh/ssh_host*
rm -rf /home/$cloud_user/.ssh
rm -rf /root/.ssh
rm -rf /var/lib/cloud
rm -f /etc/resolv.conf
which yum && yum clean all
which apt-get && apt-get clean all
rm -f /etc/apt/apt.conf

# clear history
history -c
rm -f ~/.bash_history
rm -f /root/.bash_history
rm -f /home/$cloud_user/.bash_history

# wipe free space
dd if=/dev/zero of=file
rm -f file

echo "Please shutdown"
