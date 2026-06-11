import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'e_patrimoniu_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Eroare Firebase: $e');
  }

  runApp(const EPatrimoniuApp());
}
