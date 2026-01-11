# 🐳 Guide de Déploiement Docker

## 📋 Prérequis

- Docker 20.10+
- Docker Compose 2.0+
- Au moins 4 GB de RAM disponible
- 5 GB d'espace disque

## 🚀 Démarrage Rapide

### Option 1: Utiliser le script de démarrage

```bash
# Rendre le script exécutable
chmod +x docker-start.sh

# Démarrer tous les services
./docker-start.sh
```

### Option 2: Commandes Docker Compose manuelles

```bash
# Construire les images
docker-compose build

# Démarrer les services
docker-compose up -d

# Voir les logs
docker-compose logs -f
```

## 🌐 Accès aux Services

| Service | URL | Identifiants |
|---------|-----|--------------|
| **Frontend React** | http://localhost:3000 | - |
| **API Gateway** | http://localhost:8085 | - |
| **Product Service** | http://localhost:8081 | - |
| **Order Service** | http://localhost:8082 | - |
| **Keycloak Admin** | http://localhost:8080/admin | admin / admin |

## 📊 Gestion des Conteneurs

### Voir le statut des services
```bash
docker-compose ps
```

### Voir les logs en temps réel
```bash
docker-compose logs -f

# Logs d'un service spécifique
docker-compose logs -f product-service
docker-compose logs -f gateway
```

### Redémarrer un service
```bash
docker-compose restart product-service
```

### Arrêter tous les services
```bash
docker-compose down
```

### Arrêter et supprimer les volumes
```bash
docker-compose down -v
```

## 🔨 Construction des Images

### Construire une image spécifique
```bash
docker build -t oauth2-oidc/product-service:latest ./product-service
```

### Construire toutes les images
```bash
./build-docker-images.sh
```

## 🧪 Tests

### Tester Product Service
```bash
curl -v http://localhost:8085/products
```

### Tester Order Service
```bash
curl -v http://localhost:8085/orders
```

### Tester Keycloak
```bash
curl -v http://localhost:8080/realms/microservices-realm
```

## 🔍 Debugging

### Accéder à un conteneur
```bash
docker-compose exec product-service /bin/sh
docker-compose exec gateway /bin/sh
docker-compose exec frontend /bin/sh
```

### Voir les variables d'environnement
```bash
docker-compose exec gateway env
```

### Vérifier la connectivité réseau
```bash
docker network inspect oauth2-oidc_microservices_network
```

## 📈 Scaling

### Augmenter le nombre d'instances
```bash
docker-compose up -d --scale product-service=3
```

## 🗑️ Nettoyage

### Arrêter et supprimer les services
```bash
./docker-stop.sh
```

### Supprimer les images Docker
```bash
docker rmi oauth2-oidc/product-service:latest
docker rmi oauth2-oidc/order-service:latest
docker rmi oauth2-oidc/gateway:latest
docker rmi oauth2-oidc/frontend:latest
```

### Nettoyer les ressources inutilisées
```bash
docker system prune -a
```

## 🔐 Configuration de Sécurité pour Production

Pour un déploiement en production, modifiez le `docker-compose.yml`:

```yaml
# Remplacer les mots de passe par défaut
environment:
  KEYCLOAK_ADMIN: your-secure-admin
  KEYCLOAK_ADMIN_PASSWORD: your-very-secure-password
  POSTGRES_PASSWORD: your-very-secure-db-password
```

## 🌍 Déploiement sur Docker Swarm/Kubernetes

### Pour Docker Swarm
```bash
docker swarm init
docker stack deploy -c docker-compose.yml oauth2-app
```

### Pour Kubernetes
```bash
# Convertir docker-compose en Kubernetes
kompose convert -f docker-compose.yml

# Déployer
kubectl apply -f *.yaml
```

## 📝 Notes Importantes

1. Les bases de données H2 sont en mémoire (pour développement)
2. Pour la production, utiliser PostgreSQL/MySQL
3. Les certificats SSL doivent être configurés
4. Les volumes doivent être persévérés pour la production
5. Configurer les variables d'environnement sensibles via `.env`

## 🆘 Résolution de Problèmes

### Les services ne démarrent pas
```bash
# Vérifier les logs
docker-compose logs

# Vérifier les ports en utilisation
lsof -i :8080  # Keycloak
lsof -i :8081  # Product Service
```

### Erreur de connectivité entre services
```bash
# Vérifier le réseau
docker network ls
docker network inspect oauth2-oidc_microservices_network

# Les noms de hosts doivent correspondre aux noms des services
```

### Problèmes d'authentification Keycloak
```bash
# Vérifier que le realm est importé
docker-compose logs keycloak | grep -i realm

# Réinitialiser les bases de données
docker-compose down -v
docker-compose up -d
```

## 📚 Ressources Supplémentaires

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Spring Boot Docker Guide](https://spring.io/guides/gs/spring-boot-docker/)
