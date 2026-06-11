import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ui/screens/auth/login.dart';
import 'ui/screens/auth/reset_password.dart';
import 'ui/screens/main_layout.dart';
import 'ui/theme/app_theme.dart';

class EPatrimoniuApp extends StatelessWidget {
  const EPatrimoniuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'e-Patrimoniu',
      theme: AppTheme.light,
      home: const _AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/reset': (_) => const ResetPasswordScreen(),
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((u) {
      if (mounted) setState(() => _user = u);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const LoginScreen();
    return const MainLayout();
  }
}
