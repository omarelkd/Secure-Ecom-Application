# Configuration Keycloak - Microservices Realm

## 🚀 Démarrage Rapide

### Méthode 1 : Docker Compose (Recommandée)

```bash
cd keycloak
docker-compose up -d
```

Le realm sera **automatiquement importé** au démarrage !

### Méthode 2 : Docker Run avec Volume

```bash
docker run -d --name keycloak \
  -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -v keycloak_data:/opt/keycloak/data \
  -v $(pwd)/realm-export.json:/opt/keycloak/data/import/realm-export.json \
  quay.io/keycloak/keycloak:26.0.0 \
  start-dev --import-realm
```

---

## 🔐 Informations de Connexion

### Console Admin Keycloak
- URL : http://localhost:8080
- Username : `admin`
- Password : `admin`

### Utilisateurs de Test

| Username | Email | Password | Rôle |
|----------|-------|----------|------|
| user | user@test.com | password123 | ROLE_USER |
| admin | admin@test.com | admin123 | ROLE_ADMIN |
| manager | manager@test.com | manager123 | ROLE_MANAGER |

---

## 📋 Configuration Incluse

### Realm
- **Nom** : `microservices-realm`
- **Protocole** : OpenID Connect (OIDC)

### Clients

#### 1. react-client (Public)
- **Type** : Public
- **URL** : http://localhost:3000
- **Redirect URIs** : http://localhost:3000/*
- **Web Origins** : http://localhost:3000

#### 2. gateway-client (Confidential)
- **Type** : Confidential
- **Secret** : `gateway-secret-key-12345`
- **URL** : http://localhost:8085

#### 3. product-service (Service Account)
- **Type** : Confidential
- **Secret** : `product-service-secret-12345`
- **Service Account** : Activé

#### 4. order-service (Service Account)
- **Type** : Confidential
- **Secret** : `order-service-secret-12345`
- **Service Account** : Activé

### Rôles
- `ROLE_USER` - Utilisateurs standard
- `ROLE_ADMIN` - Administrateurs
- `ROLE_MANAGER` - Gestionnaires

---

## 🔄 Import Manuel (si nécessaire)

Si l'import automatique ne fonctionne pas :

1. Accéder à http://localhost:8080
2. Se connecter avec `admin` / `admin`
3. Cliquer sur le menu déroulant "master" (en haut à gauche)
4. Sélectionner **"Create Realm"**
5. Cliquer sur **"Browse"** et sélectionner `realm-export.json`
6. Cliquer sur **"Create"**

---

## ✅ Vérification

Après le démarrage, vérifiez que tout fonctionne :

```bash
# Test de la configuration OpenID
curl http://localhost:8080/realms/microservices-realm/.well-known/openid-configuration

# Test de login (remplacer USERNAME et PASSWORD)
curl -X POST http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=react-client" \
  -d "username=user" \
  -d "password=password123" \
  -d "grant_type=password"
```

---

## 🛑 Arrêt et Suppression

```bash
# Arrêter Keycloak
docker-compose down

# Arrêter ET supprimer les données
docker-compose down -v
```

---

## 📝 Notes

- Les données sont **persistées** dans le volume `keycloak_data`
- Les mots de passe sont en clair pour le développement (à changer en production)
- HTTPS désactivé en mode développement
- Les tokens JWT expirent après 5 minutes (300 secondes)
