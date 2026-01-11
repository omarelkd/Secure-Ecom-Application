import axios from 'axios';

const API_URL = 'http://localhost:8085/orders';

const getAuthHeader = () => {
  const token = window.keycloak?.token;
  return token ? { Authorization: `Bearer ${token}` } : {};
};

export const orderService = {
  getMyOrders: async () => {
    const response = await axios.get(API_URL, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  getOrderById: async (id) => {
    const response = await axios.get(`${API_URL}/${id}`, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  getAllOrders: async () => {
    const response = await axios.get(`${API_URL}/admin`, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  getOrdersByStatus: async (status) => {
    const response = await axios.get(`${API_URL}/status/${status}`, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  createOrder: async (order) => {
    const response = await axios.post(API_URL, order, {
      headers: getAuthHeader()
    });
    return response.data;
  },

  updateOrderStatus: async (id, status) => {
    const response = await axios.put(`${API_URL}/${id}/status`, null, {
      params: { status },
      headers: getAuthHeader()
    });
    return response.data;
  },

  deleteOrder: async (id) => {
    await axios.delete(`${API_URL}/${id}`, {
      headers: getAuthHeader()
    });
  }
};
