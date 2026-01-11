#!/bin/bash

# Script pour démarrer tous les services avec Docker Compose
set -e

echo "========================================"
echo "🚀 Démarrage de la plateforme"
echo "========================================"

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé"
    exit 1
fi

# Vérifier que Docker Compose est installé
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé"
    exit 1
fi

echo -e "\n🔨 Construction des images..."
bash build-docker-images.sh

echo -e "\n📊 Démarrage des conteneurs..."
docker-compose up -d

echo -e "\n⏳ Attente du démarrage des services..."
sleep 10

echo -e "\n✅ Services démarrés!"
echo -e "\n📋 Conteneurs actifs :"
docker-compose ps

echo -e "\n🌐 Accès aux services:"
echo "  • Frontend React:       http://localhost:3000"
echo "  • API Gateway:          http://localhost:8085"
echo "  • Product Service:      http://localhost:8081"
echo "  • Order Service:        http://localhost:8082"
echo "  • Keycloak:             http://localhost:8080"
echo -e "\n🔐 Keycloak:"
echo "  • Admin: admin / admin"
echo "  • Realm: microservices-realm"

echo -e "\n📝 Commandes utiles:"
echo "  • Voir les logs:        docker-compose logs -f"
echo "  • Arrêter:              docker-compose down"
echo "  • Redémarrer:           docker-compose restart"
