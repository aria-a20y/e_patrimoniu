double _parseDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

enum ContractStatus { activ, prelungit, reziliat, expirat, finalizat, anulat }

enum ContractChangeType {
  prelungire, reziliere, actualizareChirie,
  actualizareRedeventa, modificareDurata, actAditional,
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

  factory ContractModel.fromJson(Map<String, dynamic> d) {
    return ContractModel(
      id: d['id']?.toString() ?? '',
      propertyId: d['propertyId']?.toString() ?? '',
      propertyDenumire: d['propertyDenumire'] ?? '',
      transactionId: d['transactionId']?.toString(),
      numarContract: d['numarContract'] ?? '',
      parteContractanta: d['parteContractanta'] ?? '',
      dataInceput: _parseDate(d['dataInceput']),
      dataFinal: _parseDate(d['dataFinal']),
      valoare: _parseDouble(d['valoare']),
      valutaMoneda: d['valutaMoneda'] ?? 'RON',
      status: ContractStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => ContractStatus.activ,
      ),
      documentUrl: d['documentUrl'],
      note: d['note'],
      createdAt: _parseDate(d['createdAt']),
      createdBy: d['createdBy'] ?? '',
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'propertyId': propertyId,
    'propertyDenumire': propertyDenumire,
    'transactionId': transactionId,
    'numarContract': numarContract,
    'parteContractanta': parteContractanta,
    'dataInceput': dataInceput.toIso8601String(),
    'dataFinal': dataFinal.toIso8601String(),
    'valoare': valoare,
    'valutaMoneda': valutaMoneda,
    'note': note,
  };
}
