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

if [ "$CONFIGURATION_VERSION" -eq 3 ]; then
    read -rep "Please specify database slave port: " DATABASE_SLAVE_PORT
fi

if [ "$CONFIGURATION_VERSION" -eq 5 ]; then
    read -rep "Please specify database slave port: " DATABASE_SLAVE_PORT
    read -rep "Please specify second backend port: " BACKEND_SECOND_PORT
    read -rep "Please specify load balancer port: " LOAD_BALANCER_PORT
fi

# Tworzenie nowego resource group
az group create --location norwayeast --name wuslab

# Tworzenie sieci i podsieci
az network vnet create --name wusnetwork --resource-group wuslab --location norwayeast --address-prefix 10.0.0.0/16 --subnet-name frontendsubnet --subnet-prefix 10.0.0.0/24
az network vnet subnet create --resource-group wuslab --vnet-name wusnetwork --name backendsubnet --address-prefixes 10.0.1.0/24
az network vnet subnet create --resource-group wuslab --vnet-name wusnetwork --name databasesubnet --address-prefixes 10.0.2.0/24
az network public-ip create --name wuspublicip --resource-group wuslab --allocation-method Static

az network nsg create --name wusnetworknsg \
    --resource-group wuslab \
    --location norwayeast

az vm create --name database --resource-group wuslab \
    --image UbuntuLTS --authentication-type ssh \
    --os-disk-size-gb 32 --private-ip-address 10.0.2.5 \
    --size Standard_A1_v2 --subnet databasesubnet --vnet-name wusnetwork \
    --generate-ssh-keys --public-ip-address "" \
    --nsg wusnetworknsg

az vm create --name backend --resource-group wuslab \
    --image UbuntuLTS --authentication-type ssh \
    --os-disk-size-gb 32 --private-ip-address 10.0.1.5 \
    --size Standard_B2s --subnet backendsubnet --vnet-name wusnetwork \
    --generate-ssh-keys --public-ip-address "" \
    --nsg wusnetworknsg

az vm create --name frontend --resource-group wuslab \
    --image UbuntuLTS --authentication-type ssh \
    --os-disk-size-gb 32 --private-ip-address 10.0.0.5 \
    --size Standard_B2s --subnet frontendsubnet --vnet-name wusnetwork \
    --generate-ssh-keys --public-ip-address wuspublicip \
    --nsg wusnetworknsg

az network nsg rule create --name httpport --nsg-name wusnetworknsg --priority 1000 --resource-group wuslab --access Allow \
    --destination-address-prefixes '*' --destination-port-ranges "${FRONTEND_PORT}" --protocol Tcp

echo "### INVOKING DATABASE SCRIPT ###"
az vm run-command invoke --resource-group wuslab --name database --command-id RunShellScript --scripts @database.sh --parameters "10.0.2.5" "${DATABASE_PORT}"

if [ "$CONFIGURATION_VERSION" -eq 3 ] || [ "$CONFIGURATION_VERSION" -eq 5 ]; then
    az vm create --name databaseslave --resource-group wuslab \
        --image UbuntuLTS --authentication-type ssh \
        --os-disk-size-gb 32 --private-ip-address 10.0.2.6 \
        --size Standard_A1_v2 --subnet databasesubnet --vnet-name wusnetwork \
        --generate-ssh-keys --public-ip-address "" \
        --nsg wusnetworknsg

    echo "### INVOKING DATABASE SLAVE SCRIPT ###"
    az vm run-command invoke --resource-group wuslab --name databaseslave --command-id RunShellScript --scripts @database_slave.sh --parameters "10.0.2.6" "${DATABASE_SLAVE_PORT}" "10.0.2.5" "${DATABASE_PORT}"
fi

if [ "$CONFIGURATION_VERSION" -eq 1 ]; then
    echo "### INVOKING BACKEND SCRIPT ###"
    az vm run-command invoke --resource-group wuslab --name backend --command-id RunShellScript --scripts @backend.sh --parameters "${BACKEND_PORT}" "10.0.2.5" "${DATABASE_PORT}"
fi

if [ "$CONFIGURATION_VERSION" -eq 3 ] || [ "$CONFIGURATION_VERSION" -eq 5 ]; then
    echo "### INVOKING BACKEND REPLICATION SCRIPT ###"
    az vm run-command invoke --resource-group wuslab --name backend --command-id RunShellScript --scripts @backend_replication.sh --parameters "${BACKEND_PORT}" "10.0.2.5" "${DATABASE_PORT}" "10.0.2.6" "${DATABASE_SLAVE_PORT}" "1"
fi

if [ "$CONFIGURATION_VERSION" -eq 5 ]; then
    echo "### INVOKING SECOND BACKEND REPLICATION SCRIPT ###"
    az vm run-command invoke --resource-group wuslab --name backend --command-id RunShellScript --scripts @backend_replication.sh --parameters "${BACKEND_SECOND_PORT}" "10.0.2.5" "${DATABASE_PORT}" "10.0.2.6" "${DATABASE_SLAVE_PORT}" "0"

    echo "### INVOKING LOAD BALANCER SCRIPT ###"
    az vm run-command invoke --resource-group wuslab --name backend --command-id RunShellScript --scripts @loadbalancer.sh --parameters "${LOAD_BALANCER_PORT}" "${BACKEND_PORT}" "${BACKEND_SECOND_PORT}"
fi

IP_ADDRESS=$(az vm show -d -g wuslab -n frontend --query publicIps --output tsv)

if [ "$CONFIGURATION_VERSION" -eq 1 ] || [ "$CONFIGURATION_VERSION" -eq 3 ]; then
    echo "### INVOKING FRONTEND SCRIPT ###"
    az vm run-command invoke --resource-group wuslab --name frontend --command-id RunShellScript --scripts @frontend.sh --parameters "10.0.1.5" "${BACKEND_PORT}" "${IP_ADDRESS}" "${FRONTEND_PORT}"
fi

if [ "$CONFIGURATION_VERSION" -eq 5 ]; then
    echo "### INVOKING FRONTEND SCRIPT ###"
    az vm run-command invoke --resource-group wuslab --name frontend --command-id RunShellScript --scripts @frontend.sh --parameters "10.0.1.5" "${LOAD_BALANCER_PORT}" "${IP_ADDRESS}" "${FRONTEND_PORT}"
fi

echo '######################IP ADDRESS###################'
echo "${IP_ADDRESS}"
