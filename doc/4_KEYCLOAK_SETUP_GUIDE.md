# Guide Complet de Configuration Keycloak

**Conforme avec les configurations actuelles du projet:**
- Realm: `microservices-realm`
- Issuer URI: `http://localhost:8080/realms/microservices-realm`
- Frontend Client: `react-client`
- Backend Services: Product, Order (ports 8081, 8082)
- API Gateway: port 8085

---

## Prérequis

- Docker installé (pour Keycloak)
- Accès à http://localhost:8080 après lancement
- Identifiants admin par défaut: `admin` / `admin`

---

## Étape 0: Démarrer Keycloak

### Option 1: Docker (Recommandé pour développement)

```bash
docker run -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak:26.0.0 \
  start-dev
```

### Option 2: Docker Compose (Plus simple pour tout)

Créer le fichier `docker-compose.yml` à la racine du projet:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: keycloak_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  keycloak:
    image: quay.io/keycloak/keycloak:26.0.0
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      DB_VENDOR: postgres
      DB_ADDR: postgres
      DB_DATABASE: keycloak
      DB_USER: keycloak
      DB_PASSWORD: keycloak_password
    ports:
      - "8080:8080"
    depends_on:
      - postgres
    command: start-dev

volumes:
  postgres_data:
```

Puis lancer:
```bash
docker-compose up -d
```

### Vérifier que Keycloak démarre

```bash
# Attendre 10-15 secondes, puis vérifier l'accès
curl http://localhost:8080/realms/master/.well-known/openid-configuration

# Vous devriez voir un JSON valide
```

Accéder à la console admin: http://localhost:8080/admin/master/console/

---

## Étape 1: Créer le Realm

### Via Console Admin

1. Accéder à http://localhost:8080/admin
2. Se connecter: `admin` / `admin`
3. En haut à gauche, voir "Master" → Cliquer sur dropdown
4. Cliquer sur "Create Realm"

### Détails du Realm

Remplir les champs:

```
Name: microservices-realm
Enabled: ON
```

Puis cliquer "Create"

### Vérifier

```bash
curl http://localhost:8080/realms/microservices-realm/.well-known/openid-configuration
```

Devrait retourner un JSON avec `issuer: "http://localhost:8080/realms/microservices-realm"`

**Checkpoint 1**: Realm créé et accessible

---

## Étape 2: Configurer les Rôles

### Accéder aux Rôles

1. Dans le realm `microservices-realm`
2. Sidebar gauche → "Realm Roles"
3. Cliquer "Create role"

### Créer les 3 rôles

#### Rôle 1: USER

```
Role name: user
Description: Utilisateur standard
```

Cliquer "Create"

#### Rôle 2: ADMIN

```
Role name: admin
Description: Administrateur du système
```

Cliquer "Create"

#### Rôle 3: MANAGER (optionnel mais recommandé)

```
Role name: manager
Description: Gestionnaire de commandes
```

Cliquer "Create"

**Checkpoint 2**: 3 rôles créés dans Realm Roles

---

## Étape 3: Créer les Utilisateurs

### Créer Utilisateur 1: Utilisateur Standard

1. Sidebar → "Users"
2. Cliquer "Add User"

```
Username: john.user
Email: john@test.local
Email verified: ON
First name: John
Last name: User
Enabled: ON
```

Cliquer "Create"

#### Définir le mot de passe

1. Aller dans l'onglet "Credentials"
2. Cliquer "Set password"

```
Password: password123
Confirm password: password123
Temporary: OFF (pour production)
```

Cliquer "Set Password"

#### Assigner les rôles

1. Aller dans l'onglet "Role Mapping"
2. Cliquer "Assign role"
3. Chercher et sélectionner: `user`
4. Cliquer "Assign"

### Créer Utilisateur 2: Admin

```
Username: alice.admin
Email: alice@test.local
Email verified: ON
Password: admin123
Rôle: admin
```

### Créer Utilisateur 3: Manager

```
Username: bob.manager
Email: bob@test.local
Email verified: ON
Password: manager123
Rôle: manager
```

**Checkpoint 3**: 3 utilisateurs créés avec leurs rôles

---

## Étape 4: Créer les Clients

### Client 1: react-client (Frontend)

**Type**: Public (OpenID Connect)

1. Sidebar → "Clients"
2. Cliquer "Create client"

```
Client type: OpenID Connect
Client ID: react-client
```

Cliquer "Next"

### Configuration de react-client

**Onglet "General":**

```
Client authentication: OFF (car public)
Standard flow: ON
Direct access grants: ON
```

Cliquer "Save"

**Onglet "Access settings":**

```
Valid redirect URIs: 
  http://localhost:3000
  http://localhost:3000/*

Web origins:
  http://localhost:3000
```

Cliquer "Save"

**Onglet "Client scopes":**

Vérifier que les scopes par défaut sont présents:
- openid
- profile
- email

**Vérification dans le code React:**

Le fichier `react-app/src/keycloak.js` doit contenir:

```javascript
const keycloak = new Keycloak({
    url: "http://localhost:8080",
    realm: "microservices-realm",
    clientId: "react-client",  // DOIT CORRESPONDRE
});
```

### Client 2: gateway-client (API Gateway - Optionnel)

Pour plus de contrôle si la gateway fait des appels OAuth2:

```
Client ID: gateway-client
Client authentication: ON (Confidential)
Authentication flow:
  Standard flow: ON
  Service account roles: ON
```

Sauvegarder et copier la valeur "Client secret" si nécessaire.

### Client 3: product-service (Service Account)

Si le service Product fait des appels inter-services:

```
Client ID: product-service
Client authentication: ON
Service account roles: ON
```

Sauvegarder les credentials si nécessaire.

### Client 4: order-service (Service Account)

Similaire au client Product Service:

```
Client ID: order-service
Client authentication: ON
Service account roles: ON
```

**Checkpoint 4**: Clients créés

---

## Étape 5: Vérifier la Configuration Complète

### Test 1: Vérifier le Realm est valide

```bash
curl http://localhost:8080/realms/microservices-realm/.well-known/openid-configuration | jq .
```

Chercher dans la réponse:
- `"issuer": "http://localhost:8080/realms/microservices-realm"` ✓
- `"authorization_endpoint"` ✓
- `"token_endpoint"` ✓
- `"userinfo_endpoint"` ✓

### Test 2: Obtenir un Token avec cURL

```bash
# Token pour john.user
TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client" \
  -d "grant_type=password" \
  -d "username=john.user" \
  -d "password=password123" | jq -r '.access_token')

echo "Token obtenu: $TOKEN"

# Décoder le token pour vérifier les claims
echo $TOKEN | cut -d. -f2 | base64 -d | jq .
```

Vérifier dans le token:
- `"sub"`: ID de l'utilisateur
- `"preferred_username": "john.user"`
- `"name": "John User"`
- `"email": "john@test.local"`
- `"realm_access"`: {"roles": ["user", "default-roles-microservices-realm"]}

### Test 3: Appeler un endpoint protégé

```bash
# D'abord obtenir le token
TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client" \
  -d "grant_type=password" \
  -d "username=john.user" \
  -d "password=password123" | jq -r '.access_token')

# Appeler Product Service via la Gateway
curl -H "Authorization: Bearer $TOKEN" http://localhost:8085/products

# Devrait répondre:
# "Produits accessibles pour : john.user"
```

**Checkpoint 5**: Tokens générés et endpoints accessibles

---

## Étape 6: Configuration pour Production (Optionnel)

### Changer le password admin

1. Admin Console → Realm Settings → Users
2. Chercher "admin"
3. Onglet "Credentials" → "Set Password"
4. Nouveau password fort

### Exporter la Configuration

Pour sauvegarder et partager la config entre développeurs:

```bash
# Dans le container Keycloak
docker exec keycloak_container /opt/keycloak/bin/kc.sh export \
  --realm microservices-realm \
  --users REALM_FILE \
  --file /tmp/microservices-realm.json

# Copier le fichier
docker cp keycloak_container:/tmp/microservices-realm.json ./keycloak-backup.json
```

Partager ce fichier avec l'équipe pour l'importer:

```bash
# Importer
docker exec keycloak_container /opt/keycloak/bin/kc.sh import \
  --realm microservices-realm \
  --file /tmp/microservices-realm.json
```

---

## Résumé de la Configuration

### Realm
- **Name**: `microservices-realm`
- **Issuer**: `http://localhost:8080/realms/microservices-realm`

### Rôles
- `user` - Utilisateur standard
- `admin` - Administrateur
- `manager` - Gestionnaire

### Utilisateurs
| Username | Email | Password | Rôles |
|----------|-------|----------|-------|
| john.user | john@test.local | password123 | user |
| alice.admin | alice@test.local | admin123 | admin |
| bob.manager | bob@test.local | manager123 | manager |

### Clients
| Client ID | Type | Use Case |
|-----------|------|----------|
| react-client | Public | Frontend React (Port 3000) |
| gateway-client | Confidential | API Gateway (Port 8085) |
| product-service | Confidential | Product Service (Port 8081) |
| order-service | Confidential | Order Service (Port 8082) |

### URLs Critiques
- Admin Console: http://localhost:8080/admin/master/console/
- Realm Admin: http://localhost:8080/admin/realms/microservices-realm
- OpenID Config: http://localhost:8080/realms/microservices-realm/.well-known/openid-configuration
- Token Endpoint: http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token

---

## Dépannage

### Problème: "Client not found" lors de la requête token

**Solution**: Vérifier que le `client_id` dans la requête correspond exactement au Client ID créé

### Problème: CORS error en frontend

**Solution**: Vérifier les "Web origins" du client:
```
http://localhost:3000
```

### Problème: "invalid_grant" lors de login

**Solution**: 
- Vérifier que l'utilisateur existe
- Vérifier que le password est correct
- Vérifier que "Direct access grants" est activé pour le client

### Problème: Token rejeté par le service

**Solution**:
- Vérifier l'Issuer URI dans application.yml
- Doit être: `http://localhost:8080/realms/microservices-realm`
- Décoder le token avec: `echo $TOKEN | cut -d. -f2 | base64 -d | jq .`

---

## Points de Vérification Avant Déploiement

- [ ] Realm `microservices-realm` créé
- [ ] 3 rôles créés (user, admin, manager)
- [ ] 3 utilisateurs créés avec leurs rôles
- [ ] Client `react-client` créé (public)
- [ ] Client `gateway-client` créé (confidential)
- [ ] Clients `product-service` et `order-service` créés
- [ ] Token peut être obtenu avec cURL
- [ ] Endpoints backend répondent avec le token
- [ ] Frontend peut se connecter (si implémenté)
- [ ] Roles présentes dans le JWT token

