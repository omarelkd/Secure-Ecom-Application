/**
 * Utilitaires pour vérifier les rôles utilisateur
 */

export const hasRole = (keycloak, role) => {
  if (!keycloak || !keycloak.authenticated) {
    return false;
  }
  
  // Keycloak stocke les rôles avec le préfixe ROLE_
  const roleToCheck = role.startsWith('ROLE_') ? role : `ROLE_${role}`;
  return keycloak.hasRealmRole(roleToCheck);
};

export const hasAnyRole = (keycloak, roles) => {
  return roles.some(role => hasRole(keycloak, role));
};

export const isAdmin = (keycloak) => {
  return hasRole(keycloak, 'ADMIN');
};

export const isManager = (keycloak) => {
  return hasRole(keycloak, 'MANAGER');
};

export const isUser = (keycloak) => {
  return hasRole(keycloak, 'USER');
};

export const canManageProducts = (keycloak) => {
  return isAdmin(keycloak);
};

export const canManageOrders = (keycloak) => {
  return hasAnyRole(keycloak, ['ADMIN', 'MANAGER']);
};
