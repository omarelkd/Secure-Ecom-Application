# Schéma Visuel et Résumé d'Architecture

Guide visuel de l'architecture et des flux d'authentification.

---

## Architecture Globale du Projet

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET                                │
└────┬──────────────────────────────────────────────────────────┬─┘
     │                                                            │
     │                                                            │
┌────▼─────────────────────────┐         ┌────────────────────┐
│    REACT FRONTEND             │         │  KEYCLOAK SERVER   │
│    http://localhost:3000      │◄───────►│  http://localhost  │
│                               │         │  :8080             │
│  - Login/Logout              │         │                    │
│  - Dashboard                 │         │  Realm: microser   │
│  - Products List             │         │  vices-realm       │
│  - Orders List               │         │                    │
│  - Admin Panel               │         │  Rôles:           │
│                               │         │  - user           │
└────┬──────────────────────────┘         │  - admin          │
     │                                     │  - manager        │
     │ Authorization: Bearer <JWT>        │                    │
     │                                     │  Clients:         │
┌────▼──────────────────────────────────┐│  - react-client   │
│      API GATEWAY                       ││  - gateway-client │
│      http://localhost:8085             ││  - product-sv     │
│                                        ││  - order-sv       │
│  Routes:                               ││                    │
│  /products/* ──────────┐              │└────────────────────┘
│  /orders/*   ──────────┼──────────────┘  │
│             │          │                  │
│  Validates │tokens    │                  │
└────┬───────┼──────────┬─────────────────┘
     │       │          │
     │       │          │
┌────▼──┐ ┌─▼──────┐ ┌─▼──────────┐
│Product│ │ Order  │ │ Database   │
│Service│ │ Service│ │ PostgreSQL │
│:8081  │ │ :8082  │ │ :5432      │
└───────┘ └────────┘ └────────────┘
```

---

## Flux d'Authentification OAuth2/OIDC

### 1. Utilisateur se Connecte (Frontend React)

```
┌──────────────────────────────────────────────────────┐
│ Utilisateur accède http://localhost:3000             │
└──────────────────┬───────────────────────────────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ React App initialisé │
        │ Keycloak JS chargé   │
        └──────────┬────────────┘
                   │
                   ▼
        ┌─────────────────────────────┐
        │ Si pas authentifié:         │
        │ Redirection vers Keycloak   │
        │ http://localhost:8080/auth  │
        └──────────┬────────────────────┘
                   │
                   ▼
        ┌─────────────────────────────┐
        │ Formulaire Login Keycloak    │
        │ Username: john.user          │
        │ Password: password123        │
        └──────────┬────────────────────┘
                   │
                   ▼
        ┌─────────────────────────────┐
        │ Keycloak valide credentials │
        │ Génère JWT Token            │
        │ Redirige vers React avec    │
        │ token dans l'URL             │
        └──────────┬────────────────────┘
                   │
                   ▼
        ┌─────────────────────────────┐
        │ React App reçoit le token   │
        │ Stocke dans localStorage    │
        │ Utilisateur connecté!       │
        └─────────────────────────────┘
```

### 2. Utilisateur Appelle un Endpoint Protégé

```
┌────────────────────────────────────────┐
│ Utilisateur clique sur "Voir Produits" │
└────────────────┬───────────────────────┘
                 │
                 ▼
    ┌──────────────────────────┐
    │ React App récupère token │
    │ du localStorage           │
    └────────────┬─────────────┘
                 │
                 ▼
    ┌──────────────────────────────────┐
    │ Axios/Fetch ajoute le header:     │
    │ Authorization: Bearer <JWT>      │
    │                                   │
    │ Requête:                         │
    │ GET http://localhost:8085/products│
    └────────────┬─────────────────────┘
                 │
                 ▼
    ┌──────────────────────────────┐
    │ API Gateway reçoit requête   │
    │                              │
    │ 1. Extrait le token         │
    │ 2. Valide la signature      │
    │    (via Keycloak JWKS)      │
    │ 3. Vérif l'expiration       │
    └────────────┬────────────────┘
                 │
    ┌────────────▼────────────────┐
    │ Token invalide?              │
    └────┬───────────────────┬─────┘
         │ OUI              │ NON
         ▼                  ▼
    ┌────────────┐    ┌─────────────────┐
    │ Réponse    │    │ Ajoute les user │
    │ 401        │    │ infos au context│
    │ Unauthorized    │ (username,roles)│
    └────────────┘    └────────┬────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Route vers Product   │
                    │ Service (8081)       │
                    │                      │
                    │ GET /products        │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Product Service      │
                    │ Reçoit requête       │
                    │ + Authentication obj │
                    │                      │
                    │ Retourne:            │
                    │ "Produits pour:      │
                    │  john.user"          │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Réponse 200 OK       │
                    │ + Données produits   │
                    │                      │
                    │ Retour à React       │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ React affiche        │
                    │ les produits         │
                    └──────────────────────┘
```

---

## Structure des Tokens JWT

### Structure Générale

```
Header.Payload.Signature

Exemple:
eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjEifQ.
eyJzdWIiOiI1ZTM4YTQyODUzZDQ3YzExYjM2NjcyMDgiLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODAvcmVhbG1zL21pY3Jvc2Vydmljb...
eY8QF5ewgB3lN5QJT7rkC9v3MkD...
```

### Payload du Token (Décodé)

```json
{
  "exp": 1710086400,                    // Expiration
  "iat": 1710086100,                    // Issued at
  "auth_time": 1710086050,              // Auth time
  "jti": "1234567890",                  // JWT ID
  "iss": "http://localhost:8080/realms/microservices-realm",
  "aud": "react-client",                // Audience (Client)
  "sub": "5e38a42853d47c11b3667208",   // Subject (User ID)
  "typ": "Bearer",
  "azp": "react-client",                // Authorized party
  "session_state": "abcdef123456",
  "name": "John User",
  "preferred_username": "john.user",    // Username
  "given_name": "John",
  "family_name": "User",
  "email": "john@test.local",
  "realm_access": {
    "roles": [
      "default-roles-microservices-realm",
      "user"                             // Rôles de l'utilisateur
    ]
  },
  "resource_access": {
    "account": {
      "roles": ["manage-account", "view-profile"]
    }
  }
}
```

---

## Flux de Vérification du Token

### Par l'API Gateway et les Services

```
┌─────────────────────────────────────┐
│ Requête avec Authorization header   │
│ Authorization: Bearer <JWT_TOKEN>   │
└────────────┬──────────────────────┘
             │
             ▼
┌────────────────────────────────────┐
│ Spring Security OAuth2Resource     │
│ Server extrait le token            │
└────────────┬──────────────────────┘
             │
             ▼
┌────────────────────────────────────┐
│ JwtDecoder récupère la clé publique│
│ depuis Keycloak JWKS endpoint:     │
│ http://localhost:8080/realms/      │
│  microservices-realm/protocol/     │
│  openid-connect/certs              │
└────────────┬──────────────────────┘
             │
             ▼
┌────────────────────────────────────┐
│ Valide la signature du JWT         │
│ (RSA256 avec clé publique)         │
└────────────┬──────────────────────┘
             │
      ┌──────▼──────┐
      │ Valide?     │
      └──┬────────┬─┘
    OUI  │        │ NON
         ▼        ▼
    ┌─────────┐ ┌──────────────┐
    │ Vérif   │ │ Réponse 401  │
    │ claims: │ │ Unauthorized │
    │ - iss   │ │              │
    │ - exp   │ └──────────────┘
    │ - nbf   │
    └────┬────┘
         │ OK
         ▼
    ┌─────────────────────────┐
    │ Crée l'objet            │
    │ Authentication avec:    │
    │ - username              │
    │ - roles (from JWT)      │
    │ - credentials           │
    └────┬───────────────────┘
         │
         ▼
    ┌──────────────────────────┐
    │ Continue le traitement   │
    │ Endpoint peut accéder à: │
    │ - SecurityContextHolder  │
    │ - @AuthenticationPrincipal
    │                          │
    │ Peut utiliser:           │
    │ @PreAuthorize()          │
    │ hasRole('ADMIN')         │
    └──────────────────────────┘
```

---

## Mapping des Ports et Services

```
┌─────────────────────────────────────────────────────────────┐
│                      LOCALHOST                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Port 8080 ──► Keycloak                                     │
│                - Admin Console: :8080/admin                 │
│                - Realm Config: :8080/realms/...             │
│                - Token Endpoint: :8080/.../token            │
│                                                              │
│  Port 8081 ──► Product Service                              │
│                - GET  /products       (All authenticated)    │
│                - POST /products       (Admin only)          │
│                - GET  /products/admin (Admin only)          │
│                                                              │
│  Port 8082 ──► Order Service                                │
│                - GET  /orders         (All authenticated)    │
│                - POST /orders         (All authenticated)    │
│                - GET  /orders/admin   (Admin only)          │
│                                                              │
│  Port 8085 ──► API Gateway                                  │
│                - Routes /products/** ──► 8081               │
│                - Routes /orders/**   ──► 8082               │
│                - Validates JWT tokens                       │
│                - Handles CORS                               │
│                                                              │
│  Port 3000 ──► React Frontend                               │
│                - Web UI                                     │
│                - Login via Keycloak                         │
│                - API calls via Gateway (8085)               │
│                                                              │
│  Port 5432 ──► PostgreSQL Database                          │
│                - Keycloak data storage                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Checklist Visuelle de Configuration

### Keycloak (8080)

```
[✓] Container running
[✓] Realm: microservices-realm
  ├─ [✓] Role: user
  ├─ [✓] Role: admin
  └─ [✓] Role: manager
[✓] Users:
  ├─ john.user (password123, roles: user)
  ├─ alice.admin (admin123, roles: admin)
  └─ bob.manager (manager123, roles: manager)
[✓] Clients:
  ├─ react-client (public)
  ├─ gateway-client (confidential)
  ├─ product-service (confidential)
  └─ order-service (confidential)
[✓] Token obtenu et valide
```

### Services Backend

```
[✓] Product Service (8081)
  ├─ Maven compiled
  ├─ Spring Boot started
  ├─ GET /products returns 200
  └─ Requires valid JWT

[✓] Order Service (8082)
  ├─ Maven compiled
  ├─ Spring Boot started
  ├─ GET /orders returns 200
  └─ Requires valid JWT

[✓] API Gateway (8085)
  ├─ Maven compiled
  ├─ Spring Boot started
  ├─ Routes to 8081 and 8082
  ├─ CORS for localhost:3000
  └─ Validates JWT tokens
```

### Frontend (3000)

```
[✓] React installed (npm install)
[✓] keycloak.js configured
  ├─ URL: http://localhost:8080
  ├─ Realm: microservices-realm
  └─ ClientId: react-client
[✓] npm start running
[✓] Can fetch from Gateway
```

---

## Commandes de Vérification Rapide

```bash
# 1. Keycloak accessible?
curl http://localhost:8080/realms/microservices-realm/.well-known/openid-configuration

# 2. Obtenir token
TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client&grant_type=password&username=john.user&password=password123" \
  | jq -r '.access_token')

# 3. Décoder token
echo $TOKEN | cut -d. -f2 | base64 -d | jq .

# 4. Product Service répond?
curl -H "Authorization: Bearer $TOKEN" http://localhost:8081/products

# 5. Order Service répond?
curl -H "Authorization: Bearer $TOKEN" http://localhost:8082/orders

# 6. Via Gateway?
curl -H "Authorization: Bearer $TOKEN" http://localhost:8085/products

# 7. Admin endpoint?
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client&grant_type=password&username=alice.admin&password=admin123" \
  | jq -r '.access_token')

curl -H "Authorization: Bearer $ADMIN_TOKEN" http://localhost:8085/products/admin
```

---

## Points Clés à Retenir

```
┌────────────────────────────────────────────────────────┐
│ 1. Issuer URI doit être EXACT                          │
│    http://localhost:8080/realms/microservices-realm    │
├────────────────────────────────────────────────────────┤
│ 2. Client ID doit correspondre                         │
│    React ──► react-client                             │
│    Gateway ──► gateway-client (optionnel)             │
├────────────────────────────────────────────────────────┤
│ 3. Token DOIT être dans Authorization header          │
│    Authorization: Bearer <JWT_TOKEN>                  │
├────────────────────────────────────────────────────────┤
│ 4. Rôles dans le token realm_access.roles             │
│    Services peuvent utiliser @PreAuthorize()          │
├────────────────────────────────────────────────────────┤
│ 5. CORS doit autoriser localhost:3000                 │
│    Sinon: CORS error en frontend                      │
└────────────────────────────────────────────────────────┘
```

