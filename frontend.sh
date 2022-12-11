#!/bin/bash

set -x

if [ "$#" -lt 4 ]; then
    echo "No enough arguments!"
    echo "Usage: $0 BACKEND_IP BACKEND_PORT FRONTEND_IP FRONTEND_PORT"
    exit 1
fi

BACKEND_IP="$1"
BACKEND_PORT="$2"
FRONTEND_IP="$3"
FRONTEND_PORT="$4"

sudo apt update
sudo apt install -y git
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
export NVM_DIR=$HOME/.nvm
source $NVM_DIR/nvm.sh
nvm install 16.10
git clone https://github.com/spring-petclinic/spring-petclinic-angular.git
cd spring-petclinic-angular
npm install

sudo sed -i "s/localhost:9966/$FRONTEND_IP:$FRONTEND_PORT/" src/environments/environment.prod.ts

npm run build -- --prod

sudo apt install -y nginx
sudo sed -i "s/80/$FRONTEND_PORT/" /etc/nginx/sites-available/default
sudo sed -i '54 i         location /petclinic/api {' /etc/nginx/sites-available/default
sudo sed -i "55 i                 proxy_pass http://$BACKEND_IP:$BACKEND_PORT/petclinic/api;" /etc/nginx/sites-available/default
sudo sed -i '56 i                 include proxy_params;' /etc/nginx/sites-available/default
sudo sed -i '57 i         }' /etc/nginx/sites-available/default
sudo service nginx restart
sudo rm /var/www/html/index.html
sudo cp -r dist/* /var/www/html
