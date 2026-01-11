#!/bin/bash

# Script pour initialiser les volumes Docker pour la production
set -e

echo "========================================"
echo "🔧 Initialisation des volumes Docker"
echo "========================================"

PROJECT_NAME="oauth2-oidc"
VOLUME_PATH="/var/lib/docker/volumes/${PROJECT_NAME}_postgres_keycloak_data/_data"

echo -e "\n📁 Création de la structure des volumes..."

# Vérifier si Docker est en root ou si on a besoin de sudo
if sudo -n true 2>/dev/null; then
    SUDO="sudo"
else
    SUDO=""
fi

# Créer les répertoires
echo "  • Volume PostgreSQL Keycloak..."
$SUDO mkdir -p $VOLUME_PATH
$SUDO chown 999:999 $VOLUME_PATH
$SUDO chmod 700 $VOLUME_PATH

echo -e "\n✅ Volumes initialisés"
echo -e "\n📋 Informations des volumes:"
docker volume ls | grep ${PROJECT_NAME}

echo -e "\n💾 Utilisation du disque:"
docker system df
