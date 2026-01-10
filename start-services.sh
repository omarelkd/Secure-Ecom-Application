#!/bin/bash

# Script pour démarrer tous les microservices
# Usage: ./start-services.sh

set -e

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Démarrage des Microservices${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Vérifier que Keycloak est démarré
echo -e "${YELLOW}Vérification de Keycloak...${NC}"
if curl -s http://localhost:8080/realms/microservices-realm/.well-known/openid-configuration > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Keycloak est en cours d'exécution${NC}"
else
    echo -e "${RED}✗ Keycloak n'est pas accessible sur http://localhost:8080${NC}"
    echo -e "${YELLOW}Démarrage de Keycloak...${NC}"
    cd keycloak
    docker-compose up -d
    echo -e "${GREEN}Keycloak démarré. Attente de 30 secondes...${NC}"
    sleep 30
    cd ..
fi

echo ""

# Donner les permissions d'exécution aux mvnw
echo -e "${YELLOW}Configuration des permissions...${NC}"
chmod +x product-service/mvnw
chmod +x order-service/mvnw
chmod +x gateway/mvnw
echo -e "${GREEN}✓ Permissions configurées${NC}"
echo ""

# Créer un répertoire pour les logs
mkdir -p logs

# Démarrer Product Service
echo -e "${BLUE}Démarrage du Product Service (port 8081)...${NC}"
cd product-service
./mvnw spring-boot:run > ../logs/product-service.log 2>&1 &
PRODUCT_PID=$!
echo -e "${GREEN}✓ Product Service démarré (PID: $PRODUCT_PID)${NC}"
cd ..

# Attendre un peu avant de démarrer le suivant
sleep 5

# Démarrer Order Service
echo -e "${BLUE}Démarrage du Order Service (port 8082)...${NC}"
cd order-service
./mvnw spring-boot:run > ../logs/order-service.log 2>&1 &
ORDER_PID=$!
echo -e "${GREEN}✓ Order Service démarré (PID: $ORDER_PID)${NC}"
cd ..

# Attendre un peu avant de démarrer le suivant
sleep 5

# Démarrer Gateway
echo -e "${BLUE}Démarrage du Gateway (port 8085)...${NC}"
cd gateway
./mvnw spring-boot:run > ../logs/gateway.log 2>&1 &
GATEWAY_PID=$!
echo -e "${GREEN}✓ Gateway démarré (PID: $GATEWAY_PID)${NC}"
cd ..

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Tous les services sont en cours de démarrage${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}PIDs des processus:${NC}"
echo -e "  Product Service: ${PRODUCT_PID}"
echo -e "  Order Service:   ${ORDER_PID}"
echo -e "  Gateway:         ${GATEWAY_PID}"
echo ""
echo -e "${YELLOW}Logs disponibles dans:${NC}"
echo -e "  logs/product-service.log"
echo -e "  logs/order-service.log"
echo -e "  logs/gateway.log"
echo ""
echo -e "${YELLOW}URLs des services:${NC}"
echo -e "  Keycloak:        ${BLUE}http://localhost:8080${NC}"
echo -e "  Product Service: ${BLUE}http://localhost:8081${NC}"
echo -e "  Order Service:   ${BLUE}http://localhost:8082${NC}"
echo -e "  Gateway:         ${BLUE}http://localhost:8085${NC}"
echo -e "  React App:       ${BLUE}http://localhost:3000${NC}"
echo ""
echo -e "${YELLOW}Pour voir les logs en temps réel:${NC}"
echo -e "  tail -f logs/product-service.log"
echo -e "  tail -f logs/order-service.log"
echo -e "  tail -f logs/gateway.log"
echo ""
echo -e "${YELLOW}Pour arrêter tous les services:${NC}"
echo -e "  ./stop-services.sh"
echo ""
echo -e "${GREEN}Attendez environ 30-60 secondes pour que tous les services soient complètement démarrés...${NC}"
