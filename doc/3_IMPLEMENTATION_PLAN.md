# Plan des Réalisations Restantes et Pratiques de Partage

## Plan de Réalisation (Phase 2-4)

### Phase 2: Configuration Keycloak Complète (1-2 jours)

#### Objectif
Mettre en place tous les utilisateurs, rôles et clients Keycloak nécessaires

#### Tâches
1. Accéder à la console Keycloak (http://localhost:8080)
2. Dans le realm `microservices-realm`:
   - Créer les rôles:
     - `ROLE_USER` (rôle par défaut)
     - `ROLE_ADMIN` (accès aux endpoints /admin)
     - `ROLE_MANAGER` (gestion des commandes)
   
3. Créer les utilisateurs:
   - `user@test.com` avec password `password123` - Rôle: ROLE_USER
   - `admin@test.com` avec password `admin123` - Rôle: ROLE_ADMIN
   - `manager@test.com` avec password `manager123` - Rôle: ROLE_MANAGER

4. Configurer les Clients:
   ```
   react-client:
   - Access Type: Public
   - Valid Redirect URIs: http://localhost:3000/*
   - Web Origins: http://localhost:3000
   
   gateway-client:
   - Access Type: Confidential
   - Valid Redirect URIs: http://localhost:8085/*
   
   product-service:
   - Access Type: Confidential
   - Service Account: Activé
   
   order-service:
   - Access Type: Confidential
   - Service Account: Activé
   ```

5. Mappage des rôles (Client Roles):
   - Mapper les rôles du realm aux clients
   - Inclure dans les tokens JWT

#### Fichier de Configuration (À créer: `keycloak-setup.sh`)
```bash
#!/bin/bash

KEYCLOAK_URL="http://localhost:8080"
REALM="microservices-realm"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

# Script d'automatisation de la configuration
# À implémenter avec Keycloak Admin CLI ou Python/Node scripts
```

---

### Phase 3: Implémentation des Modèles Métier (2-3 jours)

#### Product Service

**Fichier: `product-service/src/main/java/ma/enset/productservice/entity/Product.java`**
```java
@Entity
public class Product {
    @Id @GeneratedValue
    private Long id;
    private String name;
    private Double price;
    private String description;
    private Integer quantity;
    private LocalDateTime createdAt;
    private String createdBy;
}
```

**Fichier: `product-service/src/main/java/ma/enset/productservice/repository/ProductRepository.java`**
```java
@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {
    List<Product> findByNameContaining(String name);
}
```

**Fichier: `product-service/src/main/java/ma/enset/productservice/service/ProductService.java`**
```java
@Service
public class ProductService {
    // CRUD operations
    // Business logic
}
```

#### Order Service

Similaire au Product Service avec relations (User, Products, Status)

---

### Phase 4: Endpoints Complets et Sécurité (3-4 jours)

#### Product Service - Endpoints Finalisés

```
GET    /products              - List all products (AUTH)
GET    /products/{id}         - Get product detail (AUTH)
POST   /products              - Create product (ADMIN)
PUT    /products/{id}         - Update product (ADMIN)
DELETE /products/{id}         - Delete product (ADMIN)
GET    /products/admin/stats  - Admin statistics (ADMIN)
```

#### Order Service - Endpoints Finalisés

```
GET    /orders                - List user's orders (AUTH)
GET    /orders/{id}           - Get order detail (AUTH)
POST   /orders                - Create new order (AUTH)
PUT    /orders/{id}           - Update order (OWNER or ADMIN)
DELETE /orders/{id}           - Cancel order (OWNER or ADMIN)
GET    /orders/admin          - All orders (ADMIN)
GET    /orders/admin/stats    - Admin statistics (ADMIN)
```

#### Configuration Security pour chaque Service

**Exemple pour ProductController:**
```java
@RestController
@RequestMapping("/products")
public class ProductController {
    
    @GetMapping
    public ResponseEntity<List<ProductDTO>> getAll() {
        // Accessible pour tous les authentifiés
    }
    
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ProductDTO> create(@RequestBody CreateProductRequest req) {
        // Seulement ADMIN
    }
    
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        // Seulement ADMIN
    }
}
```

---

### Phase 5: Frontend React (2-3 jours)

#### Composants Principaux

1. **AuthContext.js** - Gestion de l'authentification
   - Initialisation Keycloak
   - Récupération des tokens
   - Refresh tokens automatique

2. **App.js** - Routage
   - Redirect vers login si non authentifié
   - Routes protégées

3. **ProductList.js** - Affichage des produits
   - Appel API via Axios
   - Affichage des données

4. **OrderForm.js** - Création de commande
   - Formulaire avec validation
   - Appel POST

5. **AdminPanel.js** - Interface admin
   - CRUD products et orders
   - Statistiques

#### Intégration Axios avec Bearer Token

```javascript
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:8085',
  headers: {
    'Content-Type': 'application/json'
  }
});

api.interceptors.request.use(config => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default api;
```

---

## Pratiques de Collaboration pour Équipe de 2 Personnes

### 1. Organisation du Travail

#### Répartition des Responsabilités

**Personne 1 (Backend Focus)**
- Configuration Keycloak
- Implémentation Product Service
- Implémentation Order Service
- API Gateway
- Configuration Docker/Deployment

**Personne 2 (Frontend Focus)**
- Interface React
- Intégration keycloak-js
- Tests frontend
- Documentation UI

#### Possibilité de Rotation
- Chacun teste l'autre côté (intégration)
- Cross-review des PRs

### 2. Gestion du Code Source

#### Stratégie de Branching (Git Flow)

```
main (production)
  ↑
  ├── develop (staging)
  |   ├── feature/keycloak-setup
  |   ├── feature/product-service
  |   ├── feature/product-ui
  |   ├── feature/order-service
  |   └── feature/order-ui
  └── hotfix/* (si nécessaire)
```

#### Convention de Commits

```
[BACKEND] Ajouter CRUD Product Service
[FRONTEND] Créer composant ProductList
[CONFIG] Setup Keycloak script
[DOCS] Update README
[FIX] Corriger bug authentification
```

### 3. Partage de la Configuration Locale

#### Fichier Commun: `.env.local`

Créer un fichier `.env.shared` dans le repo (à ne pas commiter):

```env
# .env.shared - À copier dans la config locale

## KEYCLOAK
KEYCLOAK_URL=http://localhost:8080
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin
KEYCLOAK_REALM=microservices-realm

## SERVICES
PRODUCT_SERVICE_URL=http://localhost:8081
ORDER_SERVICE_URL=http://localhost:8082
GATEWAY_URL=http://localhost:8085

## REACT
REACT_APP_KEYCLOAK_URL=http://localhost:8080
REACT_APP_REALM=microservices-realm
REACT_APP_CLIENT_ID=react-client
REACT_APP_API_URL=http://localhost:8085
```

#### Fichier Docker Compose Commun

`docker-compose.yml` pour tout démarrer facilement:

```yaml
version: '3.8'

services:
  keycloak:
    image: quay.io/keycloak/keycloak:26.0.0
    ports:
      - "8080:8080"
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
    command: start-dev

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: keycloak
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### 4. Synchronisation des Configurations Keycloak

#### Méthode 1: Export/Import (Simple)

```bash
# Exporter la config depuis Keycloak
# Admin Console → Realm Settings → Export

# Stocker dans le repo
git add keycloak-config.json

# Chaque développeur importe au démarrage
# Admin Console → Realm Settings → Import
```

#### Méthode 2: Script d'Automatisation (Avancé)

```bash
#!/bin/bash
# keycloak-init.sh

KEYCLOAK_URL="http://localhost:8080"
REALM="microservices-realm"

# Créer realm
curl -X POST "${KEYCLOAK_URL}/admin/realms" ...

# Créer utilisateurs
curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/users" ...

# Créer clients
curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/clients" ...
```

### 5. Partage des Jetons et Secrets

#### Ne JAMAIS Commiter

```
# .gitignore
.env.local
.env
*.secret
keycloak-secrets.json
client-secrets.json
```

#### Méthode Sécurisée

1. Créer un fichier template: `.env.example`
2. Chaque dev crée sa version locale: `.env.local`
3. Utiliser un gestionnaire de secrets (Vault, 1Password) pour le partage

### 6. Communication et Synchronisation

#### Réunions Quotidiennes (15 min)

- Standup le matin
- Blocages et dépendances
- Merge de PRs bloquantes

#### Tableau de Suivi

**Utiliser GitHub Project ou Trello**

```
Colonnes:
- To Do (Phase 2, Phase 3, Phase 4, Phase 5)
- In Progress
- In Review
- Done
```

#### Communication des Dépendances

**Exemple:**
```
Personne 1: "Les endpoints Product Service sont prêts"
Personne 2: "Je peux commencer l'intégration React"

OU

Personne 2: "J'ai besoin des specs d'erreur de l'API"
Personne 1: "Je crée une doc OpenAPI"
```

### 7. Testing et Validation

#### Checklist Avant Merge

```
- [ ] Code testé localement
- [ ] Pas de warnings/errors
- [ ] Formatage correct (Prettier, Java formatter)
- [ ] Documentation updatée
- [ ] Autre personne a reviewé (au moins 1 commentaire)
- [ ] Tests passent
```

#### Testing Cross-Team

```
Backend merge → Frontend teste
Frontend merge → Backend teste les endpoints
```

### 8. Documentation Partagée

#### Wiki Projet (dans le repo)

```
docs/
├── ARCHITECTURE.md       (Personne 1)
├── KEYCLOAK_SETUP.md     (Personne 1)
├── API_DOCUMENTATION.md  (Personne 1)
├── FRONTEND_SETUP.md     (Personne 2)
├── COMPONENT_GUIDE.md    (Personne 2)
└── DEPLOYMENT.md         (Ensemble)
```

#### Document Unique Partagé (Google Docs ou Notion)

- Notes de design
- Décisions architecturales
- Questions ouvertes
- Problèmes trouvés

### 9. Cycle de Développement Recommandé

```
Semaine 1:
  Jours 1-2: Phase 2 (Keycloak) - Personne 1
  Jours 1-2: Phase 3 (Models Backend) - Personne 1
  
Semaine 2:
  Jours 1-2: Phase 4 (Endpoints) - Personne 1
  Jours 1-4: Phase 5 (Frontend) - Personne 2
  
Semaine 3:
  Jour 1-2: Integration testing
  Jour 3-5: Bug fixes, Optimizations
  
Semaine 4:
  Documentation, Deployment, Tests finaux
```

### 10. Outils Recommandés

```
IDE:
- IntelliJ IDEA Community (Backend)
- VS Code (Frontend)
- Postman/Insomnia (API testing)

Collaboration:
- GitHub (Code)
- GitHub Projects (Kanban)
- Discord/Slack (Chat)
- Google Meet (Pair programming)

Database & Logs:
- DBeaver (Database UI)
- Lens (Kubernetes, si déploiement cloud)
- ELK Stack (Logs centralisés)
```

---

## Prochaines Étapes Immédiates

1. **Créer les branches**: `feature/keycloak-setup`, `feature/product-service`
2. **Établir le docker-compose.yml** commun
3. **Configurer Keycloak** (ou script d'automatisation)
4. **Démarrer Phase 2** en parallèle
5. **Sync daily** (15 min le matin)

