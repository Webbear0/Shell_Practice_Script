#!/bin/bash
# 功能:mariadb一键安装脚本
# 编写日期:2023/03/16
# 编写者:俺

if [ $(id -u) -ne 0 ]; then
	echo "请以root身份运行此脚本"
	exit 1
fi

printf "\n*****************************************\n"
printf "           mariadb一键安装脚本\n"
[ -e /etc/redhat-release ] && echo "    >>"$(cat /etc/redhat-release | cut -d ' ' -f 1-4)  "<<    " || printf "\n"
echo ">>"$( date;date '+%D' )"<<" 
printf "*****************************************\n"
# 设置权限
setenforce 0
firewall-cmd --add-service=mysql --permanent
systemctl restart firewalld.service
# 安装软件包
yum install -y mariadb mariadb-server.x86_64
# 启动数据库
echo "正在启动mariadb服务,请稍后"
systemctl enable --now mariadb 
sleep 3
mysql_secure_installation && read -p '请输入数据库密码:' input 
mysql -u root --password="${input}"<<EOF
grant all privileges on *.* to 'root'@'%' identified by '${input}';
flush privileges;
EOF
# 配置phpmyadmin
echo "mariadb安装完毕"
read -p '是否安装phpmyadmin? 输入y安装:' input
if [ "${input}" == 'y' ];then 
	yum install -y httpd php php-xml php-mbstring php-mysql*
	firewall-cmd --add-service=http --permanent
	systemctl restart firewalld.service
	curl -O https://files.phpmyadmin.net/phpMyAdmin/4.4.15.10/phpMyAdmin-4.4.15.10-all-languages.tar.gz
	tar -xzvf phpMyAdmin-4.4.15.10-all-languages.tar.gz
	mv phpMyAdmin-4.4.15.10-all-languages/* /var/www/html/
	chown -R apache:apache /var/www/html/
	systemctl enable --now httpd
	exit 0
else
	echo "脚本退出" 
	exit 1
fi
