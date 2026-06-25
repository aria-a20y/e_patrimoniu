import '../models/transaction/transaction_model.dart';
import '../models/contract/contract_model.dart';
import '../models/auction/auction_model.dart';
import 'api_service.dart';

// ============================================================
// TRANSACTION SERVICE
// ============================================================
class TransactionService {
  static Future<List<TransactionModel>> getAll({String? propertyId}) async {
    final query = propertyId != null ? {'propertyId': propertyId} : null;
    final data = await ApiService.get('/api/transactions', query: query);
    return (data as List).map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<String> create(TransactionModel t) async {
    final data = await ApiService.post('/api/transactions', t.toJson());
    return (data as Map<String, dynamic>)['id'].toString();
  }

  static Future<void> updateStatus(String id, TransactionStatus status) async {
    await ApiService.put('/api/transactions/$id/status', {'status': status.name});
  }

  static Future<Map<String, int>> getStats() async {
    final all = await getAll();
    int initiata = 0, aprobata = 0, inDerulare = 0, finalizata = 0, anulata = 0;
    for (final t in all) {
      switch (t.status) {
        case TransactionStatus.initiata: initiata++; break;
        case TransactionStatus.aprobata: aprobata++; break;
        case TransactionStatus.inDerulare: inDerulare++; break;
        case TransactionStatus.finalizata: finalizata++; break;
        case TransactionStatus.anulata: anulata++; break;
      }
    }
    return {
      'total': all.length,
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
  static Future<List<ContractModel>> getAll({String? propertyId}) async {
    final query = propertyId != null ? {'propertyId': propertyId} : null;
    final data = await ApiService.get('/api/contracts', query: query);
    return (data as List).map((e) => ContractModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<String> create(ContractModel c) async {
    final data = await ApiService.post('/api/contracts', c.toJson());
    return (data as Map<String, dynamic>)['id'].toString();
  }

  static Future<void> updateStatus(String id, ContractStatus status) async {
    await ApiService.put('/api/contracts/$id/status', {'status': status.name});
  }

  static Future<int> getActiveCount() async {
    final all = await getAll();
    return all.where((c) => c.status == ContractStatus.activ).length;
  }
}

// ============================================================
// AUCTION SERVICE
// ============================================================
class AuctionService {
  static Future<List<AuctionModel>> getAll({AuctionStatus? status}) async {
    final query = status != null ? {'status': status.name} : null;
    final data = await ApiService.get('/api/auctions', query: query);
    return (data as List).map((e) => AuctionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<AuctionModel?> getById(String id) async {
    final data = await ApiService.get('/api/auctions/$id');
    return AuctionModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<String> create(AuctionModel a) async {
    final data = await ApiService.post('/api/auctions', a.toJson());
    return (data as Map<String, dynamic>)['id'].toString();
  }

  static Future<void> updateStatus(String id, AuctionStatus status) async {
    await ApiService.put('/api/auctions/$id/status', {'status': status.name});
  }

  static Future<void> selectWinner(
    String auctionId,
    String winnerId,
    String winnerName,
    double winningBid,
  ) async {
    await ApiService.put('/api/auctions/$auctionId/winner', {
      'winnerId': winnerId,
      'winnerName': winnerName,
      'winningBid': winningBid,
    });
  }

  static Future<List<BidModel>> getBids(String auctionId) async {
    final data = await ApiService.get('/api/auctions/$auctionId/bids');
    return (data as List).map((e) => BidModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<String> submitBid(String auctionId, double valoare) async {
    final data = await ApiService.post('/api/auctions/$auctionId/bids', {'valoare': valoare});
    return (data as Map<String, dynamic>)['id'].toString();
  }

  static Future<int> getActiveCount() async {
    final all = await getAll(status: AuctionStatus.activa);
    return all.length;
  }

  /// Verifică dacă utilizatorul curent este înregistrat ca participant
  static Future<bool> isRegistered(String auctionId) async {
    try {
      final data = await ApiService.get('/api/auctions/$auctionId/participants/me');
      return (data as Map<String, dynamic>)['registered'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Înregistrează utilizatorul curent ca participant la licitație
  static Future<void> registerAsParticipant(String auctionId) async {
    await ApiService.post('/api/auctions/$auctionId/participants', {});
  }

  /// Returnează cele 10 criterii de evaluare ale unui ofertant (BidCriterion list)
  static Future<List<BidCriterion>> getBidCriteria(String auctionId, String bidId) async {
    final data = await ApiService.get('/api/auctions/$auctionId/bids/$bidId/criteria');
    return (data as List).map((e) => BidCriterion.fromJson(e as Map<String, dynamic>)).toList();
  }
}

// ============================================================
// MODEL: BidCriterion
// ============================================================
class BidCriterion {
  final int criterionIndex;
  final bool isMet;

  const BidCriterion({required this.criterionIndex, required this.isMet});

  factory BidCriterion.fromJson(Map<String, dynamic> d) => BidCriterion(
    criterionIndex: (d['criterionIndex'] as num).toInt(),
    isMet: d['isMet'] as bool? ?? false,
  );

  static const List<String> _labels = [
    '',
    'Capacitate financiară și bonitate dovedită',
    'Experiență relevantă în domeniu (min. 3 ani)',
    'Personal calificat și certificat disponibil',
    'Dotare tehnică corespunzătoare activității',
    'Garanție de participare achitată integral',
    'Documentație tehnică completă și conformă',
    'Referințe pozitive de la beneficiari anteriori',
    'Respectarea cerințelor de mediu și SSM',
    'Ofertă financiară în limitele bugetului aprobat',
    'Termen de execuție/livrare fezabil și realist',
  ];

  String get label => criterionIndex >= 1 && criterionIndex <= 10
      ? _labels[criterionIndex]
      : 'Criteriu $criterionIndex';

  static const List<String> labels = [
    'Prețul / redevența oferită',
    'Destinația propusă',
    'Planul de investiții',
    'Capacitatea financiară',
    'Experiența profesională',
    'Termenele de plată',
    'Angajamente locuri de muncă',
    'Norme de mediu',
    'Garanții suplimentare',
    'Durata contractului',
  ];

  String get label => criterionIndex >= 1 && criterionIndex <= 10
      ? labels[criterionIndex - 1]
      : 'Criteriu $criterionIndex';
}
