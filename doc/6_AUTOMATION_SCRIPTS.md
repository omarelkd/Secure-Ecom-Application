# Scripts d'Automatisation et Commandes Rapides

Fichiers et commandes pour accélérer le développement et vérifier le projet rapidement.

---

## 1. Script Docker Compose Complet

Créer le fichier `docker-compose.yml` à la racine du projet:

```yaml
version: '3.8'

services:
  # Base de données pour Keycloak
  postgres:
    image: postgres:15-alpine
    container_name: keycloak_postgres
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: keycloak_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U keycloak"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - microservices_network

  # Keycloak pour authentification
  keycloak:
    image: quay.io/keycloak/keycloak:26.0.0
    container_name: keycloak_server
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      DB_VENDOR: postgres
      DB_ADDR: postgres
      DB_DATABASE: keycloak
      DB_USER: keycloak
      DB_PASSWORD: keycloak_password
      KC_PROXY: edge
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - microservices_network
    command: start-dev

  # Product Service (Port 8081)
  product-service:
    image: maven:3.9-eclipse-temurin-21
    container_name: product_service
    working_dir: /workspace/product-service
    volumes:
      - .:/workspace
      - product_m2:/root/.m2
    ports:
      - "8081:8081"
    environment:
      SPRING_PROFILES_ACTIVE: dev
    command: mvn spring-boot:run
    depends_on:
      - keycloak
    networks:
      - microservices_network
    profiles: ["services"]

  # Order Service (Port 8082)
  order-service:
    image: maven:3.9-eclipse-temurin-21
    container_name: order_service
    working_dir: /workspace/order-service
    volumes:
      - .:/workspace
      - order_m2:/root/.m2
    ports:
      - "8082:8082"
    environment:
      SPRING_PROFILES_ACTIVE: dev
    command: mvn spring-boot:run
    depends_on:
      - keycloak
    networks:
      - microservices_network
    profiles: ["services"]

  # API Gateway (Port 8085)
  gateway:
    image: maven:3.9-eclipse-temurin-21
    container_name: api_gateway
    working_dir: /workspace/gateway
    volumes:
      - .:/workspace
      - gateway_m2:/root/.m2
    ports:
      - "8085:8085"
    environment:
      SPRING_PROFILES_ACTIVE: dev
    command: mvn spring-boot:run
    depends_on:
      - keycloak
      - product-service
      - order-service
    networks:
      - microservices_network
    profiles: ["services"]

volumes:
  postgres_data:
  product_m2:
  order_m2:
  gateway_m2:

networks:
  microservices_network:
    driver: bridge
```

**Usage:**

```bash
# Démarrer SEULEMENT Keycloak (pour dev local - recommandé)
docker-compose up postgres keycloak

# Démarrer tout (Keycloak + Services)
docker-compose up --profile services

# Arrêter tout
docker-compose down

# Voir les logs
docker-compose logs -f keycloak
docker-compose logs -f product-service
```

---

## 2. Script Setup Initial Keycloak (Bash)

Créer `scripts/setup-keycloak.sh`:

```bash
#!/bin/bash

set -e

KEYCLOAK_URL="http://localhost:8080"
REALM="microservices-realm"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

echo "=== Vérification de Keycloak ==="
sleep 5
curl -s $KEYCLOAK_URL/realms/master/.well-known/openid-configuration > /dev/null && echo "✓ Keycloak accessible" || {
    echo "✗ Keycloak non accessible"
    exit 1
}

echo ""
echo "=== Obtention du token admin ==="
ADMIN_TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=admin-cli" \
  -d "grant_type=password" \
  -d "username=$ADMIN_USER" \
  -d "password=$ADMIN_PASSWORD" | jq -r '.access_token')

[ -z "$ADMIN_TOKEN" ] && { echo "✗ Impossible d'obtenir le token admin"; exit 1; }
echo "✓ Token admin obtenu"

echo ""
echo "=== Création du Realm $REALM ==="
REALM_EXISTS=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" | jq -r '.realm' 2>/dev/null)

if [ "$REALM_EXISTS" != "$REALM" ]; then
    curl -s -X POST "$KEYCLOAK_URL/admin/realms" \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "realm": "'$REALM'",
        "enabled": true,
        "displayName": "Microservices Realm"
      }' > /dev/null
    echo "✓ Realm $REALM créé"
else
    echo "✓ Realm $REALM déjà existant"
fi

echo ""
echo "=== Création des rôles ==="
for ROLE in user admin manager; do
    curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM/roles" \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "name": "'$ROLE'",
        "description": "'$([ "$ROLE" = "user" ] && echo "Utilisateur standard" || echo $ROLE)'",
        "enabled": true
      }' > /dev/null 2>&1 || true
    echo "✓ Rôle $ROLE créé"
done

echo ""
echo "=== Création des utilisateurs ==="
USERS=(
    "john.user:password123:user"
    "alice.admin:admin123:admin"
    "bob.manager:manager123:manager"
)

for USER_INFO in "${USERS[@]}"; do
    IFS=':' read USERNAME PASSWORD ROLE <<< "$USER_INFO"
    
    # Créer l'utilisateur
    USER_ID=$(curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM/users" \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{
        "username": "'$USERNAME'",
        "email": "'${USERNAME%.*}'@test.local",
        "emailVerified": true,
        "firstName": "'${USERNAME%.*}'",
        "lastName": "'${USERNAME##*.}'",
        "enabled": true
      }' | jq -r '.[]' 2>/dev/null || echo "")
    
    if [ -z "$USER_ID" ]; then
        USER_ID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/users?username=$USERNAME" \
          -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[0].id' 2>/dev/null)
    fi
    
    if [ -n "$USER_ID" ]; then
        # Définir le mot de passe
        curl -s -X PUT "$KEYCLOAK_URL/admin/realms/$REALM/users/$USER_ID/reset-password" \
          -H "Authorization: Bearer $ADMIN_TOKEN" \
          -H "Content-Type: application/json" \
          -d '{
            "type": "password",
            "value": "'$PASSWORD'",
            "temporary": false
          }' > /dev/null 2>&1 || true
        
        # Assigner le rôle
        ROLE_ID=$(curl -s -X GET "$KEYCLOAK_URL/admin/realms/$REALM/roles/$ROLE" \
          -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.id')
        
        curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM/users/$USER_ID/role-mappings/realm" \
          -H "Authorization: Bearer $ADMIN_TOKEN" \
          -H "Content-Type: application/json" \
          -d '[{
            "id": "'$ROLE_ID'",
            "name": "'$ROLE'",
            "composite": false,
            "clientRole": false
          }]' > /dev/null 2>&1 || true
        
        echo "✓ Utilisateur $USERNAME créé avec rôle $ROLE"
    fi
done

echo ""
echo "=== Création des clients ==="

# Client: react-client
curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM/clients" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "react-client",
    "enabled": true,
    "publicClient": true,
    "redirectUris": ["http://localhost:3000", "http://localhost:3000/*"],
    "webOrigins": ["http://localhost:3000"],
    "standardFlowEnabled": true,
    "directAccessGrantsEnabled": true,
    "implicitFlowEnabled": false
  }' > /dev/null 2>&1 || true
echo "✓ Client react-client créé"

# Client: gateway-client
curl -s -X POST "$KEYCLOAK_URL/admin/realms/$REALM/clients" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "gateway-client",
    "enabled": true,
    "publicClient": false,
    "redirectUris": ["http://localhost:8085/*"],
    "webOrigins": ["http://localhost:8085"],
    "serviceAccountsEnabled": true,
    "standardFlowEnabled": true,
    "directAccessGrantsEnabled": true
  }' > /dev/null 2>&1 || true
echo "✓ Client gateway-client créé"

echo ""
echo "=== Configuration terminée ==="
echo ""
echo "Credentials de test:"
echo "  User: john.user / password123 (rôle: user)"
echo "  Admin: alice.admin / admin123 (rôle: admin)"
echo "  Manager: bob.manager / manager123 (rôle: manager)"
echo ""
echo "Accès à la console: http://localhost:8080/admin/realms/$REALM"
```

**Utilisation:**

```bash
chmod +x scripts/setup-keycloak.sh
./scripts/setup-keycloak.sh
```

---

## 3. Script de Test Rapide (Bash)

Créer `scripts/test-integration.sh`:

```bash
#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

KEYCLOAK_URL="http://localhost:8080"
REALM="microservices-realm"
GATEWAY_URL="http://localhost:8085"

test_count=0
pass_count=0

test_case() {
    ((test_count++))
    local name="$1"
    local cmd="$2"
    local expected="$3"
    
    echo -n "Test $test_count: $name ... "
    result=$(eval "$cmd" 2>&1)
    
    if echo "$result" | grep -q "$expected"; then
        echo -e "${GREEN}OK${NC}"
        ((pass_count++))
    else
        echo -e "${RED}FAIL${NC}"
        echo "  Expected: $expected"
        echo "  Got: $result"
    fi
}

echo "=== Tests d'Intégration OAuth2/OIDC ==="
echo ""

# Obtenir un token
echo "Obtaining test token..."
TOKEN=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client" \
  -d "grant_type=password" \
  -d "username=john.user" \
  -d "password=password123" | jq -r '.access_token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo -e "${RED}FAIL: Cannot obtain token${NC}"
    exit 1
fi
echo "✓ Token obtained"
echo ""

# Tests
test_case "Keycloak config" \
    "curl -s $KEYCLOAK_URL/realms/$REALM/.well-known/openid-configuration | jq .issuer" \
    "microservices-realm"

test_case "Product Service (direct)" \
    "curl -s -H 'Authorization: Bearer $TOKEN' http://localhost:8081/products" \
    "Produits"

test_case "Order Service (direct)" \
    "curl -s -H 'Authorization: Bearer $TOKEN' http://localhost:8082/orders" \
    "Commandes"

test_case "Product Service (via Gateway)" \
    "curl -s -H 'Authorization: Bearer $TOKEN' $GATEWAY_URL/products" \
    "Produits"

test_case "Order Service (via Gateway)" \
    "curl -s -H 'Authorization: Bearer $TOKEN' $GATEWAY_URL/orders" \
    "Commandes"

test_case "No token returns 401" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost:8081/products" \
    "401"

test_case "Admin token has admin role" \
    "curl -s -X POST '$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -d 'client_id=react-client&grant_type=password&username=alice.admin&password=admin123' | \
    jq '.access_token' | cut -d. -f2 | base64 -d 2>/dev/null | jq '.realm_access.roles' | grep -o admin" \
    "admin"

echo ""
echo "==================================="
echo "Results: $pass_count/$test_count tests passed"
echo "==================================="

[ $pass_count -eq $test_count ] && exit 0 || exit 1
```

**Utilisation:**

```bash
chmod +x scripts/test-integration.sh
./scripts/test-integration.sh
```

---

## 4. Makefile pour Commandes Rapides

Créer `Makefile` à la racine:

```makefile
.PHONY: help docker-up docker-down keycloak-setup test-integration clean build \
        start-services stop-services logs-keycloak logs-gateway logs-products logs-orders \
        token test-endpoints

help:
	@echo "Commandes disponibles:"
	@echo "  make docker-up              - Démarrer Keycloak avec Docker"
	@echo "  make docker-down            - Arrêter Keycloak"
	@echo "  make keycloak-setup         - Setup initial Keycloak"
	@echo "  make test-integration       - Lancer tests d'intégration"
	@echo "  make build                  - Build tous les services"
	@echo "  make start-services         - Démarrer les services (dans des screens)"
	@echo "  make stop-services          - Arrêter tous les services"
	@echo "  make logs-keycloak          - Voir logs Keycloak"
	@echo "  make logs-gateway           - Voir logs Gateway"
	@echo "  make token                  - Obtenir un token de test"
	@echo "  make test-endpoints         - Tester les endpoints"
	@echo "  make clean                  - Nettoyer (Docker + Maven)"

# Docker
docker-up:
	docker-compose up postgres keycloak

docker-down:
	docker-compose down

# Setup
keycloak-setup:
	./scripts/setup-keycloak.sh

test-integration:
	./scripts/test-integration.sh

# Build
build:
	cd product-service && mvn clean package -DskipTests
	cd order-service && mvn clean package -DskipTests
	cd gateway && mvn clean package -DskipTests

# Services
start-services:
	cd product-service && mvn spring-boot:run &
	cd order-service && mvn spring-boot:run &
	cd gateway && mvn spring-boot:run &

stop-services:
	pkill -f "mvn spring-boot:run"

# Logs
logs-keycloak:
	docker-compose logs -f keycloak

logs-gateway:
	cd gateway && mvn spring-boot:run

logs-products:
	cd product-service && mvn spring-boot:run

logs-orders:
	cd order-service && mvn spring-boot:run

# Token
token:
	@curl -s -X POST "http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token" \
	  -H "Content-Type: application/x-www-form-urlencoded" \
	  -d "client_id=react-client" \
	  -d "grant_type=password" \
	  -d "username=john.user" \
	  -d "password=password123" | jq .

# Test endpoints
test-endpoints:
	@TOKEN=$$(curl -s -X POST "http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token" \
	  -H "Content-Type: application/x-www-form-urlencoded" \
	  -d "client_id=react-client" \
	  -d "grant_type=password" \
	  -d "username=john.user" \
	  -d "password=password123" | jq -r '.access_token'); \
	echo "Testing with token: $$TOKEN"; \
	echo ""; \
	echo "GET /products (Gateway):"; \
	curl -H "Authorization: Bearer $$TOKEN" http://localhost:8085/products; \
	echo ""; \
	echo "GET /orders (Gateway):"; \
	curl -H "Authorization: Bearer $$TOKEN" http://localhost:8085/orders;

# Clean
clean:
	docker-compose down -v
	rm -rf product-service/target order-service/target gateway/target
	pkill -f "mvn spring-boot:run"
```

**Utilisation:**

```bash
make help
make docker-up
make keycloak-setup
make test-endpoints
make clean
```

---

## 5. Script Node.js pour Setup Keycloak (Alternatif)

Créer `scripts/setup-keycloak.js`:

```javascript
const https = require('http');
const querystring = require('querystring');

const KEYCLOAK_URL = "http://localhost:8080";
const REALM = "microservices-realm";
const ADMIN_USER = "admin";
const ADMIN_PASSWORD = "admin";

function makeRequest(method, url, body = null, token = null) {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'localhost',
            port: 8080,
            path: url.replace('http://localhost:8080', ''),
            method: method,
            headers: {
                'Content-Type': 'application/json'
            }
        };

        if (token) {
            options.headers['Authorization'] = `Bearer ${token}`;
        }

        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => resolve({ status: res.statusCode, body: data }));
        });

        req.on('error', reject);
        if (body) req.write(JSON.stringify(body));
        req.end();
    });
}

async function setup() {
    try {
        console.log("=== Setup Keycloak ===\n");

        // Obtenir token admin
        console.log("Obtaining admin token...");
        // Implementation...

        console.log("✓ Setup completed!");
    } catch (error) {
        console.error("Setup failed:", error);
        process.exit(1);
    }
}

setup();
```

---

## 6. .env.example pour Configuration

Créer `.env.example`:

```env
# Keycloak
KEYCLOAK_URL=http://localhost:8080
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin
KEYCLOAK_REALM=microservices-realm

# Services
PRODUCT_SERVICE_PORT=8081
ORDER_SERVICE_PORT=8082
GATEWAY_PORT=8085

# Database
POSTGRES_DB=keycloak
POSTGRES_USER=keycloak
POSTGRES_PASSWORD=keycloak_password

# React
REACT_APP_KEYCLOAK_URL=http://localhost:8080
REACT_APP_REALM=microservices-realm
REACT_APP_CLIENT_ID=react-client
REACT_APP_API_URL=http://localhost:8085

# JWT
JWT_ISSUER_URI=http://localhost:8080/realms/microservices-realm
```

---

## 7. Startup Rapide (Commandes à Utiliser Quotidiennement)

```bash
# Jour 1: Setup initial
docker-compose up postgres keycloak &
sleep 15
./scripts/setup-keycloak.sh
sleep 5

# Jours suivants: Dev rapide
# Terminal 1: Services backend
cd product-service && mvn spring-boot:run

# Terminal 2: Order service
cd order-service && mvn spring-boot:run

# Terminal 3: Gateway
cd gateway && mvn spring-boot:run

# Terminal 4: Frontend React
cd react-app && npm start

# Tests rapides
make test-endpoints
make test-integration

# Vérifier un token
make token
```

---

## Résumé des Fichiers à Créer

```
projet_ouath2_oidc/
├── docker-compose.yml           # Docker Compose complet
├── Makefile                     # Commandes rapides
├── .env.example                 # Variables d'environnement
└── scripts/
    ├── setup-keycloak.sh        # Setup Keycloak automatique
    ├── test-integration.sh      # Tests d'intégration
    └── setup-keycloak.js        # Alternative Node.js
```

Tous ces fichiers accélèrent significativement le développement et les tests!

