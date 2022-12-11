#!/bin/sh

set -x

if [ "$#" -lt 4 ]; then
    echo "No enough arguments!"
    echo "Usage: $0 SERVER_IP SERVER_PORT MASTER_IP MASTER_PORT"
    exit 1
fi

SERVER_IP=$1
SERVER_PORT=$2
MASTER_IP=$3
MASTER_PORT=$4

sudo apt update
sudo apt install -y mysql-server
echo "server-id = 2" >>/etc/mysql/mysql.conf.d/mysqld.cnf
echo "read_only = 1" >>/etc/mysql/mysql.conf.d/mysqld.cnf
sudo sed -i "s/127.0.0.1/$SERVER_IP/" /etc/mysql/mysql.conf.d/mysqld.cnf
echo "port = ${SERVER_PORT}" >>/etc/mysql/mysql.conf.d/mysqld.cnf
sudo mysql -e "CREATE DATABASE petclinic"
sudo mysql -e "CREATE USER 'pc'@'%' IDENTIFIED BY 'petclinic';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'pc'@'%' WITH GRANT OPTION"
sudo service mysql restart
sudo mysql -e "CHANGE MASTER TO MASTER_HOST='${MASTER_IP}', MASTER_PORT=${MASTER_PORT}, MASTER_USER='pc', MASTER_PASSWORD='petclinic';"
sudo mysql -e "START SLAVE;"
sudo mysql -e "SHOW SLAVE STATUS\G;"
