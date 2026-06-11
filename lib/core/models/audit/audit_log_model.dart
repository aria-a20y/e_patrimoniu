import 'package:cloud_firestore/cloud_firestore.dart';

enum AuditAction {
  adaugare,
  modificare,
  stergere,
  actualizareStatus,
  incarcarDocument,
  creareLicitatie,
  depunereOferta,
  autentificare,
  deconectare,
}

extension AuditActionExt on AuditAction {
  String get label {
    switch (this) {
      case AuditAction.adaugare: return 'Adăugare';
      case AuditAction.modificare: return 'Modificare';
      case AuditAction.stergere: return 'Ștergere';
      case AuditAction.actualizareStatus: return 'Actualizare Status';
      case AuditAction.incarcarDocument: return 'Încărcare Document';
      case AuditAction.creareLicitatie: return 'Creare Licitație';
      case AuditAction.depunereOferta: return 'Depunere Ofertă';
      case AuditAction.autentificare: return 'Autentificare';
      case AuditAction.deconectare: return 'Deconectare';
    }
  }
}

class AuditLogModel {
  final String id;
  final String userId;
  final String userName;
  final AuditAction actiune;
  final String entitate;      // ex: 'Bun Imobiliar', 'Document', 'Contract'
  final String? entitateId;
  final String detalii;
  final DateTime dataOra;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.actiune,
    required this.entitate,
    this.entitateId,
    required this.detalii,
    required this.dataOra,
  });

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AuditLogModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      userName: d['userName'] ?? '',
      actiune: AuditAction.values.firstWhere(
        (e) => e.name == d['actiune'],
        orElse: () => AuditAction.modificare,
      ),
      entitate: d['entitate'] ?? '',
      entitateId: d['entitateId'],
      detalii: d['detalii'] ?? '',
      dataOra: (d['dataOra'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'userName': userName,
    'actiune': actiune.name,
    'entitate': entitate,
    'entitateId': entitateId,
    'detalii': detalii,
    'dataOra': FieldValue.serverTimestamp(),
  };
}
