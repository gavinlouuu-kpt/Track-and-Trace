// Self-hosted environment configuration
// Update API_URL to match your deployment domain
export const clientId = 'GENERATE_AFTER_SETUP';
export const clientSecret = 'GENERATE_AFTER_SETUP';

const API_URL = 'http://100.81.210.49:8090/';
export const environment = {
  production: true,
  baseUrl: `${API_URL}v2`,
  ssoBaseUrl: API_URL,
  startYear: 2020,
  gMapKey: '',  // Add your own Google Maps API key
  googleMapKey: '',
  traceUrl: 'http://100.81.210.49:8090',
  authUrl: 'http://100.81.210.49:8090',
  totpToken: 'CHANGE_THIS_BASE32_SECRET',
  sentryDsn: '',
  sentryEnv: 'selfhosted',
  clientId,
  clientSecret,
  authenticateUrl: `http://100.81.210.49:8090/sso-authorization?redirect_uri=http://100.81.210.49:8090/admin/&client_id=${clientId}&response_type=code&client_secret=${clientSecret}`,
};
