# Architecture et Flux Générales

## Vue d'ensemble

Ce projet implémente une architecture microservices sécurisée avec authentification OAuth2/OIDC centralisée via Keycloak. L'application gère un e-commerce avec des services indépendants pour les produits et les commandes, orchestrés par une passerelle API.

---

## Architecture Détaillée

### Schéma d'architecture détaillée

```mermaid
graph TB
    Client["Client Web<br/>(React)"]
    Browser["Navigateur<br/>Port: 3000"]
    
    subgraph "Couche de Présentation"
        React["React App<br/>- Material UI<br/>- Keycloak-JS<br/>- Axios"]
    end
    
    subgraph "Couche d'Authentification et Autorisation"
        Keycloak["Keycloak Server<br/>Port: 8080<br/>- OAuth2/OIDC<br/>- RBAC<br/>- Gestion des rôles"]
        DB_KC["PostgreSQL<br/>Keycloak DB"]
    end
    
    subgraph "Couche API Gateway"
        Gateway["API Gateway<br/>Spring Cloud Gateway<br/>Port: 8085<br/>- Routage<br/>- JWT Validation<br/>- CORS"]
    end
    
    subgraph "Couche Microservices"
        ProductService["Product Service<br/>Spring Boot<br/>Port: 8081<br/>- Gestion Produits<br/>- H2 DB"]
        OrderService["Order Service<br/>Spring Boot<br/>Port: 8082<br/>- Gestion Commandes<br/>- H2 DB"]
    end
    
    subgraph "Infrastructure de Sécurité"
        Security["Spring Security<br/>- OAuth2 Resource Server<br/>- JWT Bearer Token<br/>- Role-Based Access Control"]
    end
    
    subgraph "Conteneurisation"
        Docker["Docker & Docker Compose<br/>- Orchestration<br/>- Networking<br/>- Health Checks"]
    end
    
    Client -->|HTTP| Browser
    Browser -->|Authentification| Keycloak
    Browser -->|API Requests<br/>JWT Token| Gateway
    Keycloak --> DB_KC
    Gateway --> Security
    Security --> ProductService
    Security --> OrderService
    ProductService -->|Validation JWT| Keycloak
    OrderService -->|Validation JWT| Keycloak
    Gateway -->|Route /products| ProductService
    Gateway -->|Route /orders| OrderService
```

---

## Schéma d'architecture Minimal

### Pour une compréhension rapide

```mermaid
graph LR
    subgraph Client["Front-end"]
        A["React App<br/>Port: 3000"]
    end
    
    subgraph Backend["Back-end"]
        B["API Gateway<br/>Port: 8085"]
        C["Microservices<br/>Port: 8081-8082"]
    end
    
    subgraph Auth["Authentification"]
        D["Keycloak<br/>Port: 8080"]
    end
    
    A -->|Login| D
    A -->|API + JWT| B
    B --> C
    C -->|Verify JWT| D
```

---

## Flux d'authentification Détaillé

### Processus complet OAuth2/OIDC

```mermaid
sequenceDiagram
    participant User as Utilisateur
    participant ReactApp as React App
    participant Keycloak as Keycloak<br/>OAuth2/OIDC
    participant Gateway as API Gateway
    participant Service as Microservice<br/>Product/Order
    
    User->>ReactApp: 1. Accès à l'application
    ReactApp->>Keycloak: 2. Redirection Login<br/>(Client ID: react-client)
    Keycloak->>User: 3. Affiche formulaire login
    User->>Keycloak: 4. Credentials
    Keycloak->>Keycloak: 5. Validation Credentials
    Keycloak->>ReactApp: 6. Authorization Code + Redirect
    ReactApp->>Keycloak: 7. Token Request<br/>(Code + Client Secret)
    Keycloak->>ReactApp: 8. Access Token + ID Token + Refresh Token<br/>(JWT)
    ReactApp->>Gateway: 9. API Request<br/>Header: Authorization: Bearer [Token]
    Gateway->>Gateway: 10. Validation JWT<br/>(Signature + Exp + Roles)
    Gateway->>Service: 11. Route + Token
    Service->>Keycloak: 12. Validation Signature JWT<br/>(Optional)
    Keycloak->>Service: 13. JWT Valide + Claims
    Service->>Service: 14. Vérification RBAC<br/>(Rôles requis)
    Service->>User: 15. Ressource / 403 Forbidden
```

---

## Flux de requête Minimal

### Processus simplifié

```mermaid
sequenceDiagram
    participant User
    participant Client as Client App
    participant Gateway as Gateway
    participant Service as Service
    
    User->>Client: Demande
    Client->>Gateway: GET /products<br/>+ JWT Token
    Gateway->>Service: Demande validée
    Service->>Gateway: Réponse (JSON)
    Gateway->>Client: Réponse (JSON)
    Client->>User: Affichage
```

---

## Flux de requête avec gestion des rôles Détaillé

```mermaid
graph TD
    A["Requête HTTP<br/>GET /products"] -->|JWT Token| B["API Gateway"]
    B -->|Validation JWT| C{Token Valide?}
    
    C -->|Non| D["401 Unauthorized"]
    C -->|Oui| E["Extraction Rôles<br/>de JWT"]
    
    E --> F{Rôles OK pour<br/>cette route?}
    F -->|Non| G["403 Forbidden"]
    F -->|Oui| H["Routage vers<br/>Microservice"]
    
    H --> I["Product Service"]
    I -->|Query DB| J["H2 Database"]
    J -->|Résultats| I
    
    I --> K["Serialization JSON"]
    K -->|Response| H
    H -->|Response| B
    B -->|Response| L["Client React"]
    L -->|Affichage| M["Utilisateur"]
    
    D --> M
    G --> M
```

---

## Architecture des rôles RBAC

```mermaid
graph TB
    subgraph Keycloak["Keycloak Realm: microservices-realm"]
        RC["React Client<br/>client_id: react-client"]
        GC["Gateway Client<br/>client_id: gateway"]
        
        Roles["Rôles Disponibles"]
        USER["ROLE_USER<br/>- Accès lecture produits<br/>- Création commandes"]
        MANAGER["ROLE_MANAGER<br/>- Accès lecture/écriture<br/>- Gestion des stocks"]
        ADMIN["ROLE_ADMIN<br/>- Accès total<br/>- Gestion utilisateurs"]
        
        Roles --> USER
        Roles --> MANAGER
        Roles --> ADMIN
    end
    
    RC -->|Demande TOKEN| Keycloak
    GC -->|Validation TOKEN| Keycloak
    
    JWT["JWT Token<br/>Claims:<br/>- sub (user id)<br/>- roles<br/>- email<br/>- exp (expiration)"]
    
    Keycloak -->|Émission| JWT
    JWT -->|Bearer| Gateway
    Gateway -->|Verification| Keycloak
```

---

## Composants Technologiques

### Stack Technologique

| Couche | Technologie | Version | Rôle |
|--------|-------------|---------|------|
| **Frontend** | React | 19.2.1 | Interface utilisateur |
| | Material-UI | 7.3.7 | Composants UI |
| | Keycloak-JS | 26.2.1 | Client OAuth2/OIDC |
| | Axios | 1.13.2 | HTTP Client |
| **Backend** | Spring Boot | 3.5.9 | Framework REST |
| | Spring Cloud Gateway | 2025.0.1 | Passerelle API |
| | Spring Security | 3.5.9 | Authentification |
| | Spring Data JPA | 3.5.9 | ORM |
| **Database** | H2 | In-Memory | Base locale microservices |
| | PostgreSQL | 15-Alpine | Base Keycloak |
| **Auth** | Keycloak | 26.0.0 | OAuth2/OIDC Server |
| **Conteneurisation** | Docker | Latest | Containerization |
| | Docker Compose | 3.8 | Orchestration |
| **Runtime** | Java | 21 | JVM Runtime |
| | Node.js | (npm) | Runtime Frontend |

---

## Flux réseau et ports

```mermaid
graph LR
    Internet["Internet<br/>utilisateur:port"]
    
    LH["Localhost"]
    
    subgraph Containers["Docker Network: microservices_network"]
        RC["React<br/>3000"]
        GW["Gateway<br/>8085"]
        PS["Product<br/>8081"]
        OS["Order<br/>8082"]
        KC["Keycloak<br/>8080"]
        DB["PostgreSQL<br/>5432"]
    end
    
    Internet -->|:3000| LH
    Internet -->|:8085| LH
    Internet -->|:8080| LH
    
    LH -->|map| RC
    LH -->|map| GW
    LH -->|map| KC
    
    RC -->|localhost:8085| GW
    RC -->|localhost:8080| KC
    GW -->|via network| PS
    GW -->|via network| OS
    PS -->|via network| KC
    OS -->|via network| KC
    KC -->|via network| DB
```

---

## Cycle de vie des requêtes

### 1. Authentification initiale

1. Utilisateur accède à http://localhost:3000
2. React App détecte pas de token
3. Redirection vers Keycloak: http://localhost:8080/auth/realms/microservices-realm/protocol/openid-connect/auth
4. Utilisateur se connecte
5. Keycloak retourne Authorization Code
6. React App échange Code contre Access Token
7. Token stocké localement (localStorage/sessionStorage)

### 2. Appel API protégé

1. React App envoie requête: `GET /products` avec header `Authorization: Bearer [JWT]`
2. Gateway reçoit requête
3. Gateway valide JWT signature avec clé publique Keycloak
4. Gateway extrait rôles du JWT
5. Gateway vérifie rôles requis pour route
6. Gateway route vers Product Service
7. Service optionnellement valide JWT
8. Service retourne résultats filtrés par rôles
9. Réponse revient au client

### 3. Expiration et refresh

1. Access Token expire après 5 minutes (configurable)
2. React App détecte expiration
3. React App envoie Refresh Token à Keycloak
4. Keycloak valide Refresh Token et émet nouveau Access Token
5. React App réessaye avec nouveau token

---

## Points critiques de sécurité

```mermaid
graph TB
    A["Requête HTTP"] -->|1. SSL/TLS| B["Chiffrement en transit"]
    A -->|2. JWT Bearer| C["Token signé RSA"]
    A -->|3. CORS| D["Cross-Origin Validation"]
    
    C -->|4. Signature Check| E["Validation Keycloak"]
    C -->|5. Expiration Check| F["Vérification Timestamp"]
    
    E -->|6. RBAC| G["Vérification Rôles"]
    F -->|OK| H["Accès Accordé"]
    F -->|Expiré| I["401 Unauthorized"]
    G -->|OK| H
    G -->|Pas de rôle| J["403 Forbidden"]
    
    B -->|OK| C
    D -->|OK| C
    D -->|NOK| K["CORS Error"]
    
    K -->|Bloquer| L["Requête Rejetée"]
    I -->|Bloquer| L
    J -->|Bloquer| L
    H -->|Autoriser| M["Requête Traitée"]
```

---

## Résumé des dépendances

- **Frontend**: React, Material-UI, Keycloak-JS, Axios
- **Backend**: Spring Boot, Spring Cloud, Spring Security
- **Base de données**: PostgreSQL (Keycloak), H2 (Services)
- **Authentification**: Keycloak 26.0.0 (OAuth2/OIDC)
- **Conteneurisation**: Docker Compose
- **Communication**: HTTP/REST avec JWT

---

## Perspectives futures

### Améliorations planifiées

**Observabilité et Monitoring:**
- Intégration ELK Stack (Elasticsearch, Logstash, Kibana)
- Prometheus pour les métriques
- Jaeger pour le distributed tracing
- AlertManager pour les alertes en temps réel

**Scalabilité et Performance:**
- Migration vers Kubernetes
- Auto-scaling des services
- Cache distribué (Redis)
- Message queue (RabbitMQ/Apache Kafka)

**Sécurité avancée:**
- Vault pour la gestion des secrets
- mTLS entre services
- WAF (Web Application Firewall)
- Rate limiting et DDoS protection

**Fonctionnalités métier:**
- Service de paiement intégré
- Notifications en temps réel
- Système de recommandations
- Analytics client

Voir aussi:
- [2_PRINCIPES_SECURITE.md](2_PRINCIPES_SECURITE.md) - Détails des principes de sécurité
- [3_DEVSECOPS_PIPELINE.md](3_DEVSECOPS_PIPELINE.md) - Pipeline DevSecOps
