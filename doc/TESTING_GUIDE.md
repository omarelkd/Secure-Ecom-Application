# 🧪 GUIDE DE TEST COMPLET - Vérification du Fix

## 📋 Pré-requis Avant de Tester

Assurez-vous que:
- ✅ Les services ont été recompilés (mvnw clean package)
- ✅ Les containers Docker sont arrêtés et redémarrés
- ✅ Keycloak est opérationnel (http://localhost:8080)
- ✅ React app est en cours d'exécution (http://localhost:3000)

---

## 🔍 TEST 1: Vérifier Que Keycloak Fonctionne

### Étape 1.1: Accéder à Keycloak Admin Console
```
URL: http://localhost:8080/admin/master/console/
```

### Étape 1.2: Vérifier le Realm
- Cliquer sur la liste déroulante en haut à gauche
- Sélectionner: **microservices-realm**
- Vous devriez voir:
  - 3 utilisateurs (user, manager, admin)
  - 3 rôles realm (ROLE_USER, ROLE_MANAGER, ROLE_ADMIN)
  - 4 clients (react-client, gateway-client, product-service, order-service)

### Étape 1.3: Vérifier les Utilisateurs
- Aller à: Users
- Vous devriez voir 3 utilisateurs:
  - `user` avec rôle: ROLE_USER
  - `manager` avec rôle: ROLE_MANAGER
  - `admin` avec rôle: ROLE_ADMIN

### Étape 1.4: Vérifier les Rôles
- Aller à: Realm Roles
- Vous devriez voir 3 rôles:
  - ROLE_USER
  - ROLE_MANAGER
  - ROLE_ADMIN

---

## 🔐 TEST 2: Obtenir un Token JWT (via cURL)

### Étape 2.1: Obtenir le Token pour ADMIN

```bash
# Commande complète (copier-coller)
TOKEN=$(curl -s -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=react-client" \
  -d "username=admin" \
  -d "password=admin123" \
  "http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token" \
  | jq -r '.access_token')

echo "Token obtenu: $TOKEN"
```

**Résultat attendu:**
```
Token obtenu: eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJqd...
```

### Étape 2.2: Décoder le Token

```bash
# Installer jq si nécessaire
# apt-get install jq  (sur Linux)
# brew install jq     (sur Mac)

# Décoder le JWT
echo $TOKEN | cut -d'.' -f2 | base64 -d | jq .
```

**Chercher dans la réponse:**
```json
{
  "preferred_username": "admin",
  "realm_access": {
    "roles": ["ROLE_ADMIN"]  ← IMPORTANT!
  },
  ...
}
```

---

## ✅ TEST 3: Tester les Endpoints avec ADMIN

### Étape 3.1: GET /products (Doit Retourner 200)

```bash
curl -X GET \
  -H "Authorization: Bearer $TOKEN" \
  http://localhost:8085/products

# Ou plus simplement
curl -H "Authorization: Bearer $TOKEN" http://localhost:8085/products
```

**Résultat attendu:**
```
200 OK
[
  {
    "id": 1,
    "name": "Laptop",
    "price": 1200.00,
    "available": true
  },
  ...
]
```

**Si vous voyez 403 Forbidden:**
- ❌ Le fix n'a pas été appliqué correctement
- ❌ Les services n'ont pas été recompilés
- ❌ Les containers n'ont pas été redémarrés

### Étape 3.2: GET /orders (Doit Retourner 200)

```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8085/orders
```

**Résultat attendu:**
```
200 OK
[]  # Ou liste des commandes
```

### Étape 3.3: GET /orders/admin (Doit Retourner 200 - ADMIN/MANAGER)

```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8085/orders/admin
```

**Résultat attendu:**
```
200 OK
[]  # Ou liste de toutes les commandes
```

### Étape 3.4: POST /products (Doit Retourner 201 - ADMIN seulement)

```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "price": 99.99,
    "available": true
  }' \
  http://localhost:8085/products
```

**Résultat attendu:**
```
201 Created
{
  "id": 2,
  "name": "Test Product",
  "price": 99.99,
  "available": true,
  "createdBy": "admin",
  "createdDate": "2026-01-11T10:00:00"
}
```

---

## 🧑 TEST 4: Tester avec USER (Permissions Restreintes)

### Étape 4.1: Obtenir le Token pour USER

```bash
TOKEN_USER=$(curl -s -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=react-client" \
  -d "username=user" \
  -d "password=password123" \
  "http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token" \
  | jq -r '.access_token')

echo "Token USER obtenu: $TOKEN_USER"
```

### Étape 4.2: USER - GET /products (Doit Retourner 200)

```bash
curl -H "Authorization: Bearer $TOKEN_USER" http://localhost:8085/products
```

**Résultat attendu:**
```
200 OK
[...]  # Produits visibles pour tout utilisateur authentifié
```

### Étape 4.3: USER - POST /products (Doit Retourner 403)

```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN_USER" \
  -H "Content-Type: application/json" \
  -d '{"name":"Hack","price":0}' \
  http://localhost:8085/products
```

**Résultat attendu:**
```
403 Forbidden
{
  "error": "Access is denied"
}
```

Pourquoi 403?
- JWT contient: `realm_access.roles = ["USER"]`
- Converter crée: `authorities = ["ROLE_USER"]`
- @PreAuthorize("hasRole('ADMIN')") cherche "ROLE_ADMIN"
- USER n'a pas ce rôle → 403 ✅

### Étape 4.4: USER - GET /orders/admin (Doit Retourner 403)

```bash
curl -H "Authorization: Bearer $TOKEN_USER" http://localhost:8085/orders/admin
```

**Résultat attendu:**
```
403 Forbidden
```

Pourquoi?
- @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
- USER n'a ni ADMIN ni MANAGER → 403 ✅

---

## 👨‍💼 TEST 5: Tester avec MANAGER

### Étape 5.1: Obtenir le Token pour MANAGER

```bash
TOKEN_MANAGER=$(curl -s -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=react-client" \
  -d "username=manager" \
  -d "password=manager123" \
  "http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token" \
  | jq -r '.access_token')

echo "Token MANAGER obtenu: $TOKEN_MANAGER"
```

### Étape 5.2: MANAGER - GET /orders/admin (Doit Retourner 200)

```bash
curl -H "Authorization: Bearer $TOKEN_MANAGER" http://localhost:8085/orders/admin
```

**Résultat attendu:**
```
200 OK
[...]  # MANAGER peut voir toutes les commandes
```

### Étape 5.3: MANAGER - POST /products (Doit Retourner 403)

```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN_MANAGER" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","price":0}' \
  http://localhost:8085/products
```

**Résultat attendu:**
```
403 Forbidden
```

Pourquoi?
- @PreAuthorize("hasRole('ADMIN')") - ADMIN seulement
- MANAGER n'a pas le rôle ADMIN → 403 ✅

### Étape 5.4: MANAGER - PUT /orders/{id}/status (Doit Retourner 200)

Supposons qu'il y a une commande avec ID 1:

```bash
curl -X PUT \
  -H "Authorization: Bearer $TOKEN_MANAGER" \
  "http://localhost:8085/orders/1/status?status=CONFIRMED"
```

**Résultat attendu:**
```
200 OK
{
  "id": 1,
  "status": "CONFIRMED",
  ...
}
```

Pourquoi 200?
- @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
- MANAGER a le rôle MANAGER → 200 ✅

---

## 🌐 TEST 6: Via l'Interface React

### Étape 6.1: Accéder à React
```
URL: http://localhost:3000
```

### Étape 6.2: Connectez-vous en tant que ADMIN

1. Cliquer sur "Se Connecter"
2. Saisir:
   - Username: `admin`
   - Password: `admin123`
3. Cliquer sur "Login"

**Résultat attendu:**
- Redirection vers l'accueil
- Navbar affiche: "Connecté en tant que: Admin"
- Tous les menus sont disponibles

### Étape 6.3: Tester les Routes

#### Route: Produits (`/products`)
1. Cliquer sur "Produits" dans la navbar
2. Devrait voir la liste des produits
3. Devrait voir les boutons "Ajouter", "Modifier", "Supprimer"

#### Route: Mes Commandes (`/my-orders`)
1. Cliquer sur "Mes Commandes"
2. Devrait voir la liste des commandes de l'admin
3. Devrait pouvoir créer une nouvelle commande

#### Route: Admin Panel (`/admin`)
1. Cliquer sur "Admin" dans la navbar
2. Devrait accéder au panel administrateur
3. Devrait voir les options de gestion

### Étape 6.4: Se Reconnecter en tant que USER

1. Cliquer sur le bouton utilisateur dans la navbar
2. Cliquer "Se Déconnecter"
3. Cliquer "Se Connecter"
4. Saisir:
   - Username: `user`
   - Password: `password123`

**Résultat attendu:**
- Navbar affiche: "Connecté en tant que: User"
- Menu "Admin" devrait être désactivé/caché
- Tentatif d'accès direct à `/admin` → redirect ou erreur

### Étape 6.5: Vérifier les Restrictions

Avec l'utilisateur USER:
- ✅ Peut voir "Produits"
- ✅ Peut voir "Mes Commandes"
- ❌ Ne peut pas voir "Admin"
- ❌ Ne peut pas créer de produit (si le formulaire apparaît, créer = 403)

---

## 📊 TABLEAU RÉCAPITULATIF DES TESTS

| Endpoint | Méthode | USER | MANAGER | ADMIN | Non-Auth |
|----------|---------|------|---------|-------|----------|
| /products | GET | ✅ 200 | ✅ 200 | ✅ 200 | ❌ 401 |
| /products | POST | ❌ 403 | ❌ 403 | ✅ 201 | ❌ 401 |
| /products/{id} | PUT | ❌ 403 | ❌ 403 | ✅ 200 | ❌ 401 |
| /products/{id} | DELETE | ❌ 403 | ❌ 403 | ✅ 204 | ❌ 401 |
| /orders | GET | ✅ 200 | ✅ 200 | ✅ 200 | ❌ 401 |
| /orders | POST | ✅ 201 | ✅ 201 | ✅ 201 | ❌ 401 |
| /orders/{id} | GET | ✅* 200 | ✅* 200 | ✅ 200 | ❌ 401 |
| /orders/admin | GET | ❌ 403 | ✅ 200 | ✅ 200 | ❌ 401 |
| /orders/{id}/status | PUT | ❌ 403 | ✅ 200 | ✅ 200 | ❌ 401 |
| /orders/{id} | DELETE | ❌ 403 | ❌ 403 | ✅ 204 | ❌ 401 |

*Seulement si c'est sa propre commande

---

## 🐛 DÉPANNAGE

### Problème: 403 Forbidden sur tous les endpoints

**Cause Probable:**
- Le fix n'a pas été appliqué
- Les services n'ont pas été recompilés
- Les containers n'ont pas été redémarrés

**Solution:**
```bash
# 1. Vérifier le code
grep -r "ROLE_" order-service/src/main/java/ma/enset/orderservice/config/SecurityConfig.java

# 2. Recompiler
cd order-service && ./mvnw clean package -DskipTests
cd product-service && ./mvnw clean package -DskipTests

# 3. Redémarrer
docker-compose down
docker-compose up -d

# 4. Attendre que Keycloak soit prêt (15-20 secondes)
sleep 20

# 5. Retester
TOKEN=$(curl -s -X POST ... | jq -r '.access_token')
curl -H "Authorization: Bearer $TOKEN" http://localhost:8085/products
```

### Problème: 401 Unauthorized

**Cause Probable:**
- Pas de token fourni
- Token expiré (5 minutes de validité)
- Token invalide

**Solution:**
```bash
# Vérifier le token
echo $TOKEN

# Obtenir un nouveau token si c'est expiré
TOKEN=$(curl -s -X POST ... | jq -r '.access_token')

# Vérifier que le token est complet
echo $TOKEN | cut -d'.' -f2 | base64 -d | jq .
```

### Problème: Keycloak non accessible

**Cause Probable:**
- Container Keycloak n'a pas démarré
- Port 8080 occupé par une autre application

**Solution:**
```bash
# Vérifier les logs Keycloak
docker logs keycloak_keycloak_1  # (ou le nom du container)

# Vérifier que le port est accessible
curl http://localhost:8080

# Si rien ne marche, redémarrer Keycloak
cd keycloak
docker-compose down
docker-compose up -d
```

### Problème: React ne peut pas appeler l'API

**Cause Probable:**
- CORS non configuré
- Gateway n'écoute pas
- Adresse incorrecte

**Solution:**
```bash
# Vérifier que le Gateway écoute
curl http://localhost:8085/actuator/health

# Vérifier que React utilise la bonne URL
# Dans src/services/orderService.js:
# const API_URL = 'http://localhost:8085/orders'  ✅

# Vérifier la CORS dans le navigateur
# Ouvrir les DevTools (F12) → Console
# Chercher les erreurs CORS
```

---

## ✨ RÉSUMÉ DES TESTS

Si tous les tests ci-dessus passent:
- ✅ Le fix a été correctement appliqué
- ✅ Les services recompilés et redéployés
- ✅ L'authentification OAuth2 fonctionne
- ✅ L'autorisation RBAC fonctionne
- ✅ Les permissions sont correctement appliquées

### Tests Prioritaires (Minimum)
1. ✅ ADMIN peut accéder à GET /products
2. ✅ ADMIN peut accéder à GET /orders
3. ✅ USER ne peut pas POST /products (403)
4. ✅ USER ne peut pas GET /orders/admin (403)

Si ces 4 tests passent, tout fonctionne! 🎉
