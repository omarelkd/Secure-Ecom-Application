# DevSecOps - Guide Complet

## 📋 Vue d'ensemble

Ce projet intègre une approche **DevSecOps** complète pour sécuriser l'ensemble du cycle de développement. Les outils suivants sont configurés :

### Outils de Sécurité Intégrés

| Outil | Objectif | Type |
|-------|----------|------|
| **SonarQube** | Analyse statique du code | SAST |
| **OWASP Dependency-Check** | Analyse des dépendances | SCA |
| **Trivy** | Scan des images Docker | Image Scanning |
| **npm audit** | Audit des dépendances Node.js | SCA |

---

## 🚀 Démarrage Rapide

### 1. Lancer SonarQube

```bash
# Démarrer le serveur SonarQube
cd sonarqube/
docker-compose up -d

# Accéder à l'interface : http://localhost:9000
# Identifiants par défaut : admin/admin
```

### 2. Installer les outils de scanning

```bash
# Installer Trivy
bash devsecops/install-trivy.sh

# Installer sonar-scanner (CLI)
# https://docs.sonarqube.org/latest/analyzing-source-code/scanners/sonarscanner/
```

### 3. Exécuter les scans

```bash
# Scanner tous les services
bash devsecops/run-devsecops-scan.sh

# Scanner un service spécifique
bash devsecops/run-devsecops-scan.sh gateway
bash devsecops/run-devsecops-scan.sh product-service
```

---

## 📊 Analyse Statique du Code - SonarQube

### Configuration

**Fichier** : `sonarqube/sonar-project.properties`

### Fonctionnalités

- ✅ Analyse du code source (Java, JavaScript)
- ✅ Détection des vulnérabilités de sécurité
- ✅ Mesure de la couverture de code
- ✅ Détection des code smells
- ✅ Rapports de qualité détaillés

### Accès à SonarQube

```
URL: http://localhost:9000
Identifiant: admin
Mot de passe: admin
```

### Configurer les Quality Gates

1. Accéder à **Quality Gates** dans SonarQube
2. Créer une nouvelle Quality Gate ou modifier la par défaut
3. Ajouter les conditions :
   - Coverage > 80%
   - Duplicated Lines < 3%
   - Security Rating = A
   - Security Hotspots Reviewed = 100%

### Exemple de résultats

```
Metrics (Exemple):
├── Lines of Code: 15,234
├── Code Coverage: 78%
├── Bugs: 3
├── Vulnerabilities: 1
├── Security Hotspots: 5
└── Maintainability Rating: A
```

---

## 🔍 Analyse des Dépendances

### OWASP Dependency-Check (Maven)

**Configuration** : `devsecops/pom-dependency-check.xml`

Scanne les dépendances Maven pour détecter les vulnérabilités connues (CVE).

#### Exécution manuelle

```bash
# Pour un service Maven spécifique
cd gateway/
mvn dependency-check:check \
  -Ddependency-check.reportDirectory=target/dependency-check \
  -Ddependency-check.format=ALL \
  -Ddependency-check.failBuildOnCVSS=7.0
```

#### Rapports générés

- `dependency-check-report.html` - Rapport visuel
- `dependency-check-report.json` - Format JSON
- `dependency-check-report.xml` - Format XML

### npm audit (Node.js)

Pour les projets Node.js/React :

```bash
# Audit des dépendances npm
cd react-app/
npm audit

# Correction automatique
npm audit fix

# Rapport JSON
npm audit --json > npm-audit-report.json
```

#### Niveaux de sévérité

| Niveau | Signification |
|--------|---------------|
| CRITICAL | Corriger immédiatement |
| HIGH | Corriger avant la production |
| MODERATE | Corriger avant la release |
| LOW | Considérer pour correction |

---

## 🐳 Scan des Images Docker - Trivy

### Installation

```bash
# Installation automatique
bash devsecops/install-trivy.sh

# Ou installation manuelle
# https://aquasecurity.github.io/trivy/
```

### Types de scans Trivy

#### 1. Scan d'images Docker

```bash
# Scanner une image existante
trivy image secure-ecom-gateway:latest

# Rapport en JSON
trivy image \
  --format json \
  --output trivy-report.json \
  secure-ecom-gateway:latest

# Rapport SARIF (format GitHub Security)
trivy image \
  --format sarif \
  --output trivy-report.sarif \
  secure-ecom-gateway:latest
```

#### 2. Scan du système de fichiers

```bash
# Scanner le code source
trivy fs ./gateway

# Avec options
trivy fs \
  --severity HIGH,CRITICAL \
  --format json \
  --output fs-scan.json \
  ./gateway
```

#### 3. Options communes

```bash
# Sévérités minimales
--severity MEDIUM,HIGH,CRITICAL

# Format de sortie
--format json|sarif|table|cyclonedx

# Sortie JSON
--output report.json

# Ignorer les vulnérabilités non corrigées
--skip-update

# Analyse approfondie
--security-checks vuln,config,secret
```

### Intégration CI/CD

Les scans Trivy sont intégrés dans le pipeline GitHub Actions et génèrent des rapports SARIF automatiquement intégrés dans l'onglet **Security** de GitHub.

---

## 🔧 Correction des Vulnérabilités

### Script de correction automatique

```bash
# Corriger tous les services
bash devsecops/fix-vulnerabilities.sh

# Corriger un service spécifique
bash devsecops/fix-vulnerabilities.sh gateway
bash devsecops/fix-vulnerabilities.sh react-app
```

### Processus de correction

Le script effectue :

1. **Backup** des fichiers originaux (`.vulnerability-backups/`)
2. **Mise à jour** des dépendances
3. **Vérification** de la compatibilité
4. **Test** des corrections
5. **Rapport** des modifications

### Corrections manuelles requises

Certaines vulnérabilités nécessitent une intervention manuelle :

#### Pour Maven (Java)

```bash
cd gateway/

# Afficher les mises à jour disponibles
mvn versions:display-dependency-updates

# Mettre à jour une dépendance spécifique
# Éditer pom.xml manuellement

# Rebâtir et tester
mvn clean test
```

#### Pour npm (Node.js)

```bash
cd react-app/

# Identifier les vulnérabilités
npm audit

# Essayer la correction automatique
npm audit fix

# Si nécessaire, mise à jour manuelle
npm install package@latest --save
```

#### Pour Docker

Utiliser les images de base les plus récentes et minimales :

```dockerfile
# ✓ BON - Leggero e aggiornato
FROM eclipse-temurin:21-jre-alpine

# ✗ MAUVAIS - Obsolète et volumineux
FROM java:8
```

---

## 📈 Pipeline CI/CD DevSecOps

### Fichier : `.github/workflows/devsecops-scan.yml`

Le pipeline s'exécute sur :
- Push vers `main`, `develop`, ou branche `fix-*`
- Pull requests
- Horaire : quotidiennement à 2h00

### Jobs du Pipeline

```
├── sonarqube-analysis (SonarQube)
├── dependency-check (OWASP Dependency-Check)
├── trivy-scan-docker (Scan d'images)
├── trivy-scan-fs (Scan du système de fichiers)
├── security-report (Rapport consolidé)
└── notify (Notification)
```

### Artefacts générés

Tous les rapports sont sauvegardés dans l'onglet **Artifacts** de GitHub Actions :

- `sonarqube-results/`
- `dependency-check-*/`
- `trivy-results-*.sarif`
- `trivy-fs-results-*.sarif`
- `security-report/`

---

## 📋 Suppression des Faux Positifs

### Dependency-Check

**Fichier** : `dependency-check-suppression.xml`

```xml
<suppression>
    <notes>Raison de la suppression</notes>
    <gav regex="false">org.springframework:spring-web:5.3.0</gav>
    <cve>CVE-2021-XXXXX</cve>
</suppression>
```

### SonarQube

Dans l'interface SonarQube :
1. Naviguer vers le problème
2. Cliquer sur "Mark as False Positive"
3. Ajouter un commentaire

---

## 🎯 Bonnes Pratiques

### 1. Dépendances

- ✅ Gardez les dépendances à jour
- ✅ Utilisez les versions stables
- ✅ Testez après mise à jour
- ❌ N'acceptez pas les dépendances obsolètes

### 2. Images Docker

```dockerfile
# ✓ BON
FROM eclipse-temurin:21-jre-alpine
RUN apk add --no-cache ca-certificates
USER app
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]

# ✗ MAUVAIS
FROM java:8
RUN apt-get update && apt-get install -y curl vim
USER root
EXPOSE 8080
```

### 3. Configuration de sécurité

- ✅ Pas de secrets en dur
- ✅ Utiliser des variables d'environnement
- ✅ Minimiser les permissions
- ✅ Activer l'audit de sécurité

### 4. Revue de code

- ✅ Examiner les résultats SonarQube
- ✅ Vérifier les hotspots de sécurité
- ✅ Vérifier les dépendances transitive
- ✅ Documenter les suppressions

---

## 📊 Tableau de Bord de Sécurité

### Accès aux rapports

| Outil | URL | Détails |
|-------|-----|---------|
| SonarQube | http://localhost:9000 | Tableau de bord sécurité |
| GitHub Security | `https://github.com/repo/security` | Résultats Trivy/SARIF |
| Rapports locaux | `./devsecops/reports/` | Fichiers générés |

### Métriques clés à suivre

- 🟢 **Coverage** : > 80%
- 🟢 **Security Rating** : A
- 🟢 **Vulnerabilities** : 0 Critical
- 🟢 **Hotspots Reviewed** : 100%
- 🟢 **No Outdated Dependencies**

---

## 🔐 Recommandations de Sécurité

### Code

1. Utiliser des variables d'environnement pour les secrets
2. Valider toutes les entrées utilisateur
3. Utiliser le paramétrage pour les requêtes SQL
4. Éviter l'exposition d'informations sensibles

### Dépendances

1. Mettre à jour régulièrement
2. Auditer avant intégration
3. Utiliser des versions fixes en production
4. Monitorer les CVE continuellement

### Images Docker

1. Utiliser des images minimales (Alpine)
2. Mettre à jour régulièrement
3. Scanner avant déploiement
4. Utiliser des registres privés

### Configuration

1. Activer HTTPS en production
2. Configurer les pare-feu
3. Utiliser les secrets de GitHub/Docker
4. Implémenter le RBAC

---

## 🆘 Troubleshooting

### SonarQube ne démarre pas

```bash
# Vérifier les logs
docker-compose -f sonarqube/docker-compose.yml logs sonarqube

# Augmenter la mémoire
export SONAR_JAVA_OPTS="-Xmx1024m"
```

### Trivy non trouvé

```bash
# Réinstaller
bash devsecops/install-trivy.sh

# Vérifier l'installation
which trivy
trivy version
```

### Dépendances non analysées

```bash
# Pour Maven : rebâtir d'abord
cd gateway/
mvn clean install

# Pour npm : installer les dépendances
cd react-app/
npm install
```

---

## 📚 Ressources Supplémentaires

- [SonarQube Documentation](https://docs.sonarqube.org/)
- [OWASP Dependency-Check](https://owasp.org/www-project-dependency-check/)
- [Trivy Scanner](https://aquasecurity.github.io/trivy/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25](https://cwe.mitre.org/top25/)

---

## ✅ Checklist de Sécurité

- [ ] SonarQube configuré et en cours d'exécution
- [ ] Tous les scans exécutés avec succès
- [ ] Aucune vulnérabilité critique
- [ ] Dépendances à jour
- [ ] Images Docker scannées
- [ ] Pipeline CI/CD activé
- [ ] Rapports archivés
- [ ] Équipe informée des résultats

---

**Dernière mise à jour** : 2026-01-11
**Version** : 1.0.0
