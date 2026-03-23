// Self-hosted environment configuration
// Update API_URL to match your deployment domain
export const clientId = 'GENERATE_AFTER_SETUP';
export const clientSecret = 'GENERATE_AFTER_SETUP';

const API_URL = 'http://100.81.210.49:8090/';
export const environment = {
  production: true,
  baseUrl: `${API_URL}v2`,
  ssoBaseUrl: API_URL,
  storyTellingUrl: '',
  googleMapKey: '',  // Add your own Google Maps API key
  authUrl: 'http://100.81.210.49:8090',
  adminUrl: 'http://100.81.210.49:8090/admin',
  totpToken: 'CHANGE_THIS_BASE32_SECRET',
  sentryDsn: '',
  sentryEnv: 'selfhosted',
  clientId,
  clientSecret,
  authenticateUrl: `http://100.81.210.49:8090/sso-authorization?redirect_uri=http://100.81.210.49:8090/&client_id=${clientId}&response_type=code&client_secret=${clientSecret}&app_type=Trace`,
};
