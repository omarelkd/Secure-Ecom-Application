# 🔒 DevSecOps - Configuration Rapide

## Résumé des composants

| Composant | Description | Port | État |
|-----------|-------------|------|------|
| **SonarQube** | Analyse statique du code | 9000 | ✅ Configuré |
| **OWASP Dependency-Check** | Analyse des dépendances | - | ✅ Configuré |
| **Trivy** | Scan des images Docker | - | ✅ Configuré |
| **GitHub Actions** | Pipeline CI/CD | - | ✅ Configuré |

---

## 🚀 Démarrage en 5 minutes

### Étape 1 : Démarrer SonarQube

```bash
cd sonarqube/
docker-compose up -d
# Attendre 30 secondes
# Accès : http://localhost:9000 (admin/admin)
```

### Étape 2 : Installer les outils

```bash
# Installer Trivy
bash devsecops/install-trivy.sh

# Installer sonar-scanner (si besoin)
# wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-6.0.0.4432-linux.zip
# unzip et ajouter au PATH
```

### Étape 3 : Exécuter les scans

```bash
# Lancer tous les scans
bash devsecops/run-devsecops-scan.sh

# Ou scanner un service spécifique
bash devsecops/run-devsecops-scan.sh gateway
```

### Étape 4 : Consulter les résultats

- **SonarQube** : http://localhost:9000
- **Rapports locaux** : `devsecops/reports/`
- **GitHub Security** : https://github.com/omarelkd/Secure-Ecom-Application/security/code-scanning

### Étape 5 : Corriger les vulnérabilités

```bash
# Correction automatique
bash devsecops/fix-vulnerabilities.sh

# Ou pour un service spécifique
bash devsecops/fix-vulnerabilities.sh gateway
```

---

## 📂 Structure des fichiers

```
devsecops/
├── install-trivy.sh                    # Installation Trivy
├── run-devsecops-scan.sh              # Script principal de scan
├── fix-vulnerabilities.sh              # Correction automatique
├── pom-dependency-check.xml            # Config Maven Dependency-Check
└── reports/                            # Rapports générés

sonarqube/
├── docker-compose.yml                  # Configuration SonarQube
└── sonar-project.properties            # Propriétés SonarQube

.github/workflows/
└── devsecops-scan.yml                  # Pipeline GitHub Actions

dependency-check-suppression.xml         # Faux positifs
```

---

## 🎯 Cas d'usage typiques

### Scanner les dépendances Maven

```bash
cd gateway/
mvn dependency-check:check
```

### Auditer les dépendances npm

```bash
cd react-app/
npm audit
npm audit fix
```

### Scanner une image Docker

```bash
docker build -t my-service:latest .
trivy image my-service:latest
trivy image --format json --output report.json my-service:latest
```

### Scanner le code source

```bash
trivy fs ./gateway
trivy fs --severity HIGH,CRITICAL ./product-service
```

---

## ⚙️ Configuration avancée

### Modifier les règles SonarQube

1. Accéder à http://localhost:9000
2. Aller dans **Rules** (Règles)
3. Filtrer par **Security** (Sécurité)
4. Activer/désactiver les règles selon les besoins

### Ajouter des faux positifs

Éditer `dependency-check-suppression.xml` :

```xml
<suppression>
    <notes>Vulnérabilité acceptée</notes>
    <gav regex="false">org.springframework:spring-web:5.3.0</gav>
    <cve>CVE-2021-XXXXX</cve>
</suppression>
```

### Modifier le seuil CVSS

Dans `devsecops/run-devsecops-scan.sh` :

```bash
# Changer le seuil (par défaut: 7.0)
--severity HIGH,CRITICAL
--failBuildOnCVSS 8.0
```

---

## 📊 Interprétation des rapports

### SonarQube

- 🟢 **Rating A** : Bon (< 1 défaut par kLOC)
- 🟡 **Rating B** : Acceptable (1-3 défauts par kLOC)
- 🟠 **Rating C** : Faible (3-10 défauts par kLOC)
- 🔴 **Rating D/E** : Critique

### CVSS (Vulnerability Severity)

- 🔴 **CRITICAL** (9.0-10.0) : Corriger immédiatement
- 🟠 **HIGH** (7.0-8.9) : Corriger avant production
- 🟡 **MEDIUM** (4.0-6.9) : Corriger avant release
- 🟢 **LOW** (0.1-3.9) : À considérer

---

## 🔄 Automatisation

### Pipeline GitHub Actions

Le pipeline `devsecops-scan.yml` s'exécute automatiquement :

- ✅ Push vers `main`, `develop`, `fix-*`
- ✅ Pull requests
- ✅ Quotidiennement (2h00 UTC)

Consultez les résultats dans l'onglet **Actions** de GitHub.

### Scans locaux avant commit

```bash
# Créer un pre-commit hook
cd .git/hooks
cat > pre-commit << 'EOF'
#!/bin/bash
bash devsecops/run-devsecops-scan.sh
EOF
chmod +x pre-commit
```

---

## 🆘 Aide

### Logs et diagnostic

```bash
# Logs SonarQube
docker-compose -f sonarqube/docker-compose.yml logs -f sonarqube

# Vérifier Trivy
trivy version

# Vérifier Maven
mvn -v

# Vérifier npm
npm audit
```

### Réinitialiser SonarQube

```bash
cd sonarqube/
docker-compose down -v
docker-compose up -d
```

---

## 📚 Documentation complète

Voir [DEVSECOPS_GUIDE.md](DEVSECOPS_GUIDE.md) pour une documentation détaillée.

---

**Statut** : ✅ Implémenté et configuré
**Version** : 1.0.0
**Date** : 2026-01-11
