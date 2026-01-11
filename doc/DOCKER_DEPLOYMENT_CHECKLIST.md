# 📋 Checklist de Déploiement Docker

## ✅ Pré-Déploiement

### Prérequis Système
- [ ] Docker 20.10+ installé
- [ ] Docker Compose 2.0+ installé
- [ ] Au moins 4 GB de RAM disponible
- [ ] Au moins 5 GB d'espace disque
- [ ] Ports 3000, 8080, 8081, 8082, 8085, 5432 libres

### Vérifications des Fichiers
- [ ] Tous les Dockerfiles présents
- [ ] `docker-compose.yml` valide
- [ ] `.env` configuré (ou `.env.docker`)
- [ ] `nginx.conf` présent dans react-app
- [ ] Scripts shell exécutables
- [ ] `realm-export.json` présent dans keycloak/

### Configuration
- [ ] Variables d'environnement configurées
- [ ] Ports TCP ouverts sur le pare-feu
- [ ] DNS fonctionnant correctement
- [ ] Connectivité réseau vérifée

## 🚀 Déploiement

### Phase 1: Construction
```bash
# [ ] Vérifier les Dockerfiles
docker-compose config

# [ ] Construire les images
./build-docker-images.sh

# [ ] Vérifier les images
docker images | grep oauth2-oidc
```

### Phase 2: Initialisation
```bash
# [ ] Initialiser les volumes
./init-volumes.sh

# [ ] Vérifier les volumes
docker volume ls | grep oauth2-oidc
```

### Phase 3: Démarrage
```bash
# [ ] Démarrer les services
./docker-start.sh

# [ ] Vérifier que tous les conteneurs sont up
docker-compose ps

# [ ] Attendre 30-40 secondes pour que tout soit stable
sleep 40
```

## ✅ Post-Déploiement

### Tests Critiques
```bash
# [ ] Frontend accessible
curl -I http://localhost:3000

# [ ] Gateway accessible
curl -I http://localhost:8085

# [ ] Product Service accessible
curl http://localhost:8085/products

# [ ] Order Service accessible
curl http://localhost:8085/orders

# [ ] Keycloak accessible
curl -I http://localhost:8080

# [ ] PostgreSQL accessible
docker-compose exec postgres-keycloak pg_isready -U keycloak
```

### Tests de Fonctionnalité
- [ ] Se connecter à Keycloak (http://localhost:8080)
  - [ ] Admin: admin/admin
  - [ ] Realm: microservices-realm

- [ ] Accéder au frontend (http://localhost:3000)
  - [ ] Page d'accueil se charge
  - [ ] Bouton "Se connecter" visible
  
- [ ] Authentification OAuth2
  - [ ] Redirection vers Keycloak
  - [ ] Login fonctionnant
  - [ ] Retour au frontend
  
- [ ] Accès aux produits
  - [ ] Page /products accessible
  - [ ] Liste des produits affichée
  - [ ] Rôles affichés correctement
  
- [ ] Accès aux commandes
  - [ ] Page /my-orders accessible
  - [ ] Historique des commandes affiché

### Tests de Sécurité
- [ ] Endpoints protégés retournent 401 sans token
- [ ] Admin panel accessible seulement avec rôle ADMIN
- [ ] Manager panel accessible seulement avec rôle MANAGER
- [ ] CORS fonctionnant correctement
- [ ] Authentification JWT validée

### Tests de Logs
```bash
# [ ] Pas d'erreurs critiques
docker-compose logs | grep ERROR

# [ ] Services en bonne santé
docker-compose ps | grep -i healthy
```

### Tests de Performance
```bash
# [ ] Tester le script de test
./test-docker.sh

# [ ] Pas de fuite mémoire
docker stats --no-stream

# [ ] Utilisation CPU raisonnable
docker stats
```

## 🔧 Production Checklist

### Configuration Sécurité
- [ ] Mots de passe changés
  - [ ] KEYCLOAK_ADMIN_PASSWORD
  - [ ] POSTGRES_PASSWORD
  
- [ ] HTTPS/TLS configuré
  - [ ] Certificats valides
  - [ ] Keycloak HOSTNAME configuré
  - [ ] KC_HOSTNAME_PROTOCOL=https
  
- [ ] Utilisateurs non-root vérifiés
  - [ ] Dockerfile multi-stage check
  - [ ] USER appuser in production
  
- [ ] Ressources limitées
  - [ ] Memory limits set
  - [ ] CPU limits set
  - [ ] Disk space monitored

### Monitoring
- [ ] Logs centralisés (ELK/Splunk)
- [ ] Monitoring des performances (Prometheus/Grafana)
- [ ] Alertes configurées
- [ ] Backups automaisés
- [ ] Disaster recovery plan

### Déploiement Production
```bash
# [ ] Utiliser docker-compose.prod.yml
docker-compose -f docker-compose.prod.yml up -d

# [ ] Vérifier les healthchecks
docker-compose ps

# [ ] Monitorer les logs
docker-compose logs -f
```

## 🧪 Tests de Charge

### Préparation
- [ ] Tool de stress test installé (Apache Bench, hey, etc.)
- [ ] Baseline défini
- [ ] Conditions de test documentées

### Exécution
```bash
# [ ] Test simple (100 requêtes)
ab -n 100 -c 10 http://localhost:8085/products

# [ ] Test de concurrence (1000 requêtes)
ab -n 1000 -c 100 http://localhost:8085/products

# [ ] Test d'endurance (10 minutes)
hey -z 10m http://localhost:8085/products
```

## 🔄 Maintenance Continue

### Quotidien
- [ ] Vérifier la santé des conteneurs
- [ ] Monitorer la consommation ressource
- [ ] Vérifier les logs d'erreurs

### Hebdomadaire
- [ ] Nettoyer les logs
- [ ] Vérifier les mises à jour
- [ ] Tester les sauvegardes

### Mensuel
- [ ] Audit de sécurité
- [ ] Mise à jour des dépendances
- [ ] Revision des performances
- [ ] Testdisaster recovery

## 📊 Commandes de Diagnostic

```bash
# Statut complet
docker-compose ps
docker-compose logs -f

# Ressources utilisées
docker stats

# Réseau
docker network inspect oauth2-oidc_microservices_network

# Volumes
docker volume ls
docker volume inspect oauth2-oidc_postgres_keycloak_data

# Images
docker images | grep oauth2-oidc

# Conteneurs running
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

## ✨ Succès!

Tous les points vérifiés? Félicitations! 🎉
La plateforme est prête pour:
- ✅ Développement
- ✅ Testing
- ✅ Staging
- ✅ Production

En cas de problème, consultez [DOCKER_DEPLOYMENT_GUIDE.md](DOCKER_DEPLOYMENT_GUIDE.md)
