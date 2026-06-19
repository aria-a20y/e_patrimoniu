enum UserRole { administrator, functionar, extern }
enum UserStatus { activ, inactiv, suspendat }

extension UserRoleExt on UserRole {
  String get label {
    switch (this) {
      case UserRole.administrator: return 'Administrator';
      case UserRole.functionar: return 'Funcționar Public';
      case UserRole.extern: return 'Utilizator Extern';
    }
  }
}

extension UserStatusExt on UserStatus {
  String get label {
    switch (this) {
      case UserStatus.activ: return 'Activ';
      case UserStatus.inactiv: return 'Inactiv';
      case UserStatus.suspendat: return 'Suspendat';
    }
  }
}

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final UserRole role;
  final UserStatus status;
  final String? photoUrl;
  final String? departament;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.photoUrl,
    this.departament,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory UserModel.fromJson(Map<String, dynamic> d) {
    return UserModel(
      uid: d['id']?.toString() ?? d['uid']?.toString() ?? '',
      firstName: d['firstName'] ?? '',
      lastName: d['lastName'] ?? '',
      email: d['email'] ?? '',
      phone: d['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == d['role'],
        orElse: () => UserRole.extern,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => UserStatus.activ,
      ),
      photoUrl: d['photoUrl'],
      departament: d['departament'],
      createdAt: DateTime.tryParse(d['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phone': phone,
    'role': role.name,
    'status': status.name,
    'departament': departament,
  };
}
