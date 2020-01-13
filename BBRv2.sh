apt -y update
apt -y install git
git clone https://github.com/xiya233/bbr2.git
cd bbr2/debian
apt -y install *
echo "tcp_bbr" >> /etc/modules
echo "tcp_bbr2" >> /etc/modules
echo "tcp_dctcp" >> /etc/modules
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr2" >> /etc/sysctl.conf
echo "net.ipv4.tcp_ecn = 1" >> /etc/sysctl.conf
echo 1 > /sys/module/tcp_bbr2/parameters/ecn_enable
sed -i "/\/sys\/module\/tcp_bbr2\/parameters\/ecn_enable/d" /etc/rc.local
add_to_rc.local "echo 1 > /sys/module/tcp_bbr2/parameters/ecn_enable"
sysctl -p
rm -rf ~/bbr2
read -p "Installation has finished.Restart？[Y/n]:" yn
[ -z "${yn}" ] && yn="y"
if [[ $yn == [Yy] ]]; then
	echo -e "restarting"
	reboot
fi
