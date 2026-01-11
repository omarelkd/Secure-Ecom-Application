# Etat Actuel du Projet OAuth2 OIDC - Microservices avec Keycloak

## Architecture Générale

Le projet est une architecture microservices basée sur OAuth2/OIDC avec Keycloak comme serveur d'authentification centralisé.

### Composants

1. **Keycloak** (Port 8080)
   - Serveur d'authentification et d'autorisation
   - Realm: `microservices-realm`
   - OAuth2/OIDC

2. **API Gateway** (Port 8085)
   - Spring Cloud Gateway
   - Routage des requêtes vers les services
   - Validation des tokens JWT

3. **Product Service** (Port 8081)
   - Service de gestion des produits
   - Endpoints: `/products`, `/products/admin`
   - Authentification requise

4. **Order Service** (Port 8082)
   - Service de gestion des commandes
   - Endpoints: `/orders`, `/orders/admin`
   - Authentification requise

5. **React App** (Port 3000)
   - Application frontend
   - Intégration Keycloak JavaScript (keycloak-js 26.2.1)
   - Client: `react-client`

## Architecture du Flux d'Authentification

```
User -> React App -> Keycloak (Login) -> JWT Token -> API Gateway -> Services
```

## État des Implémentations

### Backend (Spring Boot Services)

- Configuration OAuth2/OIDC en place
- Spring Security configuré
- Routes Gateway définies
- Contrôleurs avec endpoints basiques implémentés
- Récupération des informations utilisateur via `Authentication` object

### Frontend (React)

- Client Keycloak JavaScript initialisé
- Configuration de base du realm et client

## Comment Lancer le Projet

### Prérequis

- Java 21
- Node.js 18+
- Docker/Keycloak (ou Keycloak standalone)
- Maven

### Étapes de Lancement

#### 1. Démarrer Keycloak

```bash
# Option avec Docker
docker run -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak:26.0.0 \
  start-dev

# Puis accéder à http://localhost:8080
# Identifiants: admin / admin
```

#### 2. Configuration Keycloak (Une seule fois)

- Créer realm: `microservices-realm`
- Créer clients:
  - `gateway-client` (confidential)
  - `react-client` (public)
  - `product-service` (service account)
  - `order-service` (service account)
- Créer des utilisateurs test
- Configurer les rôles et permissions

#### 3. Démarrer les Services Backend

```bash
# Dans chaque dossier service
cd product-service
mvn spring-boot:run

cd order-service
mvn spring-boot:run

cd gateway
mvn spring-boot:run
```

#### 4. Démarrer l'Application React

```bash
cd react-app
npm install
npm start
```

## Tests des Endpoints

### Avec cURL (après obtention du token)

```bash
# Obtenir un token depuis Keycloak
TOKEN=$(curl -X POST http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client&grant_type=password&username=user&password=password" \
  | jq -r '.access_token')

# Appeler les services via la gateway
curl -H "Authorization: Bearer $TOKEN" http://localhost:8085/products
curl -H "Authorization: Bearer $TOKEN" http://localhost:8085/orders
```

### Avec l'application React

- S'authentifier via le formulaire Keycloak
- Les tokens sont gérés automatiquement par keycloak-js
- Les requêtes API incluent automatiquement le Bearer token

## Port Mapping

| Service | Port | Type |
|---------|------|------|
| Keycloak | 8080 | Authentification |
| Product Service | 8081 | Backend |
| Order Service | 8082 | Backend |
| API Gateway | 8085 | Backend (Routage) |
| React App | 3000 | Frontend |

## Configuration Keycloak (Rappel)

- URL: http://localhost:8080
- Issuer URI pour les services: http://localhost:8080/realms/microservices-realm
- Protocole: openid-connect
- Grant types: authorization_code, password (pour tests)
