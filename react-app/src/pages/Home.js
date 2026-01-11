import React from 'react';
import { Box, Container, Typography, Button, Grid, Card, CardContent } from '@mui/material';
import { useNavigate } from 'react-router-dom';
import {
  ShoppingCart as ShoppingCartIcon,
  Receipt as ReceiptIcon,
  AdminPanelSettings as AdminIcon,
  Security as SecurityIcon
} from '@mui/icons-material';

const Home = ({ keycloak }) => {
  const navigate = useNavigate();
  const username = keycloak?.tokenParsed?.preferred_username || 'User';
  const roles = keycloak?.realmAccess?.roles || [];

  return (
    <Container maxWidth="lg">
      <Box sx={{ textAlign: 'center', my: 6 }}>
        <Typography variant="h2" gutterBottom>
          Bienvenue, {username} ! 👋
        </Typography>
        <Typography variant="h5" color="text.secondary" sx={{ mb: 4 }}>
          Application E-Commerce Sécurisée avec OAuth2 & Keycloak
        </Typography>

        <Box sx={{ display: 'flex', justifyContent: 'center', gap: 2, mb: 6 }}>
          <Button
            variant="contained"
            size="large"
            startIcon={<ShoppingCartIcon />}
            onClick={() => navigate('/products')}
          >
            Voir les Produits
          </Button>
          <Button
            variant="outlined"
            size="large"
            startIcon={<ReceiptIcon />}
            onClick={() => navigate('/my-orders')}
          >
            Mes Commandes
          </Button>
        </Box>

        <Grid container spacing={3} sx={{ mt: 4 }}>
          <Grid item xs={12} md={4}>
            <Card sx={{ height: '100%', bgcolor: 'primary.light', color: 'white' }}>
              <CardContent>
                <SecurityIcon sx={{ fontSize: 60, mb: 2 }} />
                <Typography variant="h6" gutterBottom>
                  Sécurité OAuth2
                </Typography>
                <Typography variant="body2">
                  Authentification et autorisation via Keycloak avec PKCE
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={4}>
            <Card sx={{ height: '100%', bgcolor: 'secondary.light', color: 'white' }}>
              <CardContent>
                <ShoppingCartIcon sx={{ fontSize: 60, mb: 2 }} />
                <Typography variant="h6" gutterBottom>
                  Gestion Produits
                </Typography>
                <Typography variant="body2">
                  Catalogue complet avec recherche et filtres
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} md={4}>
            <Card sx={{ height: '100%', bgcolor: 'success.light', color: 'white' }}>
              <CardContent>
                <ReceiptIcon sx={{ fontSize: 60, mb: 2 }} />
                <Typography variant="h6" gutterBottom>
                  Suivi Commandes
                </Typography>
                <Typography variant="body2">
                  Historique et statuts en temps réel
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        <Box sx={{ mt: 6, p: 3, bgcolor: 'background.paper', borderRadius: 2, boxShadow: 1 }}>
          <Typography variant="h6" gutterBottom sx={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 1 }}>
            <AdminIcon /> Vos Rôles
          </Typography>
          <Box sx={{ display: 'flex', gap: 1, justifyContent: 'center', flexWrap: 'wrap' }}>
            {roles.map(role => (
              <Typography
                key={role}
                variant="body2"
                sx={{
                  px: 2,
                  py: 0.5,
                  bgcolor: role === 'ADMIN' ? 'error.main' : role === 'MANAGER' ? 'warning.main' : 'info.main',
                  color: 'white',
                  borderRadius: 1
                }}
              >
                {role}
              </Typography>
            ))}
          </Box>
        </Box>
      </Box>
    </Container>
  );
};

export default Home;
