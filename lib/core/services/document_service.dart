import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/document/document_model.dart';
import '../config/app_config.dart';
import 'api_service.dart';

export '../models/document/document_model.dart';

/// Serviciu pentru gestionarea documentelor.
/// Fișierele sunt stocate exclusiv în PostgreSQL (coloana BYTEA file_data).
/// Nu se folosește Firebase Storage.
class DocumentService {
  /// URL-ul pentru descărcarea/vizualizarea unui document din backend
  static String getFileUrl(String documentId) =>
      '${AppConfig.backendUrl}/api/documents/$documentId/file';

  /// Încarcă un fișier direct în PostgreSQL via backend (multipart/form-data).
  /// Nu folosește Firebase Storage.
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Utilizator neautentificat.');
    final token = await user.getIdToken() ?? '';

    final uri = Uri.parse('${AppConfig.backendUrl}/api/documents/upload');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['denumire']    = denumire
      ..fields['tip']         = tip.name
      ..fields['uploadedBy']  = uploadedBy;

    if (propertyId    != null) request.fields['propertyId']    = propertyId;
    if (transactionId != null) request.fields['transactionId'] = transactionId;
    if (contractId    != null) request.fields['contractId']    = contractId;
    if (auctionId     != null) request.fields['auctionId']     = auctionId;
    if (note          != null) request.fields['note']          = note;

    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    final streamed = await request.send()
        .timeout(AppConfig.connectionTimeout);

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final body = await streamed.stream.bytesToString();
      throw ApiException(streamed.statusCode, 'Upload eșuat: $body');
    }
  }

  /// Returnează lista de documente (fără bytes — doar metadate).
  static Future<List<DocumentModel>> getAll({String? propertyId}) async {
    final query = propertyId != null ? {'propertyId': propertyId} : null;
    final data = await ApiService.get('/api/documents', query: query);
    return (data as List)
        .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Documente asociate unei proprietăți specifice.
  static Future<List<DocumentModel>> getByProperty(String propertyId) =>
      getAll(propertyId: propertyId);

  /// Actualizează statusul unui document.
  static Future<void> updateStatus(String id, DocumentStatus status) async {
    await ApiService.put('/api/documents/$id/status', {'status': status.name});
  }

  /// Șterge documentul (metadate + bytes) din PostgreSQL.
  /// Parametrul [fileUrl] este ignorat — nu mai există Firebase Storage.
  static Future<void> delete(String id, [String? fileUrl]) async {
    await ApiService.delete('/api/documents/$id');
  }
}
