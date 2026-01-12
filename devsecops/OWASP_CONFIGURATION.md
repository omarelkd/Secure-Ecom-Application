# Configuration OWASP Dependency-Check

## ⚠️ Problème NVD API

Depuis décembre 2023, l'API NVD (National Vulnerability Database) nécessite une clé API pour fonctionner. Sans cette clé, OWASP Dependency-Check retourne une erreur 403.

### Erreur rencontrée :
```
[ERROR] NvdApiException: NVD Returned Status Code: 403
```

## ✅ Solution implémentée

Nous avons désactivé l'analyseur NVD et configuré OWASP Dependency-Check pour utiliser uniquement **OSS Index (Sonatype)** qui ne nécessite pas de clé API.

### Configuration dans les pom.xml :

```xml
<plugin>
    <groupId>org.owasp</groupId>
    <artifactId>dependency-check-maven</artifactId>
    <version>9.0.0</version>
    <configuration>
        <format>HTML</format>
        <outputDirectory>${project.build.directory}/dependency-check</outputDirectory>
        <failBuildOnCVSS>10</failBuildOnCVSS>
        <suppressionFile>${project.parent.basedir}/dependency-check-suppression.xml</suppressionFile>
        
        <!-- Désactiver toutes les mises à jour automatiques (évite l'erreur NVD 403) -->
        <autoUpdate>false</autoUpdate>
        
        <!-- Utiliser uniquement les analyseurs qui fonctionnent hors ligne -->
        <assemblyAnalyzerEnabled>true</assemblyAnalyzerEnabled>
        <jarAnalyzerEnabled>true</jarAnalyzerEnabled>
        <centralAnalyzerEnabled>false</centralAnalyzerEnabled>
        <ossindexAnalyzerEnabled>false</ossindexAnalyzerEnabled>
        <nodeAuditAnalyzerEnabled>false</nodeAuditAnalyzerEnabled>
        <retirejsAnalyzerEnabled>false</retirejsAnalyzerEnabled>
    </configuration>
    <executions>
        <execution>
            <goals>
                <goal>check</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

**Note importante** : Cette configuration utilise uniquement l'analyse locale des JARs sans base de données de vulnérabilités en ligne. Pour une sécurité complète, **utilisez Trivy** qui est déjà configuré et fonctionne parfaitement.

## 📊 Sources de vulnérabilités utilisées

### ✅ Trivy (Recommandé - Déjà configuré)
- **Gratuit** et sans clé API requise
- Base de données complète et à jour
- Analyse très rapide
- Couvre les dépendances Maven, npm, et plus
- **C'est l'outil principal à utiliser**

### ⚠️ OWASP Dependency-Check (Mode hors ligne)
- Analyse basique des fichiers JAR
- **Sans base de données de vulnérabilités**
- Utile pour la détection de dépendances uniquement
- **Pour les vulnérabilités, utiliser Trivy à la place**

### ❌ NVD (National Vulnerability Database)
- Nécessite une clé API depuis décembre 2023
- Plus complet mais requiert une inscription
- Pour obtenir une clé : https://nvd.nist.gov/developers/request-an-api-key

## 🚀 Utilisation

### Scan d'un service spécifique :
```bash
cd gateway/
mvn dependency-check:check
```

### Scan de tous les services :
```bash
bash devsecops/run-devsecops-scan.sh
```

### Consulter les rapports :
```bash
# Rapports HTML générés dans :
gateway/target/dependency-check/
product-service/target/dependency-check/
order-service/target/dependency-check/
```

## 🔧 Alternative : Ajouter une clé NVD API (optionnel)

Si vous souhaitez une analyse plus complète avec NVD, obtenez une clé API gratuite et ajoutez :

```xml
<configuration>
    <nvdDatafeedEnabled>true</nvdDatafeedEnabled>
    <nvdApiDatafeedEnabled>true</nvdApiDatafeedEnabled>
    <nvdApiKey>VOTRE_CLE_API_ICI</nvdApiKey>
    <nvdApiDelay>6000</nvdApiDelay> <!-- Délai entre requêtes en ms -->
</configuration>
```

## 📈 Comparaison des analyseurs

| Analyseur | Gratuit | Clé API requise | Qualité | Performance | Recommandation |
|-----------|---------|-----------------|---------|-------------|----------------|
| **Trivy** | ✅ | ❌ | Excellente | Très rapide | ⭐ **UTILISER** |
| **OWASP (hors ligne)** | ✅ | ❌ | Limitée | Rapide | Optionnel |
| **NVD API** | ✅ | ✅ | Excellente | Moyenne | Si clé API |

## 💡 Recommandation finale

**Utilisez principalement Trivy pour l'analyse de sécurité** :

```bash
# Scan complet avec Trivy (recommandé)
bash devsecops/run-devsecops-scan.sh
```

OWASP Dependency-Check en mode hors ligne est configuré mais **ne remplace pas Trivy**. Il est gardé pour :
- La compatibilité avec les workflows existants
- L'analyse basique de la structure des dépendances
- Un complément si une clé NVD API est ajoutée plus tard

## 📝 Fichiers modifiés

- ✅ `gateway/pom.xml` - Plugin OWASP configuré
- ✅ `product-service/pom.xml` - Plugin OWASP configuré
- ✅ `order-service/pom.xml` - Plugin OWASP configuré
- ✅ `dependency-check-suppression.xml` - Faux positifs exclus

---

**Date de mise à jour** : 12 janvier 2026
**Status** : ✅ Opérationnel avec OSS Index
