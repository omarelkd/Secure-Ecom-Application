#!/bin/bash

# DevSecOps Quick Commands Reference
# Copy and paste any command to execute it

# ============================================================================
# 🚀 GETTING STARTED (Setup)
# ============================================================================

# Install Trivy scanner
bash devsecops/install-trivy.sh

# Start SonarQube
cd sonarqube && docker-compose up -d && cd ..

# Wait for SonarQube to be ready (about 30 seconds)
sleep 30

# Access SonarQube
echo "SonarQube is ready at: http://localhost:9000 (admin/admin)"

# ============================================================================
# 🔍 SCANNING (Analysis)
# ============================================================================

# Run all DevSecOps scans for all services
bash devsecops/run-devsecops-scan.sh

# Run scan for a specific service
bash devsecops/run-devsecops-scan.sh gateway
bash devsecops/run-devsecops-scan.sh product-service
bash devsecops/run-devsecops-scan.sh order-service
bash devsecops/run-devsecops-scan.sh react-app

# ============================================================================
# 🏥 HEALTH CHECK
# ============================================================================

# Verify all DevSecOps components are properly configured
bash devsecops/health-check.sh

# ============================================================================
# 🔧 VULNERABILITY CORRECTION
# ============================================================================

# Fix all vulnerabilities (all services)
bash devsecops/fix-vulnerabilities.sh

# Fix vulnerabilities for a specific service
bash devsecops/fix-vulnerabilities.sh gateway
bash devsecops/fix-vulnerabilities.sh product-service
bash devsecops/fix-vulnerabilities.sh order-service
bash devsecops/fix-vulnerabilities.sh react-app

# ============================================================================
# 📊 INDIVIDUAL TOOL COMMANDS
# ============================================================================

# --- SonarQube (Code Analysis) ---

# Start SonarQube server
cd sonarqube && docker-compose up -d && cd ..

# Stop SonarQube server
cd sonarqube && docker-compose down && cd ..

# View SonarQube logs
docker-compose -f sonarqube/docker-compose.yml logs -f sonarqube

# Reset SonarQube (clean database)
cd sonarqube && docker-compose down -v && docker-compose up -d && cd ..

# --- Dependency-Check (Maven) ---

# Manual Dependency-Check for a Maven service
cd gateway
mvn dependency-check:check
cd ..

# Maven Dependency Update Check
mvn versions:display-dependency-updates

# Maven Update all dependencies
mvn versions:use-latest-versions

# --- npm audit (Node.js) ---

# Check npm vulnerabilities for React app
cd react-app
npm audit
cd ..

# Fix npm vulnerabilities automatically
cd react-app
npm audit fix
cd ..

# Generate npm audit report in JSON
cd react-app
npm audit --json > ../devsecops/reports/npm-audit.json
cd ..

# --- Trivy (Container Security) ---

# Scan a Docker image
trivy image secure-ecom-gateway:latest

# Scan with JSON output
trivy image --format json --output trivy-report.json secure-ecom-gateway:latest

# Scan with SARIF output (GitHub Security)
trivy image --format sarif --output trivy-report.sarif secure-ecom-gateway:latest

# Scan only HIGH and CRITICAL vulnerabilities
trivy image --severity HIGH,CRITICAL secure-ecom-gateway:latest

# Scan a directory (filesystem)
trivy fs ./gateway

# Scan with specific severity filter
trivy fs --severity HIGH,CRITICAL ./product-service

# Get Trivy version
trivy version

# Update Trivy database
trivy image --download-db-only

# ============================================================================
# 🐳 DOCKER OPERATIONS
# ============================================================================

# Build Docker image for gateway
docker build -f gateway/Dockerfile -t secure-ecom-gateway:latest .

# Build all service images
docker build -f gateway/Dockerfile -t secure-ecom-gateway:latest .
docker build -f product-service/Dockerfile -t secure-ecom-product-service:latest .
docker build -f order-service/Dockerfile -t secure-ecom-order-service:latest .
docker build -f react-app/Dockerfile -t secure-ecom-react-app:latest .

# Scan built image
docker build -f gateway/Dockerfile -t my-gateway:latest . && trivy image my-gateway:latest

# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f gateway

# ============================================================================
# 📈 VIEWING REPORTS
# ============================================================================

# List all generated reports
ls -la devsecops/reports/

# View dependency-check reports
ls -la devsecops/reports/dependency-check-*

# View Trivy reports
ls -la devsecops/reports/trivy-*

# Open HTML report (if available)
# On Linux
xdg-open devsecops/reports/dependency-check-gateway-*/dependency-check-report.html

# On macOS
open devsecops/reports/dependency-check-gateway-*/dependency-check-report.html

# View JSON report
cat devsecops/reports/trivy-*.json

# ============================================================================
# 📚 DOCUMENTATION
# ============================================================================

# Open quick start guide
cat devsecops/README.md

# Open complete guide
cat doc/DEVSECOPS_GUIDE.md

# Open implementation summary
cat devsecops/IMPLEMENTATION_SUMMARY.md

# Open index (navigation)
cat devsecops/INDEX.md

# Open integration status
cat DEVSECOPS_INTEGRATION.md

# ============================================================================
# 🔍 TROUBLESHOOTING
# ============================================================================

# Check if Docker is running
docker ps

# Check if Docker images are available
docker images

# Check running containers
docker-compose ps

# Stop and remove all containers and volumes
docker-compose down -v

# Remove dangling images
docker image prune -f

# Check port availability
netstat -tuln | grep 9000  # SonarQube
netstat -tuln | grep 5433  # SonarQube DB

# View SonarQube environment
docker-compose -f sonarqube/docker-compose.yml config

# Check system resources
free -h
df -h

# ============================================================================
# 🔐 SECURITY OPERATIONS
# ============================================================================

# View false positives suppression file
cat dependency-check-suppression.xml

# Edit false positives (add a new suppression)
nano dependency-check-suppression.xml

# View SonarQube Quality Gates
# Access: http://localhost:9000/admin/quality_gates

# View SonarQube Security Hotspots
# Access: http://localhost:9000/project/issues?id=<project-key>&types=SECURITY_HOTSPOT

# Export scan results
mkdir -p security-export
cp devsecops/reports/* security-export/
tar -czf security-reports-backup.tar.gz security-export/

# ============================================================================
# 🔄 CONTINUOUS INTEGRATION
# ============================================================================

# Check GitHub Actions status
# Access: https://github.com/[repo]/actions

# View workflow runs
gh run list

# View latest workflow run
gh run view

# Manually trigger workflow
gh workflow run devsecops-scan.yml

# View workflow results
gh workflow view devsecops-scan.yml

# ============================================================================
# 📊 METRICS & MONITORING
# ============================================================================

# Count vulnerabilities in code
grep -r "TODO security:" . --include="*.java" --include="*.js"

# Count security hotspots
echo "Visit SonarQube: http://localhost:9000/security_hotspots"

# Generate metrics report
echo "Date: $(date)" > metrics-report.txt
echo "Services Scanned:" >> metrics-report.txt
echo "- gateway" >> metrics-report.txt
echo "- product-service" >> metrics-report.txt
echo "- order-service" >> metrics-report.txt
echo "- react-app" >> metrics-report.txt

# ============================================================================
# 🧹 CLEANUP & MAINTENANCE
# ============================================================================

# Remove old reports (keep last 30 days)
find devsecops/reports -type f -mtime +30 -delete

# Clear vulnerability backup files (⚠️ Use with caution)
# rm -rf .vulnerability-backups

# Remove SonarQube containers and volumes (⚠️ Destructive)
# cd sonarqube && docker-compose down -v && cd ..

# Remove all Docker images (⚠️ Destructive)
# docker rmi -f $(docker images -q)

# ============================================================================
# 🆘 EMERGENCY COMMANDS
# ============================================================================

# Reset everything to clean state (⚠️ Destructive)
bash devsecops/reset-devsecops.sh  # Note: This script may need to be created

# Kill all containers
docker kill $(docker ps -q) 2>/dev/null

# Remove all stopped containers
docker container prune -f

# Force SonarQube restart
docker-compose -f sonarqube/docker-compose.yml restart

# Re-initialize SonarQube database (⚠️ Destructive)
cd sonarqube && docker-compose down -v && docker-compose up -d && cd ..

# ============================================================================
# 📋 USEFUL ALIASES (Add to ~/.bashrc or ~/.zshrc)
# ============================================================================

# Add these to your shell profile for quick access:

alias devsecops-scan="bash devsecops/run-devsecops-scan.sh"
alias devsecops-fix="bash devsecops/fix-vulnerabilities.sh"
alias devsecops-health="bash devsecops/health-check.sh"
alias sonarqube-start="cd sonarqube && docker-compose up -d && cd .."
alias sonarqube-stop="cd sonarqube && docker-compose down && cd .."
alias sonarqube-logs="docker-compose -f sonarqube/docker-compose.yml logs -f sonarqube"

# Usage:
# devsecops-scan
# devsecops-fix gateway
# devsecops-health
# sonarqube-start

# ============================================================================
# 📝 NOTES
# ============================================================================

# 1. Make sure all scripts are executable:
chmod +x devsecops/*.sh

# 2. Docker must be installed and running:
docker --version
docker-compose --version

# 3. For Maven projects, ensure Maven is installed:
mvn --version

# 4. For Node.js projects, ensure Node and npm are installed:
node --version
npm --version

# 5. Replace [repo] with your actual GitHub repository path

# ============================================================================
# 🚀 COMMON WORKFLOWS
# ============================================================================

# Workflow 1: First-time setup
echo "=== First-time Setup ==="
bash devsecops/install-trivy.sh
cd sonarqube && docker-compose up -d && cd ..
sleep 30
bash devsecops/health-check.sh

# Workflow 2: Complete security audit
echo "=== Complete Security Audit ==="
bash devsecops/run-devsecops-scan.sh
# Review results in SonarQube and reports/

# Workflow 3: Fix vulnerabilities
echo "=== Fix Vulnerabilities ==="
bash devsecops/fix-vulnerabilities.sh
# Commit changes and push

# Workflow 4: Continuous monitoring
echo "=== Continuous Monitoring ==="
# Check GitHub Actions results
# Review SonarQube dashboard
# Monitor dependency updates

# ============================================================================
# 🎯 QUICK START (Copy-Paste All)
# ============================================================================

# Run these 3 commands to get started:
#
# 1. Install tools and start SonarQube
bash devsecops/install-trivy.sh && cd sonarqube && docker-compose up -d && cd ..
#
# 2. Wait 30 seconds, then verify
sleep 30 && bash devsecops/health-check.sh
#
# 3. Run all scans
bash devsecops/run-devsecops-scan.sh

# ============================================================================

# End of Quick Commands Reference
# For more information, see:
# - devsecops/README.md
# - doc/DEVSECOPS_GUIDE.md
# - devsecops/INDEX.md
