#!/bin/bash

# Script pour vérifier l'état des microservices
# Usage: ./check-services.sh

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  État des Microservices${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Fonction pour vérifier un service
check_service() {
    local name=$1
    local url=$2
    local port=$3
    
    echo -n "[$name] "
    
    # Vérifier si le port est ouvert
    if nc -z localhost $port 2>/dev/null; then
        echo -e "${GREEN}✓ Running${NC} (port $port)"
    else
        echo -e "${RED}✗ Not running${NC} (port $port)"
    fi
}

# Vérifier Keycloak
echo -e "${YELLOW}Keycloak:${NC}"
check_service "Keycloak Server" "http://localhost:8080" 8080
if curl -s http://localhost:8080/realms/microservices-realm/.well-known/openid-configuration > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ Realm 'microservices-realm' accessible${NC}"
else
    echo -e "  ${RED}✗ Realm not accessible${NC}"
fi
echo ""

# Vérifier Product Service
echo -e "${YELLOW}Product Service:${NC}"
check_service "Product Service" "http://localhost:8081" 8081
if curl -s http://localhost:8081/h2-console > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ H2 Console accessible${NC}"
fi
echo ""

# Vérifier Order Service
echo -e "${YELLOW}Order Service:${NC}"
check_service "Order Service" "http://localhost:8082" 8082
if curl -s http://localhost:8082/h2-console > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ H2 Console accessible${NC}"
fi
echo ""

# Vérifier Gateway
echo -e "${YELLOW}API Gateway:${NC}"
check_service "Gateway" "http://localhost:8085" 8085
echo ""

# Vérifier React App
echo -e "${YELLOW}React App:${NC}"
check_service "React Frontend" "http://localhost:3000" 3000
echo ""

# Afficher les processus
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Processus actifs${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

PRODUCT_PIDS=$(ps aux | grep 'product-service.*spring-boot:run' | grep -v grep | awk '{print $2}')
ORDER_PIDS=$(ps aux | grep 'order-service.*spring-boot:run' | grep -v grep | awk '{print $2}')
GATEWAY_PIDS=$(ps aux | grep 'gateway.*spring-boot:run' | grep -v grep | awk '{print $2}')

if [ ! -z "$PRODUCT_PIDS" ]; then
    echo -e "${GREEN}Product Service PIDs:${NC} $PRODUCT_PIDS"
fi

if [ ! -z "$ORDER_PIDS" ]; then
    echo -e "${GREEN}Order Service PIDs:${NC} $ORDER_PIDS"
fi

if [ ! -z "$GATEWAY_PIDS" ]; then
    echo -e "${GREEN}Gateway PIDs:${NC} $GATEWAY_PIDS"
fi

if [ -z "$PRODUCT_PIDS" ] && [ -z "$ORDER_PIDS" ] && [ -z "$GATEWAY_PIDS" ]; then
    echo -e "${RED}Aucun processus Spring Boot actif${NC}"
fi

echo ""
echo -e "${YELLOW}URLs:${NC}"
echo -e "  Keycloak Admin:  ${BLUE}http://localhost:8080${NC}"
echo -e "  Product H2:      ${BLUE}http://localhost:8081/h2-console${NC}"
echo -e "  Order H2:        ${BLUE}http://localhost:8082/h2-console${NC}"
echo -e "  Gateway:         ${BLUE}http://localhost:8085${NC}"
echo -e "  React App:       ${BLUE}http://localhost:3000${NC}"
echo ""
