#!/bin/bash

# Script pour arrêter tous les microservices
# Usage: ./stop-services.sh

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Arrêt des Microservices${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Trouver et arrêter tous les processus Spring Boot
echo -e "${YELLOW}Recherche des processus Spring Boot...${NC}"

# Arrêter Product Service
PRODUCT_PIDS=$(ps aux | grep 'product-service.*spring-boot:run' | grep -v grep | awk '{print $2}')
if [ ! -z "$PRODUCT_PIDS" ]; then
    echo -e "${YELLOW}Arrêt du Product Service (PIDs: $PRODUCT_PIDS)...${NC}"
    echo $PRODUCT_PIDS | xargs kill -9 2>/dev/null
    echo -e "${GREEN}✓ Product Service arrêté${NC}"
else
    echo -e "${RED}✗ Product Service n'est pas en cours d'exécution${NC}"
fi

# Arrêter Order Service
ORDER_PIDS=$(ps aux | grep 'order-service.*spring-boot:run' | grep -v grep | awk '{print $2}')
if [ ! -z "$ORDER_PIDS" ]; then
    echo -e "${YELLOW}Arrêt du Order Service (PIDs: $ORDER_PIDS)...${NC}"
    echo $ORDER_PIDS | xargs kill -9 2>/dev/null
    echo -e "${GREEN}✓ Order Service arrêté${NC}"
else
    echo -e "${RED}✗ Order Service n'est pas en cours d'exécution${NC}"
fi

# Arrêter Gateway
GATEWAY_PIDS=$(ps aux | grep 'gateway.*spring-boot:run' | grep -v grep | awk '{print $2}')
if [ ! -z "$GATEWAY_PIDS" ]; then
    echo -e "${YELLOW}Arrêt du Gateway (PIDs: $GATEWAY_PIDS)...${NC}"
    echo $GATEWAY_PIDS | xargs kill -9 2>/dev/null
    echo -e "${GREEN}✓ Gateway arrêté${NC}"
else
    echo -e "${RED}✗ Gateway n'est pas en cours d'exécution${NC}"
fi

# Arrêter tous les processus Maven restants
MAVEN_PIDS=$(ps aux | grep 'mvn.*spring-boot' | grep -v grep | awk '{print $2}')
if [ ! -z "$MAVEN_PIDS" ]; then
    echo -e "${YELLOW}Arrêt des processus Maven restants...${NC}"
    echo $MAVEN_PIDS | xargs kill -9 2>/dev/null
    echo -e "${GREEN}✓ Processus Maven arrêtés${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Tous les services sont arrêtés${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Pour arrêter également Keycloak:${NC}"
echo -e "  cd keycloak && docker-compose down"
echo ""
