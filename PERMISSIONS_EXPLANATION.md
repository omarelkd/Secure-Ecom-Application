# 🔐 Gestion des Permissions - Explication Complète

## 📋 Table des Matières

1. [Architecture Globale](#architecture-globale)
2. [Flux des Tokens](#flux-des-tokens)
3. [Utilisateurs et Permissions](#utilisateurs-et-permissions)
4. [Résolution du Problème Actuel](#résolution-du-problème-actuel)

---

## 1. Architecture Globale

### Composants du Système

```
┌─────────────────────────────────────────────────────────────┐
│                       REACT FRONTEND                         │
│                    (http://localhost:3000)                   │
│  - Authentification Keycloak                                │
│  - Stockage du JWT Token                                     │
│  - Routes protégées par rôles                               │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ HTTP Request
                           │ Authorization: Bearer <JWT>
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                    API GATEWAY                                │
│              (Spring Cloud Gateway)                           │
│           (http://localhost:8085)                            │
│                                                               │
│  - Valide le JWT                                             │
│  - Route les requêtes aux microservices                      │
│  - Applique les règles de CORS                              │
└─────────┬─────────────────────────────────────┬─────────────┘
          │                                       │
          │ /products/**                          │ /orders/**
          ▼                                       ▼
┌─────────────────────────┐           ┌──────────────────────┐
│  PRODUCT SERVICE        │           │  ORDER SERVICE       │
│  (Port 8081)            │           │  (Port 8082)         │
│                         │           │                      │
│  - Gestion produits     │           │  - Gestion commandes │
│  - RBAC par endpoint    │           │  - RBAC par endpoint │
│  - Base H2 (mémoire)    │           │  - Base H2 (mémoire) │
└─────────────────────────┘           └──────────────────────┘
          │                                       │
          │ Valide le JWT                         │ Valide le JWT
          │                                       │
          └───────────────┬───────────────────────┘
                          │
                          ▼
            ┌──────────────────────────────┐
            │  KEYCLOAK - IDP & RBAC       │
            │    (http://localhost:8080)   │
            │                              │
            │ - Authentification des users │
            │ - Emission des JWT Tokens    │
            │ - Gestion des rôles/scopes   │
            │ - Realm: microservices-realm │
            └──────────────────────────────┘
```

---

## 2. Flux des Tokens

### 2.1 - Authentification Frontend (Keycloak.js)

```
ÉTAPE 1: Initialisation
┌─────────────────────────────────────────────────────────────┐
│  React App charge keycloak.js                               │
│  - URL: http://localhost:8080                               │
│  - Realm: microservices-realm                               │
│  - Client: react-client (Public)                            │
└─────────────────────────────────────────────────────────────┘

ÉTAPE 2: Login (Utilisateur clique "Se Connecter")
┌─────────────────────────────────────────────────────────────┐
│  keycloak.init() ou keycloak.login()                        │
│  └─> Redirection vers Keycloak Form                         │
│      - Utilisateur rentre username + password               │
│      - Keycloak valide les credentials                      │
└─────────────────────────────────────────────────────────────┘

ÉTAPE 3: Obtention du Token
┌─────────────────────────────────────────────────────────────┐
│  Keycloak génère JWT Token contenant:                       │
│                                                              │
│  {                                                           │
│    "sub": "user-id",                                        │
│    "preferred_username": "admin",                           │
│    "realm_access": {                                        │
│      "roles": ["ROLE_ADMIN"]                               │
│    },                                                        │
│    "scope": "openid profile email",                         │
│    "exp": 1234567890,    // Expiration                      │
│    "iat": 1234567200     // Issued At                       │
│  }                                                           │
│                                                              │
│  Token stocké dans: window.keycloak.token                   │
└─────────────────────────────────────────────────────────────┘

ÉTAPE 4: Retour à React
┌─────────────────────────────────────────────────────────────┐
│  Redirection vers http://localhost:3000/callback            │
│  Token disponible dans window.keycloak.token                │
│  Les rôles accessibles via keycloak.hasRealmRole('ADMIN')   │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 - Transmission du Token aux Services

```javascript
// Dans: react-app/src/services/orderService.js
const getAuthHeader = () => {
  const token = window.keycloak?.token;
  return token ? { Authorization: `Bearer ${token}` } : {};
};

export const orderService = {
  getAllOrders: async () => {
    const response = await axios.get(`${API_URL}/admin`, {
      headers: getAuthHeader()  // ← Ajoute Authorization: Bearer <JWT>
    });
    return response.data;
  }
};
```

**Résultat de la Requête:**
```
GET http://localhost:8085/orders/admin
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 2.3 - Validation au Gateway

```
┌──────────────────────────────────────┐
│  API Gateway (GatewaySecurityConfig) │
└──────────────────────────────────────┘

Étape 1: Récoit la requête
   GET /orders/admin
   Authorization: Bearer <JWT>

Étape 2: Valide le JWT
   - Vérifie la signature
   - Vérifie l'expiration
   - Utilise la clé publique de Keycloak
   
   Endpoint Keycloak:
   http://localhost:8080/realms/microservices-realm

Étape 3: Extraction des informations
   - Extrait les claims du JWT
   - Récupère username, rôles, scopes
   
Étape 4: Transmet au microservice
   La requête passe au Order Service avec le JWT intact
```

**Code du Gateway:**
```java
// GatewaySecurityConfig.java
@Bean
public SecurityWebFilterChain securityWebFilterChain(ServerHttpSecurity http) {
    http
        .authorizeExchange(exchange -> exchange
            .anyExchange().authenticated()  // ← Toute requête doit être authentifiée
        )
        .oauth2ResourceServer(oauth2 ->
            oauth2.jwt(Customizer.withDefaults())  // ← Valide le JWT
        );
    return http.build();
}

// application.yml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: http://localhost:8080/realms/microservices-realm
                      ↑ URL pour obtenir les clés publiques
```

### 2.4 - Validation au Microservice

```
┌──────────────────────────────────────────┐
│  Order Service ou Product Service        │
│        (SecurityConfig.java)             │
└──────────────────────────────────────────┘

Étape 1: Reçoit la requête avec JWT

Étape 2: Crée un JwtAuthenticationConverter
   - Extrait les claims du JWT
   - Recherche "realm_access.roles"
   - Convertit les rôles en GrantedAuthority
   
   IMPORTANT: Doit ajouter le préfixe "ROLE_"
   
   Exemple:
   - Rôle JWT: "ADMIN"
   - Authority Spring: "ROLE_ADMIN"  ← Préfixe nécessaire

Étape 3: Vérifie les permissions
   @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
                                    ↑
   Spring Security cherche "ROLE_ADMIN" ou "ROLE_MANAGER"

Étape 4: Exécute la méthode ou retourne 403
```

---

## 3. Utilisateurs et Permissions

### 3.1 - Utilisateurs Configurés

Tous les utilisateurs sont définis dans `keycloak/realm-export.json`:

#### 👤 USER (Utilisateur Standard)
```json
{
  "username": "user",
  "email": "user@test.com",
  "password": "password123",
  "realmRoles": ["ROLE_USER"]
}
```

**Permissions:**
- ✅ Consulter les produits (`GET /products`)
- ✅ Consulter ses propres commandes (`GET /orders`)
- ✅ Créer une commande (`POST /orders`)
- ❌ Modifier les produits
- ❌ Voir toutes les commandes
- ❌ Supprimer des données

---

#### 👨‍💼 MANAGER (Gestionnaire)
```json
{
  "username": "manager",
  "email": "manager@test.com",
  "password": "manager123",
  "realmRoles": ["ROLE_MANAGER"]
}
```

**Permissions:**
- ✅ Consulter les produits (`GET /products`)
- ✅ Consulter ses propres commandes (`GET /orders`)
- ✅ Créer une commande (`POST /orders`)
- ✅ Voir toutes les commandes (`GET /orders/admin`)
- ✅ Modifier le statut des commandes (`PUT /orders/{id}/status`)
- ❌ Modifier les produits
- ❌ Supprimer les produits
- ❌ Supprimer les commandes

---

#### 👨‍💻 ADMIN (Administrateur)
```json
{
  "username": "admin",
  "email": "admin@test.com",
  "password": "admin123",
  "realmRoles": ["ROLE_ADMIN"]
}
```

**Permissions:**
- ✅ TOUTES les permissions
- ✅ Gérer les produits (`POST`, `PUT`, `DELETE` /products)
- ✅ Gérer les commandes (`POST`, `PUT`, `DELETE` /orders)
- ✅ Voir toutes les commandes
- ✅ Modifier les statuts

---

### 3.2 - Tableau Récapitulatif

| Endpoint | Méthode | USER | MANAGER | ADMIN |
|----------|---------|------|---------|-------|
| /products | GET | ✅ | ✅ | ✅ |
| /products/{id} | GET | ✅ | ✅ | ✅ |
| /products | POST | ❌ | ❌ | ✅ |
| /products/{id} | PUT | ❌ | ❌ | ✅ |
| /products/{id} | DELETE | ❌ | ❌ | ✅ |
| /orders | GET | ✅ | ✅ | ✅ |
| /orders/{id} | GET | ✅* | ✅* | ✅ |
| /orders | POST | ✅ | ✅ | ✅ |
| /orders/admin | GET | ❌ | ✅ | ✅ |
| /orders/{id}/status | PUT | ❌ | ✅ | ✅ |
| /orders/{id} | DELETE | ❌ | ❌ | ✅ |

*Seulement si c'est sa propre commande

---

## 4. Résolution du Problème Actuel

### 4.1 - Problème Identifié

**Symptôme:** Même avec l'utilisateur `admin`, impossible d'accéder à `/orders` ou `/products`

**Cause Racine:** Mismatch entre les rôles du JWT et les authorities de Spring Security

### 4.2 - Diagnostic Détaillé

#### ❌ Problème dans SecurityConfig

Dans **order-service/config/SecurityConfig.java** et **product-service/config/SecurityConfig.java**:

```java
// PROBLÈME ACTUEL (INCORRECT)
realmRoles = roles.stream()
    .map(SimpleGrantedAuthority::new)  // ← Crée "ADMIN"
    .collect(Collectors.toList());

// Mais @PreAuthorize cherche:
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
                          ↑
// Spring Security ajoute "ROLE_" automatiquement
// Donc il cherche "ROLE_ADMIN" mais trouve "ADMIN" → 403!
```

### 4.3 - Solution : Ajouter le Préfixe "ROLE_"

#### Fix pour Order Service

**Fichier:** `order-service/src/main/java/ma/enset/orderservice/config/SecurityConfig.java`

Remplacer:
```java
realmRoles = roles.stream()
    .map(SimpleGrantedAuthority::new)
    .collect(Collectors.toList());
```

Par:
```java
realmRoles = roles.stream()
    .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
    .collect(Collectors.toList());
```

#### Fix pour Product Service

**Fichier:** `product-service/src/main/java/ma/enset/productservice/config/SecurityConfig.java`

Même changement:
```java
realmRoles = roles.stream()
    .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
    .collect(Collectors.toList());
```

### 4.4 - Vérification du Mapping

Après le fix, le mapping sera:

| Rôle JWT | Authority Spring | @PreAuthorize |
|----------|------------------|---------------|
| ADMIN | ROLE_ADMIN | hasRole('ADMIN') |
| MANAGER | ROLE_MANAGER | hasRole('MANAGER') |
| USER | ROLE_USER | hasRole('USER') |

Spring Security convertira `hasRole('ADMIN')` en cherchant `ROLE_ADMIN` ✅

### 4.5 - Étapes d'Application

1. **Arrêter les services** (s'ils tournent)
2. **Appliquer le fix** aux deux fichiers SecurityConfig
3. **Recompiler** les services
4. **Redémarrer** les services
5. **Tester** les accès

```bash
# Arrêter
docker-compose down

# Recompiler (dans chaque répertoire)
./mvnw clean package

# Redémarrer
docker-compose up -d
```

### 4.6 - Test de Vérification

Après le fix, tester avec chaque utilisateur:

**Connexion ADMIN:**
```bash
# Doit retourner 200 OK
curl -H "Authorization: Bearer <token>" http://localhost:8085/orders

# Doit retourner 200 OK
curl -H "Authorization: Bearer <token>" http://localhost:8085/products
```

**Connexion USER:**
```bash
# Doit retourner 200 OK (ses commandes)
curl -H "Authorization: Bearer <token>" http://localhost:8085/orders

# Doit retourner 403 Forbidden
curl -H "Authorization: Bearer <token>" http://localhost:8085/products -X POST
```

---

## 5. Résumé - Points Clés

### Authentification
1. Frontend: Keycloak gère le login et émet un JWT
2. JWT stocké dans `window.keycloak.token`
3. Transmis via header: `Authorization: Bearer <JWT>`

### Autorisation (RBAC)
1. Gateway valide le JWT avec la clé publique Keycloak
2. Microservices extraient les rôles du JWT
3. **IMPORTANT:** Ajouter le préfixe "ROLE_" pour Spring Security
4. @PreAuthorize vérifie les authorities

### Problème & Solution
- **Problème:** Pas de préfixe "ROLE_" dans SecurityConfig
- **Solution:** Ajouter `"ROLE_" +` lors de la création des authorities
- **Résultat:** Spring Security trouvera les bonnes authorities

### Points de Vérification
- ✅ Keycloak tourne sur le port 8080
- ✅ Realm `microservices-realm` existe
- ✅ Les utilisateurs sont configurés dans `realm-export.json`
- ✅ Le JWT contient `realm_access.roles`
- ✅ SecurityConfig ajoute le préfixe "ROLE_"
- ✅ @PreAuthorize utilise la syntaxe correcte
