import React from 'react';
import { Container, Typography, Alert } from '@mui/material';
import OrdersManagement from '../components/OrdersManagement';

const ManagerPanel = () => {
  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Typography variant="h3" gutterBottom>
        👔 Panel Manager
      </Typography>

      <Alert severity="info" sx={{ mb: 3 }}>
        Vous pouvez gérer les statuts des commandes (MANAGER)
      </Alert>

      <OrdersManagement isAdmin={false} />
    </Container>
  );
};

export default ManagerPanel;
