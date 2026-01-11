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

  const hasRole = roles.some(role => keycloak.hasRealmRole(role));

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
