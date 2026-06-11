import 'package:cloud_firestore/cloud_firestore.dart';

enum ContractStatus {
  activ,
  prelungit,
  reziliat,
  expirat,
  finalizat,
  anulat,
}

enum ContractChangeType {
  prelungire,
  reziliere,
  actualizareChirie,
  actualizareRedeventa,
  modificareDurata,
  actAditional,
}

extension ContractStatusExt on ContractStatus {
  String get label {
    switch (this) {
      case ContractStatus.activ: return 'Activ';
      case ContractStatus.prelungit: return 'Prelungit';
      case ContractStatus.reziliat: return 'Reziliat';
      case ContractStatus.expirat: return 'Expirat';
      case ContractStatus.finalizat: return 'Finalizat';
      case ContractStatus.anulat: return 'Anulat';
    }
  }
}

extension ContractChangeTypeExt on ContractChangeType {
  String get label {
    switch (this) {
      case ContractChangeType.prelungire: return 'Prelungire';
      case ContractChangeType.reziliere: return 'Reziliere';
      case ContractChangeType.actualizareChirie: return 'Actualizare Chirie';
      case ContractChangeType.actualizareRedeventa: return 'Actualizare Redevență';
      case ContractChangeType.modificareDurata: return 'Modificare Durată';
      case ContractChangeType.actAditional: return 'Act Adițional';
    }
  }
}

class ContractModel {
  final String id;
  final String propertyId;
  final String propertyDenumire;
  final String? transactionId;
  final String numarContract;
  final String parteContractanta;
  final DateTime dataInceput;
  final DateTime dataFinal;
  final double valoare;
  final String valutaMoneda;
  final ContractStatus status;
  final String? documentUrl;
  final String? note;
  final DateTime createdAt;
  final String createdBy;

  ContractModel({
    required this.id,
    required this.propertyId,
    required this.propertyDenumire,
    this.transactionId,
    required this.numarContract,
    required this.parteContractanta,
    required this.dataInceput,
    required this.dataFinal,
    required this.valoare,
    required this.valutaMoneda,
    required this.status,
    this.documentUrl,
    this.note,
    required this.createdAt,
    required this.createdBy,
  });

  factory ContractModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ContractModel(
      id: doc.id,
      propertyId: d['propertyId'] ?? '',
      propertyDenumire: d['propertyDenumire'] ?? '',
      transactionId: d['transactionId'],
      numarContract: d['numarContract'] ?? '',
      parteContractanta: d['parteContractanta'] ?? '',
      dataInceput: (d['dataInceput'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataFinal: (d['dataFinal'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 365)),
      valoare: (d['valoare'] ?? 0).toDouble(),
      valutaMoneda: d['valutaMoneda'] ?? 'RON',
      status: ContractStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => ContractStatus.activ,
      ),
      documentUrl: d['documentUrl'],
      note: d['note'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: d['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'propertyId': propertyId,
    'propertyDenumire': propertyDenumire,
    'transactionId': transactionId,
    'numarContract': numarContract,
    'parteContractanta': parteContractanta,
    'dataInceput': Timestamp.fromDate(dataInceput),
    'dataFinal': Timestamp.fromDate(dataFinal),
    'valoare': valoare,
    'valutaMoneda': valutaMoneda,
    'status': status.name,
    'documentUrl': documentUrl,
    'note': note,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': createdBy,
  };
}

class ContractChange {
  final String id;
  final String contractId;
  final ContractChangeType tip;
  final String descriere;
  final DateTime data;
  final String? documentUrl;
  final String createdBy;
  final DateTime createdAt;

  ContractChange({
    required this.id,
    required this.contractId,
    required this.tip,
    required this.descriere,
    required this.data,
    this.documentUrl,
    required this.createdBy,
    required this.createdAt,
  });

  factory ContractChange.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ContractChange(
      id: doc.id,
      contractId: d['contractId'] ?? '',
      tip: ContractChangeType.values.firstWhere(
        (e) => e.name == d['tip'],
        orElse: () => ContractChangeType.actAditional,
      ),
      descriere: d['descriere'] ?? '',
      data: (d['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
      documentUrl: d['documentUrl'],
      createdBy: d['createdBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'contractId': contractId,
    'tip': tip.name,
    'descriere': descriere,
    'data': Timestamp.fromDate(data),
    'documentUrl': documentUrl,
    'createdBy': createdBy,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
