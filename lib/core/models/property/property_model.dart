double _parseDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

enum PropertyType { teren, cladire, spatiu, constructie }
enum JuridicalDomain { public, privat }
enum PropertyStatus { activ, inactiv, scosEvidenta, inLitigiu }

extension PropertyTypeExt on PropertyType {
  String get label {
    switch (this) {
      case PropertyType.teren: return 'Teren';
      case PropertyType.cladire: return 'Clădire';
      case PropertyType.spatiu: return 'Spațiu';
      case PropertyType.constructie: return 'Construcție';
    }
  }
}

extension JuridicalDomainExt on JuridicalDomain {
  String get label {
    switch (this) {
      case JuridicalDomain.public: return 'Domeniu Public';
      case JuridicalDomain.privat: return 'Domeniu Privat';
    }
  }
}

extension PropertyStatusExt on PropertyStatus {
  String get label {
    switch (this) {
      case PropertyStatus.activ: return 'Activ';
      case PropertyStatus.inactiv: return 'Inactiv';
      case PropertyStatus.scosEvidenta: return 'Scos din evidență';
      case PropertyStatus.inLitigiu: return 'În litigiu';
    }
  }
}

class PropertyModel {
  final String id;
  final String denumire;
  final PropertyType tip;
  final String adresa;
  final String localitate;
  final JuridicalDomain domeniuJuridic;
  final String numarCadastral;
  final String numarCarteF;
  final double suprafata;
  final double valoareInventar;
  final String destinatie;
  final PropertyStatus status;
  final String? descriere;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  PropertyModel({
    required this.id,
    required this.denumire,
    required this.tip,
    required this.adresa,
    required this.localitate,
    required this.domeniuJuridic,
    required this.numarCadastral,
    required this.numarCarteF,
    required this.suprafata,
    required this.valoareInventar,
    required this.destinatie,
    required this.status,
    this.descriere,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> d) {
    return PropertyModel(
      id: d['id']?.toString() ?? '',
      denumire: d['denumire'] ?? '',
      tip: PropertyType.values.firstWhere(
        (e) => e.name == d['tip'],
        orElse: () => PropertyType.teren,
      ),
      adresa: d['adresa'] ?? '',
      localitate: d['localitate'] ?? '',
      domeniuJuridic: JuridicalDomain.values.firstWhere(
        (e) => e.name == d['domeniuJuridic'],
        orElse: () => JuridicalDomain.public,
      ),
      numarCadastral: d['numarCadastral'] ?? '',
      numarCarteF: d['numarCarteF'] ?? '',
      suprafata: _parseDouble(d['suprafata']),
      valoareInventar: _parseDouble(d['valoareInventar']),
      destinatie: d['destinatie'] ?? '',
      status: PropertyStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => PropertyStatus.activ,
      ),
      descriere: d['descriere'],
      imageUrl: d['imageUrl'],
      createdAt: _parseDate(d['createdAt']),
      updatedAt: _parseDate(d['updatedAt']),
      createdBy: d['createdBy'] ?? '',
    );
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'denumire': denumire,
    'tip': tip.name,
    'adresa': adresa,
    'localitate': localitate,
    'domeniuJuridic': domeniuJuridic.name,
    'numarCadastral': numarCadastral,
    'numarCarteF': numarCarteF,
    'suprafata': suprafata,
    'valoareInventar': valoareInventar,
    'destinatie': destinatie,
    'status': status.name,
    'descriere': descriere,
    'imageUrl': imageUrl,
  };

  PropertyModel copyWith({
    String? denumire,
    PropertyType? tip,
    String? adresa,
    String? localitate,
    JuridicalDomain? domeniuJuridic,
    String? numarCadastral,
    String? numarCarteF,
    double? suprafata,
    double? valoareInventar,
    String? destinatie,
    PropertyStatus? status,
    String? descriere,
    String? imageUrl,
  }) {
    return PropertyModel(
      id: id,
      denumire: denumire ?? this.denumire,
      tip: tip ?? this.tip,
      adresa: adresa ?? this.adresa,
      localitate: localitate ?? this.localitate,
      domeniuJuridic: domeniuJuridic ?? this.domeniuJuridic,
      numarCadastral: numarCadastral ?? this.numarCadastral,
      numarCarteF: numarCarteF ?? this.numarCarteF,
      suprafata: suprafata ?? this.suprafata,
      valoareInventar: valoareInventar ?? this.valoareInventar,
      destinatie: destinatie ?? this.destinatie,
      status: status ?? this.status,
      descriere: descriere ?? this.descriere,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      createdBy: createdBy,
    );
  }
}
