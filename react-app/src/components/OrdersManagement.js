import React, { useState, useEffect } from 'react';
import {
  Box, Table, TableBody, TableCell, TableContainer, TableHead,
  TableRow, Paper, IconButton, MenuItem, Select, CircularProgress,
  Alert, FormControl, InputLabel
} from '@mui/material';
import { Delete as DeleteIcon } from '@mui/icons-material';
import { orderService } from '../services/orderService';

const OrdersManagement = ({ isAdmin }) => {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filterStatus, setFilterStatus] = useState('ALL');

  useEffect(() => {
    loadOrders();
  }, []);

  const loadOrders = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await orderService.getAllOrders();
      setOrders(Array.isArray(data) ? data : []);
    } catch (err) {
      setError(err.response?.data?.message || 'Erreur de chargement');
      setOrders([]);
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (orderId, newStatus) => {
    try {
      await orderService.updateOrderStatus(orderId, newStatus);
      loadOrders();
    } catch (err) {
      setError(err.response?.data?.message || 'Erreur lors de la modification');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Êtes-vous sûr de vouloir supprimer cette commande ?')) {
      try {
        await orderService.deleteOrder(id);
        loadOrders();
      } catch (err) {
        setError(err.response?.data?.message || 'Erreur lors de la suppression');
      }
    }
  };

  const filteredOrders = filterStatus === 'ALL'
    ? orders
    : orders.filter(o => o.status === filterStatus);

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', p: 4 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Box sx={{ mb: 3 }}>
        <FormControl sx={{ minWidth: 200 }}>
          <InputLabel>Filtrer par statut</InputLabel>
          <Select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            label="Filtrer par statut"
          >
            <MenuItem value="ALL">Tous</MenuItem>
            <MenuItem value="PENDING">En attente</MenuItem>
            <MenuItem value="PROCESSING">En cours</MenuItem>
            <MenuItem value="COMPLETED">Complété</MenuItem>
            <MenuItem value="CANCELLED">Annulé</MenuItem>
          </Select>
        </FormControl>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell><strong>ID</strong></TableCell>
              <TableCell><strong>Client</strong></TableCell>
              <TableCell><strong>Produit</strong></TableCell>
              <TableCell align="right"><strong>Quantité</strong></TableCell>
              <TableCell align="right"><strong>Prix Total</strong></TableCell>
              <TableCell><strong>Statut</strong></TableCell>
              <TableCell><strong>Date</strong></TableCell>
              {isAdmin && <TableCell align="center"><strong>Actions</strong></TableCell>}
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredOrders.map((order) => (
              <TableRow key={order.id} hover>
                <TableCell>{order.id}</TableCell>
                <TableCell>{order.customerUsername}</TableCell>
                <TableCell>{order.productName}</TableCell>
                <TableCell align="right">{order.quantity}</TableCell>
                <TableCell align="right">
                  <strong>{order.totalPrice ? order.totalPrice.toFixed(2) : '0.00'} MAD</strong>
                </TableCell>
                <TableCell>
                  <Select
                    value={order.status}
                    onChange={(e) => handleStatusChange(order.id, e.target.value)}
                    size="small"
                    sx={{ minWidth: 130 }}
                  >
                    <MenuItem value="PENDING">En attente</MenuItem>
                    <MenuItem value="PROCESSING">En cours</MenuItem>
                    <MenuItem value="COMPLETED">Complété</MenuItem>
                    <MenuItem value="CANCELLED">Annulé</MenuItem>
                  </Select>
                </TableCell>
                <TableCell>
                  {new Date(order.orderDate).toLocaleDateString('fr-FR')}
                </TableCell>
                {isAdmin && (
                  <TableCell align="center">
                    <IconButton
                      color="error"
                      onClick={() => handleDelete(order.id)}
                    >
                      <DeleteIcon />
                    </IconButton>
                  </TableCell>
                )}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {filteredOrders.length === 0 && (
        <Box sx={{ textAlign: 'center', mt: 4 }}>
          <Alert severity="info">
            Aucune commande trouvée
          </Alert>
        </Box>
      )}
    </Box>
  );
};

export default OrdersManagement;
