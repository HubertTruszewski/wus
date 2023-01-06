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

# Aktualizacja listy pakietów i instalacja gita i openjdk
sudo apt update
sudo apt install -y git openjdk-8-jdk
mkdir "$SERVER_PORT"
cd "$SERVER_PORT"
# Pobranie kodu źródłowego
git clone https://github.com/spring-petclinic/spring-petclinic-rest.git
cd ./spring-petclinic-rest/
# Ustawienie portu na którym ma być dostępny backend po uruchomieniu
sed -i "s/9966/$SERVER_PORT/" src/main/resources/application.properties
# Ustawienie, że używaną bazą będzie mysql
sed -i 's/=hsqldb/=mysql/' src/main/resources/application.properties
# Odkomentowanie linijek, które wykonają inicjację bazy danych
sed -i 's/#spring.sql/spring.sql/' src/main/resources/application-mysql.properties
# Ustawienie parametrów połączenia z bazą danych
sed -i "s/localhost/$MYSQL_IP/" src/main/resources/application-mysql.properties
sed -i "s/3306/$MYSQL_PORT/" src/main/resources/application-mysql.properties
# Zakomentowanie polecenia, które jest wykonywane przy instalacji bazy
sed -i 's/GRANT/-- GRANT/' src/main/resources/db/mysql/initDB.sql
# Zbudowanie backendu a następnie jego uruchomienie
./mvnw package test
./mvnw spring-boot:start >/tmp/mylogfile 2>&1 &
