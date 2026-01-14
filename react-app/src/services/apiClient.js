import axios from 'axios';
import config from '../config/config';

// Instance Axios configurée
const apiClient = axios.create({
  baseURL: config.api.baseUrl,
  timeout: 10000,
});

// Intercepteur de requête pour ajouter le token
apiClient.interceptors.request.use(
  async (config) => {
    const keycloak = window.keycloak;
    
    if (keycloak && keycloak.authenticated) {
      try {
        // Rafraîchir le token si nécessaire (5 secondes avant expiration)
        await keycloak.updateToken(5);
        config.headers.Authorization = `Bearer ${keycloak.token}`;
      } catch (error) {
        console.error('Failed to refresh token', error);
        // Si le rafraîchissement échoue, rediriger vers login
        keycloak.login();
      }
    }
    
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Intercepteur de réponse pour gérer les erreurs
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const keycloak = window.keycloak;
    
    // Si erreur 401 (non autorisé), rafraîchir le token ou rediriger
    if (error.response?.status === 401 && keycloak) {
      try {
        await keycloak.updateToken(-1); // Force refresh
        // Retry la requête originale
        error.config.headers.Authorization = `Bearer ${keycloak.token}`;
        return apiClient.request(error.config);
      } catch (refreshError) {
        // Token expiré, rediriger vers login
        keycloak.login();
      }
    }
    
    // Si erreur 403 (accès refusé)
    if (error.response?.status === 403) {
      console.error('Access denied:', error.response.data);
    }
    
    return Promise.reject(error);
  }
);

export default apiClient;
