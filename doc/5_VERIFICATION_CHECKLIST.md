# Guide de Vérification et Validation du Projet

Checklist complète pour vérifier que tout est bien configuré dans le projet OAuth2/OIDC.

À utiliser **avant chaque étape** et **après chaque modification**.

---

## Phase 0: Vérification de l'Environnement

### Prérequis Installés

```bash
# Java 21
java -version
# Devrait afficher: openjdk version "21.x.x"

# Maven
mvn --version
# Devrait afficher: Maven 3.8.x

# Node.js
node --version
# Devrait afficher: v18.x.x ou supérieur

# Docker
docker --version
# Devrait afficher: Docker version xx.x.x

# Git
git --version
# Devrait afficher: git version 2.x.x
```

### Vérifier les Ports Disponibles

```bash
# Vérifier que les ports ne sont pas utilisés
lsof -i :8080 || echo "Port 8080 libre"
lsof -i :8081 || echo "Port 8081 libre"
lsof -i :8082 || echo "Port 8082 libre"
lsof -i :8085 || echo "Port 8085 libre"
lsof -i :3000 || echo "Port 3000 libre"
lsof -i :5432 || echo "Port 5432 libre (PostgreSQL)"
```

**Checkpoint 0.1**: Tous les outils installés et ports libres

---

## Phase 1: Vérification Keycloak

### 1.1 Keycloak Démarre

```bash
# Vérifier que le container est en cours d'exécution
docker ps | grep keycloak
# Devrait voir une ligne avec le container keycloak

# Vérifier l'accès à la console
curl -s http://localhost:8080/admin/master/console/ | grep -q "Keycloak" && echo "Keycloak accessible" || echo "ERREUR: Keycloak non accessible"
```

### 1.2 Vérifier que le Realm Existe

```bash
# Vérifier via l'endpoint OpenID Config
curl -s http://localhost:8080/realms/microservices-realm/.well-known/openid-configuration | jq -r '.issuer'
# Devrait afficher: http://localhost:8080/realms/microservices-realm
```

### 1.3 Vérifier les Rôles

```bash
# Se connecter à Keycloak et vérifier les rôles
curl -s -X GET "http://localhost:8080/admin/realms/microservices-realm/roles" \
  -H "Authorization: Bearer $(curl -s -X POST http://localhost:8080/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=admin-cli&grant_type=password&username=admin&password=admin" | jq -r '.access_token')" | jq -r '.[].name'
# Devrait afficher: user, admin, manager
```

### 1.4 Vérifier les Utilisateurs

```bash
curl -s -X GET "http://localhost:8080/admin/realms/microservices-realm/users" \
  -H "Authorization: Bearer $(curl -s -X POST http://localhost:8080/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=admin-cli&grant_type=password&username=admin&password=admin" | jq -r '.access_token')" | jq -r '.[].username'
# Devrait afficher: john.user, alice.admin, bob.manager
```

### 1.5 Obtenir un Token Valide

```bash
TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client" \
  -d "grant_type=password" \
  -d "username=john.user" \
  -d "password=password123" | jq -r '.access_token')

echo "Token: $TOKEN"

# Vérifier que le token n'est pas vide
[ -z "$TOKEN" ] && echo "ERREUR: Token vide" || echo "OK: Token obtenu"
```

### 1.6 Décoder et Vérifier le Token

```bash
# Décoder le JWT (sans vérifier la signature)
TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client" \
  -d "grant_type=password" \
  -d "username=john.user" \
  -d "password=password123" | jq -r '.access_token')

echo "Claims du token:"
echo $TOKEN | cut -d. -f2 | base64 -d 2>/dev/null | jq .

# Vérifier les champs présents:
# - "iss": "http://localhost:8080/realms/microservices-realm"
# - "sub": "<user_id>"
# - "preferred_username": "john.user"
# - "realm_access": {"roles": [...]}
```

**Checkpoint 1**: Keycloak, realm, rôles, utilisateurs et tokens fonctionnent

---

## Phase 2: Vérification des Services Backend

### 2.1 Vérifier que Product Service Démarre

```bash
cd product-service

# Compiler le projet
mvn clean compile
# Devrait terminer sans erreur

# Vérifier la structure Maven
ls -la src/main/java/ma/enset/productservice/
# Devrait contenir: ProductServiceApplication.java, config/, controller/

# Vérifier la configuration
grep -A5 "issuer-uri" src/main/resources/application.yml
# Devrait afficher: issuer-uri: http://localhost:8080/realms/microservices-realm
```

### 2.2 Démarrer Product Service

```bash
cd product-service

# Démarrer le service
mvn spring-boot:run

# Dans un autre terminal, vérifier qu'il démarre
sleep 5 && curl -s http://localhost:8081/actuator/health 2>/dev/null | jq . || echo "Service pas encore prêt"

# Après ~10-15 secondes, devrait répondre: {"status":"UP"}
```

### 2.3 Tester Endpoint Protégé du Product Service

```bash
# SANS TOKEN - Devrait refuser
curl -i http://localhost:8081/products
# Devrait retourner: 401 Unauthorized

# AVEC TOKEN VALIDE - Devrait accepter
TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client" \
  -d "grant_type=password" \
  -d "username=john.user" \
  -d "password=password123" | jq -r '.access_token')

curl -H "Authorization: Bearer $TOKEN" http://localhost:8081/products
# Devrait retourner: "Produits accessibles pour : john.user"

# AVEC TOKEN INVALIDE - Devrait refuser
curl -i -H "Authorization: Bearer invalid_token" http://localhost:8081/products
# Devrait retourner: 401 Unauthorized
```

### 2.4 Vérifier que Order Service Démarre

```bash
# Même procédure que Product Service
cd order-service

mvn clean compile

# Vérifier la configuration
grep -A5 "issuer-uri" src/main/resources/application.yml
# Devrait afficher: issuer-uri: http://localhost:8080/realms/microservices-realm

# Démarrer
mvn spring-boot:run
```

### 2.5 Tester Endpoint Protégé du Order Service

```bash
TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client" \
  -d "grant_type=password" \
  -d "username=john.user" \
  -d "password=password123" | jq -r '.access_token')

curl -H "Authorization: Bearer $TOKEN" http://localhost:8082/orders
# Devrait retourner: "Commandes de l'utilisateur : john.user"
```

### 2.6 Vérifier que API Gateway Démarre

```bash
cd gateway

mvn clean compile

# Vérifier la configuration
grep -A5 "issuer-uri" src/main/resources/application.yml

# Vérifier les routes
grep -A10 "routes:" src/main/resources/application.yml
# Devrait contenir:
# - product-service → localhost:8081
# - order-service → localhost:8082

# Vérifier CORS
grep -A5 "cors" src/main/java/ma/enset/gateway/config/GatewaySecurityConfig.java
# Devrait contenir: http://localhost:3000

mvn spring-boot:run
```

### 2.7 Tester les Routes Gateway

```bash
TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client" \
  -d "grant_type=password" \
  -d "username=john.user" \
  -d "password=password123" | jq -r '.access_token')

# Route vers Product Service via Gateway
curl -H "Authorization: Bearer $TOKEN" http://localhost:8085/products
# Devrait répondre: "Produits accessibles pour : john.user"

# Route vers Order Service via Gateway
curl -H "Authorization: Bearer $TOKEN" http://localhost:8085/orders
# Devrait répondre: "Commandes de l'utilisateur : john.user"
```

**Checkpoint 2**: Tous les services démarrent et répondent correctement avec tokens

---

## Phase 3: Vérification Frontend

### 3.1 Vérifier la Configuration Keycloak.js

```bash
cd react-app

cat src/keycloak.js
# Devrait contenir:
# - url: "http://localhost:8080"
# - realm: "microservices-realm"
# - clientId: "react-client"
```

### 3.2 Installer les Dépendances

```bash
cd react-app

npm install

# Vérifier que keycloak-js est installé
npm list keycloak-js
# Devrait afficher: keycloak-js@26.2.1 (ou version similaire)
```

### 3.3 Démarrer l'Application React

```bash
cd react-app

npm start

# Attendre le message:
# "Compiled successfully!"
# "On Your Network: http://localhost:3000"
```

### 3.4 Vérifier les Requêtes CORS

Dans la console du navigateur (F12):

```javascript
// Vérifier que les requêtes vers la Gateway passent
fetch('http://localhost:8085/products', {
  headers: {
    'Authorization': 'Bearer <TOKEN>'
  }
}).then(r => r.text()).then(console.log)
```

**Checkpoint 3**: Frontend démarre et peut faire des requêtes

---

## Phase 4: Vérification de Sécurité

### 4.1 Endpoints Protégés

```bash
# Test 1: Endpoint sans auth devrait échouer
curl -i http://localhost:8085/products
# Devrait retourner: 401 Unauthorized

# Test 2: Endpoint avec token valide
TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client" \
  -d "grant_type=password" \
  -d "username=john.user" \
  -d "password=password123" | jq -r '.access_token')

curl -i -H "Authorization: Bearer $TOKEN" http://localhost:8085/products
# Devrait retourner: 200 OK

# Test 3: Token expiré
curl -i -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U" http://localhost:8085/products
# Devrait retourner: 401 Unauthorized
```

### 4.2 Vérifier Issuer URI

```bash
# Pour chaque service, vérifier qu'il valide les tokens du bon issuer

# Dans Product Service logs, chercher:
# "Configuring Spring Cloud Gateway"

curl -s http://localhost:8080/realms/microservices-realm/.well-known/openid-configuration | jq -r '.issuer'
# Devrait être: http://localhost:8080/realms/microservices-realm
```

### 4.3 CORS Configuration

```bash
# Vérifier les headers CORS depuis la Gateway
curl -i -X OPTIONS http://localhost:8085/products \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: GET"

# Devrait contenir:
# Access-Control-Allow-Origin: http://localhost:3000
# Access-Control-Allow-Methods: GET, POST, PUT, DELETE, ...
```

### 4.4 Vérifier Rôles dans Token

```bash
TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client" \
  -d "grant_type=password" \
  -d "username=alice.admin" \
  -d "password=admin123" | jq -r '.access_token')

echo $TOKEN | cut -d. -f2 | base64 -d 2>/dev/null | jq '.realm_access.roles'
# Devrait contenir: "admin"
```

**Checkpoint 4**: Sécurité validée (auth, CORS, tokens, rôles)

---

## Phase 5: Tests d'Intégration Complets

### Script Test Complet

```bash
#!/bin/bash

echo "=== Test 1: Keycloak Accessible ==="
curl -s http://localhost:8080/realms/microservices-realm/.well-known/openid-configuration > /dev/null && echo "OK" || echo "FAIL"

echo "=== Test 2: Obtenir Token ==="
TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client" \
  -d "grant_type=password" \
  -d "username=john.user" \
  -d "password=password123" | jq -r '.access_token')
[ -z "$TOKEN" ] && echo "FAIL" || echo "OK"

echo "=== Test 3: Product Service via Gateway ==="
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8085/products | grep -q "Produits" && echo "OK" || echo "FAIL"

echo "=== Test 4: Order Service via Gateway ==="
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8085/orders | grep -q "Commandes" && echo "OK" || echo "FAIL"

echo "=== Test 5: Product Service Direct ==="
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8081/products | grep -q "Produits" && echo "OK" || echo "FAIL"

echo "=== Test 6: Order Service Direct ==="
curl -s -H "Authorization: Bearer $TOKEN" http://localhost:8082/orders | grep -q "Commandes" && echo "OK" || echo "FAIL"

echo "=== Test 7: Admin Endpoint (avec admin) ==="
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client" \
  -d "grant_type=password" \
  -d "username=alice.admin" \
  -d "password=admin123" | jq -r '.access_token')
curl -s -H "Authorization: Bearer $ADMIN_TOKEN" http://localhost:8085/products/admin 2>/dev/null | grep -q "Gestion" && echo "OK" || echo "FAIL"

echo "=== Tous les tests terminés ==="
```

Sauvegarder en `test-integration.sh` et exécuter:

```bash
chmod +x test-integration.sh
./test-integration.sh
```

**Checkpoint 5**: Tous les tests d'intégration passent

---

## Checklist de Déploiement Final

```
Keycloak:
  [ ] Realm microservices-realm créé
  [ ] 3 rôles créés (user, admin, manager)
  [ ] 3 utilisateurs créés avec passwords
  [ ] Clients créés (react-client, gateway-client, product-service, order-service)
  [ ] Token valide obtenu avec cURL
  [ ] Issuer URI correct: http://localhost:8080/realms/microservices-realm

Backend (Product Service):
  [ ] Service démarre sans erreur
  [ ] Configuration issuer-uri correcte
  [ ] Endpoint /products retourne 401 sans token
  [ ] Endpoint /products retourne 200 avec token
  [ ] Endpoint /products/admin retourne données avec admin token

Backend (Order Service):
  [ ] Service démarre sans erreur
  [ ] Configuration issuer-uri correcte
  [ ] Endpoint /orders retourne 401 sans token
  [ ] Endpoint /orders retourne 200 avec token
  [ ] POST /orders fonctionne avec token valide

Gateway:
  [ ] Service démarre sans erreur
  [ ] Routes vers Product et Order Service configurées
  [ ] CORS autorise http://localhost:3000
  [ ] Requête via gateway retourne 200 avec token
  [ ] OPTIONS CORS retourne headers corrects

Frontend (React):
  [ ] npm install réussit
  [ ] keycloak.js correctement configuré
  [ ] npm start lance l'app
  [ ] App accessible sur http://localhost:3000

Tests:
  [ ] Toutes les requêtes cURL réussissent
  [ ] Token contient les rôles corrects
  [ ] Endpoints protégés rejettent les requêtes sans token
  [ ] CORS fonctionne depuis le frontend
```

---

## Logs à Vérifier

### Logs Keycloak

```bash
docker logs keycloak_container | tail -50
# Chercher: "realm successfully started", pas d'erreur
```

### Logs Services

```bash
# Terminal du service
mvn spring-boot:run

# Chercher dans les logs:
# "Started ProductServiceApplication"
# "JwtDecoder configured with Spring Security"
# Pas de "java.security.cert.CertificateException"
```

### Logs Gateway

```bash
# Chercher:
# "Configuring Spring Cloud Gateway"
# "Routes: product-service, order-service"
# "CORS configured"
```

---

## Dépannage Rapide

| Problème | Cause Probable | Solution |
|----------|---|---|
| 401 Unauthorized | Token manquant ou expiré | Obtenir nouveau token avec cURL |
| 403 Forbidden | Rôle insuffisant | Utiliser alice.admin au lieu de john.user |
| CORS error | Origine non autorisée | Vérifier Web Origins dans Keycloak |
| Connection refused | Service non lancé | Démarrer le service avec mvn spring-boot:run |
| Invalid issuer | URI mal configurée | Vérifier application.yml pour issuer-uri |
| Client not found | Client inexistant | Vérifier que react-client existe dans Keycloak |

