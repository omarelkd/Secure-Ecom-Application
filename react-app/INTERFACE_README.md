# 🎨 Interface React - Documentation

## 📋 Vue d'ensemble

Interface utilisateur complète avec Material-UI et React Router pour l'application E-Commerce sécurisée.

## 🏗️ Architecture

```
src/
├── components/           # Composants réutilisables
│   ├── Navbar.js        # Barre de navigation
│   ├── ProtectedRoute.js # Route protégée avec RBAC
│   ├── OrderFormModal.js # Modal de création de commande
│   ├── ProductsManagement.js # CRUD produits (ADMIN)
│   └── OrdersManagement.js   # Gestion commandes (ADMIN/MANAGER)
│
├── pages/               # Pages principales
│   ├── Home.js         # Page d'accueil
│   ├── Products.js     # Liste produits avec recherche
│   ├── MyOrders.js     # Commandes utilisateur
│   ├── AdminPanel.js   # Panel administrateur
│   └── ManagerPanel.js # Panel manager
│
├── services/           # Services API
│   ├── productService.js # API produits
│   └── orderService.js   # API commandes
│
└── App.js             # Configuration Router + Routes
```

## 🚀 Fonctionnalités

### 🏠 Page d'accueil (`/`)
- Bienvenue personnalisée
- Affichage des rôles utilisateur
- Accès rapide aux fonctionnalités
- Cards informationnelles

### 🛍️ Page Produits (`/products`)
- Affichage de tous les produits avec Material-UI Cards
- **Recherche en temps réel** (nom, description)
- **Filtre disponibilité** (toggle switch)
- Badge coloré pour le statut
- Bouton "Commander" → ouvre modal
- **Accessible à** : USER, ADMIN, MANAGER

### 📦 Modal Commande
- Sélection automatique du produit
- Input quantité (validation min: 1)
- Calcul automatique du prix total
- Création via POST `/orders`
- Gestion des erreurs

### 📋 Mes Commandes (`/my-orders`)
- Table Material-UI avec toutes les commandes de l'utilisateur
- Colonnes : ID, Produit, Quantité, Prix, Statut, Date
- **Badges colorés** :
  - 🟠 PENDING → Orange
  - 🔵 PROCESSING → Bleu
  - 🟢 COMPLETED → Vert
  - 🔴 CANCELLED → Rouge
- Lecture seule (pas d'actions)
- **Accessible à** : USER, ADMIN, MANAGER

### 🔧 Panel Admin (`/admin`)
**Onglet 1 : Gestion Produits**
- Table avec tous les produits
- Bouton "+ Nouveau Produit"
- Actions : ✏️ Modifier, 🗑️ Supprimer
- Modal CRUD avec validation
- **Accessible à** : ADMIN uniquement

**Onglet 2 : Gestion Commandes**
- Table de toutes les commandes (tous clients)
- Dropdown pour changer le statut
- Bouton 🗑️ Supprimer (ADMIN only)
- Filtre par statut
- **Accessible à** : ADMIN uniquement

### 👔 Panel Manager (`/manager`)
- Table de toutes les commandes
- Dropdown pour changer le statut (PUT `/orders/{id}/status`)
- **PAS** de bouton Supprimer (403 si tenté)
- Filtre par statut
- **Accessible à** : MANAGER uniquement

## 🔒 Sécurité

### Routes Protégées
```javascript
<ProtectedRoute roles={['USER', 'ADMIN']} keycloak={keycloak}>
  <Products />
</ProtectedRoute>
```

### Gestion des Rôles
- **USER** : Voir produits, créer/voir ses commandes
- **MANAGER** : + Modifier statuts de toutes les commandes
- **ADMIN** : + CRUD produits + Supprimer commandes

### Authentification
- Vérification automatique via `keycloak.authenticated`
- Page de connexion si non authentifié
- Page "Accès Refusé" si rôle insuffisant

## 🎨 Design Material-UI

### Thème
```javascript
palette: {
  primary: '#1976d2',    // Bleu
  secondary: '#dc004e',  // Rose
}
```

### Composants utilisés
- AppBar, Toolbar, Button
- Card, CardContent, CardActions
- Table, TableContainer
- Dialog, TextField
- Chip, Alert, CircularProgress
- Icons (@mui/icons-material)

## 📡 Services API

### productService
```javascript
getAllProducts()
getProductById(id)
searchProducts(name)
getAvailableProducts()
createProduct(product)      // ADMIN
updateProduct(id, product)  // ADMIN
deleteProduct(id)           // ADMIN
```

### orderService
```javascript
getMyOrders()                    // Mes commandes
getOrderById(id)
getAllOrders()                   // ADMIN/MANAGER
getOrdersByStatus(status)
createOrder(order)               // USER
updateOrderStatus(id, status)    // ADMIN/MANAGER
deleteOrder(id)                  // ADMIN
```

## 🚦 Démarrage

```bash
cd react-app
npm install  # Déjà fait
npm start    # Démarre sur http://localhost:3000
```

## 🧪 Tester l'interface

### En tant que USER
1. Login avec `user / user`
2. Accès : Produits, Mes Commandes
3. Créer une commande via modal
4. Voir ses commandes dans "Mes Commandes"

### En tant que MANAGER
1. Login avec `manager / manager`
2. Accès : Produits, Mes Commandes, Panel Manager
3. Modifier le statut des commandes
4. **Impossible** de supprimer des commandes

### En tant que ADMIN
1. Login avec `admin / admin`
2. Accès complet à toutes les fonctionnalités
3. Panel Admin avec 2 onglets :
   - CRUD complet sur les produits
   - Gestion complète des commandes (statut + suppression)

## 📊 Statuts de Commande

```
PENDING     → En attente (🟠)
PROCESSING  → En cours (🔵)
COMPLETED   → Complété (🟢)
CANCELLED   → Annulé (🔴)
```

## 🔄 Flux Utilisateur Typique

1. **Connexion** → Page d'accueil avec rôles
2. **Produits** → Recherche/Filtres → Sélection → Commander
3. **Modal** → Choix quantité → Confirmer
4. **Mes Commandes** → Voir la nouvelle commande (PENDING)
5. **Manager/Admin** → Change le statut → PROCESSING/COMPLETED

## ⚠️ Points Importants

- ✅ Tous les appels API passent par le Gateway (8085)
- ✅ Token JWT automatiquement ajouté via `getAuthHeader()`
- ✅ Refresh token automatique avec `keycloak.updateToken(30)`
- ✅ Gestion des erreurs 401/403 avec messages clairs
- ✅ Routes protégées avec vérification des rôles
- ✅ UI responsive avec Material-UI Grid

## 🎯 Prochaines Améliorations

- [ ] Pagination des produits/commandes
- [ ] Tri des colonnes dans les tables
- [ ] Upload d'images pour les produits
- [ ] Notifications Toast pour les actions
- [ ] Mode sombre
- [ ] Export CSV des commandes (Admin)
