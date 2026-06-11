import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory DocumentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DocumentModel(
      id: doc.id,
      denumire: d['denumire'] ?? '',
      tip: DocumentType.values.firstWhere(
        (e) => e.name == d['tip'],
        orElse: () => DocumentType.altele,
      ),
      status: DocumentStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => DocumentStatus.neverificat,
      ),
      fileUrl: d['fileUrl'] ?? '',
      fileType: d['fileType'] ?? 'pdf',
      fileSize: d['fileSize'] ?? 0,
      propertyId: d['propertyId'],
      transactionId: d['transactionId'],
      contractId: d['contractId'],
      auctionId: d['auctionId'],
      note: d['note'],
      uploadedAt: (d['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      uploadedBy: d['uploadedBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
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
    'uploadedAt': FieldValue.serverTimestamp(),
    'uploadedBy': uploadedBy,
  };
}
