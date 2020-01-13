yum -y install git
git clone https://github.com/xiya233/bbr2.git
cd bbr2/centos
yum -y localinstall *
grub2-set-default 0
echo "tcp_bbr" >> /etc/modules-load.d/tcp_bbr.conf
echo "tcp_bbr2" >> /etc/modules-load.d/tcp_bbr2.conf
echo "tcp_dctcp" >> /etc/modules-load.d/tcp_dctcp.conf
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr2" >> /etc/sysctl.conf
echo "net.ipv4.tcp_ecn = 1" >> /etc/sysctl.conf
sysctl -p
rm -rf ~/bbr2
echo 1 > /sys/module/tcp_bbr2/parameters/ecn_enable
read -p "Installation has been finished.Restart？[Y/n] :" yn
[ -z "${yn}" ] && yn="y"
if [[ $yn == [Yy] ]]; then
      echo -e "restarting"
		  reboot
fi
