import React, { useState } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Button, TextField, Typography, Box, Alert
} from '@mui/material';
import { orderService } from '../services/orderService';

const OrderFormModal = ({ open, onClose, product, onSuccess }) => {
  const [quantity, setQuantity] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleSubmit = async () => {
    try {
      setLoading(true);
      setError(null);

      const orderData = {
        productName: product.name,
        quantity: parseInt(quantity),
        totalPrice: parseFloat((product.price * quantity).toFixed(2))
      };

      await orderService.createOrder(orderData);
      onSuccess();
      setQuantity(1);
    } catch (err) {
      setError(err.response?.data?.message || 'Erreur lors de la création de la commande');
    } finally {
      setLoading(false);
    }
  };

  const totalPrice = product ? (product.price * quantity).toFixed(2) : 0;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>
        Nouvelle Commande
      </DialogTitle>
      <DialogContent>
        {product && (
          <Box sx={{ mt: 2 }}>
            <Typography variant="h6" gutterBottom>
              {product.name}
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
              {product.description}
            </Typography>
            <Typography variant="body1" sx={{ mb: 3 }}>
              Prix unitaire: <strong>{product.price.toFixed(2)} MAD</strong>
            </Typography>

            <TextField
              fullWidth
              type="number"
              label="Quantité"
              value={quantity}
              onChange={(e) => setQuantity(Math.max(1, parseInt(e.target.value) || 1))}
              inputProps={{ min: 1 }}
              sx={{ mb: 3 }}
            />

            <Box sx={{ p: 2, bgcolor: 'primary.light', borderRadius: 1 }}>
              <Typography variant="h6" color="white">
                Total: {totalPrice} MAD
              </Typography>
            </Box>

            {error && (
              <Alert severity="error" sx={{ mt: 2 }}>
                {error}
              </Alert>
            )}
          </Box>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={loading}>
          Annuler
        </Button>
        <Button
          onClick={handleSubmit}
          variant="contained"
          disabled={loading || !quantity || quantity < 1}
        >
          {loading ? 'Création...' : 'Confirmer la commande'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default OrderFormModal;
