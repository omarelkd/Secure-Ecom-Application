#!/bin/bash

##############################################################################
# Health Check DevSecOps
# Vérifie que tous les composants DevSecOps sont correctement configurés
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         🏥 Health Check - DevSecOps Components            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Compteurs
checks_passed=0
checks_failed=0

print_check() {
    local name=$1
    local status=$2
    local details=$3
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $name"
        [ ! -z "$details" ] && echo -e "  ${GREEN}  $details${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}✗${NC} $name"
        [ ! -z "$details" ] && echo -e "  ${RED}  $details${NC}"
        ((checks_failed++))
    fi
}

# ============= FICHIERS ET RÉPERTOIRES =============
echo -e "${BLUE}Fichiers et Répertoires${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# SonarQube
[ -f "$PROJECT_ROOT/sonarqube/docker-compose.yml" ] && \
    print_check "SonarQube docker-compose.yml" "PASS" "Fichier présent" || \
    print_check "SonarQube docker-compose.yml" "FAIL" "Fichier manquant"

[ -f "$PROJECT_ROOT/sonarqube/sonar-project.properties" ] && \
    print_check "SonarQube sonar-project.properties" "PASS" "Fichier présent" || \
    print_check "SonarQube sonar-project.properties" "FAIL" "Fichier manquant"

# Dependency-Check
[ -f "$PROJECT_ROOT/devsecops/pom-dependency-check.xml" ] && \
    print_check "Dependency-Check config" "PASS" "Fichier présent" || \
    print_check "Dependency-Check config" "FAIL" "Fichier manquant"

[ -f "$PROJECT_ROOT/dependency-check-suppression.xml" ] && \
    print_check "Suppression des faux positifs" "PASS" "Fichier présent" || \
    print_check "Suppression des faux positifs" "FAIL" "Fichier manquant"

# Trivy
[ -f "$PROJECT_ROOT/devsecops/install-trivy.sh" ] && \
    print_check "Trivy install script" "PASS" "Fichier présent" || \
    print_check "Trivy install script" "FAIL" "Fichier manquant"

# Scripts de scan
[ -f "$PROJECT_ROOT/devsecops/run-devsecops-scan.sh" ] && \
    print_check "DevSecOps scan script" "PASS" "Fichier présent" || \
    print_check "DevSecOps scan script" "FAIL" "Fichier manquant"

[ -f "$PROJECT_ROOT/devsecops/fix-vulnerabilities.sh" ] && \
    print_check "Vulnerability fix script" "PASS" "Fichier présent" || \
    print_check "Vulnerability fix script" "FAIL" "Fichier manquant"

# Pipeline GitHub
[ -f "$PROJECT_ROOT/.github/workflows/devsecops-scan.yml" ] && \
    print_check "GitHub Actions Pipeline" "PASS" "Fichier présent" || \
    print_check "GitHub Actions Pipeline" "FAIL" "Fichier manquant"

# Documentation
[ -f "$PROJECT_ROOT/doc/DEVSECOPS_GUIDE.md" ] && \
    print_check "DevSecOps Guide" "PASS" "Fichier présent" || \
    print_check "DevSecOps Guide" "FAIL" "Fichier manquant"

[ -f "$PROJECT_ROOT/devsecops/README.md" ] && \
    print_check "DevSecOps README" "PASS" "Fichier présent" || \
    print_check "DevSecOps README" "FAIL" "Fichier manquant"

echo ""

# ============= PERMISSIONS DES SCRIPTS =============
echo -e "${BLUE}Permissions des Scripts${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for script in "$PROJECT_ROOT/devsecops"/*.sh; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            print_check "$(basename $script) - exécutable" "PASS"
        else
            print_check "$(basename $script) - exécutable" "FAIL" "Script non exécutable"
        fi
    fi
done

echo ""

# ============= OUTILS SYSTÈME =============
echo -e "${BLUE}Outils Système${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Docker
if command -v docker &> /dev/null; then
    version=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')
    print_check "Docker" "PASS" "Version: $version"
else
    print_check "Docker" "FAIL" "Non installé"
fi

# Docker Compose
if command -v docker-compose &> /dev/null; then
    version=$(docker-compose --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')
    print_check "Docker Compose" "PASS" "Version: $version"
else
    print_check "Docker Compose" "FAIL" "Non installé"
fi

# Maven
if command -v mvn &> /dev/null; then
    version=$(mvn --version 2>/dev/null | head -1 | cut -d' ' -f3)
    print_check "Maven" "PASS" "Version: $version"
else
    print_check "Maven" "FAIL" "Non installé"
fi

# Node.js
if command -v node &> /dev/null; then
    version=$(node --version 2>/dev/null)
    print_check "Node.js" "PASS" "Version: $version"
else
    print_check "Node.js" "FAIL" "Non installé"
fi

# npm
if command -v npm &> /dev/null; then
    version=$(npm --version 2>/dev/null)
    print_check "npm" "PASS" "Version: $version"
else
    print_check "npm" "FAIL" "Non installé"
fi

# Trivy
if command -v trivy &> /dev/null; then
    version=$(trivy version 2>/dev/null | grep -oP '(?<=Version : )[0-9.]+' | head -1 || echo "unknown")
    print_check "Trivy" "PASS" "Installé (Version: $version)"
else
    print_check "Trivy" "FAIL" "Non installé - exécuter: bash devsecops/install-trivy.sh"
fi

echo ""

# ============= SERVICES EN COURS D'EXÉCUTION =============
echo -e "${BLUE}Services en Cours d'Exécution${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# SonarQube
if curl -s -m 5 http://localhost:9000 &> /dev/null; then
    print_check "SonarQube Server" "PASS" "http://localhost:9000 accessible"
else
    print_check "SonarQube Server" "FAIL" "Non accessible - démarrer: cd sonarqube && docker-compose up -d"
fi

# SonarQube Database
if docker ps --filter "name=sonarqube_db" --filter "status=running" --quiet | grep -q .; then
    print_check "SonarQube Database" "PASS" "Conteneur actif"
else
    print_check "SonarQube Database" "FAIL" "Conteneur inactif"
fi

echo ""

# ============= CONTENU DES FICHIERS =============
echo -e "${BLUE}Validation du Contenu des Fichiers${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Vérifier SonarQube docker-compose
if grep -q "sonarqube:10.3-community" "$PROJECT_ROOT/sonarqube/docker-compose.yml" 2>/dev/null; then
    print_check "SonarQube version" "PASS" "10.3-community configuré"
else
    print_check "SonarQube version" "FAIL" "Configuration incomplète"
fi

# Vérifier les services dans GitHub Actions
if grep -q "sonarqube-analysis" "$PROJECT_ROOT/.github/workflows/devsecops-scan.yml" 2>/dev/null; then
    print_check "GitHub Actions - SonarQube Job" "PASS" "Configuré"
else
    print_check "GitHub Actions - SonarQube Job" "FAIL" "Manquant"
fi

if grep -q "dependency-check" "$PROJECT_ROOT/.github/workflows/devsecops-scan.yml" 2>/dev/null; then
    print_check "GitHub Actions - Dependency Check Job" "PASS" "Configuré"
else
    print_check "GitHub Actions - Dependency Check Job" "FAIL" "Manquant"
fi

if grep -q "trivy-scan-docker" "$PROJECT_ROOT/.github/workflows/devsecops-scan.yml" 2>/dev/null; then
    print_check "GitHub Actions - Trivy Job" "PASS" "Configuré"
else
    print_check "GitHub Actions - Trivy Job" "FAIL" "Manquant"
fi

echo ""

# ============= RÉSUMÉ =============
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

total=$((checks_passed + checks_failed))
pass_percent=$((checks_passed * 100 / total))

echo -e "Tests passés   : ${GREEN}$checks_passed${NC}/$total"
echo -e "Tests échoués  : ${RED}$checks_failed${NC}/$total"
echo -e "Réussite      : ${BLUE}$pass_percent%${NC}"

echo ""

if [ $checks_failed -eq 0 ]; then
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ✓ Tous les composants sont correctement configurés    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║      ⚠ Certains composants nécessitent de l'attention      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Actions recommandées :${NC}"
    [ ! -f "$PROJECT_ROOT/sonarqube/docker-compose.yml" ] && echo "  - Vérifier les fichiers SonarQube"
    ! command -v docker &> /dev/null && echo "  - Installer Docker"
    ! command -v mvn &> /dev/null && echo "  - Installer Maven"
    ! command -v trivy &> /dev/null && echo "  - Exécuter: bash devsecops/install-trivy.sh"
    ! curl -s -m 5 http://localhost:9000 &> /dev/null && echo "  - Démarrer SonarQube: cd sonarqube && docker-compose up -d"
    exit 1
fi
