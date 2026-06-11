import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property/property_model.dart';
import '../config/app_config.dart';
import 'audit_service.dart';

class PropertyService {
  static final _firestore = FirebaseFirestore.instance;
  static final _col = _firestore.collection(AppConfig.colProperties);

  static Stream<List<PropertyModel>> getAll({
    PropertyType? tip,
    JuridicalDomain? domeniu,
    PropertyStatus? status,
  }) {
    Query query = _col.orderBy('createdAt', descending: true);
    if (tip != null) query = query.where('tip', isEqualTo: tip.name);
    if (domeniu != null) query = query.where('domeniuJuridic', isEqualTo: domeniu.name);
    if (status != null) query = query.where('status', isEqualTo: status.name);
    return query.snapshots().map(
      (s) => s.docs.map((d) => PropertyModel.fromFirestore(d)).toList(),
    );
  }

  static Future<PropertyModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return PropertyModel.fromFirestore(doc);
  }

  static Future<String> create(PropertyModel p, {
    required String userId,
    required String userName,
  }) async {
    final ref = await _col.add(p.toFirestore());
    await AuditService.log(
      userId: userId,
      userName: userName,
      actiune: AuditAction.adaugare,
      entitate: 'Bun Imobiliar',
      entitateId: ref.id,
      detalii: 'A adăugat bunul imobiliar: ${p.denumire}',
    );
    return ref.id;
  }

  static Future<void> update(PropertyModel p, {
    required String userId,
    required String userName,
  }) async {
    final data = p.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(p.id).update(data);
    await AuditService.log(
      userId: userId,
      userName: userName,
      actiune: AuditAction.modificare,
      entitate: 'Bun Imobiliar',
      entitateId: p.id,
      detalii: 'A modificat bunul imobiliar: ${p.denumire}',
    );
  }

  static Future<void> updateStatus(
    String id,
    PropertyStatus status, {
    required String userId,
    required String userName,
    required String denumire,
  }) async {
    await _col.doc(id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await AuditService.log(
      userId: userId,
      userName: userName,
      actiune: AuditAction.actualizareStatus,
      entitate: 'Bun Imobiliar',
      entitateId: id,
      detalii: 'Status actualizat la "${status.label}" pentru: $denumire',
    );
  }

  static Future<void> delete(String id, {
    required String userId,
    required String userName,
    required String denumire,
  }) async {
    await _col.doc(id).delete();
    await AuditService.log(
      userId: userId,
      userName: userName,
      actiune: AuditAction.stergere,
      entitate: 'Bun Imobiliar',
      entitateId: id,
      detalii: 'A șters bunul imobiliar: $denumire',
    );
  }

  /// Statistici pentru dashboard
  static Future<Map<String, dynamic>> getStats() async {
    final snap = await _col.get();
    final all = snap.docs.map((d) => PropertyModel.fromFirestore(d)).toList();
    
    int active = 0, teren = 0, cladire = 0, spatiu = 0, constructie = 0;
    double totalValoare = 0;

    for (var p in all) {
      if (p.status == PropertyStatus.activ) active++;
      totalValoare += p.valoareInventar;
      switch (p.tip) {
        case PropertyType.teren: teren++; break;
        case PropertyType.cladire: cladire++; break;
        case PropertyType.spatiu: spatiu++; break;
        case PropertyType.constructie: constructie++; break;
      }
    }

    return {
      'total': all.length,
      'active': active,
      'totalValoare': totalValoare,
      'byType': {
        'teren': teren,
        'cladire': cladire,
        'spatiu': spatiu,
        'constructie': constructie,
      },
    };
  }
}
