enum DocumentType {
  hcl,
  extrasCF,
  planCadastral,
  raportEvaluare,
  contract,
  procesVerbal,
  actAditional,
  documentPlata,
  altele,
}

enum DocumentStatus {
  neverificat,
  inVerificare,
  verificat,
  respins,
}

extension DocumentTypeExt on DocumentType {
  String get label {
    switch (this) {
      case DocumentType.hcl: return 'HCL';
      case DocumentType.extrasCF: return 'Extras Carte Funciară';
      case DocumentType.planCadastral: return 'Plan Cadastral';
      case DocumentType.raportEvaluare: return 'Raport de Evaluare';
      case DocumentType.contract: return 'Contract';
      case DocumentType.procesVerbal: return 'Proces-Verbal';
      case DocumentType.actAditional: return 'Act Adițional';
      case DocumentType.documentPlata: return 'Document de Plată';
      case DocumentType.altele: return 'Alte Documente';
    }
  }
}

extension DocumentStatusExt on DocumentStatus {
  String get label {
    switch (this) {
      case DocumentStatus.neverificat: return 'Neverificat';
      case DocumentStatus.inVerificare: return 'În Verificare';
      case DocumentStatus.verificat: return 'Verificat';
      case DocumentStatus.respins: return 'Respins';
    }
  }
}

class DocumentModel {
  final String id;
  final String denumire;
  final DocumentType tip;
  final DocumentStatus status;
  final String fileUrl;
  final String fileType; // pdf, jpg, png
  final int fileSize;    // bytes
  final String? propertyId;
  final String? transactionId;
  final String? contractId;
  final String? auctionId;
  final String? note;
  final DateTime uploadedAt;
  final String uploadedBy;

  DocumentModel({
    required this.id,
    required this.denumire,
    required this.tip,
    required this.status,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    this.propertyId,
    this.transactionId,
    this.contractId,
    this.auctionId,
    this.note,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> d) {
    return DocumentModel(
      id: d['id']?.toString() ?? '',
      denumire: d['denumire']?.toString() ?? '',
      tip: DocumentType.values.firstWhere(
        (e) => e.name == d['tip'],
        orElse: () => DocumentType.altele,
      ),
      status: DocumentStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => DocumentStatus.neverificat,
      ),
      fileUrl: d['fileUrl']?.toString() ?? '',
      fileType: d['fileType']?.toString() ?? 'pdf',
      fileSize: (d['fileSize'] as num?)?.toInt() ?? 0,
      propertyId: d['propertyId']?.toString(),
      transactionId: d['transactionId']?.toString(),
      contractId: d['contractId']?.toString(),
      auctionId: d['auctionId']?.toString(),
      note: d['note']?.toString(),
      uploadedAt: _parseDate(d['uploadedAt'] ?? d['createdAt']),
      uploadedBy: d['uploadedBy']?.toString() ?? d['createdBy']?.toString() ?? '',
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'denumire': denumire,
    'tip': tip.name,
    'status': status.name,
    'fileUrl': fileUrl,
    'fileType': fileType,
    'fileSize': fileSize,
    'propertyId': propertyId,
    'transactionId': transactionId,
    'contractId': contractId,
    'auctionId': auctionId,
    'note': note,
    'uploadedBy': uploadedBy,
  };
}
