#!/bin/bash

blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

if [[ -f /etc/redhat-release ]]; then
    release="centos"
    systemPackage="yum"
    systempwd="/usr/lib/systemd/system/"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
    systemPackage="yum"
    systempwd="/usr/lib/systemd/system/"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
    systemPackage="apt-get"
    systempwd="/lib/systemd/system/"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
    systemPackage="yum"
    systempwd="/usr/lib/systemd/system/"
fi


function install_proxy(){
Port80=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80`
Port443=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 443`
if [ -n "$Port80" ]; then
    process80=`netstat -tlpn | awk -F '[: ]+' '$5=="80"{print $9}'`
    red "==========================================================="
    red "port 80 has been occupied：${process80}，installation ended"
    red "==========================================================="
    exit 1
fi
if [ -n "$Port443" ]; then
    process443=`netstat -tlpn | awk -F '[: ]+' '$5=="443"{print $9}'`
    red "============================================================="
    red "port 443 has been occupied：${process443}，installation ended"
    red "============================================================="
    exit 1
fi
CHECK=$(grep SELINUX= /etc/selinux/config | grep -v "#")
if [ "$CHECK" == "SELINUX=enforcing" ]; then
    red "======================================================================="
    red "SELinux is enabled. Please restart to disabled first."
    red "======================================================================="
    read -p "restart now? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
	    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
	    echo -e "restarting..."
	    reboot
	fi
    exit
fi
if [ "$CHECK" == "SELINUX=permissive" ]; then
    red "======================================================================="
    red "SELinux is enabled. Please restart to disabled first."
    red "======================================================================="
    read -p "restart now? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
	    sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
            setenforce 0
	    echo -e "restarting..."
	    reboot
	fi
    exit
fi

if [ "$release" == "centos" ]; then
    if  [ -n "$(grep ' 6\.' /etc/redhat-release)" ] ;then
    red "==============="
    red "plz use centos7"
    red "==============="
    exit
    fi
    if  [ -n "$(grep ' 5\.' /etc/redhat-release)" ] ;then
    red "==============="
    red "plz use centos7"
    red "==============="
    exit
    fi
    systemctl stop firewalld
    systemctl disable firewalld
    rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
elif [ "$release" == "ubuntu" ]; then
    if  [ -n "$(grep ' 14\.' /etc/os-release)" ] ;then
    red "==============="
    red "plz use centos7"
    red "==============="
    exit
    fi
    if  [ -n "$(grep ' 12\.' /etc/os-release)" ] ;then
    red "==============="
    red "plz use centos7"
    red "==============="
    exit
    fi
    systemctl stop ufw
    systemctl disable ufw
    apt-get update
fi

$systemPackage -y install  nginx wget unzip zip curl tar >/dev/null 2>&1
systemctl enable nginx.service
green "======================="
blue "please enter your domain"
green "======================="
read your_domain
real_addr=`ping ${your_domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
local_addr=`curl ipv4.icanhazip.com`
if [ $real_addr == $local_addr ] ; then
	green "=========================================="
	green  "Your domain is functioning. Let's begin"
	green "=========================================="
	sleep 1s
cat > /etc/nginx/nginx.conf <<-EOF
user  root;
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    keepalive_timeout  120;
    client_max_body_size 20m;
    server {
        listen       80;
        server_name  $your_domain;
        root /usr/share/nginx/html;
        index index.php index.html index.htm;
    }
}
EOF
	rm -rf /usr/share/nginx/html/*
	cd /usr/share/nginx/html/
	wget https://raw.githubusercontent.com/Eggie-EPQ/EPQ/master/proxy/fake.zip
    	unzip fake.zip
	systemctl restart nginx.service
	mkdir /usr/src/proxy-cert
	curl https://get.acme.sh | sh
	~/.acme.sh/acme.sh  --issue  -d $your_domain  --webroot /usr/share/nginx/html/
    	~/.acme.sh/acme.sh  --installcert  -d  $your_domain   \
        --key-file   /usr/src/proxy-cert/private.key \
        --fullchain-file /usr/src/proxy-cert/fullchain.cer \
        --reloadcmd  "systemctl force-reload  nginx.service"
	if test -s /usr/src/proxy-cert/fullchain.cer; then
        cd /usr/src
	wget https://raw.githubusercontent.com/Eggie-EPQ/EPQ/master/proxy/proxy.tar.xz
	tar xf proxy.tar.xz
	
	wget https://raw.githubusercontent.com/Eggie-EPQ/EPQ/master/proxy-win.zip
	unzip proxy-win.zip
	rm -rf proxy-win.zip
	wget https://raw.githubusercontent.com/Eggie-EPQ/EPQ/master/proxy-mac.zip
	unzip proxy-mac.zip
	rm -rf proxy-mac.zip
	
	cp /usr/src/proxy-cert/fullchain.cer /usr/src/proxy-win/fullchain.cer
	cp /usr/src/proxy-cert/fullchain.cer /usr/src/proxy-mac/fullchain.cer
	proxy_passwd=$(cat /dev/urandom | head -1 | md5sum | head -c 8)
	cat > /usr/src/proxy-win/config.json <<-EOF
{
    "run_type": "client",
    "local_addr": "127.0.0.1",
    "local_port": 1080,
    "remote_addr": "$your_domain",
    "remote_port": 443,
    "password": [
        "$proxy_passwd"
    ],
    "log_level": 1,
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "fullchain.cer",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
	"sni": "",
        "alpn": [
            "h2",
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "curves": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    }
}
EOF

	cat > /usr/src/proxy-mac/config.json <<-EOF
{
    "run_type": "client",
    "local_addr": "127.0.0.1",
    "local_port": 1080,
    "remote_addr": "$your_domain",
    "remote_port": 443,
    "password": [
        "$proxy_passwd"
    ],
    "log_level": 1,
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "fullchain.cer",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
	"sni": "",
        "alpn": [
            "h2",
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "curves": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    }
}
EOF
	
	rm -rf /usr/src/trojan/server.conf
	cat > /usr/src/trojan/server.conf <<-EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "$proxy_passwd"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/usr/src/proxy-cert/fullchain.cer",
        "key": "/usr/src/proxy-cert/private.key",
        "key_password": "",
        "cipher_tls13":"TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
	"prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
EOF
	cd /usr/src/
	zip -q -r proxy-win.zip proxy-win
	zip -q -r proxy-mac.zip proxy-mac
	secure_path=$(cat /dev/urandom | head -1 | md5sum | head -c 16)
	mkdir /usr/share/nginx/html/${secure_path}
	mv /usr/src/proxy-win.zip /usr/share/nginx/html/${secure_path}/
	mv /usr/src/proxy-mac.zip /usr/share/nginx/html/${secure_path}/
	
cat > ${systempwd}proxy.service <<-EOF
[Unit]  
Description=proxy
After=network.target

[Service]  
Type=simple  
PIDFile=/usr/src/trojan/trojan/trojan.pid
ExecStart=/usr/src/trojan/trojan -c "/usr/src/trojan/server.conf"  
ExecReload=  
ExecStop=/usr/src/trojan/trojan  
PrivateTmp=true  
   
[Install]  
WantedBy=multi-user.target
EOF

	chmod +x ${systempwd}proxy.service
	systemctl start proxy.service
	systemctl enable proxy.service
	wget "https://raw.githubusercontent.com/Eggie-EPQ/EPQ/master/BBRmodified.sh" && chmod +x BBRmodified.sh && ./BBRmodified.sh
	green "======================================================================"
	green  "The proxy has been installed."
	green  "For Windows system please download this file."
	red    "http://${your_domain}/$secure_path/proxy-win.zip"
	green  "For MacOS please download this file."
	red    "http://${your_domain}/$secure_path/proxy-mac.zip"
	green  "Unzip it and click the start.command or start.bat to start using it"
	blue   "Use other tools like SwichyOmega or v2ray client to build a sock5 connection on your device. ip:127.0.0.1 port:1080"
	red    "Carefully copy all the instructions and download all the files. If you enter "Y", VPS will reboot, and proxy will start functioning."
	green "======================================================================"
	read -p "Restart now? [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "restarting VPS"
		reboot
	fi

	else
        red "================================"
	red "your certificate application was unsuccessful"
	red "Installation is unsuccessful. Please try another subdomain and start again."
	red "================================"
	fi
	
else
	red "================================"
	red "Your domain resolution isn't functioning"
	red "Installation is unsuccessful. Please fix your domain resolution and start again."
	red "================================"
fi
}

function remove_proxy(){
    red "================================"
    red       "Uninstall proxy"
    red       "Uninstall nginx"
    red "================================"
    systemctl stop trojan
    systemctl disable trojan
    rm -f ${systempwd}trojan.service
    if [ "$release" == "centos" ]; then
        yum remove -y nginx
    else
        apt autoremove -y nginx
    fi
    rm -rf /usr/src/trojan*
    rm -rf /usr/share/nginx/html/*
    green "=============="
    green "Uninstall is completed"
    green "=============="
}
start_menu(){
    clear
    echo
    green " 1. install"
    blue  " 0. exit"
    echo
    read -p "please enter the number:" num
    case "$num" in
    1)
    install_proxy
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    red "please enter the correct number"
    sleep 1s
    start_menu
    ;;
    esac
}

start_menu
