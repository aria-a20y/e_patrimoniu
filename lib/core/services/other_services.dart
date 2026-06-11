import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction/transaction_model.dart';
import '../models/contract/contract_model.dart';
import '../models/auction/auction_model.dart';
import '../config/app_config.dart';
import 'audit_service.dart';

// ============================================================
// TRANSACTION SERVICE
// ============================================================
class TransactionService {
  static final _col = FirebaseFirestore.instance.collection(AppConfig.colTransactions);

  static Stream<List<TransactionModel>> getAll({String? propertyId}) {
    Query q = _col.orderBy('createdAt', descending: true);
    if (propertyId != null) q = q.where('propertyId', isEqualTo: propertyId);
    return q.snapshots().map(
      (s) => s.docs.map((d) => TransactionModel.fromFirestore(d)).toList(),
    );
  }

  static Future<String> create(TransactionModel t, {
    required String userId,
    required String userName,
  }) async {
    final ref = await _col.add(t.toFirestore());
    await AuditService.log(
      userId: userId,
      userName: userName,
      actiune: AuditAction.adaugare,
      entitate: 'Tranzacție',
      entitateId: ref.id,
      detalii: 'Tranzacție creată: ${t.tip.label} pentru ${t.propertyDenumire}',
    );
    return ref.id;
  }

  static Future<void> updateStatus(
    String id,
    TransactionStatus status, {
    required String userId,
    required String userName,
  }) async {
    await _col.doc(id).update({'status': status.name});
    await AuditService.log(
      userId: userId,
      userName: userName,
      actiune: AuditAction.actualizareStatus,
      entitate: 'Tranzacție',
      entitateId: id,
      detalii: 'Status actualizat: ${status.label}',
    );
  }

  static Future<Map<String, int>> getStats() async {
    final snap = await _col.get();
    int initiata = 0, aprobata = 0, inDerulare = 0, finalizata = 0, anulata = 0;
    for (final doc in snap.docs) {
      final t = TransactionModel.fromFirestore(doc);
      switch (t.status) {
        case TransactionStatus.initiata: initiata++; break;
        case TransactionStatus.aprobata: aprobata++; break;
        case TransactionStatus.inDerulare: inDerulare++; break;
        case TransactionStatus.finalizata: finalizata++; break;
        case TransactionStatus.anulata: anulata++; break;
      }
    }
    return {
      'total': snap.docs.length,
      'initiata': initiata,
      'aprobata': aprobata,
      'inDerulare': inDerulare,
      'finalizata': finalizata,
      'anulata': anulata,
    };
  }
}

// ============================================================
// CONTRACT SERVICE
// ============================================================
class ContractService {
  static final _col = FirebaseFirestore.instance.collection(AppConfig.colContracts);
  static final _changesCol = FirebaseFirestore.instance.collection(AppConfig.colContractChanges);

  static Stream<List<ContractModel>> getAll({String? propertyId}) {
    Query q = _col.orderBy('createdAt', descending: true);
    if (propertyId != null) q = q.where('propertyId', isEqualTo: propertyId);
    return q.snapshots().map(
      (s) => s.docs.map((d) => ContractModel.fromFirestore(d)).toList(),
    );
  }

  static Future<String> create(ContractModel c, {
    required String userId,
    required String userName,
  }) async {
    final ref = await _col.add(c.toFirestore());
    await AuditService.log(
      userId: userId,
      userName: userName,
      actiune: AuditAction.adaugare,
      entitate: 'Contract',
      entitateId: ref.id,
      detalii: 'Contract creat: ${c.numarContract} cu ${c.parteContractanta}',
    );
    return ref.id;
  }

  static Future<void> updateStatus(
    String id,
    ContractStatus status, {
    required String userId,
    required String userName,
  }) async {
    await _col.doc(id).update({'status': status.name});
    await AuditService.log(
      userId: userId,
      userName: userName,
      actiune: AuditAction.actualizareStatus,
      entitate: 'Contract',
      entitateId: id,
      detalii: 'Status contract actualizat: ${status.label}',
    );
  }

  static Future<void> addChange(ContractChange change) async {
    await _changesCol.add(change.toFirestore());
  }

  static Stream<List<ContractChange>> getChanges(String contractId) {
    return _changesCol
        .where('contractId', isEqualTo: contractId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ContractChange.fromFirestore(d)).toList());
  }

  static Future<int> getActiveCount() async {
    final snap = await _col.where('status', isEqualTo: ContractStatus.activ.name).get();
    return snap.docs.length;
  }
}

// ============================================================
// AUCTION SERVICE
// ============================================================
class AuctionService {
  static final _col = FirebaseFirestore.instance.collection(AppConfig.colAuctions);
  static final _bidsCol = FirebaseFirestore.instance.collection(AppConfig.colBids);

  static Stream<List<AuctionModel>> getAll({AuctionStatus? status}) {
    Query q = _col.orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    return q.snapshots().map(
      (s) => s.docs.map((d) => AuctionModel.fromFirestore(d)).toList(),
    );
  }

  static Future<String> create(AuctionModel a, {
    required String userId,
    required String userName,
  }) async {
    final ref = await _col.add(a.toFirestore());
    await AuditService.log(
      userId: userId,
      userName: userName,
      actiune: AuditAction.creareLicitatie,
      entitate: 'Licitație',
      entitateId: ref.id,
      detalii: 'Licitație creată: ${a.titlu}',
    );
    return ref.id;
  }

  static Future<void> publish(String id, {
    required String userId,
    required String userName,
  }) async {
    await _col.doc(id).update({'status': AuctionStatus.publicata.name});
    await AuditService.log(
      userId: userId,
      userName: userName,
      actiune: AuditAction.actualizareStatus,
      entitate: 'Licitație',
      entitateId: id,
      detalii: 'Licitație publicată',
    );
  }

  static Future<void> updateStatus(String id, AuctionStatus status, {
    required String userId,
    required String userName,
  }) async {
    await _col.doc(id).update({'status': status.name});
    await AuditService.log(
      userId: userId,
      userName: userName,
      actiune: AuditAction.actualizareStatus,
      entitate: 'Licitație',
      entitateId: id,
      detalii: 'Status licitație: ${status.label}',
    );
  }

  static Future<void> submitBid(BidModel bid, {
    required String userId,
    required String userName,
  }) async {
    await _bidsCol.add(bid.toFirestore());
    await AuditService.log(
      userId: userId,
      userName: userName,
      actiune: AuditAction.depunereOferta,
      entitate: 'Licitație',
      entitateId: bid.auctionId,
      detalii: 'Ofertă depusă: ${bid.valoare.toStringAsFixed(2)} RON de ${bid.participantNume}',
    );
  }

  static Stream<List<BidModel>> getBids(String auctionId) {
    return _bidsCol
        .where('auctionId', isEqualTo: auctionId)
        .orderBy('dataOra', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => BidModel.fromFirestore(d)).toList());
  }

  static Future<void> selectWinner(
    String auctionId,
    String winnerId,
    String winnerName,
    double winningBid, {
    required String userId,
    required String userName,
  }) async {
    await _col.doc(auctionId).update({
      'status': AuctionStatus.atribuita.name,
      'castigatorId': winnerId,
      'castigatorNume': winnerName,
      'ofertaCastigatoare': winningBid,
    });
    await AuditService.log(
      userId: userId,
      userName: userName,
      actiune: AuditAction.actualizareStatus,
      entitate: 'Licitație',
      entitateId: auctionId,
      detalii: 'Câștigător desemnat: $winnerName cu ${winningBid.toStringAsFixed(2)} RON',
    );
  }

  static Future<int> getActiveCount() async {
    final snap = await _col.where('status', isEqualTo: AuctionStatus.activa.name).get();
    return snap.docs.length;
  }
}
