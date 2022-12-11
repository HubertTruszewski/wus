#!/bin/sh

set -x

if [ "$#" -lt 3 ]; then
    echo "No enough arguments!"
    echo "Usage: $0 SERVER_PORT BACKEND_1_PORT BACKEND_2_PORT"
    exit 1
fi

SERVER_PORT=$1
BACKEND_1_PORT=$2
BACKEND_2_PORT=$3

sudo apt update
sudo apt install -y nginx
{
    echo "upstream backend {
        server 10.0.1.5:$BACKEND_1_PORT;
        server 10.0.1.5:$BACKEND_2_PORT;
     }"

} | sudo tee -a /etc/nginx/sites-available/default

sudo sed -i "s/80/$SERVER_PORT/" /etc/nginx/sites-available/default
sudo sed -i "s/try_files/# try_files/" /etc/nginx/sites-available/default
sudo sed -i '49 i        proxy_pass http://backend;' /etc/nginx/sites-available/default
sudo nginx -t
sudo nginx -s reload
