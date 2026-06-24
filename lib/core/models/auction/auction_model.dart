// Helper: PostgreSQL returnează NUMERIC ca String ("1000.00") — convertim safe
double _parseDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

enum AuctionType { vanzare, inchiriere, concesionare }
enum AuctionStatus { draft, publicata, activa, inchisa, atribuita, anulata, contestata }

extension AuctionTypeExt on AuctionType {
  String get label {
    switch (this) {
      case AuctionType.vanzare: return 'Vânzare';
      case AuctionType.inchiriere: return 'Închiriere';
      case AuctionType.concesionare: return 'Concesionare';
    }
  }
}

extension AuctionStatusExt on AuctionStatus {
  String get label {
    switch (this) {
      case AuctionStatus.draft: return 'Draft';
      case AuctionStatus.publicata: return 'Publicată';
      case AuctionStatus.activa: return 'Activă';
      case AuctionStatus.inchisa: return 'Închisă';
      case AuctionStatus.atribuita: return 'Atribuită';
      case AuctionStatus.anulata: return 'Anulată';
      case AuctionStatus.contestata: return 'Contestată';
    }
  }
}

class AuctionModel {
  final String id;
  final String propertyId;
  final String propertyDenumire;
  final String titlu;
  final AuctionType tipAtribuire;
  final double pretPornire;
  final double pasLicitare;
  final double garantieParticipare;
  final DateTime dataInceput;
  final DateTime dataFinal;
  final AuctionStatus status;
  final String? castigatorId;
  final String? castigatorNume;
  final double? ofertaCastigatoare;
  final String? transactionId;
  final String? contractId;
  final String? descriere;
  final DateTime createdAt;
  final String createdBy;

  AuctionModel({
    required this.id,
    required this.propertyId,
    required this.propertyDenumire,
    required this.titlu,
    required this.tipAtribuire,
    required this.pretPornire,
    required this.pasLicitare,
    required this.garantieParticipare,
    required this.dataInceput,
    required this.dataFinal,
    required this.status,
    this.castigatorId,
    this.castigatorNume,
    this.ofertaCastigatoare,
    this.transactionId,
    this.contractId,
    this.descriere,
    required this.createdAt,
    required this.createdBy,
  });

  factory AuctionModel.fromJson(Map<String, dynamic> d) {
    return AuctionModel(
      id: d['id']?.toString() ?? '',
      propertyId: d['propertyId']?.toString() ?? '',
      propertyDenumire: d['propertyDenumire'] ?? '',
      titlu: d['titlu'] ?? '',
      tipAtribuire: AuctionType.values.firstWhere(
        (e) => e.name == d['tipAtribuire'],
        orElse: () => AuctionType.inchiriere,
      ),
      pretPornire: _parseDouble(d['pretPornire']),
      pasLicitare: _parseDouble(d['pasLicitare']),
      garantieParticipare: _parseDouble(d['garantieParticipare']),
      dataInceput: _parseDate(d['dataInceput']),
      dataFinal: _parseDate(d['dataFinal']),
      status: AuctionStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => AuctionStatus.draft,
      ),
      castigatorId: d['castigatorId'],
      castigatorNume: d['castigatorNume'],
      ofertaCastigatoare: d['ofertaCastigatoare'] != null
          ? _parseDouble(d['ofertaCastigatoare'])
          : null,
      transactionId: d['transactionId']?.toString(),
      contractId: d['contractId']?.toString(),
      descriere: d['descriere'],
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
    'titlu': titlu,
    'tipAtribuire': tipAtribuire.name,
    'pretPornire': pretPornire,
    'pasLicitare': pasLicitare,
    'garantieParticipare': garantieParticipare,
    'dataInceput': dataInceput.toIso8601String(),
    'dataFinal': dataFinal.toIso8601String(),
    'descriere': descriere,
  };
}

class BidModel {
  final String id;
  final String auctionId;
  final String participantId;
  final String participantNume;
  final double valoare;
  final DateTime dataOra;
  final bool validata;
  final bool respinsa;
  final String? motivRespingere;

  BidModel({
    required this.id,
    required this.auctionId,
    required this.participantId,
    required this.participantNume,
    required this.valoare,
    required this.dataOra,
    required this.validata,
    required this.respinsa,
    this.motivRespingere,
  });

  factory BidModel.fromJson(Map<String, dynamic> d) {
    return BidModel(
      id: d['id']?.toString() ?? '',
      auctionId: d['auctionId']?.toString() ?? '',
      participantId: d['participantId'] ?? '',
      participantNume: d['participantNume'] ?? '',
      valoare: _parseDouble(d['valoare']),
      dataOra: DateTime.tryParse(d['dataOra']?.toString() ?? '') ?? DateTime.now(),
      validata: d['validata'] ?? false,
      respinsa: d['respinsa'] ?? false,
      motivRespingere: d['motivRespingere'],
    );
  }

  Map<String, dynamic> toJson() => {'valoare': valoare};
}
