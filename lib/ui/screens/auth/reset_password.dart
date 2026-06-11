import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../styles/auth_styles.dart';
import '../../theme/app_theme.dart';

// ============================================================
// RESET PASSWORD SCREEN
// ============================================================
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailCtl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  Future<void> _send() async {
    if (_emailCtl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      // Trimitere email resetare parolă prin Firebase (fără legătură cu proiectul vechi)
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailCtl.text.trim(),
      );
      setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message ?? 'Eroare la trimiterea emailului'),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _emailCtl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.loginGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AuthStyles.logo(context: context, size: 60),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: _sent ? _buildSentView() : _buildForm(),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.greenLight),
                      child: const Text('← Înapoi la Conectare'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset_rounded, color: Colors.white70, size: 40),
        const SizedBox(height: 16),
        const Text(
          'Resetare Parolă',
          style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Introduceți emailul și vă vom trimite instrucțiunile de resetare.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _emailCtl,
          style: const TextStyle(color: Colors.white),
          decoration: AuthStyles.inputDecoration('Email', context),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: AuthStyles.primaryButton(context),
            onPressed: _loading ? null : _send,
            child: _loading
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Trimite Instrucțiunile', style: TextStyle(fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildSentView() {
    return Column(
      children: [
        const Icon(Icons.mark_email_read_outlined, color: AppTheme.greenLight, size: 56),
        const SizedBox(height: 16),
        const Text('Email Trimis!', style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
          'Verificați inbox-ul pentru emailul de resetare a parolei.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ============================================================
// VERIFY EMAIL SCREEN
// ============================================================
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.loginGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mark_email_unread_outlined, color: AppTheme.greenLight, size: 60),
                      const SizedBox(height: 20),
                      const Text('Verificare Email', style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text(
                        'Vă rugăm să verificați emailul și să confirmați adresa pentru a continua.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: AuthStyles.primaryButton(context),
                          onPressed: () async {
                            await FirebaseAuth.instance.currentUser?.reload();
                          },
                          child: const Text('Am verificat emailul'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.currentUser?.sendEmailVerification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Email de verificare retrimis'), backgroundColor: AppTheme.successGreen),
                            );
                          }
                        },
                        style: TextButton.styleFrom(foregroundColor: AppTheme.greenLight),
                        child: const Text('Retrimite emailul de verificare'),
                      ),
                      TextButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        style: TextButton.styleFrom(foregroundColor: Colors.white54),
                        child: const Text('Deconectare'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
