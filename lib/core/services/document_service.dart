import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/document/document_model.dart';
import '../config/app_config.dart';
import 'audit_service.dart';

class DocumentService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;
  static final _col = _firestore.collection(AppConfig.colDocuments);

  /// Încarcă fișierul în Storage și creează înregistrarea în Firestore
  /// Funcționează pe web (Uint8List) și pe mobile
  static Future<DocumentModel> uploadDocument({
    required Uint8List fileBytes,
    required String fileName,
    required String denumire,
    required DocumentType tip,
    required String uploadedBy,
    String? propertyId,
    String? transactionId,
    String? contractId,
    String? auctionId,
    String? note,
  }) async {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    final storageName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final storagePath = 'documents/$storageName';

    final ref = _storage.ref(storagePath);
    final task = await ref.putData(fileBytes);
    final url = await task.ref.getDownloadURL();
    final fileSize = fileBytes.length;

    final docRef = await _col.add({
      'denumire': denumire,
      'tip': tip.name,
      'status': DocumentStatus.neverificat.name,
      'fileUrl': url,
      'fileType': ext,
      'fileSize': fileSize,
      'propertyId': propertyId,
      'transactionId': transactionId,
      'contractId': contractId,
      'auctionId': auctionId,
      'note': note,
      'uploadedAt': FieldValue.serverTimestamp(),
      'uploadedBy': uploadedBy,
    });

    await AuditService.log(
      userId: uploadedBy,
      userName: uploadedBy,
      actiune: AuditAction.incarcarDocument,
      entitate: 'Document',
      entitateId: docRef.id,
      detalii: 'A încărcat documentul: $denumire',
    );

    final doc = await docRef.get();
    return DocumentModel.fromFirestore(doc);
  }

  static Stream<List<DocumentModel>> getByProperty(String propertyId) {
    return _col
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => DocumentModel.fromFirestore(d)).toList());
  }

  static Stream<List<DocumentModel>> getAll() {
    return _col
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => DocumentModel.fromFirestore(d)).toList());
  }

  static Future<void> updateStatus(
    String id,
    DocumentStatus status, {
    required String userId,
  }) async {
    await _col.doc(id).update({'status': status.name});
    await AuditService.log(
      userId: userId,
      userName: userId,
      actiune: AuditAction.actualizareStatus,
      entitate: 'Document',
      entitateId: id,
      detalii: 'Status document actualizat: ${status.label}',
    );
  }

  static Future<void> delete(String id, String fileUrl, {required String userId}) async {
    await _col.doc(id).delete();
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (_) {}
    await AuditService.log(
      userId: userId,
      userName: userId,
      actiune: AuditAction.stergere,
      entitate: 'Document',
      entitateId: id,
      detalii: 'Document șters',
    );
  }

  static Future<int> getCountForProperty(String propertyId) async {
    final snap = await _col
        .where('propertyId', isEqualTo: propertyId)
        .get();
    return snap.docs.length;
  }
}
