#!/bin/sh

set -x

if [ "$#" -lt 2 ]; then
    echo "No enough arguments!"
    echo "Usage: $0 SERVER_IP SERVER_PORT"
    exit 1
fi

SERVER_IP=$1
SERVER_PORT=$2

# Aktualizacja pakietów i instalacja serwera mysql
sudo apt update
sudo apt install -y mysql-server
# Ustawienie opcji potrzebnych do działania jako master
echo "server-id = 1" >>/etc/mysql/mysql.conf.d/mysqld.cnf
echo "log_bin = /var/log/mysql/mysql-bi.log" >>/etc/mysql/mysql.conf.d/mysqld.cnf
# Ustawienie adresu IP i portu serwera
sudo sed -i "s/127.0.0.1/$SERVER_IP/" /etc/mysql/mysql.conf.d/mysqld.cnf
echo "port = ${SERVER_PORT}" >>/etc/mysql/mysql.conf.d/mysqld.cnf
# Tworzenie bazy danych i użytkownika
sudo mysql -e "CREATE DATABASE petclinic"
sudo mysql -e "CREATE USER 'pc'@'%' IDENTIFIED BY 'petclinic';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'pc'@'%' WITH GRANT OPTION"
# Restart aby uruchomić serwer z ustawionymi parametrami
sudo service mysql restart
sudo mysql -e "UNLOCK TABLES;"
