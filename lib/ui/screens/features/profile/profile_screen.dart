import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../../core/models/user/user_model.dart';
import '../../../../core/services/auth_service.dart';

/// Dialog complet pentru vizualizare, editare și ștergere cont propriu.
/// Apelat din sidebar footer via showDialog.
Future<void> showProfileDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => const _ProfileDialog(),
  );
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog();
  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  UserModel? _user;
  bool _loading = true;
  bool _editMode = false;
  bool _saving = false;
  String? _error;

  final _firstNameCtl = TextEditingController();
  final _lastNameCtl  = TextEditingController();
  final _phoneCtl     = TextEditingController();
  final _deptCtl      = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final u = await AuthService.getCurrentUserModel();
      if (u != null && mounted) {
        _firstNameCtl.text = u.firstName;
        _lastNameCtl.text  = u.lastName;
        _phoneCtl.text     = u.phone;
        _deptCtl.text      = u.departament ?? '';
        setState(() { _user = u; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    if (_firstNameCtl.text.trim().isEmpty || _lastNameCtl.text.trim().isEmpty) {
      _showSnack('Prenume și nume sunt obligatorii.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await AuthService.updateProfile(
        firstName:   _firstNameCtl.text.trim(),
        lastName:    _lastNameCtl.text.trim(),
        phone:       _phoneCtl.text.trim(),
        departament: _deptCtl.text.trim().isEmpty ? null : _deptCtl.text.trim(),
      );
      await _load();
      if (mounted) {
        setState(() => _editMode = false);
        _showSnack('Profil actualizat cu succes.');
      }
    } catch (e) {
      if (mounted) _showSnack('Eroare: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _user?.email ?? FirebaseAuth.instance.currentUser?.email ?? '';
    try {
      await AuthService.sendPasswordReset(email);
      if (mounted) _showSnack('Email de resetare trimis la $email.');
    } catch (e) {
      if (mounted) _showSnack('Eroare: $e', error: true);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteConfirmDialog(email: _user?.email ?? ''),
    );
    if (confirmed != true || !mounted) return;

    try {
      await AuthService.deleteAccount();
      // Firebase sign-out triggers auth redirect automatically
    } catch (e) {
      if (mounted) _showSnack('Eroare la ștergere: $e', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.errorRed : AppTheme.successGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _phoneCtl.dispose();
    _deptCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, minWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Eroare: $_error', style: const TextStyle(color: AppTheme.errorRed)),
              )
            else ...[
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: _editMode ? _buildEditForm() : _buildViewContent(),
                ),
              ),
              _buildActions(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = _user;
    final initials = user != null
        ? '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'.toUpperCase()
        : 'U';
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Contul meu',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 2),
                if (user != null)
                  _roleBadge(user.role),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(UserRole role) {
    Color color;
    IconData icon;
    switch (role) {
      case UserRole.administrator:
        color = const Color(0xFFF59E0B); icon = Icons.admin_panel_settings_outlined;
      case UserRole.functionar:
        color = AppTheme.infoBlue; icon = Icons.work_outline_rounded;
      case UserRole.extern:
        color = Colors.white60; icon = Icons.person_outline_rounded;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(role.label, style: TextStyle(color: color, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildViewContent() {
    final u = _user!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(Icons.email_outlined, 'Email', u.email),
        _infoRow(Icons.phone_outlined, 'Telefon', u.phone.isEmpty ? '—' : u.phone),
        _infoRow(Icons.business_outlined, 'Departament', u.departament?.isEmpty != false ? '—' : u.departament!),
        _infoRow(Icons.shield_outlined, 'Status', u.status.label),
        _infoRow(Icons.calendar_today_outlined, 'Cont creat la',
            DateFormat('dd.MM.yyyy').format(u.createdAt)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey, fontFamily: 'Inter')),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.textDark, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _field('Prenume *', _firstNameCtl, Icons.person_outlined)),
          const SizedBox(width: 12),
          Expanded(child: _field('Nume *', _lastNameCtl, Icons.person_outlined)),
        ]),
        const SizedBox(height: 14),
        _field('Telefon', _phoneCtl, Icons.phone_outlined, type: TextInputType.phone),
        const SizedBox(height: 14),
        _field('Departament', _deptCtl, Icons.business_outlined),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctl, IconData icon, {TextInputType? type}) {
    return TextFormField(
      controller: ctl,
      keyboardType: type,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppTheme.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppTheme.textGrey, fontFamily: 'Inter'),
        prefixIcon: Icon(icon, size: 18, color: AppTheme.textGrey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.greenEmerald, width: 2)),
        filled: true, fillColor: AppTheme.bgGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildActions() {
    if (_editMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => setState(() => _editMode = false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Anulează', style: TextStyle(fontFamily: 'Inter', color: AppTheme.textGrey)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.greenEmerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Salvează', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _editMode = true),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editează', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.greenEmerald,
                    side: const BorderSide(color: AppTheme.greenEmerald),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sendPasswordReset,
                  icon: const Icon(Icons.lock_reset_outlined, size: 16),
                  label: const Text('Schimbă parola', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.infoBlue,
                    side: const BorderSide(color: AppTheme.infoBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Șterge contul', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                side: const BorderSide(color: AppTheme.errorRed),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog de confirmare ștergere cont ─────────────────────────────────────

class _DeleteConfirmDialog extends StatefulWidget {
  final String email;
  const _DeleteConfirmDialog({required this.email});
  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  final _ctl = TextEditingController();
  bool _canDelete = false;

  @override
  void dispose() { _ctl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.errorRed,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Șterge contul', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Inter')),
            ),
            IconButton(icon: const Icon(Icons.close, color: Colors.white70, size: 20), onPressed: () => Navigator.pop(context, false)),
          ],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Această acțiune este ireversibilă. Contul și toate datele asociate vor fi șterse permanent.',
            style: TextStyle(fontSize: 13, color: AppTheme.textDark, fontFamily: 'Inter', height: 1.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Tastați "ȘTERGE" pentru a confirma:',
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'Inter'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ctl,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ȘTERGE',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.errorRed, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true, fillColor: AppTheme.bgGrey,
            ),
            onChanged: (v) => setState(() => _canDelete = v.trim() == 'ȘTERGE'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Anulează', style: TextStyle(color: AppTheme.textGrey, fontFamily: 'Inter')),
        ),
        ElevatedButton(
          onPressed: _canDelete ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorRed,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.red.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Șterge contul', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
