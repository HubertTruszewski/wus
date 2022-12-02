#!/bin/sh

sudo apt update
sudo apt install -y mysql-server
sudo sed -i 's/127.0.0.1/0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo mysql "CREATE DATABASE petclinic"
sudo mysql "CREATE USER 'pet' IDENTIFIED BY 'pet'"
sudo mysql "GRANT ALL PRIVILEGES ON petclinic.* TO 'pet'"
sudo service mysql restart
