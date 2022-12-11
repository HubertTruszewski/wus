#!/bin/bash

set -x

if [ "$#" -lt 3 ]; then
    echo "No enough arguments!"
    echo "Usage: $0 SERVER_PORT MYSQL_IP MYSQL_PORT"
    exit 1
fi

SERVER_PORT=$1
MYSQL_IP=$2
MYSQL_PORT=$3

sudo apt update
sudo apt install -y git openjdk-8-jdk
mkdir "$SERVER_PORT"
cd "$SERVER_PORT"
git clone https://github.com/spring-petclinic/spring-petclinic-rest.git
cd ./spring-petclinic-rest/
sed -i "s/9966/$SERVER_PORT/" src/main/resources/application.properties
sed -i 's/=hsqldb/=mysql/' src/main/resources/application.properties
sed -i 's/#spring.sql/spring.sql/' src/main/resources/application-mysql.properties
sed -i "s/localhost/$MYSQL_IP/" src/main/resources/application-mysql.properties
sed -i "s/3306/$MYSQL_PORT/" src/main/resources/application-mysql.properties
sed -i 's/GRANT/-- GRANT/' src/main/resources/db/mysql/initDB.sql
./mvnw package test
./mvnw spring-boot:start >/tmp/mylogfile 2>&1 &
