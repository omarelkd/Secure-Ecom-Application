import React from 'react';
import { Box, Typography, Button } from '@mui/material';
import { Lock as LockIcon } from '@mui/icons-material';

const ProtectedRoute = ({ children, roles, keycloak }) => {
  if (!keycloak?.authenticated) {
    return (
      <Box sx={{ textAlign: 'center', mt: 8 }}>
        <LockIcon sx={{ fontSize: 80, color: 'text.secondary', mb: 2 }} />
        <Typography variant="h4" gutterBottom>
          Authentification Requise
        </Typography>
        <Typography color="text.secondary" sx={{ mb: 3 }}>
          Vous devez être connecté pour accéder à cette page.
        </Typography>
        <Button variant="contained" onClick={() => keycloak.login()}>
          Se Connecter
        </Button>
      </Box>
    );
  }

  // Vérifier si l'utilisateur a au moins un des rôles requis
  // Keycloak stocke les rôles avec le préfixe ROLE_ (ex: ROLE_ADMIN)
  const hasRole = roles.some(role => {
    // Si le rôle fourni n'a pas le préfixe, l'ajouter
    const roleToCheck = role.startsWith('ROLE_') ? role : `ROLE_${role}`;
    return keycloak.hasRealmRole(roleToCheck);
  });

  if (!hasRole) {
    return (
      <Box sx={{ textAlign: 'center', mt: 8 }}>
        <LockIcon sx={{ fontSize: 80, color: 'error.main', mb: 2 }} />
        <Typography variant="h4" gutterBottom>
          Accès Refusé
        </Typography>
        <Typography color="text.secondary" sx={{ mb: 3 }}>
          Vous n'avez pas les permissions nécessaires pour accéder à cette page.
        </Typography>
        <Button variant="contained" onClick={() => window.history.back()}>
          Retour
        </Button>
      </Box>
    );
  }

  return children;
};

export default ProtectedRoute;
