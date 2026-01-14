import apiClient from './apiClient';

const API_URL = '/products';

export const productService = {
  getAllProducts: async () => {
    const response = await apiClient.get(API_URL);
    return response.data;
  },

  getProductById: async (id) => {
    const response = await apiClient.get(`${API_URL}/${id}`);
    return response.data;
  },

  searchProducts: async (name) => {
    const response = await apiClient.get(`${API_URL}/search`, {
      params: { name }
    });
    return response.data;
  },

  getAvailableProducts: async () => {
    const response = await apiClient.get(`${API_URL}/available`);
    return response.data;
  },

  createProduct: async (product) => {
    const response = await apiClient.post(API_URL, product);
    return response.data;
  },

  updateProduct: async (id, product) => {
    const response = await apiClient.put(`${API_URL}/${id}`, product);
    return response.data;
  },

  deleteProduct: async (id) => {
    await apiClient.delete(`${API_URL}/${id}`);
  }
};

export default productService;
