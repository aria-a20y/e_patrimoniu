import 'package:flutter/material.dart';
import '../../styles/auth_styles.dart';
import '../../theme/app_theme.dart';
import '../../../core/models/user/user_model.dart';
import '../../../core/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtl = TextEditingController();
  final _lastNameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmPassCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  UserRole _selectedRole = UserRole.extern;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.register(
        email: _emailCtl.text.trim(),
        password: _passCtl.text,
        firstName: _firstNameCtl.text.trim(),
        lastName: _lastNameCtl.text.trim(),
        phone: _phoneCtl.text.trim(),
        role: _selectedRole,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cont creat! Verificaţi emailul pentru confirmare.'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError('Eroare: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Acest email este deja înregistrat.';
      case 'weak-password': return 'Parola trebuie să aibă minim 6 caractere.';
      case 'invalid-email': return 'Email invalid.';
      default: return 'Eroare la înregistrare ($code)';
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.errorRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _emailCtl.dispose();
    _passCtl.dispose();
    _confirmPassCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.loginGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      AuthStyles.logo(context: context, size: 60),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Creare Cont',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _firstNameCtl,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: AuthStyles.inputDecoration('Prenume', context),
                                      validator: (v) => v?.trim().isEmpty == true ? 'Obligatoriu' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _lastNameCtl,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: AuthStyles.inputDecoration('Nume', context),
                                      validator: (v) => v?.trim().isEmpty == true ? 'Obligatoriu' : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _emailCtl,
                                style: const TextStyle(color: Colors.white),
                                decoration: AuthStyles.inputDecoration('Email', context),
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v?.trim().isEmpty == true) return 'Obligatoriu';
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v!.trim())) return 'Email invalid';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _phoneCtl,
                                style: const TextStyle(color: Colors.white),
                                decoration: AuthStyles.inputDecoration('Telefon', context),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 14),
                              // Selecţie rol
                              DropdownButtonFormField<UserRole>(
                                value: _selectedRole,
                                dropdownColor: const Color(0xFF1B4332),
                                style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                                decoration: AuthStyles.inputDecoration('Tip cont', context),
                                items: const [
                                  DropdownMenuItem(value: UserRole.extern,         child: Text('Utilizator')),
                                  DropdownMenuItem(value: UserRole.functionar,     child: Text('Funcţionar')),
                                  DropdownMenuItem(value: UserRole.administrator,  child: Text('Administrator')),
                                ],
                                onChanged: (v) => setState(() => _selectedRole = v ?? UserRole.extern),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passCtl,
                                obscureText: _obscure,
                                style: const TextStyle(color: Colors.white),
                                decoration: AuthStyles.inputDecoration('Parolă', context).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white54, size: 20),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => (v?.length ?? 0) < 6 ? 'Minim 6 caractere' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _confirmPassCtl,
                                obscureText: _obscureConfirm,
                                style: const TextStyle(color: Colors.white),
                                decoration: AuthStyles.inputDecoration('Confirmare Parolă', context).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white54, size: 20),
                                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),
                                validator: (v) => v != _passCtl.text ? 'Parolele nu coincid' : null,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  style: AuthStyles.primaryButton(context),
                                  onPressed: _loading ? null : _submit,
                                  child: _loading
                                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                      : const Text('Creare Cont', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ),
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
      ),
    );
  }
}
