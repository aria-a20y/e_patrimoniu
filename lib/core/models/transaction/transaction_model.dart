import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  vanzare,
  cumparare,
  inchiriere,
  concesionare,
  dareAdministrare,
  dareFolosintaGratuita,
  comodat,
  schimbImobiliar,
  transfer,
  preluarePatrimoniu,
  scoatereEvidenta,
  modificareValoare,
}

enum TransactionStatus {
  initiata,
  aprobata,
  inDerulare,
  finalizata,
  anulata,
}

extension TransactionTypeExt on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.vanzare: return 'Vânzare';
      case TransactionType.cumparare: return 'Cumpărare';
      case TransactionType.inchiriere: return 'Închiriere';
      case TransactionType.concesionare: return 'Concesionare';
      case TransactionType.dareAdministrare: return 'Dare în Administrare';
      case TransactionType.dareFolosintaGratuita: return 'Dare în Folosință Gratuită';
      case TransactionType.comodat: return 'Comodat';
      case TransactionType.schimbImobiliar: return 'Schimb Imobiliar';
      case TransactionType.transfer: return 'Transfer';
      case TransactionType.preluarePatrimoniu: return 'Preluare în Patrimoniu';
      case TransactionType.scoatereEvidenta: return 'Scoatere din Evidență';
      case TransactionType.modificareValoare: return 'Modificare Valoare de Inventar';
    }
  }
}

extension TransactionStatusExt on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.initiata: return 'Inițiată';
      case TransactionStatus.aprobata: return 'Aprobată';
      case TransactionStatus.inDerulare: return 'În Derulare';
      case TransactionStatus.finalizata: return 'Finalizată';
      case TransactionStatus.anulata: return 'Anulată';
    }
  }
}

class TransactionModel {
  final String id;
  final String propertyId;
  final String propertyDenumire;
  final TransactionType tip;
  final String descriere;
  final String numarHcl;
  final DateTime dataTransactie;
  final TransactionStatus status;
  final List<String> documentIds;
  final String? note;
  final DateTime createdAt;
  final String createdBy;

  TransactionModel({
    required this.id,
    required this.propertyId,
    required this.propertyDenumire,
    required this.tip,
    required this.descriere,
    required this.numarHcl,
    required this.dataTransactie,
    required this.status,
    required this.documentIds,
    this.note,
    required this.createdAt,
    required this.createdBy,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      propertyId: d['propertyId'] ?? '',
      propertyDenumire: d['propertyDenumire'] ?? '',
      tip: TransactionType.values.firstWhere(
        (e) => e.name == d['tip'],
        orElse: () => TransactionType.transfer,
      ),
      descriere: d['descriere'] ?? '',
      numarHcl: d['numarHcl'] ?? '',
      dataTransactie: (d['dataTransactie'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => TransactionStatus.initiata,
      ),
      documentIds: List<String>.from(d['documentIds'] ?? []),
      note: d['note'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: d['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'propertyId': propertyId,
    'propertyDenumire': propertyDenumire,
    'tip': tip.name,
    'descriere': descriere,
    'numarHcl': numarHcl,
    'dataTransactie': Timestamp.fromDate(dataTransactie),
    'status': status.name,
    'documentIds': documentIds,
    'note': note,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': createdBy,
  };
}
