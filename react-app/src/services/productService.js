import axios from 'axios';

const API_URL = 'http://localhost:8085/products';

const getAuthHeader = () => {
  const token = window.keycloak?.token;
  return token ? { Authorization: `Bearer ${token}` } : {};
};

export const productService = {
  getAllProducts: async () => {
    const response = await axios.get(API_URL, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  getProductById: async (id) => {
    const response = await axios.get(`${API_URL}/${id}`, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  searchProducts: async (name) => {
    const response = await axios.get(`${API_URL}/search`, {
      params: { name },
      headers: getAuthHeader()
    });
    return response.data;
  },

  getAvailableProducts: async () => {
    const response = await axios.get(`${API_URL}/available`, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  createProduct: async (product) => {
    const response = await axios.post(API_URL, product, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  updateProduct: async (id, product) => {
    const response = await axios.put(`${API_URL}/${id}`, product, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  deleteProduct: async (id) => {
    await axios.delete(`${API_URL}/${id}`, {
      headers: getAuthHeader()
    });
  }
};
