# 🔧 Correction RBAC - Problème d'Accès

## 🐛 Problème Identifié

**Symptôme** : Aucun utilisateur (USER, ADMIN, MANAGER) ne pouvait accéder aux endpoints protégés avec `@PreAuthorize`.

**Cause Racine** : Incompatibilité entre les authorities du JWT et les vérifications Spring Security.

### Explication Technique

1. **JWT Keycloak** contient les rôles dans `realm_access.roles` :
   ```json
   {
     "realm_access": {
       "roles": ["USER", "ADMIN", "MANAGER"]
     }
   }
   ```

2. **JwtAuthenticationConverter** extrayait ces rôles et créait des authorities :
   ```java
   // ❌ AVANT (INCORRECT)
   realmRoles = roles.stream()
       .map(SimpleGrantedAuthority::new)  // Crée "USER", "ADMIN", etc.
       .collect(Collectors.toList());
   ```

3. **@PreAuthorize** utilise `hasRole()` qui cherche des authorities avec le préfixe "ROLE_" :
   ```java
   @PreAuthorize("hasRole('ADMIN')")  // Cherche "ROLE_ADMIN"
   ```

4. **Résultat** : Spring Security cherchait "ROLE_ADMIN" mais trouvait seulement "ADMIN" → **403 Forbidden**

---

## ✅ Solution Appliquée

### Modification du JwtAuthenticationConverter

Ajout du préfixe "ROLE_" lors de la création des authorities :

**product-service/config/SecurityConfig.java**
```java
// ✅ APRÈS (CORRECT)
realmRoles = roles.stream()
    .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
    .collect(Collectors.toList());
```

**order-service/config/SecurityConfig.java**
```java
// ✅ APRÈS (CORRECT)
realmRoles = roles.stream()
    .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
    .collect(Collectors.toList());
```

### Correction des Annotations

**order-service/controller/OrderController.java**
```java
// ❌ AVANT
@PreAuthorize("hasAnyRole('ADMIN', 'ROLE_MANAGER')")  // Doublon de préfixe!

// ✅ APRÈS
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")  // Correct
```

---

## 🔍 Mapping Complet

| Rôle Keycloak | Authority Spring | @PreAuthorize |
|---------------|------------------|---------------|
| USER          | ROLE_USER        | hasRole('USER') |
| ADMIN         | ROLE_ADMIN       | hasRole('ADMIN') |
| MANAGER       | ROLE_MANAGER     | hasRole('MANAGER') |

---

## 🧪 Validation

### Tests à exécuter

```bash
./test-rbac-fixed.sh
```

### Résultats attendus

#### USER
- ✅ GET /products → 200 (accès autorisé)
- ✅ GET /orders → 200 (ses commandes)
- ❌ POST /products → 403 (bloqué, ADMIN only)
- ❌ GET /orders/admin → 403 (bloqué, ADMIN/MANAGER only)

#### MANAGER
- ✅ GET /products → 200
- ✅ GET /orders/admin → 200 (toutes les commandes)
- ✅ PUT /orders/{id}/status → 200 (changer statut)
- ❌ POST /products → 403 (bloqué, ADMIN only)
- ❌ DELETE /orders/{id} → 403 (bloqué, ADMIN only)

#### ADMIN
- ✅ GET /products → 200
- ✅ POST /products → 201 (créer produit)
- ✅ PUT /products/{id} → 200 (modifier produit)
- ✅ DELETE /products/{id} → 204 (supprimer produit)
- ✅ GET /orders/admin → 200
- ✅ PUT /orders/{id}/status → 200
- ✅ DELETE /orders/{id} → 204

---

## 📋 Checklist de Vérification

- [x] Ajout du préfixe "ROLE_" dans product-service/SecurityConfig
- [x] Ajout du préfixe "ROLE_" dans order-service/SecurityConfig
- [x] Correction des annotations @PreAuthorize (suppression de "ROLE_" en double)
- [x] Redémarrage des services
- [ ] Tests RBAC validés avec le script
- [ ] Tests manuels dans l'interface React

---

## 🎯 Impact sur l'Interface React

### Aucun changement nécessaire côté Frontend

L'interface React utilise `keycloak.hasRealmRole()` qui vérifie directement les rôles du JWT **sans préfixe** :

```javascript
// ✅ Fonctionne déjà correctement
const hasRole = (role) => keycloak?.hasRealmRole(role);

if (hasRole('ADMIN')) {
  // Afficher le Panel Admin
}
```

### Routes protégées

```javascript
<ProtectedRoute roles={['ADMIN']} keycloak={keycloak}>
  <AdminPanel />
</ProtectedRoute>
```

Le composant `ProtectedRoute` vérifie avec `keycloak.hasRealmRole()`, pas besoin de modifier.

---

## 🚀 Déploiement

1. **Arrêter les services**
   ```bash
   ./stop-services.sh
   ```

2. **Démarrer avec les corrections**
   ```bash
   ./start-services.sh
   ```

3. **Vérifier les logs**
   ```bash
   tail -f logs/product-service.log
   tail -f logs/order-service.log
   ```

4. **Tester l'accès**
   ```bash
   ./test-rbac-fixed.sh
   ```

5. **Tester l'interface**
   - Ouvrir http://localhost:3000
   - Login avec `user / user`
   - Vérifier accès aux produits et commandes
   - Login avec `admin / admin`
   - Vérifier accès au Panel Admin

---

## 📚 Ressources

### Documentation Spring Security
- [Method Security](https://docs.spring.io/spring-security/reference/servlet/authorization/method-security.html)
- [OAuth 2.0 Resource Server JWT](https://docs.spring.io/spring-security/reference/servlet/oauth2/resource-server/jwt.html)

### Pourquoi le préfixe "ROLE_" ?
C'est une convention Spring Security historique. Quand vous utilisez :
- `hasRole('ADMIN')` → cherche l'authority "ROLE_ADMIN"
- `hasAuthority('ADMIN')` → cherche l'authority "ADMIN" (sans préfixe)

**Bonnes pratiques** :
- Utiliser `hasRole()` + ajouter le préfixe dans le converter ✅
- OU utiliser `hasAuthority()` sans préfixe
- Ne JAMAIS mélanger les deux approches

---

## ✅ Statut Final

- **Problème** : Résolu ✅
- **Impact** : Backend seulement
- **Tests** : En cours de validation
- **Prochaine étape** : Commit + Push des corrections
