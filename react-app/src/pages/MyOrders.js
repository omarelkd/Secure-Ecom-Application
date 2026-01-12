import React, { useState, useEffect } from 'react';
import {
  Container, Typography, Box, CircularProgress, Alert,
  Table, TableBody, TableCell, TableContainer, TableHead,
  TableRow, Paper, Chip
} from '@mui/material';
import { orderService } from '../services/orderService';

const getStatusColor = (status) => {
  switch (status) {
    case 'PENDING':
      return 'warning';
    case 'COMPLETED':
      return 'success';
    case 'CANCELLED':
      return 'error';
    case 'PROCESSING':
      return 'info';
    default:
      return 'default';
  }
};

const getStatusLabel = (status) => {
  switch (status) {
    case 'PENDING':
      return 'En attente';
    case 'COMPLETED':
      return 'Complété';
    case 'CANCELLED':
      return 'Annulé';
    case 'PROCESSING':
      return 'En cours';
    default:
      return status;
  }
};

const MyOrders = () => {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadOrders();
  }, []);

  const loadOrders = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await orderService.getMyOrders();
      setOrders(data);
    } catch (err) {
      setError(err.response?.data?.message || 'Erreur lors du chargement des commandes');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', mt: 8 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ py: 4 }}>
      <Typography variant="h3" gutterBottom>
        📋 Mes Commandes
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {orders.length === 0 ? (
        <Box sx={{ textAlign: 'center', mt: 8 }}>
          <Typography variant="h6" color="text.secondary">
            Vous n'avez pas encore de commandes
          </Typography>
        </Box>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell><strong>ID</strong></TableCell>
                <TableCell><strong>Produit</strong></TableCell>
                <TableCell align="right"><strong>Quantité</strong></TableCell>
                <TableCell align="right"><strong>Prix Total</strong></TableCell>
                <TableCell><strong>Statut</strong></TableCell>
                <TableCell><strong>Date</strong></TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {Array.isArray(orders) && orders.map((order) => (
                <TableRow key={order.id} hover>
                  <TableCell>{order.id}</TableCell>
                  <TableCell>
                    <Typography variant="body1">{order.productName}</Typography>
                  </TableCell>
                  <TableCell align="right">{order.quantity}</TableCell>
                  <TableCell align="right">
                    <strong>{order.totalPrice ? order.totalPrice.toFixed(2) : '0.00'} MAD</strong>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={getStatusLabel(order.status)}
                      color={getStatusColor(order.status)}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    {new Date(order.orderDate).toLocaleDateString('fr-FR', {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit'
                    })}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}
    </Container>
  );
};

export default MyOrders;
