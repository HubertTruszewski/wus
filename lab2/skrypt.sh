#!/bin/bash

set -x

if [ "$#" -lt 4 ]; then
    echo "No enugh arguments!"
    echo "Usage $0 CONFIGURATION_VERSION DATABASE_PORT BACKEND_PORT FRONTEND_PORT"
    exit 1
fi

CONFIGURATION_VERSION=$1
DATABASE_PORT=$2
BACKEND_PORT=$3
FRONTEND_PORT=$4

# Pobrania parametrów potrzebnych do konifuracji nr 3
if [ "$CONFIGURATION_VERSION" -eq 3 ]; then
    read -rep "Please specify database slave port: " DATABASE_SLAVE_PORT
fi

# Pobrania parametrów potrzebnych do konifuracji nr 5
if [ "$CONFIGURATION_VERSION" -eq 5 ]; then
    read -rep "Please specify database slave port: " DATABASE_SLAVE_PORT
    read -rep "Please specify second backend port: " BACKEND_SECOND_PORT
    read -rep "Please specify load balancer port: " LOAD_BALANCER_PORT
fi

az group create --location norwayeast --name wuslab

az network vnet create --name wusnetwork --resource-group wuslab --location norwayeast --address-prefix 10.0.0.0/16 --subnet-name wussubnet --subnet-prefix 10.0.0.0/24

az network public-ip create --name wuspublicip --resource-group wuslab --allocation-method Static

az network nsg create --name wusnetworknsg \
    --resource-group wuslab \
    --location norwayeast

az network nsg rule create --name sshport --nsg-name wusnetworknsg --priority 1000 --resource-group wuslab --access Allow \
    --destination-address-prefixes '*' --destination-port-ranges 22 --protocol Tcp

az network nsg rule create --name httpport --nsg-name wusnetworknsg --priority 1001 --resource-group wuslab --access Allow \
    --destination-address-prefixes '*' --destination-port-ranges "${FRONTEND_PORT}" --protocol Tcp

az vm create --name wusvm --resource-group wuslab \
    --image Canonical:0001-com-ubuntu-server-focal:20_04-lts:latest --authentication-type ssh \
    --os-disk-size-gb 32 --private-ip-address 10.0.0.5 \
    --size Standard_B4ms --subnet wussubnet --vnet-name wusnetwork \
    --generate-ssh-keys --public-ip-address wuspublicip \
    --nsg wusnetworknsg

FRONTEND_HOST=$(az vm show -d -g wuslab -n wusvm --query publicIps --output tsv)

sed "s/HOST/$FRONTEND_HOST/;s/USER/$(whoami)/" inventory/all.template >inventory/all

if [ "$CONFIGURATION_VERSION" -eq 1 ]; then
    ansible-playbook -i inventory/all config_1.yml --extra-vars="backend_primary_port=$BACKEND_PORT backend_host=backend-primary backend_port=$BACKEND_PORT frontend_port=$FRONTEND_PORT frontend_host=$FRONTEND_HOST database_primary_port=$DATABASE_PORT"
fi

if [ "$CONFIGURATION_VERSION" -eq 3 ]; then
    ansible-playbook -i inventory/all config_3.yml --extra-vars="backend_primary_port=$BACKEND_PORT backend_host=backend-primary backend_port=$BACKEND_PORT frontend_port=$FRONTEND_PORT frontend_host=$FRONTEND_HOST database_primary_port=$DATABASE_PORT database_secondary_port=$DATABASE_SLAVE_PORT"
fi

if [ "$CONFIGURATION_VERSION" -eq 5 ]; then
    ansible-playbook -i inventory/all config_5.yml --extra-vars="backend_primary_port=$BACKEND_PORT backend_host=loadbalancer backend_port=$LOAD_BALANCER_PORT frontend_port=$FRONTEND_PORT frontend_host=$FRONTEND_HOST database_primary_port=$DATABASE_PORT database_secondary_port=$DATABASE_SLAVE_PORT backend_secondary_port=$BACKEND_SECOND_PORT load_balancer_port=$LOAD_BALANCER_PORT"
fi

# Wypisanie publiczego adresu IP
echo '######################IP ADDRESS###################'
echo "${FRONTEND_HOST}"
