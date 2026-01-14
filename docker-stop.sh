#!/bin/bash

# Script pour arrêter et nettoyer les conteneurs Docker
set -e

echo "========================================"
echo "🛑 Arrêt de la plateforme"
echo "========================================"

echo -e "\n📊 Services actifs :"
docker-compose ps

echo -e "\n⏸️  Arrêt des conteneurs..."
docker-compose down

echo -e "\n✅ Services arrêtés!"

# Optionnel: supprimer les images
read -p "Voulez-vous supprimer les images Docker construites? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Suppression des images..."
    docker rmi oauth2-oidc/product-service:latest || true
    docker rmi oauth2-oidc/order-service:latest || true
    docker rmi oauth2-oidc/gateway:latest || true
    docker rmi oauth2-oidc/frontend:latest || true
    echo "✅ Images supprimées"
fi
