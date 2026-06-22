/// Configurări globale pentru aplicația e-Patrimoniu
class AppConfig {
  static const String appName = 'e-Patrimoniu';
  static const String appSubtitle = 'Evidența bunurilor imobiliare';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'suport@epatrimoniu.ro';

  /// Roluri utilizatori
  static const String roleAdmin     = 'administrator';
  static const String roleFunctionar = 'functionar';
  static const String roleExtern    = 'extern';

  /// Feature flags
  static const bool enableAI = true;
  static const bool enablePushNotifications = false;

  /// Backend API URL
  /// - Local dev: suprascrie cu --dart-define=BACKEND_URL=http://localhost:10000
  /// - Productie: https://e-patrimoniu-api.onrender.com (default)
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://e-patrimoniu-api.onrender.com',
  );

  /// Timeout rețea
  static const Duration connectionTimeout = Duration(seconds: 30);
}
