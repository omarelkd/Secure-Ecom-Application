# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

# Copier les fichiers package
COPY package.json package-lock.json ./

# Installer les dépendances
RUN npm ci

# Copier le code source
COPY . .

# Variables d'environnement pour le build (peuvent être overridées)
ARG REACT_APP_KEYCLOAK_URL=http://keycloak:8080
ARG REACT_APP_KEYCLOAK_REALM=microservices-realm
ARG REACT_APP_KEYCLOAK_CLIENT_ID=react-client
ARG REACT_APP_API_URL=/api

ENV REACT_APP_KEYCLOAK_URL=$REACT_APP_KEYCLOAK_URL
ENV REACT_APP_KEYCLOAK_REALM=$REACT_APP_KEYCLOAK_REALM
ENV REACT_APP_KEYCLOAK_CLIENT_ID=$REACT_APP_KEYCLOAK_CLIENT_ID
ENV REACT_APP_API_URL=$REACT_APP_API_URL

# Construire l'application
RUN npm run build

# Stage 2: Runtime avec Nginx
FROM nginx:alpine

# Copier la configuration Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copier les fichiers construits
COPY --from=builder /app/build /usr/share/nginx/html

# Exposer le port
EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:3000 || exit 1

# Lancer Nginx
CMD ["nginx", "-g", "daemon off;"]
