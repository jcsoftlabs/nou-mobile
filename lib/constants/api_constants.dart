class ApiConstants {
  // Base URL du backend nou-backend
  static const String baseUrl = 'https://nou-backend-production.up.railway.app';
  
  // Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String podcasts = '/podcasts';
  static const String formations = '/formations';
  static const String referrals = '/referrals';
  static const String points = '/points';
  static const String membres = '/membres';
  static const String news = '/news';
  static const String annonces = '/annonces';
  
  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
}
