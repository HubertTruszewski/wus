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

# Aktualizacja pakietów i instalacja gita
sudo apt update
sudo apt install -y git
# Instalacja nvm (narzędzie do zarządzania wersjami NodeJS)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
export NVM_DIR=$HOME/.nvm
source $NVM_DIR/nvm.sh
# Instalacja NodeJS w wersji 16.10
nvm install 16.10
# Pobranie kodu źródłowego
git clone https://github.com/spring-petclinic/spring-petclinic-angular.git
cd spring-petclinic-angular
# Instalacja zależności projektu
npm install
# Ustawienie adresu i portu aby linki wskazywały na dobrą lokalizację
sudo sed -i "s/localhost:9966/$FRONTEND_IP:$FRONTEND_PORT/" src/environments/environment.prod.ts
# Tworzenie wersji produkcyjnej aplikacji
npm run build -- --prod
# Instalacja serwera nginx do serwowania frontendu
sudo apt install -y nginx
# Zmiana portu z domyślnego 80 na podany jako argument
sudo sed -i "s/80/$FRONTEND_PORT/" /etc/nginx/sites-available/default
# Ustawienie przekierowania ścieżki /petclinic/api do backendu używając reverse proxy nginx
sudo sed -i '54 i         location /petclinic/api {' /etc/nginx/sites-available/default
sudo sed -i "55 i                 proxy_pass http://$BACKEND_IP:$BACKEND_PORT/petclinic/api;" /etc/nginx/sites-available/default
sudo sed -i '56 i                 include proxy_params;' /etc/nginx/sites-available/default
sudo sed -i '57 i         }' /etc/nginx/sites-available/default
# Restart serwera do użycia ustawionych parametrów
sudo service nginx restart
# Skopiowanie plików frontendu do lokalizacji na którą wskazuje serwer nginx
sudo rm /var/www/html/index.html
sudo cp -r dist/* /var/www/html
