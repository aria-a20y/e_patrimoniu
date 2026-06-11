/// Configurări globale pentru aplicația e-Patrimoniu
class AppConfig {
  static const String appName = 'e-Patrimoniu';
  static const String appSubtitle = 'Evidența bunurilor imobiliare';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'suport@epatrimoniu.ro';

  /// Colecții Firestore
  static const String colUsers        = 'users';
  static const String colProperties   = 'properties';
  static const String colDocuments    = 'documents';
  static const String colScanTasks    = 'scan_tasks';
  static const String colTransactions = 'transactions';
  static const String colContracts    = 'contracts';
  static const String colContractChanges = 'contract_changes';
  static const String colAuctions     = 'auctions';
  static const String colParticipants = 'auction_participants';
  static const String colBids         = 'bids';
  static const String colChatSessions = 'chat_sessions';
  static const String colChatMessages = 'chat_messages';
  static const String colAuditLog     = 'audit_log';

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
