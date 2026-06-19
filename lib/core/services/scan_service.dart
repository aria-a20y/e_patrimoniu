import 'dart:typed_data';
import 'dart:math';

enum ScanStatus { inAsteptare, procesare, finalizat, eroare }

class ScanResult {
  final String id;
  final String documentId;
  final String? propertyId;
  final Map<String, dynamic> extractedFields;
  final double confidenceScore;
  final String rawText;
  final ScanStatus status;
  final DateTime createdAt;
  bool verificatManual;

  ScanResult({
    required this.id,
    required this.documentId,
    this.propertyId,
    required this.extractedFields,
    required this.confidenceScore,
    required this.rawText,
    required this.status,
    required this.createdAt,
    required this.verificatManual,
  });
}

class ScanService {
  // Stocare in-memory (feature demo/OCR mock — nu necesită persistență server)
  static final List<ScanResult> _store = [];
  static final _rng = Random();

  /// Procesează documentul și extrage câmpuri (Mock OCR realist)
  static Future<ScanResult> processDocument({
    required Uint8List fileBytes,
    required String fileName,
    required String documentId,
    String? propertyId,
  }) async {
    // Simulăm procesarea (1-2 secunde)
    await Future.delayed(const Duration(milliseconds: 1500));

    final extracted = _mockExtraction(fileName);
    final confidence = 0.75 + _rng.nextDouble() * 0.22; // 75-97%

    final result = ScanResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      documentId: documentId,
      propertyId: propertyId,
      extractedFields: extracted,
      confidenceScore: double.parse(confidence.toStringAsFixed(2)),
      rawText: _generateMockText(extracted),
      status: ScanStatus.finalizat,
      createdAt: DateTime.now(),
      verificatManual: false,
    );

    _store.add(result);
    return result;
  }

  static Map<String, dynamic> _mockExtraction(String filePath) {
    // Generăm date cadastrale realiste
    final judet = ['Cluj', 'Iași', 'Timiș', 'Brașov', 'Sibiu'][_rng.nextInt(5)];
    final numarCadastral = '${_rng.nextInt(900000) + 100000}';
    final numarCF = '${_rng.nextInt(900000) + 100000}';
    final year = 2018 + _rng.nextInt(7);
    final month = 1 + _rng.nextInt(12);
    final day = 1 + _rng.nextInt(28);

    final tipuri = ['Extras Carte Funciară', 'Plan Cadastral', 'HCL', 'Contract de Concesiune'];
    final tipDoc = tipuri[_rng.nextInt(tipuri.length)];

    final emitenti = [
      'OCPI $judet',
      'Primăria Municipiului $judet',
      'Consiliul Local $judet',
      'ANCPI',
    ];

    return {
      'numarCadastral': {
        'valoare': numarCadastral,
        'incredere': 0.85 + _rng.nextDouble() * 0.12,
      },
      'numarCarteF': {
        'valoare': numarCF,
        'incredere': 0.80 + _rng.nextDouble() * 0.15,
      },
      'dataDocument': {
        'valoare': '$day.${month.toString().padLeft(2, '0')}.$year',
        'incredere': 0.88 + _rng.nextDouble() * 0.10,
      },
      'tipDocument': {
        'valoare': tipDoc,
        'incredere': 0.90 + _rng.nextDouble() * 0.08,
      },
      'numarAct': {
        'valoare': '${_rng.nextInt(9000) + 1000}/${year}',
        'incredere': 0.82 + _rng.nextDouble() * 0.13,
      },
      'emitent': {
        'valoare': emitenti[_rng.nextInt(emitenti.length)],
        'incredere': 0.78 + _rng.nextDouble() * 0.18,
      },
    };
  }

  static String _generateMockText(Map<String, dynamic> fields) {
    final cf = fields['numarCarteF']?['valoare'] ?? '';
    final cad = fields['numarCadastral']?['valoare'] ?? '';
    final data = fields['dataDocument']?['valoare'] ?? '';
    final tip = fields['tipDocument']?['valoare'] ?? '';

    return '''$tip

Nr. $cad / $data

CARTE FUNCIARĂ NR. $cf
UAT - Municipiul

IMOBIL ÎNSCRIS ÎN CARTEA FUNCIARĂ:
Număr cadastral: $cad
Suprafața din acte: conform documentație cadastrală
Categorie de folosință: conform destinație

Data eliberării: $data
Emis în conformitate cu prevederile Legii nr. 7/1996,
a cadastrului și publicității imobiliare, republicată.
''';
  }

  static Future<void> markVerified(String id) async {
    final r = _store.where((e) => e.id == id).firstOrNull;
    if (r != null) r.verificatManual = true;
  }

  static Future<void> updateFields(String id, Map<String, dynamic> fields) async {
    final r = _store.where((e) => e.id == id).firstOrNull;
    if (r != null) {
      r.extractedFields.addAll(fields);
      r.verificatManual = true;
    }
  }

  static Stream<List<ScanResult>> getAll() {
    final sorted = List<ScanResult>.from(_store)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Stream.value(sorted);
  }

  static Future<ScanResult?> getByDocument(String documentId) async {
    return _store.where((e) => e.documentId == documentId).firstOrNull;
  }
}
