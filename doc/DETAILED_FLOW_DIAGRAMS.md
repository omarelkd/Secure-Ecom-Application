# 🔐 Diagrammes et Flux Détaillés - Architecture OAuth2/OIDC

## 📊 Vue d'Ensemble Générale

```
┌───────────────────────────────────────────────────────────────────────┐
│                           UTILISATEUR FINAL                            │
└─────────────────────────────────────────────────┬─────────────────────┘
                                                  │
                                                  │ 1. Visite
                                                  ▼
                    ┌─────────────────────────────────────────────┐
                    │     REACT APP (Frontend)                    │
                    │     http://localhost:3000                   │
                    │                                              │
                    │ - Affiche la page d'accueil               │
                    │ - Bouton "Se Connecter" visible            │
                    └─────────────────────┬───────────────────────┘
                                          │
                                          │ 2. Clique sur "Se Connecter"
                                          │ keycloak.login()
                                          ▼
            ┌─────────────────────────────────────────────────────┐
            │         KEYCLOAK LOGIN FORM                          │
            │        http://localhost:8080                         │
            │                                                       │
            │  ┌──────────────────────────────────────────┐       │
            │  │ Username: [____________]                 │       │
            │  │ Password: [____________]                 │       │
            │  │                    [Login]              │       │
            │  └──────────────────────────────────────────┘       │
            │                                                       │
            │ 3. Utilisateur entre ses credentials                │
            │    - admin / admin123                                │
            │    - user / password123                             │
            │    - manager / manager123                           │
            └────────────────┬─────────────────────────────────────┘
                             │
                             │ 4. Keycloak valide
                             │ 5. Génère JWT Token
                             ▼
            ┌─────────────────────────────────────────────────────┐
            │         JWT TOKEN CRÉÉ                               │
            │                                                       │
            │ {                                                    │
            │   "jti": "some-id",                                 │
            │   "exp": 1234567890,                                │
            │   "nbf": 1234567200,                                │
            │   "iat": 1234567300,                                │
            │   "iss": "http://localhost:8080/realms/...",       │
            │   "aud": ["react-client"],                          │
            │   "sub": "user-id",                                 │
            │   "typ": "Bearer",                                  │
            │   "azp": "react-client",                            │
            │   "preferred_username": "admin",                    │
            │   "realm_access": {                                 │
            │     "roles": ["ROLE_ADMIN"]                        │
            │   },                                                 │
            │   "scope": "openid profile email"                   │
            │ }                                                    │
            └────────────────┬─────────────────────────────────────┘
                             │
                             │ 6. Redirect vers React
                             │    http://localhost:3000/callback
                             ▼
                    ┌─────────────────────────────────────────────┐
                    │     REACT APP (CONNECTÉ)                     │
                    │                                              │
                    │ window.keycloak.token = "eyJhbGc..."       │
                    │ window.keycloak.authenticated = true         │
                    │ Navbar affiche "Admin"                       │
                    │                                              │
                    │ Bouton "Produits" cliquable                 │
                    │ Bouton "Mes Commandes" cliquable            │
                    │ Bouton "Admin Panel" visible                │
                    └─────────────────────┬───────────────────────┘
                                          │
                                          │ 7. Utilisateur clique sur "Produits"
                                          │ Appel API: GET /products
                                          ▼
            ┌──────────────────────────────────────────────────────┐
            │            REQUÊTE HTTP                               │
            │                                                        │
            │ GET /products                                        │
            │ Authorization: Bearer eyJhbGc...                     │
            │                                                        │
            │ Cible: http://localhost:8085/products              │
            │ (via le gateway)                                     │
            └────────────┬─────────────────────────────────────────┘
                         │
                         │ 8. Requête arrives au Gateway
                         ▼
        ┌─────────────────────────────────────────────────────────┐
        │         API GATEWAY (Spring Cloud Gateway)              │
        │        http://localhost:8085                            │
        │                                                          │
        │ GatewaySecurityConfig:                                  │
        │  1. Extrait le JWT du header Authorization             │
        │  2. Valide la signature avec clé pub de Keycloak       │
        │  3. Vérifie l'expiration                               │
        │  4. Crée une Authentication avec les rôles du JWT       │
        │  5. Ajoute le JWT à la requête                         │
        │  6. Route vers le service approprié                    │
        │                                                          │
        │ Endpoint Keycloak pour clé publique:                   │
        │ http://localhost:8080/realms/microservices-realm/...   │
        └────────────┬─────────────────────────────────────────────┘
                     │
                     │ Route en fonction du path
                     │ /products → order-service:8081
                     │ /orders → order-service:8082
                     ▼
    ┌─────────────────────────────────────────────────────────────┐
    │         PRODUCT SERVICE (Port 8081)                         │
    │              ProductController.java                         │
    │                                                              │
    │  @GetMapping                                                │
    │  public ResponseEntity<List<ProductResponse>>              │
    │  getAllProducts(Authentication auth) {                     │
    │                                                              │
    │    // 1. Valide le JWT avec JwtAuthenticationConverter     │
    │    // 2. Extrait les rôles: realm_access.roles            │
    │    // 3. Ajoute "ROLE_" → ["ROLE_ADMIN"]                  │
    │    // 4. Crée les GrantedAuthority                        │
    │                                                              │
    │    // 5. Aucune annotation @PreAuthorize                   │
    │    //    → Accès autorisé pour tous les authentifiés       │
    │                                                              │
    │    return ResponseEntity.ok(products);                    │
    │  }                                                           │
    └────────────────┬─────────────────────────────────────────────┘
                     │
                     │ 9. Produits récupérés de H2 DB
                     │ 10. Réponse JSON retournée
                     ▼
            ┌──────────────────────────────────────────────────┐
            │          RÉPONSE HTTP 200 OK                      │
            │                                                    │
            │ [                                                 │
            │   {                                               │
            │     "id": 1,                                      │
            │     "name": "Laptop",                             │
            │     "price": 1200.00,                             │
            │     "available": true                             │
            │   },                                              │
            │   ...                                             │
            │ ]                                                 │
            └──────────────────────────┬──────────────────────┘
                                       │
                                       │ 11. React affiche les produits
                                       ▼
                    ┌─────────────────────────────────────────────┐
                    │     REACT APP - Affiche Produits             │
                    │                                              │
                    │ Liste des produits chargée                 │
                    │ Bouton "Ajouter" visible (si ADMIN)        │
                    │ Bouton "Modifier" visible (si ADMIN)       │
                    │ Bouton "Supprimer" visible (si ADMIN)      │
                    └─────────────────────────────────────────────┘
```

---

## 🔐 Flux d'Authentification Détaillé

### Phase 1: Login & Token Obtention

```
┌──────────────────┐
│  Utilisateur     │
│  (Frontend)      │
└────────┬─────────┘
         │ 1. click "Se Connecter"
         │    keycloak.login()
         ▼
┌─────────────────────────────────────────────────────┐
│ Keycloak - OAuth2 Authorization Code Flow           │
│                                                      │
│ 1. React redirige vers:                             │
│    GET /auth?client_id=react-client                 │
│       &redirect_uri=http://localhost:3000/callback  │
│       &scope=openid profile email                   │
│       &response_type=code                           │
│                                                      │
│ 2. Affiche le formulaire de login                   │
│    Utilisateur entre ses credentials                │
│                                                      │
│ 3. Keycloak valide:                                 │
│    - Username existe                                │
│    - Password est correct                           │
│    - User est activé                                │
│                                                      │
│ 4. Keycloak génère un Authorization Code            │
│    Code: très_long_string_aleatoire                 │
│                                                      │
│ 5. Redirige vers:                                   │
│    http://localhost:3000/callback?code=...&state=..│
└──────────────┬──────────────────────────────────────┘
               │
               │ 6. React (adapter Keycloak) utilise le code
               │    pour obtenir le token
               ▼
┌─────────────────────────────────────────────────────┐
│ Keycloak - Token Endpoint                           │
│                                                      │
│ Adapter Keycloak JS fait une requête POST:         │
│                                                      │
│ POST /protocol/openid-connect/token                 │
│ Content-Type: application/x-www-form-urlencoded    │
│                                                      │
│ grant_type=authorization_code                       │
│ code=<authorization_code>                           │
│ client_id=react-client                              │
│ redirect_uri=http://localhost:3000/callback         │
│                                                      │
│ (react-client est public, pas besoin de secret)    │
│                                                      │
│ 7. Keycloak valide et génère:                       │
│    ✅ access_token (JWT) - 5 minutes                │
│    ✅ refresh_token                                 │
│    ✅ id_token (optionnel)                          │
└──────────────┬──────────────────────────────────────┘
               │
               │ 8. Adapter Keycloak JS stocke le token
               │    window.keycloak.token = "..."
               │    localStorage ou sessionStorage
               ▼
┌──────────────────────────────────────────────────────┐
│ React App                                            │
│                                                      │
│ keycloak.authenticated = true                       │
│ keycloak.token = "eyJhbGciOiJSUzI1NiIsInR5cCI..."   │
│ keycloak.tokenParsed = {                            │
│   exp, nbf, iat, iss, ...                           │
│ }                                                    │
│                                                      │
│ Navbar affiche:                                     │
│ "Connecté en tant que: Admin"                       │
└──────────────────────────────────────────────────────┘
```

### Phase 2: Transmission du Token

```
┌──────────────────────────────────────────────┐
│ React App - Appel API                        │
│                                              │
│ const getAuthHeader = () => {               │
│   const token = window.keycloak?.token;     │
│   return token ?                             │
│     { Authorization: `Bearer ${token}` }    │
│     : {};                                    │
│ };                                           │
│                                              │
│ axios.get('/products', {                    │
│   headers: getAuthHeader()  ← Ajoute header│
│ });                                          │
└────────────┬─────────────────────────────────┘
             │
             │ Requête HTTP
             │
             ▼
┌──────────────────────────────────────────────────────┐
│ HTTP Request                                         │
│                                                      │
│ GET http://localhost:8085/products                 │
│ Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI..│
│                                                      │
│ Headers:                                             │
│ - Host: localhost:8085                              │
│ - Authorization: Bearer <JWT>  ← Important!        │
│ - Content-Type: application/json                    │
│ - Origin: http://localhost:3000                     │
└───────────────┬────────────────────────────────────┘
                │
                │ Route vers Gateway
                ▼
```

### Phase 3: Validation au Gateway

```
┌───────────────────────────────────────────────────────────┐
│  API Gateway                                              │
│  (GatewaySecurityConfig)                                  │
│                                                            │
│  Reçoit: GET /products                                    │
│  Header: Authorization: Bearer eyJhbGc...                 │
└─────────────────────────┬─────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────────────────┐
        │ 1. Extract JWT from Authorization Header    │
        │    Token = "eyJhbGc..."                      │
        └────────────────┬────────────────────────────┘
                         │
                         ▼
        ┌─────────────────────────────────────────────┐
        │ 2. Valider la Signature du JWT              │
        │                                              │
        │ Les services reçoivent la clé publique de   │
        │ Keycloak depuis:                            │
        │                                              │
        │ http://localhost:8080/realms/               │
        │   microservices-realm/protocol/             │
        │   openid-connect/certs                      │
        │                                              │
        │ Cette clé change tous les jours             │
        │ Les services la mettent en cache            │
        │                                              │
        │ RSA256: Header.Payload.Signature            │
        │ Decode: HMAC-SHA256(Header.Payload) = Sig  │
        └────────────────┬────────────────────────────┘
                         │
                         ▼
        ┌──────────────────────────────────────────────┐
        │ 3. Vérifier l'Expiration                      │
        │                                               │
        │ if (jwt.exp > System.currentTimeMillis())    │
        │   → Token valide                             │
        │ else                                          │
        │   → 401 Unauthorized (demande new token)    │
        └────────────────┬─────────────────────────────┘
                         │
                         ▼
        ┌──────────────────────────────────────────────┐
        │ 4. Décoder et Extraire les Claims            │
        │                                               │
        │ Claims disponibles:                          │
        │ - sub: user ID                               │
        │ - preferred_username: "admin"                │
        │ - realm_access.roles: ["ROLE_ADMIN"]        │
        │ - email: "admin@test.com"                    │
        │ - other_claims...                            │
        └────────────────┬─────────────────────────────┘
                         │
                         ▼
        ┌──────────────────────────────────────────────┐
        │ 5. Créer une Authentication                   │
        │    avec les rôles du JWT                     │
        │                                               │
        │ authentication.name = "admin"                │
        │ authentication.authorities = [ROLE_ADMIN]   │
        │                                               │
        │ Puis: SecurityContext.setAuthentication()    │
        └────────────────┬─────────────────────────────┘
                         │
                         ▼
        ┌──────────────────────────────────────────────┐
        │ 6. Route la Requête vers le Service          │
        │                                               │
        │ /products → forward to product-service:8081 │
        │ /orders → forward to order-service:8082     │
        │                                               │
        │ JWT est transmis avec la requête             │
        └──────────────────────────────────────────────┘
```

### Phase 4: Validation au Microservice

```
┌────────────────────────────────────────────────────────┐
│  Product Service ou Order Service                       │
│  (SecurityConfig)                                       │
│                                                         │
│  Reçoit la requête avec JWT du Gateway                │
└──────────────┬───────────────────────────────────────┘
               │
               ▼
    ┌──────────────────────────────────────────────┐
    │ 1. JwtAuthenticationConverter                 │
    │                                               │
    │ @Bean                                         │
    │ public JwtAuthenticationConverter             │
    │ jwtAuthenticationConverter() {                │
    │                                               │
    │   converter.setPrincipalClaimName(            │
    │     "preferred_username"                      │
    │   );  // Principal = "admin"                  │
    │                                               │
    │   converter.setJwtGrantedAuthoritiesConverter(│
    │     jwt -> {                                  │
    │       // Récupère realm_access.roles        │
    │       Map<String, Object> realmAccess =     │
    │         jwt.getClaim("realm_access");        │
    │                                               │
    │       List<String> roles = realmAccess      │
    │         .get("roles");                       │
    │       // ["ADMIN"]                           │
    │                                               │
    │       // ✅ IMPORTANT: Ajouter le préfixe   │
    │       return roles.stream()                  │
    │         .map(r ->                            │
    │           new SimpleGrantedAuthority(        │
    │             "ROLE_" + r  // "ROLE_ADMIN"   │
    │           )                                  │
    │         )                                    │
    │         .collect(toList());                 │
    │     }                                         │
    │   );                                          │
    │                                               │
    │   return converter;                           │
    │ }                                             │
    └──────────────┬───────────────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────────────┐
    │ 2. Créer l'Authentication                     │
    │                                               │
    │ Authentication = {                           │
    │   principal: "admin",                        │
    │   credentials: <JWT>,                        │
    │   authorities: [ROLE_ADMIN],                 │
    │   authenticated: true                        │
    │ }                                             │
    │                                               │
    │ SecurityContext.setAuthentication(auth)      │
    └──────────────┬───────────────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────────────┐
    │ 3. Invoquer le Contrôleur                     │
    │                                               │
    │ @GetMapping                                   │
    │ public ResponseEntity<List<ProductResponse>> │
    │ getAllProducts(Authentication auth) {        │
    │   // auth est injectable via Spring          │
    │                                               │
    │   // À ce point, on sait que:               │
    │   // - Le JWT est valide                    │
    │   // - L'utilisateur est "admin"           │
    │   // - L'utilisateur a le rôle "ROLE_ADMIN" │
    │                                               │
    │   return ResponseEntity.ok(...);             │
    │ }                                             │
    └──────────────┬───────────────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────────────┐
    │ 4. Appliquer les Annotations @PreAuthorize   │
    │                                               │
    │ @PreAuthorize("hasAnyRole('ADMIN')")        │
    │ // Spring Security cherche "ROLE_ADMIN"     │
    │ // Trouve dans authorities: ✅ Accès OK     │
    │                                               │
    │ @PreAuthorize("hasAnyRole('MANAGER')")      │
    │ // Spring Security cherche "ROLE_MANAGER"   │
    │ // Ne trouve pas → 403 Forbidden            │
    └──────────────┬───────────────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────────────┐
    │ 5. Exécuter la Logique Métier                │
    │                                               │
    │ - Requête BD: SELECT * FROM products        │
    │ - Mapper les résultats                       │
    │ - Retourner le DTO JSON                      │
    └──────────────┬───────────────────────────────┘
                   │
                   ▼
    ┌──────────────────────────────────────────────┐
    │ 6. HTTP Response                              │
    │                                               │
    │ 200 OK                                        │
    │ Content-Type: application/json                │
    │                                               │
    │ [                                             │
    │   {"id":1,"name":"Laptop",...},              │
    │   ...                                         │
    │ ]                                             │
    └──────────────────────────────────────────────┘
```

---

## 🎯 Tableau Récapitulatif - Flux Complet

| Étape | Composant | Action | Données |
|-------|-----------|--------|---------|
| 1 | React | User clicks "Login" | - |
| 2 | Keycloak | Affiche formulaire login | - |
| 3 | Keycloak | Valide credentials | user/password |
| 4 | Keycloak | Génère JWT | Token + Refresh Token |
| 5 | React | Stocke token | window.keycloak.token |
| 6 | React | Affiche Dashboard | username, rôles |
| 7 | React | Crée requête avec token | GET /products + JWT |
| 8 | Gateway | Valide JWT avec clé Keycloak | JWT valid ✅ |
| 9 | Gateway | Extrait rôles du JWT | ["ADMIN"] |
| 10 | Gateway | Route vers service | /products → port 8081 |
| 11 | Service | Crée JwtAuthenticationConverter | realm_access.roles |
| 12 | Service | Ajoute préfixe "ROLE_" | ["ROLE_ADMIN"] |
| 13 | Service | Vérifie @PreAuthorize | "ROLE_ADMIN" ∈ authorities? |
| 14 | Service | Exécute contrôleur | Business logic |
| 15 | Service | Retourne JSON | 200 OK + data |
| 16 | Gateway | Propage la réponse | Response au React |
| 17 | React | Affiche données | User see products |

---

## 🔑 Points Critiques

### 1️⃣ Le Préfixe "ROLE_"

**C'est LE problème du projet!**

```
JWT → realm_access.roles = ["ADMIN"]
                                ↓
JwtAuthenticationConverter → authority = "ADMIN"
                                ↓
@PreAuthorize("hasAnyRole('ADMIN')")
  → Spring cherche "ROLE_ADMIN" (ajoute "ROLE_" automatiquement)
  → Ne trouve pas "ADMIN"
  → 403 Forbidden ❌

SOLUTION:
JwtAuthenticationConverter → authority = "ROLE_ADMIN"  ← Add prefix
  → Spring cherche "ROLE_ADMIN"
  → Trouve!
  → 200 OK ✅
```

### 2️⃣ Token Expiration

```
Access Token: 5 minutes (300 secondes)
  - Pour les API calls
  - Expire rapidement

Refresh Token: 30 jours
  - Pour obtenir un nouveau access token
  - React peut auto-refresh

Keycloak renouvelle automatiquement via l'adapter JS
```

### 3️⃣ Clés de Signature

```
Keycloak génère une paire RSA 2048:
  - Clé privée: sur Keycloak (sign les tokens)
  - Clé publique: accessible pour valider
  
Endpoint: /realms/{realm}/protocol/openid-connect/certs

Services mettent en cache les clés publiques
  - Améliore les performances
  - Gère la rotation automatique
```

---

## 🧪 Exemples de Requêtes

### Exemple 1: Login avec Grant Type Password (Développement)

```bash
curl -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=react-client" \
  -d "username=admin" \
  -d "password=admin123" \
  http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token
```

**Réponse:**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 300,
  "refresh_expires_in": 2592000,
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "not-before-policy": 0,
  "session_state": "some-state-id",
  "scope": "openid email profile"
}
```

### Exemple 2: Appel API Protégé

```bash
TOKEN="<access_token_from_above>"

curl -X GET \
  -H "Authorization: Bearer $TOKEN" \
  http://localhost:8085/products
```

**Réponse Attendue:**
```json
[
  {
    "id": 1,
    "name": "Laptop",
    "price": 1200.00,
    "available": true
  }
]
```

### Exemple 3: Accès Refusé (USER essaie POST /products)

```bash
TOKEN="<user_token>"

curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"New Product","price":99}' \
  http://localhost:8085/products
```

**Réponse:**
```
403 Forbidden
```

Pourquoi?
- JWT contient: `realm_access.roles = ["USER"]`
- Converter crée: `authorities = ["ROLE_USER"]`
- @PreAuthorize cherche: `ROLE_ADMIN` ou `ROLE_MANAGER`
- USER n'a pas ce rôle → 403

---

## ✅ Vérification Post-Fix

Après application du fix (ajout du préfixe "ROLE_"):

```
USER Token:
├─ realm_access.roles = ["ADMIN"]
└─ Authorities = ["ROLE_ADMIN"]  ← Correct!

@PreAuthorize("hasAnyRole('ADMIN')")
├─ Spring cherche: "ROLE_ADMIN"
└─ Trouve! ✅ → 200 OK
```
