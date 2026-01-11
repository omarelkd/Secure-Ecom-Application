# Option 2 Complétée : Couche Métier (Backend)

## 🎉 Ce qui a été ajouté

### **Product Service** - Gestion des Produits

#### **Entities**
- `Product` : Entity JPA avec validation
  - id, name, description, price, quantity
  - Timestamps (createdAt, updatedAt)
  - Audit (createdBy)

#### **DTOs**
- `ProductRequest` : Pour création/modification
- `ProductResponse` : Pour les réponses API

#### **Repository**
- `ProductRepository` : JPA Repository avec queries custom
  - findByNameContainingIgnoreCase()
  - findAvailableProducts()
  - findOutOfStockProducts()

#### **Service**
- `ProductService` : Logique métier complète
  - CRUD complet
  - Recherche et filtrage
  - Logging avec SLF4J

#### **Controller (Mis à jour)**
- GET `/products` - Liste tous les produits (authentifié)
- GET `/products/{id}` - Détails d'un produit
- GET `/products/search?name=xxx` - Recherche
- GET `/products/available` - Produits en stock
- POST `/products` - Créer (ADMIN uniquement)
- PUT `/products/{id}` - Modifier (ADMIN uniquement)
- DELETE `/products/{id}` - Supprimer (ADMIN uniquement)
- GET `/products/admin` - Page admin (ADMIN uniquement)

#### **Base de Données**
- H2 en mémoire (productdb)
- 10 produits pré-chargés (data.sql)
- Console H2 : http://localhost:8081/h2-console

---

### **Order Service** - Gestion des Commandes

#### **Entities**
- `Order` : Entity JPA avec validation
  - id, productName, quantity, totalPrice
  - customerUsername, status (PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED)
  - Timestamps

#### **DTOs**
- `OrderRequest` : Pour création
- `OrderResponse` : Pour les réponses API

#### **Repository**
- `OrderRepository` : JPA Repository avec queries
  - findByCustomerUsername()
  - findByStatus()
  - findByCustomerUsernameAndStatus()

#### **Service**
- `OrderService` : Logique métier complète
  - CRUD complet
  - Gestion des statuts
  - Filtrage par utilisateur

#### **Controller (Mis à jour)**
- GET `/orders` - Mes commandes (utilisateur connecté)
- GET `/orders/{id}` - Détails d'une commande
- POST `/orders` - Créer une commande
- GET `/orders/admin` - Toutes les commandes (ADMIN/MANAGER)
- PUT `/orders/{id}/status?status=XXX` - Changer statut (ADMIN/MANAGER)
- DELETE `/orders/{id}` - Supprimer (ADMIN uniquement)
- GET `/orders/status/{status}` - Filtrer par statut (ADMIN/MANAGER)

#### **Base de Données**
- H2 en mémoire (orderdb)
- 5 commandes pré-chargées (data.sql)
- Console H2 : http://localhost:8082/h2-console

---

## 🔒 RBAC (Role-Based Access Control) Implémenté

### **SecurityConfig amélioré**
- `@EnableMethodSecurity` activé
- `JwtAuthenticationConverter` custom pour extraire les rôles de Keycloak
- Mapping des rôles depuis `realm_access.roles`

### **Contrôle d'accès par rôle**
- `@PreAuthorize("hasRole('ADMIN')")` - Réservé aux ADMIN
- `@PreAuthorize("hasAnyRole('ADMIN', 'ROLE_MANAGER')")` - ADMIN ou MANAGER

### **Permissions**

| Endpoint | USER | ADMIN | MANAGER |
|----------|------|-------|---------|
| GET /products | ✅ | ✅ | ✅ |
| POST /products | ❌ | ✅ | ❌ |
| PUT /products | ❌ | ✅ | ❌ |
| DELETE /products | ❌ | ✅ | ❌ |
| GET /orders | ✅ (ses commandes) | ✅ (toutes) | ✅ (toutes) |
| POST /orders | ✅ | ✅ | ✅ |
| PUT /orders/status | ❌ | ✅ | ✅ |
| DELETE /orders | ❌ | ✅ | ❌ |

---

## 🚀 Comment tester

### **1. Démarrer les services**

```bash
# Terminal 1 - Keycloak (si pas déjà démarré)
cd keycloak
docker-compose up -d

# Terminal 2 - Product Service
cd product-service
./mvnw clean spring-boot:run

# Terminal 3 - Order Service
cd order-service
./mvnw clean spring-boot:run

# Terminal 4 - Gateway
cd gateway
./mvnw spring-boot:run
```

### **2. Tester avec cURL**

#### **Obtenir un token (via React ou directement)**
Connectez-vous sur http://localhost:3000 et récupérez le token dans la console développeur :
```javascript
console.log(keycloak.token)
```

#### **Tester Product Service**

```bash
# Liste des produits (USER)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8085/products

# Créer un produit (ADMIN uniquement)
curl -X POST http://localhost:8085/products \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "description": "A test product",
    "price": 99.99,
    "quantity": 10
  }'

# Rechercher
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://localhost:8085/products/search?name=laptop"
```

#### **Tester Order Service**

```bash
# Mes commandes (USER)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8085/orders

# Créer une commande
curl -X POST http://localhost:8085/orders \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "productName": "iPhone 15 Pro",
    "quantity": 1,
    "totalPrice": 999.99
  }'

# Toutes les commandes (ADMIN/MANAGER)
curl -H "Authorization: Bearer ADMIN_TOKEN" \
  http://localhost:8085/orders/admin

# Changer le statut (ADMIN/MANAGER)
curl -X PUT "http://localhost:8085/orders/1/status?status=SHIPPED" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

### **3. Accéder aux consoles H2**

**Product Service :**
- URL : http://localhost:8081/h2-console
- JDBC URL : `jdbc:h2:mem:productdb`
- Username : `sa`
- Password : (vide)

**Order Service :**
- URL : http://localhost:8082/h2-console
- JDBC URL : `jdbc:h2:mem:orderdb`
- Username : `sa`
- Password : (vide)

---

## 📦 Dépendances ajoutées

```xml
<!-- JPA & Database -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
</dependency>

<!-- Validation -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>

<!-- Lombok -->
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
</dependency>
```

---

## ✅ Checklist de validation

- [x] Entities avec validation Jakarta
- [x] Repositories JPA
- [x] Services avec logique métier
- [x] DTOs Request/Response
- [x] Controllers REST complets
- [x] RBAC avec @PreAuthorize
- [x] JwtAuthenticationConverter custom
- [x] H2 Database configurée
- [x] Données de test (data.sql)
- [x] Logging SLF4J
- [x] Gestion d'erreurs basique

---

## 🎯 Prochaines étapes

1. **Améliorer l'interface React** pour utiliser ces nouveaux endpoints
2. **Ajouter la gestion d'erreurs** globale (@ControllerAdvice)
3. **Tests unitaires** pour Services et Controllers
4. **Documentation API** (Swagger/OpenAPI)
5. **Pagination** pour les listes de produits/commandes
