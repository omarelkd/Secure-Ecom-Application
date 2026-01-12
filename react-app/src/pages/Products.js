import React, { useState, useEffect } from 'react';
import {
  Container, Grid, Card, CardContent, CardActions, Typography,
  Button, TextField, Box, Chip, CircularProgress, Alert,
  InputAdornment, FormControlLabel, Switch
} from '@mui/material';
import {
  Search as SearchIcon,
  ShoppingCart as CartIcon,
  CheckCircle as AvailableIcon
} from '@mui/icons-material';
import { productService } from '../services/productService';
import OrderFormModal from '../components/OrderFormModal';
import { canManageProducts } from '../utils/roleUtils';

const Products = () => {
  const keycloak = window.keycloak;
  const [products, setProducts] = useState([]);
  const [filteredProducts, setFilteredProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [availableOnly, setAvailableOnly] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [modalOpen, setModalOpen] = useState(false);

  useEffect(() => {
    loadProducts();
  }, []);

  useEffect(() => {
    filterProducts();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchTerm, availableOnly, products]);

  const loadProducts = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await productService.getAllProducts();
      setProducts(data);
    } catch (err) {
      setError(err.response?.data?.message || 'Erreur lors du chargement des produits');
    } finally {
      setLoading(false);
    }
  };

  const filterProducts = () => {
    let filtered = [...products];

    if (searchTerm) {
      filtered = filtered.filter(p =>
        p.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.description.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    if (availableOnly) {
      filtered = filtered.filter(p => p.quantity > 0);
    }

    setFilteredProducts(filtered);
  };

  const handleOrderClick = (product) => {
    setSelectedProduct(product);
    setModalOpen(true);
  };

  const handleOrderSuccess = () => {
    setModalOpen(false);
    setSelectedProduct(null);
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
        🛍️ Catalogue Produits
      </Typography>

      <Box sx={{ mb: 4, display: 'flex', gap: 2, alignItems: 'center' }}>
        <TextField
          fullWidth
          placeholder="Rechercher un produit..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon />
              </InputAdornment>
            ),
          }}
        />
        <FormControlLabel
          control={
            <Switch
              checked={availableOnly}
              onChange={(e) => setAvailableOnly(e.target.checked)}
              color="primary"
            />
          }
          label="Disponibles uniquement"
        />
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
        {filteredProducts.length} produit(s) trouvé(s)
      </Typography>

      <Grid container spacing={3}>
        {filteredProducts.map((product) => (
          <Grid item xs={12} sm={6} md={4} key={product.id}>
            <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
              <CardContent sx={{ flexGrow: 1 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', mb: 1 }}>
                  <Typography variant="h6" component="div">
                    {product.name}
                  </Typography>
                  {product.quantity > 0 ? (
                    <Chip
                      icon={<AvailableIcon />}
                      label="Disponible"
                      color="success"
                      size="small"
                    />
                  ) : (
                    <Chip
                      label="Rupture"
                      color="error"
                      size="small"
                    />
                  )}
                </Box>

                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  {product.description}
                </Typography>

                <Typography variant="h5" color="primary">
                  {product.price ? product.price.toFixed(2) : '0.00'} MAD
                </Typography>
              </CardContent>

              <CardActions>
                <Button
                  fullWidth
                  variant="contained"
                  startIcon={<CartIcon />}
                  onClick={() => handleOrderClick(product)}
                  disabled={product.quantity <= 0}
                >
                  Commander
                </Button>
              </CardActions>
            </Card>
          </Grid>
        ))}
      </Grid>

      {filteredProducts.length === 0 && !loading && (
        <Box sx={{ textAlign: 'center', mt: 8 }}>
          <Typography variant="h6" color="text.secondary">
            Aucun produit trouvé
          </Typography>
        </Box>
      )}

      <OrderFormModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        product={selectedProduct}
        onSuccess={handleOrderSuccess}
      />
    </Container>
  );
};

export default Products;
