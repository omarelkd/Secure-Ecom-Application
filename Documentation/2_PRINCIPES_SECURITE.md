# Principes de Sécurité Utilisés

## Vue d'ensemble

Ce projet implémente une architecture de sécurité en couches, utilisant les meilleures pratiques de l'OWASP et les standards de l'industrie pour protéger une application microservices contre les menaces courantes.

---

## 1. Authentification - OAuth2 et OpenID Connect

### Implémentation

```
Keycloak OAuth2/OIDC Server
├── Realm: microservices-realm
├── Protocole: OpenID Connect
├── Grant Type: Authorization Code + PKCE (Frontend)
└── Endpoints:
    ├── /auth/realms/microservices-realm/protocol/openid-connect/auth
    ├── /auth/realms/microservices-realm/protocol/openid-connect/token
    └── /auth/realms/microservices-realm/protocol/openid-connect/userinfo
```

### Flux d'authentification

```mermaid
graph LR
    A["1. Utilisateur<br/>clique Login"] -->|Navigateur| B["2. React App<br/>redirige vers<br/>Keycloak"]
    B -->|OAuth2 AuthZ Code| C["3. Keycloak<br/>formulaire login"]
    C -->|Credentials| D["4. User Login<br/>et Consent"]
    D -->|AuthZ Code| E["5. React App<br/>échange Code"]
    E -->|Client ID<br/>+ Secret| F["6. Keycloak<br/>Token Endpoint"]
    F -->|JWT Token| E
    E -->|Stockage<br/>localStorage| G["7. App Authentifiée"]
```

### Tokens JWT

```json
{
  "access_token": "eyJhbGc...",
  "token_type": "Bearer",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "refresh_token": "eyJhbGc...",
  "id_token": "eyJhbGc..."
}
```

**Claims dans le JWT:**
- `sub` (Subject): ID utilisateur unique
- `email`: Adresse email utilisateur
- `email_verified`: Vérification email
- `name`: Nom complet
- `preferred_username`: Identifiant préféré
- `realm_access.roles`: Rôles dans le realm
- `resource_access`: Rôles spécifiques au client
- `iat` (Issued At): Moment d'émission (timestamp)
- `exp` (Expiration): Moment d'expiration (5 minutes)
- `aud` (Audience): Client ID pour lequel le token est valide

### Sécurité des credentials

```mermaid
graph TB
    A["Stockage Passwords<br/>Keycloak"] -->|Hachage| B["PBKDF2<br/>Bcrypt<br/>Argon2"]
    A -->|Politique| C["Complexité mot de passe"]
    C -->|Minima| D["- 8 caractères<br/>- Majuscule<br/>- Minuscule<br/>- Chiffre<br/>- Caractère spécial"]
    
    E["Protection Brute Force<br/>Keycloak"] -->|Config| F["maxFailureWaitSeconds: 900"]
    E -->|Config| G["failureFactor: 5"]
    E -->|Config| H["waitIncrementSeconds: 60"]
    
    F -->|Signifie| I["5 tentatives échouées<br/>= verrouillage 15 min"]
    G -->|Signifie| H
    H -->|Signifie| I
```

---

## 2. Autorisation - Contrôle d'accès basé sur les rôles (RBAC)

### Hiérarchie des rôles

```mermaid
graph TB
    Admin["ROLE_ADMIN<br/>Administrateur système"]
    Manager["ROLE_MANAGER<br/>Manager produits"]
    User["ROLE_USER<br/>Utilisateur standard"]
    
    Admin -->|Permissions supplémentaires| Manager
    Manager -->|Permissions supplémentaires| User
    
    Admin -->|Accès| A["- Tout le système<br/>- Gestion utilisateurs<br/>- Configuration<br/>- Rapports sensibles"]
    Manager -->|Accès| B["- Gestion produits<br/>- Gestion stocks<br/>- Commandes clients"]
    User -->|Accès| C["- Consultation produits<br/>- Création commandes<br/>- Profil personnel"]
```

### Matrice de permissions

```
Rôle        | GET /products | POST /products | PUT /products | DELETE /products | GET /orders | POST /orders
------------|---------------|----------------|---------------|------------------|-------------|-------------
ROLE_USER   | OUI           | NON            | NON           | NON              | NON         | OUI
ROLE_MANAGER| OUI           | OUI            | OUI           | NON              | OUI         | OUI
ROLE_ADMIN  | OUI           | OUI            | OUI           | OUI              | OUI         | OUI
```

### Implémentation dans le code

**Spring Security Configuration:**

```java
.securityMatchers("/products/**")
  .authorizeHttpRequests()
    .requestMatchers(HttpMethod.GET, "/products")
      .hasAnyRole("USER", "MANAGER", "ADMIN")
    .requestMatchers(HttpMethod.POST, "/products")
      .hasAnyRole("MANAGER", "ADMIN")
    .requestMatchers(HttpMethod.DELETE, "/products/**")
      .hasRole("ADMIN")
    .anyRequest()
      .authenticated()

.securityMatchers("/orders/**")
  .authorizeHttpRequests()
    .requestMatchers(HttpMethod.GET, "/orders")
      .authenticated()
    .requestMatchers(HttpMethod.POST, "/orders")
      .hasAnyRole("USER", "MANAGER", "ADMIN")
    .anyRequest()
      .authenticated()
```

---

## 3. Sécurité des données en transit - TLS/SSL

### HTTPS et certificats

```mermaid
graph LR
    Client["Client"] -->|Handshake TLS| Server["Server"]
    Server -->|Certificat RSA 2048-bit| Client
    Client -->|Validate Cert<br/>Check CN| Validation["Validation OK"]
    Validation -->|Encrypted Channel<br/>AES-256-GCM| Client
    Client <-->|Données chiffrées| Server
```

### Configuration pour production

```
- Protocole: TLS 1.2+ (minimum)
- Cipher Suites: AES-256-GCM, ChaCha20-Poly1305
- Certificats: Let's Encrypt ou CA réputée
- HSTS: Strict-Transport-Security header
- Perfect Forward Secrecy: Ephemeral keys
```

**En développement:**
- Localhost accepte HTTP non chiffré
- HTTPS peut être désactivé

---

## 4. Sécurité des données au repos

### Stockage sensible

```mermaid
graph TB
    A["Données Sensibles"] -->|Utilisateurs| B["Hachage PBKDF2"]
    A -->|Tokens refresh| C["Chiffrement symétrique"]
    A -->|Données PII| D["Chiffrement AES-256"]
    
    B -->|Stockage| E["Base Keycloak<br/>PostgreSQL"]
    C -->|Stockage| E
    D -->|Stockage| E
    
    E -->|Replication| F["Backup chiffré"]
    F -->|Archivage| G["Stockage sécurisé"]
```

### Keycloak Storage

```
PostgreSQL Database
├── Realm Configuration (public)
├── User Credentials (hashed + salted)
├── Sessions (tokens)
└── Audit Log (toutes les authentifications)
```

---

## 5. Gestion des sessions

### Timeouts de session

```
Session Configuration dans Keycloak:
├── accessTokenLifespan: 300 secondes (5 minutes)
├── accessTokenLifespanForImplicitFlow: 900 secondes (15 minutes)
├── ssoSessionIdleTimeout: 1800 secondes (30 minutes)
├── ssoSessionMaxLifespan: 36000 secondes (10 heures)
├── offlineSessionIdleTimeout: 2592000 secondes (30 jours)
└── refreshTokenLifespan: dépend config
```

### Diagramme de cycle de vie

```mermaid
graph LR
    A["Access Token<br/>5 min"] -->|Expired| B["Refresh Token<br/>30 min"]
    B -->|Valide| C["Nouveau Access<br/>Token"]
    C -->|Expired| B
    B -->|Expired| D["Re-login<br/>requis"]
    
    E["SSO Session<br/>30 min inactivité"] -->|Inactivité| F["Session fermée"]
    E -->|Activité détectée| E
    G["SSO Session Max<br/>10 heures total"] -->|Atteint| F
```

---

## 6. Protection contre les attaques courantes

### OWASP Top 10

```mermaid
graph TB
    A["OWASP Top 10"]
    
    A1["A01: Broken Access Control<br/>Mitigation: RBAC + JWT"] -->|Implémentation| B["Rôles + Permissions<br/>Validation à chaque endpoint"]
    
    A2["A02: Cryptographic Failures<br/>Mitigation: TLS/SSL"] -->|Implémentation| C["HTTPS + AES-256<br/>Hachage passwords"]
    
    A3["A03: Injection<br/>Mitigation: Parameterized Queries"] -->|Implémentation| D["Hibernate ORM<br/>Prepared Statements"]
    
    A5["A05: CORS<br/>Mitigation: CORS Config"] -->|Implémentation| E["Allowlist domaines<br/>Credentials mode"]
    
    A7["A07: Identification<br/>Mitigation: Strong Auth"] -->|Implémentation| F["OAuth2/OIDC<br/>Brute force protection"]
    
    A8["A08: Data Integrity<br/>Mitigation: JWT Signature"] -->|Implémentation| G["RSA Signature<br/>Validation serveur"]
    
    A10["A10: Logging & Monitoring<br/>Mitigation: Audit"] -->|Implémentation| H["Logs sécurité<br/>Audit trail Keycloak"]
```

### Détails des mitigations

#### A01: Broken Access Control
```
- Validation JWT à chaque requête
- Vérification rôles requis
- Validation côté serveur (pas de confiance client)
- Audit des accès refusés
```

#### A02: Cryptographic Failures
```
- TLS 1.2+ obligatoire
- Hachage PBKDF2 pour passwords
- Signatures RSA pour JWT
- Pas de données sensibles en logs
```

#### A03: Injection
```
- ORM (Hibernate) avec prepared statements
- Validation input
- Parameterized queries
- Escaping output
```

#### A05: CORS (Cross-Origin Resource Sharing)
```
Allowed Origins:
- http://localhost:3000 (dev)
- https://domain.com (prod)

Methods: GET, POST, PUT, DELETE
Headers: Authorization, Content-Type
Credentials: true (allow cookies)
Max-Age: 3600 secondes
```

#### A07: Identification and Authentication
```
- Pas de plaintext passwords
- Minimum 8 caractères, complexité
- Brute force protection (5 tentatives = 15 min lockout)
- MFA/2FA possible via Keycloak
- Session timeout (30 min inactivité)
```

#### A08: Data Integrity Failures
```
- JWT signé avec RSA-256
- Signature validée à chaque use
- Impossible de modifier token sans clé privée
- Expiration stricte
- Audience validation
```

#### A10: Logging and Monitoring
```
Keycloak logs:
- Toutes les authentifications
- Tous les refus d'accès
- Changements de configuration
- Tentatives échouées
```

---

## 7. CORS (Cross-Origin Resource Sharing)

### Configuration

```mermaid
graph TB
    Browser["Navigateur<br/>http://localhost:3000"]
    API["API Server<br/>http://localhost:8085"]
    
    Browser -->|CORS Preflight<br/>OPTIONS| API
    API -->|Access-Control-Allow-Origin: http://localhost:3000| Browser
    
    Browser -->|Regular Request<br/>+ Header Origin| API
    API -->|Validation Origin| Check{Allowlist?}
    Check -->|OUI| Allow["Allow<br/>CORS Headers"]
    Check -->|NON| Deny["Deny<br/>CORS Headers<br/>Browser bloque"]
    
    Allow --> Browser
    Deny --> Browser
```

### Headers CORS critiques

```
Request (Browser):
  Origin: http://localhost:3000
  Access-Control-Request-Method: POST
  Access-Control-Request-Headers: Authorization, Content-Type

Response (Server):
  Access-Control-Allow-Origin: http://localhost:3000
  Access-Control-Allow-Methods: GET, POST, PUT, DELETE
  Access-Control-Allow-Headers: Authorization, Content-Type
  Access-Control-Allow-Credentials: true
  Access-Control-Max-Age: 3600
```

---

## 8. Protection des secrets

### Gestion des variables d'environnement

```mermaid
graph TB
    A["Secrets"] -->|Ne jamais| B["Hardcoder en code"]
    A -->|Ne jamais| C["Commit dans Git"]
    A -->|Utiliser| D["Variables d'environnement"]
    A -->|Utiliser| E[".env local (gitignore)"]
    A -->|Utiliser| F["Secrets Manager (Prod)"]
    
    D -->|Docker| G["docker-compose.yml"]
    E -->|Local| H["développement local"]
    F -->|Production| I["AWS Secrets Manager<br/>Azure Key Vault"]
```

### Secrets critiques du projet

```
Keycloak Admin:
  - KEYCLOAK_ADMIN: admin
  - KEYCLOAK_ADMIN_PASSWORD: admin (DEV ONLY!)

Database:
  - POSTGRES_PASSWORD: keycloak_password (DEV ONLY!)
  - POSTGRES_USER: keycloak

OAuth2:
  - Client Secret (confidential clients)
  - JWT Signing Key (private)
```

---

## 9. Validation des entrées

### Input Validation Strategy

```mermaid
graph TB
    A["Requête Utilisateur"] -->|Validation| B["Longueur OK?"]
    B -->|NON| C["400 Bad Request"]
    B -->|OUI| D["Format OK?<br/>Regex/Pattern"]
    D -->|NON| C
    D -->|OUI| E["Contenu OK?<br/>XSS, Injection"]
    E -->|NON| C
    E -->|OUI| F["Business Logic"]
    F -->|OK| G["Response OK"]
    F -->|NON| H["422 Unprocessable"]
    C -->|Rejeter| I["Log + Fail"]
    H -->|Rejeter| I
    G -->|Accepter| J["Database"]
```

### Exemple Product Service

```
POST /products
Body: {
  "name": "Product Name",
  "price": 99.99,
  "description": "..."
}

Validations:
- name: NotNull, Length(min=3, max=255), Pattern "[a-zA-Z0-9\\s-]"
- price: NotNull, DecimalMin(0.01), DecimalMax(999999.99)
- description: NotNull, Length(min=10, max=1000)
- XSS check: StripHTML(description)
```

---

## 10. Logging et Audit

### Architecture de logging

```mermaid
graph TB
    A["Application Events"] -->|Authentication| B["Auth Events"]
    A -->|API Calls| C["API Events"]
    A -->|Errors| D["Error Events"]
    
    B -->|Destination| E["Keycloak Audit Log"]
    C -->|Destination| F["Application Logs"]
    D -->|Destination| F
    
    E -->|Stockage| G["PostgreSQL<br/>Keycloak"]
    F -->|Stockage| H["Files/Syslog<br/>logs/"]
    
    G -->|Monitoring| I["SIEM Dashboard"]
    H -->|Monitoring| I
```

### Informations loggées

```
Authentication:
  - Timestamp
  - User ID / Username
  - Success / Failure
  - IP Address
  - User Agent
  - Reason if failed (invalid password, user not found, etc.)

API Calls:
  - Timestamp
  - User ID
  - Method (GET, POST, etc.)
  - Endpoint
  - Status Code
  - Response Time
  - IP Address

Errors:
  - Timestamp
  - Service Name
  - Error Type
  - Stack Trace
  - User affected (if applicable)
  - Severity (ERROR, WARN, etc.)
```

### Exemple log d'authentification

```
2024-01-12T10:30:45.123Z INFO  keycloak.authentication
  EventType: USER_LOGIN
  UserId: user-123
  Username: john.doe@example.com
  ClientId: react-client
  Success: true
  IpAddress: 192.168.1.100
  UserAgent: Mozilla/5.0...
  RealmId: microservices-realm
```

---

## Résumé de la posture de sécurité

```
Layer             | Mechanism              | Strength
------------------|------------------------|------------------
Authentication    | OAuth2/OIDC + Keycloak | Fort (Entreprise)
Authorization     | RBAC + JWT             | Fort (Granulaire)
Transit           | TLS 1.2+               | Fort (Chiffré)
At Rest           | AES-256 + Hash         | Fort (Chiffré)
Sessions          | Timeout + Refresh      | Modéré (5 min)
Input             | Validation + Escaping  | Modéré
Secrets           | Env Vars + Keycloak    | Modéré (DEV)
Audit             | Logging + Keycloak     | Bon
CORS              | Allowlist              | Bon
OWASP             | 8/10 mitigations       | Excellent
```

Voir aussi:
- [1_ARCHITECTURE_ET_FLUX.md](1_ARCHITECTURE_ET_FLUX.md) - Architecture globale
- [3_DEVSECOPS_PIPELINE.md](3_DEVSECOPS_PIPELINE.md) - Pipeline de sécurisation

---

## Perspectives futures

### Améliorations de sécurité planifiées

**Authentification avancée:**
- MFA (Multi-Factor Authentication) via TOTP/SMS
- WebAuthn/FIDO2 support
- Social login (Google, GitHub, Microsoft)
- Passwordless authentication

**Autorisation granulaire:**
- Attribute-Based Access Control (ABAC)
- Policy-based access control
- Resource-level permissions
- Time-based access restrictions

**Encryption et Secrets:**
- HashiCorp Vault integration
- End-to-end encryption
- Envelope encryption
- Key rotation automation

**Compliance et Audit:**
- GDPR compliance features
- PCI-DSS support
- Automated compliance reports
- Advanced threat detection

**Infrastructure de sécurité:**
- mTLS entre services
- Service mesh (Istio)
- Zero-trust network architecture
- Advanced WAF rules
