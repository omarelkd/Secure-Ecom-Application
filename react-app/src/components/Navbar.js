import React from 'react';
import { AppBar, Toolbar, Typography, Button, Box, Avatar } from '@mui/material';
import { Link } from 'react-router-dom';
import {
  Home as HomeIcon,
  ShoppingCart as ShoppingCartIcon,
  Receipt as ReceiptIcon,
  AdminPanelSettings as AdminIcon,
  ManageAccounts as ManagerIcon,
  Logout as LogoutIcon
} from '@mui/icons-material';

const Navbar = ({ keycloak }) => {
  const handleLogout = () => {
    keycloak.logout();
  };

  const hasRole = (role) => {
    return keycloak?.hasRealmRole(role);
  };

  const username = keycloak?.tokenParsed?.preferred_username || 'User';

  return (
    <AppBar position="sticky" sx={{ mb: 3 }}>
      <Toolbar>
        <Typography variant="h6" component="div" sx={{ flexGrow: 0, mr: 4 }}>
          🛒 E-Commerce
        </Typography>

        <Box sx={{ flexGrow: 1, display: 'flex', gap: 2 }}>
          <Button
            color="inherit"
            startIcon={<HomeIcon />}
            component={Link}
            to="/"
          >
            Accueil
          </Button>
          <Button
            color="inherit"
            startIcon={<ShoppingCartIcon />}
            component={Link}
            to="/products"
          >
            Produits
          </Button>
          <Button
            color="inherit"
            startIcon={<ReceiptIcon />}
            component={Link}
            to="/my-orders"
          >
            Mes Commandes
          </Button>

          {hasRole('ADMIN') && (
            <Button
              color="inherit"
              startIcon={<AdminIcon />}
              component={Link}
              to="/admin"
              sx={{ bgcolor: 'rgba(255,255,255,0.1)' }}
            >
              Panel Admin
            </Button>
          )}

          {hasRole('MANAGER') && (
            <Button
              color="inherit"
              startIcon={<ManagerIcon />}
              component={Link}
              to="/manager"
              sx={{ bgcolor: 'rgba(255,255,255,0.1)' }}
            >
              Panel Manager
            </Button>
          )}
        </Box>

        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Avatar sx={{ width: 32, height: 32, bgcolor: 'secondary.main' }}>
            {username.charAt(0).toUpperCase()}
          </Avatar>
          <Typography variant="body2">{username}</Typography>
          <Button
            color="inherit"
            startIcon={<LogoutIcon />}
            onClick={handleLogout}
            variant="outlined"
          >
            Déconnexion
          </Button>
        </Box>
      </Toolbar>
    </AppBar>
  );
};

export default Navbar;
