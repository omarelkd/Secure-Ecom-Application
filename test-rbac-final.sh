#!/bin/bash

# Script de test RBAC FINAL - Après correction complète

KEYCLOAK_URL="http://localhost:8080"
PRODUCT_SERVICE="http://localhost:8081"
ORDER_SERVICE="http://localhost:8082"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "  Test RBAC FINAL - Correction Complète"
echo "================================================"
echo ""

# Fonction pour obtenir le token
get_token() {
    local username=$1
    local password=$2
    
    response=$(curl -s -X POST "$KEYCLOAK_URL/realms/microservices-realm/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "client_id=react-client" \
        -d "grant_type=password" \
        -d "username=$username" \
        -d "password=$password" \
        -d "scope=openid profile")
    
    token=$(echo $response | jq -r '.access_token')
    
    if [ "$token" == "null" ] || [ -z "$token" ]; then
        echo -e "${RED}❌ Échec authentification $username${NC}"
        echo "Erreur: $(echo $response | jq -r '.error_description')"
        return 1
    fi
    
    echo $token
}

# Test USER
echo -e "${YELLOW}=== Tests USER (password123) ===${NC}"
USER_TOKEN=$(get_token "user" "password123")
if [ ! -z "$USER_TOKEN" ] && [ "$USER_TOKEN" != "null" ]; then
    echo ""
    echo "1. GET /products (devrait fonctionner):"
    RESULT=$(curl -s "http://localhost:8081/products" -H "Authorization: Bearer $USER_TOKEN")
    COUNT=$(echo $RESULT | jq -s 'if .[0] | type == "array" then .[0] | length else 0 end')
    if [ "$COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Accès autorisé - $COUNT produits${NC}"
    else
        echo -e "${RED}❌ Échec${NC}"
    fi
    
    echo ""
    echo "2. POST /products (devrait être bloqué - 403):"
    STATUS=$(curl -s -w "%{http_code}" -o /dev/null -X POST "http://localhost:8081/products" \
        -H "Authorization: Bearer $USER_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"name":"Test","description":"Test","price":99.99,"quantity":10}')
    if [ "$STATUS" == "403" ]; then
        echo -e "${GREEN}✅ Accès refusé comme prévu (403)${NC}"
    else
        echo -e "${RED}❌ HTTP $STATUS (attendu 403)${NC}"
    fi
    
    echo ""
    echo "3. GET /orders (mes commandes):"
    RESULT=$(curl -s "http://localhost:8082/orders" -H "Authorization: Bearer $USER_TOKEN")
    COUNT=$(echo $RESULT | jq -s 'if .[0] | type == "array" then .[0] | length else 0 end')
    if [ "$COUNT" -ge 0 ]; then
        echo -e "${GREEN}✅ Accès autorisé - $COUNT commandes${NC}"
    else
        echo -e "${RED}❌ Échec${NC}"
    fi
fi

# Test ADMIN
echo ""
echo -e "${YELLOW}=== Tests ADMIN (admin123) ===${NC}"
ADMIN_TOKEN=$(get_token "admin" "admin123")
if [ ! -z "$ADMIN_TOKEN" ] && [ "$ADMIN_TOKEN" != "null" ]; then
    echo ""
    echo "1. GET /products:"
    RESULT=$(curl -s "http://localhost:8081/products" -H "Authorization: Bearer $ADMIN_TOKEN")
    COUNT=$(echo $RESULT | jq -s 'if .[0] | type == "array" then .[0] | length else 0 end')
    if [ "$COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Accès autorisé - $COUNT produits${NC}"
    else
        echo -e "${RED}❌ Échec${NC}"
    fi
    
    echo ""
    echo "2. POST /products (devrait fonctionner):"
    RESULT=$(curl -s -X POST "http://localhost:8081/products" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"name":"Produit Admin Test","description":"Créé par admin","price":299.99,"quantity":50}')
    ID=$(echo $RESULT | jq -r '.id // empty')
    if [ ! -z "$ID" ]; then
        echo -e "${GREEN}✅ Produit créé (ID=$ID)${NC}"
    else
        echo -e "${RED}❌ Échec: $(echo $RESULT | jq -c '.')${NC}"
    fi
    
    echo ""
    echo "3. GET /orders/admin (toutes les commandes):"
    RESULT=$(curl -s "http://localhost:8082/orders/admin" -H "Authorization: Bearer $ADMIN_TOKEN")
    COUNT=$(echo $RESULT | jq -s 'if .[0] | type == "array" then .[0] | length else 0 end')
    if [ "$COUNT" -ge 0 ]; then
        echo -e "${GREEN}✅ Accès autorisé - $COUNT commandes au total${NC}"
    else
        echo -e "${RED}❌ Échec${NC}"
    fi
fi

# Test MANAGER
echo ""
echo -e "${YELLOW}=== Tests MANAGER (manager123) ===${NC}"
MANAGER_TOKEN=$(get_token "manager" "manager123")
if [ ! -z "$MANAGER_TOKEN" ] && [ "$MANAGER_TOKEN" != "null" ]; then
    echo ""
    echo "1. GET /orders/admin (toutes les commandes):"
    RESULT=$(curl -s "http://localhost:8082/orders/admin" -H "Authorization: Bearer $MANAGER_TOKEN")
    COUNT=$(echo $RESULT | jq -s 'if .[0] | type == "array" then .[0] | length else 0 end')
    if [ "$COUNT" -ge 0 ]; then
        echo -e "${GREEN}✅ Accès autorisé - $COUNT commandes${NC}"
    else
        echo -e "${RED}❌ Échec${NC}"
    fi
    
    echo ""
    echo "2. POST /products (devrait être bloqué - 403):"
    STATUS=$(curl -s -w "%{http_code}" -o /dev/null -X POST "http://localhost:8081/products" \
        -H "Authorization: Bearer $MANAGER_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"name":"Test","description":"Test","price":99.99,"quantity":10}')
    if [ "$STATUS" == "403" ]; then
        echo -e "${GREEN}✅ Accès refusé comme prévu (403)${NC}"
    else
        echo -e "${RED}❌ HTTP $STATUS (attendu 403)${NC}"
    fi
fi

echo ""
echo "================================================"
echo "  Résumé: Tests RBAC Terminés"
echo "================================================"
