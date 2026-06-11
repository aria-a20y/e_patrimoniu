import 'package:cloud_firestore/cloud_firestore.dart';

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
  final List<String> documentIds;
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
    required this.documentIds,
    required this.createdAt,
    required this.createdBy,
  });

  factory AuctionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AuctionModel(
      id: doc.id,
      propertyId: d['propertyId'] ?? '',
      propertyDenumire: d['propertyDenumire'] ?? '',
      titlu: d['titlu'] ?? '',
      tipAtribuire: AuctionType.values.firstWhere(
        (e) => e.name == d['tipAtribuire'],
        orElse: () => AuctionType.inchiriere,
      ),
      pretPornire: (d['pretPornire'] ?? 0).toDouble(),
      pasLicitare: (d['pasLicitare'] ?? 0).toDouble(),
      garantieParticipare: (d['garantieParticipare'] ?? 0).toDouble(),
      dataInceput: (d['dataInceput'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataFinal: (d['dataFinal'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: AuctionStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => AuctionStatus.draft,
      ),
      castigatorId: d['castigatorId'],
      castigatorNume: d['castigatorNume'],
      ofertaCastigatoare: d['ofertaCastigatoare']?.toDouble(),
      transactionId: d['transactionId'],
      contractId: d['contractId'],
      descriere: d['descriere'],
      documentIds: List<String>.from(d['documentIds'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: d['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'propertyId': propertyId,
    'propertyDenumire': propertyDenumire,
    'titlu': titlu,
    'tipAtribuire': tipAtribuire.name,
    'pretPornire': pretPornire,
    'pasLicitare': pasLicitare,
    'garantieParticipare': garantieParticipare,
    'dataInceput': Timestamp.fromDate(dataInceput),
    'dataFinal': Timestamp.fromDate(dataFinal),
    'status': status.name,
    'castigatorId': castigatorId,
    'castigatorNume': castigatorNume,
    'ofertaCastigatoare': ofertaCastigatoare,
    'transactionId': transactionId,
    'contractId': contractId,
    'descriere': descriere,
    'documentIds': documentIds,
    'createdAt': FieldValue.serverTimestamp(),
    'createdBy': createdBy,
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

  factory BidModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BidModel(
      id: doc.id,
      auctionId: d['auctionId'] ?? '',
      participantId: d['participantId'] ?? '',
      participantNume: d['participantNume'] ?? '',
      valoare: (d['valoare'] ?? 0).toDouble(),
      dataOra: (d['dataOra'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validata: d['validata'] ?? false,
      respinsa: d['respinsa'] ?? false,
      motivRespingere: d['motivRespingere'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'auctionId': auctionId,
    'participantId': participantId,
    'participantNume': participantNume,
    'valoare': valoare,
    'dataOra': FieldValue.serverTimestamp(),
    'validata': validata,
    'respinsa': respinsa,
    'motivRespingere': motivRespingere,
  };
}
