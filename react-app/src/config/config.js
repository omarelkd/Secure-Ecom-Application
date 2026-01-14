// Configuration centrale de l'application
const config = {
  keycloak: {
    url: process.env.REACT_APP_KEYCLOAK_URL || 'http://localhost:8080',
    realm: process.env.REACT_APP_KEYCLOAK_REALM || 'microservices-realm',
    clientId: process.env.REACT_APP_KEYCLOAK_CLIENT_ID || 'react-client',
  },
  api: {
    baseUrl: process.env.REACT_APP_API_URL || 'http://localhost:8085',
  },
};

export default config;
