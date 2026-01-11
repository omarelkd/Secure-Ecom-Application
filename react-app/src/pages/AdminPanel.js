import React, { useState } from 'react';
import {
  Container, Typography, Box, Tabs, Tab, Alert
} from '@mui/material';
import ProductsManagement from '../components/ProductsManagement';
import OrdersManagement from '../components/OrdersManagement';

const AdminPanel = () => {
  const [currentTab, setCurrentTab] = useState(0);

  const handleTabChange = (event, newValue) => {
    setCurrentTab(newValue);
  };

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Typography variant="h3" gutterBottom>
        🔧 Panel Administrateur
      </Typography>

      <Alert severity="info" sx={{ mb: 3 }}>
        Vous avez un accès complet à toutes les fonctionnalités (ADMIN)
      </Alert>

      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs value={currentTab} onChange={handleTabChange}>
          <Tab label="Gestion Produits" />
          <Tab label="Gestion Commandes" />
        </Tabs>
      </Box>

      {currentTab === 0 && <ProductsManagement />}
      {currentTab === 1 && <OrdersManagement isAdmin={true} />}
    </Container>
  );
};

export default AdminPanel;
