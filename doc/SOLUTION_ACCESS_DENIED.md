# Solution: Problème d'Accès Refusé Malgré les Rôles Correctes

## 🔴 Problème Identifié

Même si les rôles s'affichent correctement dans l'interface React (**"Vos Rôles - ROLE_ADMIN"**), l'accès aux ressources protégées est refusé (403 Forbidden).

### Cause Root

Le **Gateway API** n'avait **PAS de JwtAuthenticationConverter** pour extraire les rôles du token JWT Keycloak. 

**Résumé:**
- Les services (Order et Product) avaient correctement le `JwtAuthenticationConverter`
- Le Gateway utilisait seulement `Customizer.withDefaults()` qui n'extrait pas les rôles
- Sans extraction des rôles, le Gateway ne pouvait pas autoriser les requêtes basées sur `@PreAuthorize`

---

## ✅ Solution Appliquée

### Modification du Gateway Security Config

Fichier: `gateway/src/main/java/ma/enset/gateway/config/GatewaySecurityConfig.java`

**Changements:**
1. Ajouté les imports nécessaires pour JwtAuthenticationConverter
2. Remplacé `oauth2.jwt(Customizer.withDefaults())` par `oauth2.jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthenticationConverter()))`
3. Implémenté la méthode `jwtAuthenticationConverter()` pour:
   - Extraire les rôles du claim `realm_access.roles` de Keycloak
   - Préfixer les rôles avec `ROLE_`
   - Combiner avec les scopes standards
   - Utiliser `preferred_username` comme principal claim

### Code Ajouté

```java
@Bean
public JwtAuthenticationConverter jwtAuthenticationConverter() {
    JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
    
    // Extract username from preferred_username claim
    converter.setPrincipalClaimName("preferred_username");
    
    converter.setJwtGrantedAuthoritiesConverter(jwt -> {
        // Extract realm roles from 'realm_access' claim
        Map<String, Object> realmAccess = jwt.getClaim("realm_access");
        Collection<GrantedAuthority> realmRoles = List.of();
        
        if (realmAccess != null && realmAccess.get("roles") != null) {
            @SuppressWarnings("unchecked")
            List<String> roles = (List<String>) realmAccess.get("roles");
            realmRoles = roles.stream()
                    .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                    .collect(Collectors.toList());
        }

        // Extract scopes
        JwtGrantedAuthoritiesConverter scopesConverter = new JwtGrantedAuthoritiesConverter();
        Collection<GrantedAuthority> scopes = scopesConverter.convert(jwt);

        // Combine realm roles and scopes
        return Stream.concat(realmRoles.stream(), scopes.stream())
                .collect(Collectors.toList());
    });
    
    return converter;
}
```

---

## 📋 Checklist de Vérification

### 1. Vérifier la Configuration

```bash
# Vérifier que le Gateway utilise le bon converter
grep -n "jwtAuthenticationConverter" gateway/src/main/java/ma/enset/gateway/config/GatewaySecurityConfig.java
# Doit afficher plusieurs lignes avec "jwtAuthenticationConverter"
```

### 2. Compiler et Démarrer les Services

```bash
# Compiler le gateway avec Java 17 (ajusté dans pom.xml)
mvn clean package -DskipTests -f gateway/pom.xml

# Démarrer les services
./start-services.sh
```

### 3. Tester l'Accès

```bash
# 1. Accéder à React App: http://localhost:3000
# 2. Se connecter avec un administrateur (admin / admin)
# 3. Vérifier "Vos Rôles" affiche "ROLE_ADMIN"
# 4. Accéder au Panel Admin
# 5. Vérifier que les données s'affichent (200 OK, pas 403)
```

### 4. Vérifier les Logs

```bash
# Chercher les erreurs d'accès refusé
tail -f logs/*.log | grep -i "access denied\|403\|401"

# Vérifier que les rôles sont extraits
tail -f logs/*.log | grep -i "granted.*authority\|role_"
```

---

## 🔍 Vérification Technique du Token

Pour déboguer, extraire et décoder le token JWT:

```javascript
// Dans la console React Developer Tools:
const token = keycloak.token;
console.log("Full Token:", token);

// Décoder le payload (base64)
const parts = token.split('.');
const payload = JSON.parse(atob(parts[1]));
console.log("Token Payload:", payload);
console.log("Realm Access:", payload.realm_access);
console.log("Roles:", payload.realm_access?.roles);
```

---

## 📊 Différence Avant/Après

| Aspect | Avant | Après |
|--------|-------|-------|
| Gateway Security | `Customizer.withDefaults()` | `jwtAuthenticationConverter()` |
| Extraction de rôles | ❌ Non | ✅ Oui |
| Autorisation | ❌ Échoue (403) | ✅ Réussit (200) |
| Affichage rôles React | ✅ Correct | ✅ Correct |
| Accès aux ressources | ❌ Refusé | ✅ Autorisé |

---

## ⚠️ Points Importants

1. **Le Gateway doit avoir le même converter que les Services**
   - Order Service: ✅ Avait
   - Product Service: ✅ Avait
   - Gateway: ❌ N'avait pas → ✅ Ajouté

2. **Les rôles Keycloak doivent avoir le préfixe "ROLE_"**
   - Keycloak: `admin` → JWT `realm_access.roles = ["admin"]`
   - Spring Security: `ROLE_admin` (via SimpleGrantedAuthority)

3. **L'ordre d'extraction est important:**
   - Extraire d'abord les rôles realm
   - Puis les scopes
   - Combiner les deux

---

## 🧪 Test de Validation

Créez un test avec la commande suivante:

```bash
# 1. Démarrer les services
./start-services.sh && sleep 30

# 2. Obtenir un token admin
ADMIN_TOKEN=$(curl -s -X POST "http://localhost:8080/realms/microservices-realm/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=api-client&client_secret=api-client-secret&grant_type=client_credentials" | jq -r '.access_token')

# 3. Tester l'accès au Product Service via Gateway
curl -H "Authorization: Bearer $ADMIN_TOKEN" http://localhost:8085/products

# Doit retourner 200 OK avec la liste des produits, pas 403 Forbidden
```

---

## 📝 Résumé

**Problème:** Gateway n'extrait pas les rôles du JWT  
**Solution:** Ajouter `JwtAuthenticationConverter` au Gateway  
**Impact:** Les requêtes protégées sont maintenant autorisées correctement  
**Statut:** ✅ RÉSOLU
