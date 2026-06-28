import 'package:flutter/foundation.dart';
import '../models/audit/audit_log_model.dart';
import 'api_service.dart';

export '../models/audit/audit_log_model.dart';

class AuditService {
  /// Log-ul de audit este scris de backend automat la fiecare operație.
  /// Această metodă este păstrată pentru compatibilitate (login/logout client-side).
  /// Backend-ul ignoră cererile fără token valid, deci nu face nimic la login.
  static Future<void> log({
    required String userId,
    required String userName,
    required AuditAction actiune,
    required String entitate,
    required String detalii,
    String? entitateId,
  }) async {
    // Audit log pentru autentificare/deconectare nu are endpoint dedicat.
    // Toate celelalte acțiuni sunt logate automat de backend.
  }

  static Future<List<AuditLogModel>> getLogs({
    int limit = 200,
  }) async {
    try {
      final data = await ApiService.get('/api/audit');
      return (data as List).map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, st) {
      debugPrint('AuditService.getLogs error: $e\n$st');
      rethrow;
    }
  }
}
