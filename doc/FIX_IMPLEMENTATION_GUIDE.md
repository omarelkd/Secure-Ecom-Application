# 🔧 Guide d'Application du Fix - Permissions

## ✅ Problème Fixé

Le préfixe "ROLE_" a été ajouté aux deux services microservice:
- ✅ **order-service/src/main/java/ma/enset/orderservice/config/SecurityConfig.java**
- ✅ **product-service/src/main/java/ma/enset/productservice/config/SecurityConfig.java**

---

## 📋 Étapes de Déploiement

### Étape 1: Arrêter les Services

```bash
# Arrêter tous les containers
docker-compose down

# Ou si vous utilisez des commandes manuelles
docker stop $(docker ps -q)
```

### Étape 2: Recompiler les Services

#### Order Service
```bash
cd order-service
./mvnw clean package -DskipTests
```

#### Product Service
```bash
cd product-service
./mvnw clean package -DskipTests
```

#### Gateway
```bash
cd gateway
./mvnw clean package -DskipTests
```

### Étape 3: Redémarrer Keycloak

```bash
cd keycloak
docker-compose up -d
```

### Étape 4: Vérifier que Keycloak est Prêt

```bash
# Attendre 10-15 secondes
sleep 15

# Vérifier que Keycloak est accessible
curl http://localhost:8080/realms/microservices-realm/.well-known/openid-configuration
```

### Étape 5: Démarrer les Services (Optionnel - Si pas de Docker)

```bash
# Dans des terminaux séparés
cd order-service && java -jar target/order-service-1.0.jar
cd product-service && java -jar target/product-service-1.0.jar
cd gateway && java -jar target/gateway-1.0.jar
cd react-app && npm start
```

---

## 🧪 Tests de Vérification

### Via cURL - Test ADMIN

```bash
# 1. Obtenir le token pour l'utilisateur admin
# (En utilisant l'interface Keycloak ou une requête POST)

TOKEN=$(curl -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=react-client&username=admin&password=admin123" \
  http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

# 2. Tester GET /products (doit retourner 200)
curl -H "Authorization: Bearer $TOKEN" http://localhost:8085/products

# 3. Tester GET /orders (doit retourner 200)
curl -H "Authorization: Bearer $TOKEN" http://localhost:8085/orders

# 4. Tester GET /orders/admin (doit retourner 200)
curl -H "Authorization: Bearer $TOKEN" http://localhost:8085/orders/admin

# 5. Tester POST /products (doit retourner 201 ou créer)
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Product","price":99.99}' \
  http://localhost:8085/products
```

### Via l'Interface React

1. **Accéder à http://localhost:3000**
2. **Cliquer sur "Se Connecter"**
3. **Utiliser les identifiants:**
   - Username: `admin`
   - Password: `admin123`

4. **Vérifier l'accès:**
   - ✅ Produits: Cliquer sur "Produits"
   - ✅ Commandes: Cliquer sur "Mes Commandes"
   - ✅ Admin Panel: Cliquer sur "Admin"

### Tester les Différents Utilisateurs

#### USER (Accès Standard)
- Username: `user`
- Password: `password123`
- ✅ Devrait accéder: Produits, Mes Commandes
- ❌ Devrait être bloqué: Admin Panel

#### MANAGER (Gestionnaire)
- Username: `manager`
- Password: `manager123`
- ✅ Devrait accéder: Produits, Mes Commandes, Manager Panel
- ❌ Devrait être bloqué: Admin Panel (création de produits)

#### ADMIN (Administrateur)
- Username: `admin`
- Password: `admin123`
- ✅ Devrait accéder: TOUT (y compris Admin Panel)

---

## 🔍 Vérification des Logs

### Chercher les Messages de Succès

```bash
# Pour Order Service
docker logs <order-service-container-id> | grep -i "authenticated\|authority"

# Pour Product Service
docker logs <product-service-container-id> | grep -i "authenticated\|authority"

# Pour Gateway
docker logs <gateway-container-id> | grep -i "authenticated\|jwt"
```

### Chercher les Erreurs

```bash
# Pour voir les erreurs d'authentification
docker logs <service-container-id> | grep -i "403\|forbidden\|denied"
```

---

## 📊 Résumé du Fix

### Avant (❌ INCORRECT)

```java
realmRoles = roles.stream()
    .map(SimpleGrantedAuthority::new)  // Crée "ADMIN"
    .collect(Collectors.toList());

// Spring Security cherche "ROLE_ADMIN" mais trouve "ADMIN" → 403
```

### Après (✅ CORRECT)

```java
realmRoles = roles.stream()
    .map(role -> new SimpleGrantedAuthority("ROLE_" + role))  // Crée "ROLE_ADMIN"
    .collect(Collectors.toList());

// Spring Security cherche "ROLE_ADMIN" et le trouve → 200 OK
```

---

## 🎯 Résultats Attendus

| Utilisateur | GET /products | GET /orders | GET /orders/admin | POST /products |
|-------------|---------------|-------------|-------------------|----------------|
| USER | ✅ 200 | ✅ 200 | ❌ 403 | ❌ 403 |
| MANAGER | ✅ 200 | ✅ 200 | ✅ 200 | ❌ 403 |
| ADMIN | ✅ 200 | ✅ 200 | ✅ 200 | ✅ 201/200 |
| Non-auth | ❌ 401 | ❌ 401 | ❌ 401 | ❌ 401 |

---

## 🛠️ Dépannage

### Si vous voyez encore des 403 après le fix:

**1. Vérifier le rebuild**
```bash
# Assurez-vous que les JAR ont été recompilés
ls -la order-service/target/*.jar
ls -la product-service/target/*.jar

# Vérifier la date du fichier (doit être récente)
stat order-service/target/order-service-1.0.jar
```

**2. Vérifier que Keycloak est accessible**
```bash
curl http://localhost:8080/realms/microservices-realm
```

**3. Vérifier le contenu du JWT**
```bash
# Décoder le token à https://jwt.io
# Chercher dans les claims:
# "realm_access": { "roles": ["ROLE_ADMIN"] }
```

**4. Vérifier les logs des services**
```bash
# Pour Order Service
docker logs <container> -f | grep -i authority

# Chercher des lignes comme:
# "Loaded 1 authorities for ADMIN"
```

**5. Redémarrer les containers**
```bash
docker-compose down
docker-compose up -d

# Ou si vous lancez manuellement, kill le processus Java et relancez
```

---

## ✨ Commandes Utiles

```bash
# Voir tous les containers
docker ps -a

# Voir les logs en temps réel
docker logs -f <container-id>

# Vérifier l'état de Keycloak
curl -s http://localhost:8080/realms/microservices-realm | jq .

# Tester la connectivité entre services
docker exec <service-container> curl -v http://localhost:8080/realms/microservices-realm

# Restart rapide
docker-compose restart
```

---

## 📝 Résumé

✅ **Fix appliqué:** Préfixe "ROLE_" ajouté aux deux services  
✅ **Fichiers modifiés:** 2 fichiers SecurityConfig.java  
🔄 **Action requise:** Recompiler et redéployer  
🧪 **Teste:** Via React ou cURL avec les 3 utilisateurs  
📊 **Résultat:** Tous les utilisateurs devraient pouvoir accéder à leurs endpoints autorisés
