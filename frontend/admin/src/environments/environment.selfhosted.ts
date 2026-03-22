// Self-hosted environment configuration
// Update API_URL to match your deployment domain
export const clientId = 'GENERATE_AFTER_SETUP';
export const clientSecret = 'GENERATE_AFTER_SETUP';

const API_URL = 'http://localhost/';
export const environment = {
  production: true,
  baseUrl: `${API_URL}v2`,
  ssoBaseUrl: API_URL,
  startYear: 2020,
  gMapKey: '',  // Add your own Google Maps API key
  googleMapKey: '',
  traceUrl: 'http://localhost',
  authUrl: 'http://localhost',
  totpToken: 'CHANGE_THIS_BASE32_SECRET',
  sentryDsn: '',
  sentryEnv: 'selfhosted',
  clientId,
  clientSecret,
  authenticateUrl: `http://localhost/sso-authorization?redirect_uri=http://localhost/admin/&client_id=${clientId}&response_type=code&client_secret=${clientSecret}`,
};
