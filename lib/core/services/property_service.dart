import '../models/property/property_model.dart';
import 'api_service.dart';

class PropertyService {
  static Future<List<PropertyModel>> getAll({
    PropertyType? tip,
    PropertyStatus? status,
    String? localitate,
  }) async {
    final query = <String, String>{};
    if (tip != null) query['tip'] = tip.name;
    if (status != null) query['status'] = status.name;
    if (localitate != null) query['localitate'] = localitate;

    final data = await ApiService.get('/api/properties', query: query.isEmpty ? null : query);
    return (data as List).map((e) => PropertyModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<PropertyModel?> getById(String id) async {
    final data = await ApiService.get('/api/properties/$id');
    return PropertyModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<String> create(PropertyModel p) async {
    final data = await ApiService.post('/api/properties', p.toJson());
    return (data as Map<String, dynamic>)['id'].toString();
  }

  static Future<void> update(PropertyModel p) async {
    await ApiService.put('/api/properties/${p.id}', p.toJson());
  }

  static Future<void> updateStatus(String id, PropertyStatus status) async {
    await ApiService.put('/api/properties/$id', {'status': status.name});
  }

  static Future<void> delete(String id) async {
    await ApiService.delete('/api/properties/$id');
  }

  /// Statistici pentru dashboard — calculat local din lista completă
  static Future<Map<String, dynamic>> getStats() async {
    final all = await getAll();
    int active = 0, teren = 0, cladire = 0, spatiu = 0, constructie = 0;
    double totalValoare = 0;

    for (final p in all) {
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
