import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user/user_model.dart';
import '../config/app_config.dart';
import 'audit_service.dart';

class AuthService {
  AuthService._();

  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  // --- Utilizator curent ---
  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Obține modelul complet al utilizatorului curent
  static Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore
          .collection(AppConfig.colUsers)
          .doc(user.uid)
          .get();
      if (doc.exists) return UserModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting user model: $e');
    }
    return null;
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
        await AuditService.log(
          userId: user.uid,
          userName: user.displayName ?? email,
          actiune: AuditAction.autentificare,
          entitate: 'Sesiune',
          detalii: 'Autentificare reușită',
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  /// Înregistrare utilizator nou (doar de admin sau primul utilizator)
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
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = cred.user;
      if (user != null) {
        final displayName = '$firstName $lastName'.trim();
        await user.updateDisplayName(displayName);

        // Creare document utilizator în Firestore
        await _firestore.collection(AppConfig.colUsers).doc(user.uid).set({
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'role': role.name,
          'status': UserStatus.activ.name,
          'departament': departament,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _saveLocalUser(user);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  /// Trimitere email resetare parolă (folosind domeniu propriu e-Patrimoniu)
  static Future<void> sendPasswordReset(String email) async {
    try {
      final actionSettings = ActionCodeSettings(
        url: 'https://epatrimoniu.ro/reset-password',
        handleCodeInApp: false,
      );
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
        actionCodeSettings: actionSettings,
      );
    } on FirebaseAuthException catch (e) {
      // Fallback fără action settings dacă domeniul nu e configurat
      try {
        await _auth.sendPasswordResetEmail(email: email.trim());
      } catch (_) {
        throw Exception(_mapAuthError(e.code));
      }
    }
  }

  /// Trimitere email verificare (cu branding e-Patrimoniu)
  static Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        final actionSettings = ActionCodeSettings(
          url: 'https://epatrimoniu.ro/verify-email',
          handleCodeInApp: false,
        );
        await user.sendEmailVerification(actionSettings);
      } catch (_) {
        // Fallback fără action settings
        await user.sendEmailVerification();
      }
    }
  }

  static Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      await AuditService.log(
        userId: user.uid,
        userName: user.displayName ?? user.email ?? '',
        actiune: AuditAction.deconectare,
        entitate: 'Sesiune',
        detalii: 'Deconectare utilizator',
      );
    }
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
    await _firestore.collection(AppConfig.colUsers).doc(user.uid).update({
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'phone': phone.trim(),
      'departament': departament,
    });
  }

  /// Actualizare status utilizator (doar admin)
  static Future<void> updateUserStatus(String uid, UserStatus status) async {
    await _firestore
        .collection(AppConfig.colUsers)
        .doc(uid)
        .update({'status': status.name});
  }

  /// Actualizare rol utilizator (doar admin)
  static Future<void> updateUserRole(String uid, UserRole role) async {
    await _firestore
        .collection(AppConfig.colUsers)
        .doc(uid)
        .update({'role': role.name});
  }

  /// Obține toți utilizatorii (doar admin)
  static Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection(AppConfig.colUsers)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
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
