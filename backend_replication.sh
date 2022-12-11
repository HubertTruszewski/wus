#!/bin/bash

set -x

if [ "$#" -lt 6 ]; then
    echo "No enough arguments!"
    echo "Usage: $0 SERVER_PORT MASTER_MYSQL_IP MASTER_MYSQL_PORT SLAVE_MYSQL_IP SLAVE_MYSQL_PORT INIT_DB"
    exit 1
fi

SERVER_PORT=$1
MASTER_MYSQL_IP=$2
MASTER_MYSQL_PORT=$3
SLAVE_MYSQL_IP=$4
SLAVE_MYSQL_PORT=$5
INIT_DB=$6

sudo apt update
sudo apt install -y git openjdk-8-jdk
mkdir "$SERVER_PORT"
cd "$SERVER_PORT"
git clone https://github.com/spring-petclinic/spring-petclinic-rest.git
cd ./spring-petclinic-rest/
sed -i "s/9966/$SERVER_PORT/" src/main/resources/application.properties
sed -i 's/=hsqldb/=mysql/' src/main/resources/application.properties
if [ "$INIT_DB" -eq 1 ]; then
    sed -i 's/#spring.sql/spring.sql/' src/main/resources/application-mysql.properties
fi
sed -i "s/spring.datasource.url/# spring.datasource.url/" src/main/resources/application-mysql.properties
sed -i 's/GRANT/-- GRANT/' src/main/resources/db/mysql/initDB.sql
echo "spring.datasource.url = jdbc:mysql:replication://$MASTER_MYSQL_IP:$MASTER_MYSQL_PORT,$SLAVE_MYSQL_IP:$SLAVE_MYSQL_PORT/petclinic?useUnicode=true" >>src/main/resources/application-mysql.properties
./mvnw package test
java -jar target/*.jar >logfile 2>&1 &
