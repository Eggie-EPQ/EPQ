 #!/usr/bin/env bash

#Author:Eggie
kernel_version="4.14.129-bbrplus"
if [[ ! -f /etc/redhat-release ]]; then
	echo -e "only for centos 7"
	exit 0
fi

if [[ "$(uname -r)" == "${kernel_version}" ]]; then
	echo -e "kernal has already been installed, please don't repeat this step"
	exit 0
fi

#uninstall BBRplus
echo -e "uninstall BBRplus..."
sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
if [[ -e /appex/bin/serverSpeeder.sh ]]; then
	wget --no-check-certificate -O appex.sh https://raw.githubusercontent.com/0oVicero0/serverSpeeder_Install/master/appex.sh && chmod +x appex.sh && bash appex.sh uninstall
	rm -f appex.sh
fi
echo -e "downloading kernals..."
wget https://github.com/cx9208/bbrplus/raw/master/centos7/x86_64/kernel-${kernel_version}.rpm
echo -e "installing kernal..."
yum install -y kernel-${kernel_version}.rpm

#check whether installation is successful
list="$(awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg)"
target="CentOS Linux (${kernel_version})"
result=$(echo $list | grep "${target}")
if [[ "$result" = "" ]]; then
	echo -e "installation failed"
	exit 1
fi

echo -e "swiching kernal..."
grub2-set-default 'CentOS Linux (${kernel_version}) 7 (Core)'
echo -e "activating..."
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbrplus" >> /etc/sysctl.conf
rm -f kernel-${kernel_version}.rpm

read -p "successfully installed please restart [Y/n] :" yn
[ -z "${yn}" ] && yn="y"
if [[ $yn == [Yy] ]]; then
	echo -e "restarting..."
	reboot
fi