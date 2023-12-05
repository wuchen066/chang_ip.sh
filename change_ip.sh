#!/bin/bash
# 一个简单的Centos更换IP的脚本
# 使用方法：./change_ip.sh <ip> <netmask> <gateway>
# 例如：./change_ip.sh 192.168.1.100 255.255.255.0 192.168.1.1

# 检查参数个数是否为3
if [ $# -ne 3 ]; then
  echo "Usage: $0 <ip> <netmask> <gateway>"
  exit 1
fi

# 检查IP地址格式是否正确
ip=$1
netmask=$2
gateway=$3
echo $ip | grep "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Invalid IP address format"
  exit 2
fi

# 检查系统是否安装了ifconfig命令
which ifconfig > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "ifconfig command not found, install net-tools package"
  yum install -y net-tools
fi

# 获取网络设备名称
device=$(ifconfig | grep flags | grep -v lo | cut -d":" -f1)
echo "Network device: $device"

# 备份网络配置文件
cp /etc/sysconfig/network-scripts/ifcfg-$device /etc/sysconfig/network-scripts/ifcfg-$device.bak
echo "Backup network configuration file"

# 修改网络配置文件
sed -i "s/BOOTPROTO=.*/BOOTPROTO=static/g" /etc/sysconfig/network-scripts/ifcfg-$device
sed -i "s/IPADDR=.*/IPADDR=$ip/g" /etc/sysconfig/network-scripts/ifcfg-$device
sed -i "s/NETMASK=.*/NETMASK=$netmask/g" /etc/sysconfig/network-scripts/ifcfg-$device
sed -i "s/GATEWAY=.*/GATEWAY=$gateway/g" /etc/sysconfig/network-scripts/ifcfg-$device
echo "Modify network configuration file"

# 重启网络服务
systemctl restart network
echo "Restart network service"

# 测试网络连通性
ping -c 2 www.baidu.com
if [ $? -eq 0 ]; then
  echo "IP address change success!"
else
  echo "IP address change failed, restore configuration!"
  cp /etc/sysconfig/network-scripts/ifcfg-$device.bak /etc/sysconfig/network-scripts/ifcfg-$device
  systemctl restart network
fi

