import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/document/document_model.dart';
import 'api_service.dart';

export '../models/document/document_model.dart';

class DocumentService {
  static final _storage = FirebaseStorage.instance;

  /// Încarcă fișierul în Firebase Storage și înregistrează metadata în PostgreSQL (via backend)
  static Future<void> uploadDocument({
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
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'bin';
    final storageName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final storagePath = 'documents/$storageName';

    // 1. Upload fișier în Firebase Storage
    final ref = _storage.ref(storagePath);
    final task = await ref.putData(fileBytes);
    final fileUrl = await task.ref.getDownloadURL();

    // 2. Salvează metadata în PostgreSQL via backend
    await ApiService.post('/api/documents', {
      'propertyId': propertyId,
      'transactionId': transactionId,
      'contractId': contractId,
      'auctionId': auctionId,
      'denumire': denumire,
      'tip': tip.name,
      'fileUrl': fileUrl,
      'fileType': ext,
      'fileSize': fileBytes.length,
      'note': note,
    });
  }

  /// Obține toate documentele (opțional filtrate după proprietate)
  static Future<List<DocumentModel>> getAll({String? propertyId}) async {
    final query = propertyId != null ? {'propertyId': propertyId} : null;
    final data = await ApiService.get('/api/documents', query: query);
    return (data as List).map((e) => DocumentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Documente asociate unei proprietăți specifice
  static Future<List<DocumentModel>> getByProperty(String propertyId) {
    return getAll(propertyId: propertyId);
  }

  static Future<void> updateStatus(String id, DocumentStatus status) async {
    await ApiService.put('/api/documents/$id/status', {'status': status.name});
  }

  static Future<void> delete(String id, String? fileUrl) async {
    await ApiService.delete('/api/documents/$id');
    // Șterge și fișierul din Firebase Storage dacă există
    if (fileUrl != null && fileUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(fileUrl).delete();
      } catch (_) {
        // Ignoră eroarea dacă fișierul nu mai există
      }
    }
  }
}
