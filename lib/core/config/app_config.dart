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
  /// - Local:   'http://localhost:10000'
  /// - Render:  setat din --dart-define=BACKEND_URL=https://e-patrimoniu-api.onrender.com
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:10000',
  );

  /// Timeout rețea
  static const Duration connectionTimeout = Duration(seconds: 30);
}
