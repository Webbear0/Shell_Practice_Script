#!/bin/bash
# 功能:实现银行业务开户、销户、存款、取款和查询余额等功能
# 编写日期:2023/4/2
# 更新说明:修复跨平台兼容问题,同时兼容 RedHat 系与 Debian 系发行版


# RedHat/CentOS              : yum install -y mariadb
# Debian/Ubuntu              : apt install -y default-mysql-client
# Debian 13+ / MariaDB 11.8+ : apt install -y mariadb-client mariadb-client-compat
if command -v mysql >/dev/null 2>&1;then
	mysql_client='mysql'      # 传统命令名,MySQL 全系与 MariaDB 10.x 均提供
elif command -v mariadb >/dev/null 2>&1;then
	mysql_client='mariadb'    # MariaDB 新命令名,Debian 13+ 默认只提供这个
else
	echo "错误:未找到 mysql 或 mariadb 客户端命令,请先安装数据库客户端"
	echo "  RedHat/CentOS : yum install -y mariadb"
	echo "  Debian/Ubuntu : apt install -y default-mysql-client"
	echo "  Debian 13+    : apt install -y mariadb-client mariadb-client-compat"
	exit 1
fi


money_to_cents() {
	local amount="$1" int_part frac_part
	local re='^[0-9]+([.][0-9]{1,2})?$'
	amount="${amount#+}"
	[[ "${amount}" =~ ${re} ]] || return 1
	if [[ "${amount}" == *.* ]];then
		int_part="${amount%%.*}"
		frac_part="${amount#*.}"
	else
		int_part="${amount}"
		frac_part=""
	fi
	frac_part="${frac_part}00"      # 小数不足两位时补零
	frac_part="${frac_part:0:2}"
	printf '%d' "$(( 10#${int_part} * 100 + 10#${frac_part} ))"
}

read -p "请输入数据库地址:" host_name
read -p "请输入数据库用户名:" sql_username
read -s -p "请输入数据库密码:" sql_passwd
echo ""

# 统一连接参数:显式指定客户端字符集,避免中文用户名在不同发行版下出现乱码
db_opts=(-h"${host_name}" -u"${sql_username}" -p"${sql_passwd}" --default-character-set=utf8mb4)

while true
do
	cat <<EOF
----欢迎使用银行系统----
输入0初始化数据库
输入1开户
输入2销户
输入3存款
输入4取款
输入5查询
EOF
	read -p '请输入序号,取消运行输入其他字符: ' input
	case $input in
	"0")
		"${mysql_client}" "${db_opts[@]}" <<EOF
create database if not exists bank;
use bank;
create table if not exists bank(
card_id int unsigned not null primary key auto_increment comment '卡号',
card_name varchar(8) not null unique key comment '持卡人',
card_password varchar(16) not null default '88888888' comment '卡密码',
card_money decimal(10,2) not null default 0 comment '余额'
)charset=utf8mb4;
EOF
		echo "数据库初始化完成"
		;;
	"1")
		echo "----开户系统----"
		read -p "请输入开户用户名:" user_name
		read -s -p "请输入密码:" user_password
		echo ""
		"${mysql_client}" "${db_opts[@]}" <<EOF
        use bank;
        insert into bank (card_name,card_password) values ('${user_name}','${user_password}');
EOF
		command=$?
		if [ "${command}" != 0 ];then
			echo "开户失败,请检查输入"
		else
			echo "用户 ${user_name} 开户成功"
		fi
		;;
	"2")
		echo "----销户系统----"
		read -p "请输入用户名:" user_name
		read -s -p "请输入密码:" user_password
		echo ""
		"${mysql_client}" "${db_opts[@]}" <<EOF
        use bank;
        delete from bank where card_name='${user_name}' and card_password='${user_password}' and card_money=0;
EOF
		command=$?
		if [ "${command}" != 0 ];then
			echo "销户失败,请检查输入"
		else
			echo "用户 ${user_name} 销户成功"
		fi
		;;
	"3")
		echo "----存款系统----"
		read -p "请输入用户名:" user_name
		read -s -p "请输入密码:" user_password
		echo ""
		read -p "请输入需要存款的金额: " user_money
		"${mysql_client}" "${db_opts[@]}" <<EOF
        use bank;
        update bank set card_money=card_money+'${user_money}' where card_name='${user_name}' and card_password='${user_password}';
EOF
		command=$?
		if [ "${command}" != 0 ];then
			echo "存款失败,请检查输入"
		else
			echo "用户 ${user_name} 存款 ${user_money} 成功"
		fi
		;;
	"4")
		echo "----取款系统----"
		read -p "请输入用户名:" user_name
		read -s -p "请输入密码:" user_password
		echo ""
		read -p "请输入需要取款的金额:" user_money
		if ! user_money_cents=$(money_to_cents "${user_money}");then
			echo "金额格式错误:${user_money} ,请输入正数且最多两位小数(例如 100 或 99.50)"
			continue
		fi
		# 先检查余额是否充足
		balance=$("${mysql_client}" "${db_opts[@]}" -sN -e "use bank; select card_money from bank where card_name='${user_name}' and card_password='${user_password}';")
		if [ -z "${balance}" ];then
			echo "用户名或密码错误"
		elif ! balance_cents=$(money_to_cents "${balance}");then
			echo "账户余额数据异常: ${balance}"
		elif [ "${balance_cents}" -ge "${user_money_cents}" ];then
			"${mysql_client}" "${db_opts[@]}" <<EOF
        use bank;
        update bank set card_money=card_money-'${user_money}' where card_name='${user_name}' and card_password='${user_password}';
EOF
			command=$?
			if [ "${command}" != 0 ];then
				echo "取款失败,请检查输入"
			else
				echo "用户 ${user_name} 取款 ${user_money} 成功"
			fi
		else
			echo "余额不足，当前余额为: ${balance}"
		fi
		;;
	"5")
		echo "----查询系统----"
		read -p "请输入用户名:" user_name
		read -s -p "请输入密码:" user_password
		echo ""
		"${mysql_client}" "${db_opts[@]}" <<EOF
        use bank;
        select card_money from bank where card_name='${user_name}' and card_password='${user_password}';
EOF
		;;
	*)
		echo "输入为其他字符,脚本将自动退出"
		exit 0
		;;
	esac
done
