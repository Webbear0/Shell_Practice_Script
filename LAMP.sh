#!/bin/bash
# 功能:LAMP一键安装脚本
# 编写日期:2023/03/17
# 编写者:王

echo "LAMP一键安装脚本"
while true 
do 
	cat <<EOF
输入1安装Apache与php
输入2安装MariaDB
输入3安装phpmyadmin
输入4安装WordPress
输入5安装Discuz
EOF
	read -p '请输入序号,取消运行输入其他字符' input
	case $input in 
	"1") 
		yum install -y httpd php php-xml php-mbstring php-mysql*
		firewall-cmd --add-service=http --permanent
		systemctl restart firewalld.service
		systemctl enable --now httpd
		;; 
	"2")
		setenforce 0
		firewall-cmd --add-service=mysql --permanent
		systemctl restart firewalld.service
		yum install -y mariadb mariadb-server.x86_64
		echo "正在启动mariadb服务,请稍后"
		systemctl enable --now mariadb 
		sleep 3
		mysql_secure_installation && read -p '请输入数据库密码:' input 
		mysql -u root --password=${input}<<EOF
		grant all privileges on *.* to 'root'@'%' identified by '${input}';
		flush privileges;
EOF
		echo "mariadb安装完毕"
		;;
	"3")
		cat <<EOF
请选择安装的phpmyadmin版本
4.9（适用于CentOS8版本）
4.4（适用于CentOS7版本）
EOF
		while true 
		do
		read -p "请输入安装的版本" input
		if [ ${input} == '4.9' ];then
			curl -O https://files.phpmyadmin.net/phpMyAdmin/4.9.11/phpMyAdmin-4.9.11-all-languages.tar.gz
			tar -xzvf phpMyAdmin-4.9.11-all-languages.tar.gz
			rm -f phpMyAdmin-4.9.11-all-languages.tar.gz 
			mv phpMyAdmin-4.9.11-all-languages/* /var/www/html/
			chown -R apache:apache /var/www/html/
			systemctl restart httpd
			echo "安装完成"
			exit 0
		elif [ ${input} == '4.4' ];then
			curl -O https://files.phpmyadmin.net/phpMyAdmin/4.4.15.10/phpMyAdmin-4.4.15.10-all-languages.tar.gz
			tar -xzvf phpMyAdmin-4.4.15.10-all-languages.tar.gz
			rm -f phpMyAdmin-4.4.15.10-all-languages.tar.gz
			mv phpMyAdmin-4.4.15.10-all-languages/* /var/www/html/
			chown -R apache:apache /var/www/html/
			systemctl restart httpd
			echo "安装完成"
			exit 0
		fi
		done
		;;
	"4")	
		cat <<EOF
请选择安装wordpress的版本
5.9（适用于CentOS8版本）
4.9（适用于CentOS7版本）
EOF
		while true 
		do
		read -p "请输入安装的版本" input
		if [ ${input} == '5.9' ];then
			curl -O https://wordpress.org/wordpress-5.9.5.tar.gz
			tar -xzvf wordpress-5.9.5.tar.gz
			rm -f  wordpress-5.9.5.tar.gz
			mv wordpress/* /var/www/html/
			chown -R apache:apache /var/www/html/
			read -p '请输入数据库密码:' input
			mysql -uroot -p${input} -e "create database wordpress;"
			systemctl restart httpd
			echo "安装完成"
			exit 0			
		elif [ ${input} == '4.9' ];then
			curl -O https://wordpress.org/wordpress-4.9.22.tar.gz
			tar -xzvf wordpress-4.9.22.tar.gz
			rm -f wordpress-4.9.22.tar.gz
			mv wordpress/* /var/www/html/
			chown -R apache:apache /var/www/html/
			read -p '请输入数据库密码:' input 
			mysql -uroot -p${input} -e "create database wordpress;"
			systemctl restart httpd
			echo "安装完成"
			exit 0		
		fi
		done
		;;
	*) 
		echo "输入为其他字符,脚本将自动退出"
		exit 1
		;;
	esac
done
