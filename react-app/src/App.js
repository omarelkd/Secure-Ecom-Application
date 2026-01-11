import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider, createTheme, CssBaseline, Box } from '@mui/material';
import Navbar from './components/Navbar';
import ProtectedRoute from './components/ProtectedRoute';
import Home from './pages/Home';
import Products from './pages/Products';
import MyOrders from './pages/MyOrders';
import AdminPanel from './pages/AdminPanel';
import ManagerPanel from './pages/ManagerPanel';

const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

function App({ keycloak }) {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <Box sx={{ minHeight: '100vh', bgcolor: 'background.default' }}>
          <Navbar keycloak={keycloak} />
          <Routes>
            <Route path="/" element={<Home keycloak={keycloak} />} />
            
            <Route 
              path="/products" 
              element={
                <ProtectedRoute roles={['USER', 'ADMIN', 'MANAGER']} keycloak={keycloak}>
                  <Products />
                </ProtectedRoute>
              } 
            />
            
            <Route 
              path="/my-orders" 
              element={
                <ProtectedRoute roles={['USER', 'ADMIN', 'MANAGER']} keycloak={keycloak}>
                  <MyOrders />
                </ProtectedRoute>
              } 
            />
            
            <Route 
              path="/admin" 
              element={
                <ProtectedRoute roles={['ADMIN']} keycloak={keycloak}>
                  <AdminPanel />
                </ProtectedRoute>
              } 
            />
            
            <Route 
              path="/manager" 
              element={
                <ProtectedRoute roles={['MANAGER']} keycloak={keycloak}>
                  <ManagerPanel />
                </ProtectedRoute>
              } 
            />
          </Routes>
        </Box>
      </Router>
    </ThemeProvider>
  );
}

export default App;
