#!/bin/bash

# Script de test RBAC après correction du préfixe ROLE_

KEYCLOAK_URL="http://localhost:8080"
GATEWAY_URL="http://localhost:8085"

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "  Test RBAC - Après Correction ROLE_ Prefix"
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
        echo -e "${RED}❌ Échec de l'authentification pour $username${NC}"
        return 1
    fi
    
    echo $token
}

# Fonction pour tester un endpoint
test_endpoint() {
    local method=$1
    local url=$2
    local token=$3
    local expected_code=$4
    local description=$5
    
    response=$(curl -s -w "\n%{http_code}" -X $method "$url" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" == "$expected_code" ]; then
        echo -e "${GREEN}✓${NC} $description (HTTP $http_code)"
        if [ "$http_code" == "200" ] || [ "$http_code" == "201" ]; then
            echo "   Résultat: $(echo $body | jq -c 'if type == "array" then "[\(length) items]" else . end' 2>/dev/null || echo "$body" | head -c 100)"
        fi
    else
        echo -e "${RED}✗${NC} $description"
        echo "   Attendu: HTTP $expected_code, Reçu: HTTP $http_code"
    fi
    echo ""
}

# Test USER
echo -e "${YELLOW}=== Tests USER ===${NC}"
USER_TOKEN=$(get_token "user" "user")
if [ ! -z "$USER_TOKEN" ]; then
    test_endpoint "GET" "$GATEWAY_URL/products" "$USER_TOKEN" "200" "USER - Liste des produits"
    test_endpoint "POST" "$GATEWAY_URL/products" "$USER_TOKEN" "403" "USER - Créer produit (devrait être bloqué)"
    test_endpoint "GET" "$GATEWAY_URL/orders" "$USER_TOKEN" "200" "USER - Mes commandes"
    test_endpoint "GET" "$GATEWAY_URL/orders/admin" "$USER_TOKEN" "403" "USER - Toutes les commandes (devrait être bloqué)"
fi

# Test MANAGER
echo -e "${YELLOW}=== Tests MANAGER ===${NC}"
MANAGER_TOKEN=$(get_token "manager" "manager")
if [ ! -z "$MANAGER_TOKEN" ]; then
    test_endpoint "GET" "$GATEWAY_URL/products" "$MANAGER_TOKEN" "200" "MANAGER - Liste des produits"
    test_endpoint "POST" "$GATEWAY_URL/products" "$MANAGER_TOKEN" "403" "MANAGER - Créer produit (devrait être bloqué)"
    test_endpoint "GET" "$GATEWAY_URL/orders/admin" "$MANAGER_TOKEN" "200" "MANAGER - Toutes les commandes"
    test_endpoint "PUT" "$GATEWAY_URL/orders/1/status?status=PROCESSING" "$MANAGER_TOKEN" "200" "MANAGER - Changer statut commande"
    test_endpoint "DELETE" "$GATEWAY_URL/orders/1" "$MANAGER_TOKEN" "403" "MANAGER - Supprimer commande (devrait être bloqué)"
fi

# Test ADMIN
echo -e "${YELLOW}=== Tests ADMIN ===${NC}"
ADMIN_TOKEN=$(get_token "admin" "admin")
if [ ! -z "$ADMIN_TOKEN" ]; then
    test_endpoint "GET" "$GATEWAY_URL/products" "$ADMIN_TOKEN" "200" "ADMIN - Liste des produits"
    test_endpoint "GET" "$GATEWAY_URL/orders/admin" "$ADMIN_TOKEN" "200" "ADMIN - Toutes les commandes"
    test_endpoint "DELETE" "$GATEWAY_URL/orders/6" "$ADMIN_TOKEN" "204" "ADMIN - Supprimer commande"
    
    # Test création produit
    echo -e "${GREEN}✓${NC} ADMIN - Test création de produit"
    curl -s -X POST "$GATEWAY_URL/products" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"name":"Test Product","description":"Created by test","price":99.99,"available":true}' | jq '.'
fi

echo ""
echo "================================================"
echo "  Fin des Tests"
echo "================================================"
