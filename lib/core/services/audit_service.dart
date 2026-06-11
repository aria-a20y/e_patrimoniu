import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit/audit_log_model.dart';
import '../config/app_config.dart';

export '../models/audit/audit_log_model.dart';

class AuditService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> log({
    required String userId,
    required String userName,
    required AuditAction actiune,
    required String entitate,
    required String detalii,
    String? entitateId,
  }) async {
    try {
      await _firestore.collection(AppConfig.colAuditLog).add({
        'userId': userId,
        'userName': userName,
        'actiune': actiune.name,
        'entitate': entitate,
        'entitateId': entitateId,
        'detalii': detalii,
        'dataOra': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Audit nu trebuie să blocheze operațiunile principale
    }
  }

  static Stream<List<AuditLogModel>> getLogs({
    String? userId,
    AuditAction? actiune,
    DateTime? from,
    DateTime? to,
  }) {
    Query query = _firestore
        .collection(AppConfig.colAuditLog)
        .orderBy('dataOra', descending: true)
        .limit(200);

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    if (actiune != null) {
      query = query.where('actiune', isEqualTo: actiune.name);
    }

    return query.snapshots().map(
      (snap) => snap.docs.map((d) => AuditLogModel.fromFirestore(d)).toList(),
    );
  }
}
