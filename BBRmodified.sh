kernel_version="4.14.129-bbrplus"
sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
if [[ -e /appex/bin/serverSpeeder.sh ]]; then
	wget --no-check-certificate -O appex.sh https://raw.githubusercontent.com/0oVicero0/serverSpeeder_Install/master/appex.sh && chmod +x appex.sh && bash appex.sh uninstall
	rm -f appex.sh
fi
wget https://raw.githubusercontent.com/Eggie-EPQ/EPQ/master/BBRmodified/kernel-${kernel_version}.rpm
yum install -y kernel-${kernel_version}.rpm
grub2-set-default 'CentOS Linux (${kernel_version}) 7 (Core)'
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbrplus" >> /etc/sysctl.conf
rm -f kernel-${kernel_version}.rpm
