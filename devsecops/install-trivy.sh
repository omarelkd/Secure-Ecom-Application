#!/bin/bash

##############################################################################
# Script d'installation de Trivy
# Trivy est un scanner de vulnérabilités pour conteneurs et autres artefacts
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            🔒 Installation de Trivy                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Vérifier si Trivy est déjà installé
if command -v trivy &> /dev/null; then
    TRIVY_VERSION=$(trivy --version | head -n1 | awk '{print $2}')
    echo -e "${GREEN}✓ Trivy est déjà installé (version $TRIVY_VERSION)${NC}"
    echo ""
    echo -e "${YELLOW}Voulez-vous réinstaller ? (y/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo -e "${GREEN}Installation annulée${NC}"
        exit 0
    fi
fi

echo -e "${YELLOW}Détection du système d'exploitation...${NC}"

# Détecter l'OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)
        echo -e "${GREEN}✓ Linux détecté${NC}"
        
        # Détecter la distribution
        if [ -f /etc/debian_version ]; then
            echo -e "${BLUE}Installation via apt (Debian/Ubuntu)...${NC}"
            sudo apt-get update -qq
            sudo apt-get install -y wget apt-transport-https gnupg lsb-release
            
            # Méthode moderne pour ajouter la clé GPG (apt-key est obsolète)
            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
            # Utiliser le dépôt générique au lieu de $(lsb_release -sc) pour Kali
            echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list
            sudo apt-get update -qq
            sudo apt-get install -y trivy
            
        elif [ -f /etc/redhat-release ]; then
            echo -e "${BLUE}Installation via yum/dnf (RedHat/CentOS/Fedora)...${NC}"
            RELEASE_VERSION=$(grep -Po '(?<=VERSION_ID=")[0-9]' /etc/os-release | head -n1)
            cat << EOF | sudo tee /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/\$releasever/\$basearch/
gpgcheck=0
enabled=1
EOF
            sudo yum -y update
            sudo yum -y install trivy
            
        elif [ -f /etc/arch-release ]; then
            echo -e "${BLUE}Installation via yay (Arch Linux)...${NC}"
            yay -S trivy
            
        else
            echo -e "${YELLOW}Distribution non reconnue, installation depuis le binaire...${NC}"
            install_from_binary
        fi
        ;;
        
    Darwin*)
        echo -e "${GREEN}✓ macOS détecté${NC}"
        if command -v brew &> /dev/null; then
            echo -e "${BLUE}Installation via Homebrew...${NC}"
            brew install trivy
        else
            echo -e "${RED}Homebrew n'est pas installé${NC}"
            echo -e "${YELLOW}Installation depuis le binaire...${NC}"
            install_from_binary
        fi
        ;;
        
    *)
        echo -e "${RED}Système d'exploitation non supporté: ${OS}${NC}"
        echo -e "${YELLOW}Tentative d'installation depuis le binaire...${NC}"
        install_from_binary
        ;;
esac

# Fonction d'installation depuis le binaire
install_from_binary() {
    echo -e "${BLUE}Téléchargement de Trivy...${NC}"
    
    TRIVY_VERSION="0.48.3"
    ARCH="$(uname -m)"
    
    case "${ARCH}" in
        x86_64)
            ARCH="64bit"
            ;;
        aarch64|arm64)
            ARCH="ARM64"
            ;;
        *)
            echo -e "${RED}Architecture non supportée: ${ARCH}${NC}"
            exit 1
            ;;
    esac
    
    if [ "$(uname -s)" = "Linux" ]; then
        OS_TYPE="Linux"
    else
        OS_TYPE="macOS"
    fi
    
    DOWNLOAD_URL="https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_${OS_TYPE}-${ARCH}.tar.gz"
    
    echo -e "${YELLOW}Téléchargement depuis: ${DOWNLOAD_URL}${NC}"
    
    cd /tmp
    wget -q "${DOWNLOAD_URL}" -O trivy.tar.gz
    tar zxf trivy.tar.gz
    sudo mv trivy /usr/local/bin/
    sudo chmod +x /usr/local/bin/trivy
    rm trivy.tar.gz
    
    echo -e "${GREEN}✓ Trivy installé dans /usr/local/bin/trivy${NC}"
}

echo ""
echo -e "${BLUE}Vérification de l'installation...${NC}"

if command -v trivy &> /dev/null; then
    TRIVY_VERSION=$(trivy --version | head -n1)
    echo -e "${GREEN}✓ Trivy installé avec succès !${NC}"
    echo -e "${GREEN}  Version: ${TRIVY_VERSION}${NC}"
    echo ""
    
    echo -e "${BLUE}Mise à jour de la base de données de vulnérabilités...${NC}"
    trivy image --download-db-only
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          ✓ Installation terminée avec succès !            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Commandes utiles :${NC}"
    echo -e "  ${BLUE}trivy image <image>:tag${NC}      - Scanner une image Docker"
    echo -e "  ${BLUE}trivy fs .${NC}                   - Scanner le système de fichiers"
    echo -e "  ${BLUE}trivy config .${NC}               - Scanner les fichiers de config"
    echo ""
else
    echo -e "${RED}✗ Échec de l'installation${NC}"
    echo -e "${YELLOW}Essayez d'installer manuellement depuis:${NC}"
    echo -e "  https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
    exit 1
fi
