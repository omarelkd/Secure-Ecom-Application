#!/bin/bash

# Script pour construire toutes les images Docker
set -e

echo "========================================"
echo "🐳 Construction des images Docker"
echo "========================================"

PROJECT_NAME="oauth2-oidc"

echo -e "\n📦 Construction de la Product Service..."
docker build -t ${PROJECT_NAME}/product-service:latest ./product-service

echo -e "\n📦 Construction de la Order Service..."
docker build -t ${PROJECT_NAME}/order-service:latest ./order-service

echo -e "\n📦 Construction du Gateway..."
docker build -t ${PROJECT_NAME}/gateway:latest ./gateway

echo -e "\n📦 Construction du Frontend React..."
docker build -t ${PROJECT_NAME}/frontend:latest ./react-app

echo -e "\n✅ Toutes les images ont été construites avec succès!"
echo -e "\n📋 Images disponibles :"
docker images | grep ${PROJECT_NAME}
