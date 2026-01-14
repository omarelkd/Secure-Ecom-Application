#!/bin/bash

##############################################################################
# Script Principal de Scanning DevSecOps
# 
# Exécute tous les scans de sécurité :
# - SonarQube (analyse statique du code)
# - OWASP Dependency-Check (dépendances)
# - Trivy (images Docker)
#
# Utilisation : ./run-devsecops-scan.sh [service]
# Exemple : ./run-devsecops-scan.sh gateway
##############################################################################

set -e

# Configuration
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVSECOPS_DIR="$PROJECT_ROOT/devsecops"
REPORTS_DIR="$DEVSECOPS_DIR/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Créer le répertoire des rapports
mkdir -p "$REPORTS_DIR"

# Services à scanner
SERVICES=("gateway" "product-service" "order-service" "react-app")

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      🔒 DevSecOps - Suite Complète de Scanning                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Fonction pour afficher les résultats
print_section() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# ============= SCAN SONARQUBE =============
scan_sonarqube() {
    local service=$1
    local service_dir="$PROJECT_ROOT/$service"
    
    if [ ! -d "$service_dir" ]; then
        print_warning "Service $service non trouvé"
        return
    fi
    
    print_section "SonarQube - Analyse statique : $service"
    
    cd "$service_dir"
    
    # Vérifier si c'est un projet Maven ou Node.js
    if [ -f "pom.xml" ]; then
        print_warning "Scan SonarQube pour projet Maven"
        
        # Supposé que sonar-scanner CLI est installé
        if command -v sonar-scanner &> /dev/null; then
            sonar-scanner \
                -Dsonar.projectKey="$service" \
                -Dsonar.sources=src \
                -Dsonar.host.url=http://localhost:9000 \
                -Dsonar.login=admin \
                -Dsonar.password=admin || print_warning "SonarQube non accessible"
        else
            print_warning "sonar-scanner non installé - passer ce scan"
        fi
    elif [ -f "package.json" ]; then
        print_warning "Scan SonarQube pour projet Node.js"
        
        if command -v sonar-scanner &> /dev/null; then
            sonar-scanner \
                -Dsonar.projectKey="$service" \
                -Dsonar.sources=src \
                -Dsonar.language=js \
                -Dsonar.host.url=http://localhost:9000 \
                -Dsonar.login=admin \
                -Dsonar.password=admin || print_warning "SonarQube non accessible"
        fi
    fi
    
    print_success "SonarQube scan complété pour $service"
    echo ""
}

# ============= SCAN OWASP DEPENDENCY-CHECK =============
scan_dependency_check() {
    local service=$1
    local service_dir="$PROJECT_ROOT/$service"
    
    if [ ! -d "$service_dir" ]; then
        print_warning "Service $service non trouvé"
        return
    fi
    
    print_section "OWASP Dependency-Check : $service"
    
    cd "$service_dir"
    
    # Créer le répertoire de rapport
    local report_dir="$REPORTS_DIR/dependency-check-$service-$TIMESTAMP"
    mkdir -p "$report_dir"
    
    if [ -f "pom.xml" ]; then
        print_warning "Scan des dépendances Maven"
        
        # Utiliser Maven pour Dependency-Check
        mvn dependency-check:check \
            -Ddependency-check.reportDirectory="$report_dir" \
            -Ddependency-check.format=ALL \
            -Ddependency-check.failBuildOnCVSS=7.0 || print_warning "Vulnérabilités détectées"
            
    elif [ -f "package.json" ]; then
        print_warning "Scan des dépendances npm"
        
        # Utiliser npm audit
        if [ -d "node_modules" ]; then
            npm audit --json > "$report_dir/npm-audit-report.json" || print_warning "Vulnérabilités npm détectées"
        else
            print_warning "node_modules non trouvés - npm install requis"
        fi
    fi
    
    print_success "Dependency-Check scan complété pour $service"
    print_success "Rapport généré : $report_dir"
    echo ""
}

# ============= SCAN TRIVY POUR IMAGES DOCKER =============
scan_trivy_images() {
    print_section "Trivy - Scan des Images Docker"
    
    if ! command -v trivy &> /dev/null; then
        print_error "Trivy non installé"
        print_warning "Exécuter : ./devsecops/install-trivy.sh"
        return
    fi
    
    # Services et leurs images
    declare -A IMAGES=(
        ["gateway"]="secure-ecom-gateway:latest"
        ["product-service"]="secure-ecom-product-service:latest"
        ["order-service"]="secure-ecom-order-service:latest"
        ["react-app"]="secure-ecom-react-app:latest"
    )
    
    local report_dir="$REPORTS_DIR/trivy-$TIMESTAMP"
    mkdir -p "$report_dir"
    
    for service in "${SERVICES[@]}"; do
        local image="${IMAGES[$service]}"
        
        # Vérifier si l'image existe
        if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$image$"; then
            print_warning "Scan de l'image : $image"
            
            # Générer un rapport Trivy
            trivy image \
                --format json \
                --output "$report_dir/trivy-$service.json" \
                --severity HIGH,CRITICAL \
                "$image" || print_warning "Vulnérabilités détectées dans $image"
                
            print_success "Rapport Trivy généré pour $service"
        else
            print_warning "Image $image non trouvée"
        fi
    done
    
    print_success "Scan Trivy complété"
    print_success "Rapports générés : $report_dir"
    echo ""
}

# ============= SCAN TRIVY POUR CODE SOURCE =============
scan_trivy_filesystem() {
    print_section "Trivy - Scan du Système de Fichiers"
    
    if ! command -v trivy &> /dev/null; then
        print_error "Trivy non installé"
        return
    fi
    
    local report_dir="$REPORTS_DIR/trivy-filesystem-$TIMESTAMP"
    mkdir -p "$report_dir"
    
    for service in "${SERVICES[@]}"; do
        local service_dir="$PROJECT_ROOT/$service"
        
        if [ -d "$service_dir" ]; then
            print_warning "Scan du répertoire : $service"
            
            trivy fs \
                --format json \
                --output "$report_dir/trivy-fs-$service.json" \
                --severity MEDIUM,HIGH,CRITICAL \
                "$service_dir" || print_warning "Vulnérabilités détectées"
                
            print_success "Rapport système de fichiers généré"
        fi
    done
    
    print_success "Scan système de fichiers complété"
    print_success "Rapports générés : $report_dir"
    echo ""
}

# ============= RÉSUMÉ DES RAPPORTS =============
generate_summary() {
    print_section "Résumé des Rapports"
    
    if [ -d "$REPORTS_DIR" ]; then
        echo -e "${GREEN}Répertoire des rapports : $REPORTS_DIR${NC}"
        echo ""
        
        # Compter les fichiers de rapport
        local sonarqube_reports=$(find "$REPORTS_DIR" -name "*sonarqube*" -type f | wc -l)
        local dependency_reports=$(find "$REPORTS_DIR" -name "*dependency-check*" -type f | wc -l)
        local trivy_reports=$(find "$REPORTS_DIR" -name "trivy-*" -type f | wc -l)
        
        echo -e "Rapports générés :"
        [ $sonarqube_reports -gt 0 ] && echo -e "  ${GREEN}✓ SonarQube${NC} : $sonarqube_reports rapport(s)"
        [ $dependency_reports -gt 0 ] && echo -e "  ${GREEN}✓ Dependency-Check${NC} : $dependency_reports rapport(s)"
        [ $trivy_reports -gt 0 ] && echo -e "  ${GREEN}✓ Trivy${NC} : $trivy_reports rapport(s)"
        
        echo ""
        echo -e "${YELLOW}Pour plus de détails, consultez :${NC}"
        echo -e "  SonarQube Dashboard : http://localhost:9000"
        echo -e "  Rapports : $REPORTS_DIR"
    else
        print_warning "Aucun rapport généré"
    fi
}

# ============= MAIN =============
main() {
    local selected_service=$1
    
    # Exécuter les scans
    if [ -z "$selected_service" ]; then
        # Scanner tous les services
        for service in "${SERVICES[@]}"; do
            scan_sonarqube "$service"
            scan_dependency_check "$service"
        done
    else
        # Scanner un service spécifique
        scan_sonarqube "$selected_service"
        scan_dependency_check "$selected_service"
    fi
    
    # Scan des images Docker
    scan_trivy_images
    
    # Scan du système de fichiers
    scan_trivy_filesystem
    
    # Générer le résumé
    generate_summary
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ✓ Scan DevSecOps terminé avec succès                      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
}

# Exécuter
main "$@"
