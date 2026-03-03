#!/bin/bash
# 功能:yum更换本地源
# 编写日期:2023/03/17
# 编写者:俺

if [ $(id -u) -ne 0 ]; then
	echo "请以root身份运行此脚本"
	exit 1
fi

mkdir -p /media/CentOS
if [ -e  /dev/sr0 ];then
	read -p "是否开机自动挂载镜像? y/n:" input
	while true
	do
		if [ "${input}" == "y" ];then
			echo "/dev/cdrom /media/CentOS/ iso9660 ro 0 0" >> /etc/fstab
			break
		elif [ "${input}" == "n" ];then
			echo "/dev/cdrom /media/CentOS/ iso9660 noauto 0 0" >> /etc/fstab
			break
		else
			read -p "输入错误，请重新输入 y/n:" input
		fi
	done
	mount -a
	sed -i "s/gpgcheck=1//g" /etc/yum.repos.d/CentOS-Media.repo
	sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/CentOS-Media.repo
	mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
	yum clean all && yum makecache
	echo "本地源更换成功"
	exit 0
else
	echo "未检测到光驱设备 /dev/sr0，脚本退出"
	exit 1
fi
