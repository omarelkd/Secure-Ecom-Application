import apiClient from './apiClient';

const API_URL = '/orders';

export const orderService = {
  getMyOrders: async () => {
    const response = await apiClient.get(API_URL);
    return response.data;
  },

  getOrderById: async (id) => {
    const response = await apiClient.get(`${API_URL}/${id}`);
    return response.data;
  },

  getAllOrders: async () => {
    const response = await apiClient.get(`${API_URL}/admin`);
    return response.data;
  },

  getOrdersByStatus: async (status) => {
    const response = await apiClient.get(`${API_URL}/status/${status}`);
    return response.data;
  },

  createOrder: async (order) => {
    const response = await apiClient.post(API_URL, order);
    return response.data;
  },

  updateOrderStatus: async (id, status) => {
    const response = await apiClient.put(`${API_URL}/${id}/status`, null, {
      params: { status }
    });
    return response.data;
  },

  deleteOrder: async (id) => {
    await apiClient.delete(`${API_URL}/${id}`);
  }
};

export default orderService;
