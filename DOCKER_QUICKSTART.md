# 🐳 Docker - Guide de Démarrage Rapide

## 🚀 Démarrer en 2 Commandes

```bash
# 1. Rendre les scripts exécutables
chmod +x docker-start.sh docker-stop.sh build-docker-images.sh test-docker.sh

# 2. Lancer la plateforme complète
./docker-start.sh
```

**C'est tout!** 🎉 Votre plateforme démarre en 30 secondes.

## 🌐 Accès Immédiat

| Service | URL | Identifiants |
|---------|-----|--------------|
| **Frontend** | http://localhost:3000 | - |
| **API Gateway** | http://localhost:8085 | - |
| **Keycloak** | http://localhost:8080/admin | admin / admin |

## 🧪 Tester Rapidement

```bash
# Test complet de la plateforme
./test-docker.sh

# Voir les logs en direct
docker-compose logs -f

# Accéder à un conteneur
docker-compose exec product-service /bin/sh

# Redémarrer un service
docker-compose restart gateway
```

## 🛑 Arrêter

```bash
./docker-stop.sh
```

## 📁 Structure Docker

```
.
├── gateway/
│   ├── Dockerfile                 # Multi-stage build
│   └── .dockerignore             # Fichiers à ignorer
├── product-service/
│   ├── Dockerfile
│   └── .dockerignore
├── order-service/
│   ├── Dockerfile
│   └── .dockerignore
├── react-app/
│   ├── Dockerfile
│   ├── nginx.conf               # Config Nginx
│   └── .dockerignore
├── docker-compose.yml            # Dev config
├── docker-compose.prod.yml       # Prod config
├── .env.docker                  # Variables Docker
├── .env.example                 # Exemple de config
├── build-docker-images.sh       # Build images
├── docker-start.sh              # Start all
├── docker-stop.sh               # Stop all
├── test-docker.sh               # Run tests
├── init-volumes.sh              # Init volumes
└── DOCKER_DEPLOYMENT_GUIDE.md   # Documentation
```

## 📊 Architecture

```
Internet
    ↓
┌─────────────────────────────────┐
│  React Frontend (Nginx)         │
│  Port: 3000                     │
└────────────┬────────────────────┘
             ↓
┌─────────────────────────────────┐
│  API Gateway                    │
│  Port: 8085                     │
└────────┬──────────────┬─────────┘
         ↓              ↓
    ┌────────┐      ┌────────┐
    │Product │      │ Order  │
    │Service │      │Service │
    │8081    │      │8082    │
    └────────┘      └────────┘
         ↓              ↓
    ┌──────────────────────────┐
    │  Keycloak Auth Server    │
    │  Port: 8080              │
    └──────────┬───────────────┘
               ↓
         ┌──────────────┐
         │  PostgreSQL  │
         │  Port: 5432  │
         └──────────────┘
```

## 🔧 Commandes Principales

### Gestion des Conteneurs
```bash
# Voir le statut
docker-compose ps

# Voir les logs
docker-compose logs -f [service]

# Redémarrer
docker-compose restart [service]

# Arrêter
docker-compose down

# Arrêter et supprimer les volumes
docker-compose down -v
```

### Débuggage
```bash
# Accéder au shell d'un service
docker-compose exec product-service /bin/sh

# Voir l'environnement
docker-compose exec gateway env

# Vérifier les logs
docker-compose logs keycloak

# Monitorer les ressources
docker stats
```

## 🚨 Troubleshooting Rapide

### "Port already in use"
```bash
# Vérifier quel processus utilise le port
lsof -i :8080
lsof -i :3000

# Arrêter et nettoyer
docker-compose down -v
docker system prune -a
```

### Services ne démarrent pas
```bash
# Voir les logs détaillés
docker-compose logs -f

# Redémarrer tout
docker-compose restart

# Attendre 30 secondes et retester
sleep 30 && curl http://localhost:8085/products
```

### Erreur de connexion entre services
```bash
# Vérifier le réseau
docker network inspect oauth2-oidc_microservices_network

# Ping un service depuis un autre
docker-compose exec gateway ping product-service
```

## 📈 Production

Pour déployer en production:

```bash
# Utiliser la config prod
docker-compose -f docker-compose.prod.yml up -d

# Avec variables d'environnement
export POSTGRES_PASSWORD=secure_password
export KEYCLOAK_ADMIN_PASSWORD=secure_password
docker-compose -f docker-compose.prod.yml up -d
```

Voir [DOCKER_DEPLOYMENT_GUIDE.md](DOCKER_DEPLOYMENT_GUIDE.md) pour les détails.

## 📚 Documentation Complète

- **[DOCKER_DEPLOYMENT_GUIDE.md](DOCKER_DEPLOYMENT_GUIDE.md)** - Guide complet
- **[DOCKER_DEPLOYMENT_CHECKLIST.md](DOCKER_DEPLOYMENT_CHECKLIST.md)** - Checklist
- **[DOCKERIZATION_SUMMARY.md](DOCKERIZATION_SUMMARY.md)** - Résumé technique

## 🎯 Étapes Suivantes

1. ✅ Plateforme en Docker fonctionnelle
2. 📦 Ajouter MongoDB pour les données
3. 🔴 Ajouter Redis pour le cache
4. 📊 Ajouter Monitoring (Prometheus/Grafana)
5. 📝 Ajouter Logging (ELK Stack)
6. 🚀 Déployer sur Kubernetes
7. 🌐 Configurer un domaine
8. 🔒 Ajouter HTTPS avec Let's Encrypt

## ❓ Questions?

Consultez la [documentation complète](DOCKER_DEPLOYMENT_GUIDE.md) ou les logs:

```bash
docker-compose logs -f [service]
```

---

**Happy Containerizing!** 🐳✨
