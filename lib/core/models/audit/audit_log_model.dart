enum AuditAction {
  adaugare, modificare, stergere, actualizareStatus,
  incarcarDocument, creareLicitatie, depunereOferta,
  autentificare, deconectare,
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
  final String entitate;
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

  factory AuditLogModel.fromJson(Map<String, dynamic> d) {
    return AuditLogModel(
      id: d['id']?.toString() ?? '',
      userId: d['userId'] ?? d['user_id'] ?? '',
      userName: d['userName'] ?? d['user_name'] ?? '',
      actiune: AuditAction.values.firstWhere(
        (e) => e.name == d['actiune'],
        orElse: () => AuditAction.modificare,
      ),
      entitate: d['entitate'] ?? '',
      entitateId: d['entitateId']?.toString() ?? d['entitate_id']?.toString(),
      detalii: d['detalii'] ?? '',
      dataOra: DateTime.tryParse(
            (d['timestamp'] ?? d['dataOra'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }
}
