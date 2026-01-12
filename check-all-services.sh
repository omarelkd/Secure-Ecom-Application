#!/bin/bash

# Script de vérification rapide de tous les services
# Usage: ./check-all-services.sh

echo "🔍 Vérification de l'état des services"
echo "========================================"
echo ""

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fonction pour tester un service
check_service() {
    local name=$1
    local url=$2
    local port=$3
    
    echo -n "  $name (port $port): "
    
    if curl -s -f "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ NON DISPONIBLE${NC}"
        return 1
    fi
}

echo -e "${BLUE}📦 Services Backend:${NC}"
check_service "Keycloak        " "http://localhost:8080/realms/microservices-realm" "8080"
check_service "Product Service " "http://localhost:8081/products" "8081"
check_service "Order Service   " "http://localhost:8082/actuator/health" "8082"
check_service "API Gateway     " "http://localhost:8085/products" "8085"

echo ""
echo -e "${BLUE}🎨 Frontend:${NC}"
check_service "React App       " "http://localhost:3000" "3000"

echo ""
echo -e "${BLUE}🗄️  Base de données:${NC}"
if pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
    echo -e "  PostgreSQL (port 5432): ${GREEN}✅ OK${NC}"
else
    echo -e "  PostgreSQL (port 5432): ${RED}❌ NON DISPONIBLE${NC}"
fi

echo ""
echo "========================================"
echo -e "${YELLOW}📊 Statistiques Docker:${NC}"
docker-compose ps --format "table {{.Service}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | grep -v "^NAME"

echo ""
echo -e "${YELLOW}🔗 URLs d'accès:${NC}"
echo -e "  ${BLUE}Frontend:${NC}     http://localhost:3000"
echo -e "  ${BLUE}Keycloak:${NC}     http://localhost:8080"
echo -e "  ${BLUE}API Gateway:${NC}  http://localhost:8085"
echo -e "  ${BLUE}Products:${NC}     http://localhost:8081/products"
echo -e "  ${BLUE}Orders:${NC}       http://localhost:8082/orders"

echo ""
echo -e "${GREEN}✨ Vérification terminée!${NC}"
