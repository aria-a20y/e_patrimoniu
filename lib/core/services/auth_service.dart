import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user/user_model.dart';
import 'api_service.dart';

class AuthService {
  AuthService._();

  static final _auth = FirebaseAuth.instance;

  // --- Utilizator curent ---
  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Obține modelul complet al utilizatorului curent din backend (PostgreSQL)
  static Future<UserModel?> getCurrentUserModel() async {
    try {
      final data = await ApiService.get('/api/users/me');
      return UserModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting user model: $e');
      return null;
    }
  }

  /// Obține rolul utilizatorului curent
  static Future<UserRole> getCurrentUserRole() async {
    final model = await getCurrentUserModel();
    return model?.role ?? UserRole.extern;
  }

  // --- Autentificare ---
  static Future<User?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = cred.user;
      if (user != null) {
        await _saveLocalUser(user);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  /// Înregistrare utilizator nou — trimis la backend care creează în Firebase Auth + PostgreSQL
  static Future<User?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
    String? departament,
  }) async {
    try {
      // Apelăm backend-ul care creează utilizatorul în Firebase Auth și PostgreSQL
      await ApiService.post('/api/users/register', {
        'email': email.trim(),
        'password': password.trim(),
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phone': phone.trim(),
        'role': role.name,
        'departament': departament,
      });

      // Autentifică utilizatorul nou creat
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = cred.user;
      if (user != null) {
        await user.updateDisplayName('$firstName $lastName'.trim());
        await _saveLocalUser(user);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  static Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  static Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  static Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? departament,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilizator neautentificat');
    await user.updateDisplayName('$firstName $lastName');
    await ApiService.put('/api/users/${user.uid}', {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'phone': phone.trim(),
      'departament': departament,
    });
  }

  static Future<void> updateUserStatus(String uid, UserStatus status) async {
    await ApiService.put('/api/users/$uid/status', {'status': status.name});
  }

  static Future<void> updateUserRole(String uid, UserRole role) async {
    await ApiService.put('/api/users/$uid/role', {'role': role.name});
  }

  static Future<List<UserModel>> getAllUsers() async {
    final data = await ApiService.get('/api/users');
    return (data as List).map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- Private helpers ---
  static Future<void> _saveLocalUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', user.uid);
    await prefs.setString('displayName', user.displayName ?? '');
    await prefs.setString('email', user.email ?? '');
  }

  static String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-email': return 'Adresa de email nu este validă.';
      case 'user-not-found': return 'Nu există un cont cu acest email.';
      case 'wrong-password': return 'Parola este incorectă.';
      case 'user-disabled': return 'Acest cont a fost dezactivat.';
      case 'email-already-in-use': return 'Acest email este deja folosit.';
      case 'weak-password': return 'Parola trebuie să aibă minim 6 caractere.';
      case 'too-many-requests': return 'Prea multe încercări. Reîncercați mai târziu.';
      case 'network-request-failed': return 'Eroare de rețea. Verificați conexiunea.';
      default: return 'Eroare de autentificare. Cod: $code';
    }
  }
}
