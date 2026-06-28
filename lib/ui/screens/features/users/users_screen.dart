import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../../core/models/user/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../widgets/shared_widgets.dart';

// ─── Dialog creare utilizator de admin ─────────────────────────────────────────
Future<void> showCreateUserDialog(BuildContext context, VoidCallback onCreated) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CreateUserDialog(onCreated: onCreated),
  );
}

class _CreateUserDialog extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateUserDialog({required this.onCreated});
  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _deptCtrl       = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  UserRole _role        = UserRole.extern;
  bool _loading         = false;
  String? _error;

  @override
  void dispose() {
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _deptCtrl.dispose(); _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.createUserAsAdmin(
        email: _emailCtrl.text, password: _passwordCtrl.text,
        firstName: _firstNameCtrl.text, lastName: _lastNameCtrl.text,
        phone: _phoneCtrl.text, role: _role,
        departament: _deptCtrl.text.isEmpty ? null : _deptCtrl.text,
      );
      if (mounted) { Navigator.of(context).pop(); widget.onCreated(); }
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  InputDecoration _dec(String label, {IconData? icon}) => InputDecoration(
    labelText: label,
    prefixIcon: icon != null ? Icon(icon, size: 18, color: AppTheme.textGrey) : null,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderColor)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.greenEmerald, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.person_add_outlined, color: AppTheme.greenEmerald),
        SizedBox(width: 10),
        Text('Adaugă utilizator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
      ]),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.errorRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 13))),
                ]),
              ),
              const SizedBox(height: 12),
            ],
            Row(children: [
              Expanded(child: TextFormField(controller: _firstNameCtrl, decoration: _dec('Prenume', icon: Icons.person_outline),
                validator: (v) => (v == null || v.isEmpty) ? 'Obligatoriu' : null)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _lastNameCtrl, decoration: _dec('Nume'),
                validator: (v) => (v == null || v.isEmpty) ? 'Obligatoriu' : null)),
            ]),
            const SizedBox(height: 12),
            TextFormField(controller: _emailCtrl, decoration: _dec('Email', icon: Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@')) ? 'Email invalid' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _passwordCtrl, decoration: _dec('Parolă', icon: Icons.lock_outline),
              obscureText: true,
              validator: (v) => (v == null || v.length < 8) ? 'Minim 8 caractere' : null),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextFormField(controller: _phoneCtrl, decoration: _dec('Telefon', icon: Icons.phone_outlined),
                keyboardType: TextInputType.phone)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _deptCtrl, decoration: _dec('Departament', icon: Icons.business_outlined))),
            ]),
            const SizedBox(height: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tip cont', style: TextStyle(fontSize: 12, color: AppTheme.textGrey, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(children: UserRole.values.map((r) {
                final sel = _role == r;
                return Expanded(child: GestureDetector(
                  onTap: () => setState(() => _role = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(right: r != UserRole.values.last ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.greenEmerald.withValues(alpha: 0.12) : AppTheme.bgGrey,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? AppTheme.greenEmerald : AppTheme.borderColor, width: sel ? 1.5 : 1),
                    ),
                    child: Text(r.label, textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontFamily: 'Inter', fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        color: sel ? AppTheme.greenEmerald : AppTheme.textGrey)),
                  ),
                ));
              }).toList()),
            ]),
          ])),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Anulează', style: TextStyle(color: AppTheme.textGrey)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenEmerald, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Creează cont', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _searchQuery = '';
  UserRole? _filterRole;
  UserStatus? _filterStatus;
  Future<List<UserModel>>? _future;

  @override
  void initState() {
    super.initState();
    _future = AuthService.getAllUsers();
  }

  void _loadData() {
    setState(() => _future = AuthService.getAllUsers());
  }

  Color _roleColor(UserRole r) {
    switch (r) {
      case UserRole.administrator: return const Color(0xFF7C3AED);
      case UserRole.functionar: return AppTheme.greenEmerald;
      case UserRole.extern: return AppTheme.textGrey;
    }
  }

  Color _statusColor(UserStatus s) {
    switch (s) {
      case UserStatus.activ: return AppTheme.successGreen;
      case UserStatus.inactiv: return AppTheme.textGrey;
      case UserStatus.suspendat: return AppTheme.errorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreateUserDialog(context, _loadData),
        backgroundColor: AppTheme.greenEmerald,
        icon: const Icon(Icons.person_add_outlined, color: Colors.white),
        label: const Text('Utilizator nou', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
      ),
      body: Column(
        children: [
          _buildFiltersBar(),
          Expanded(
            child: FutureBuilder<List<UserModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snap.hasError) return Center(child: Text('Eroare: ${snap.error}'));
                var users = snap.data ?? [];
                if (_filterRole != null) users = users.where((u) => u.role == _filterRole).toList();
                if (_filterStatus != null) users = users.where((u) => u.status == _filterStatus).toList();
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  users = users.where((u) =>
                    u.fullName.toLowerCase().contains(q) ||
                    u.email.toLowerCase().contains(q)
                  ).toList();
                }
                if (users.isEmpty) return const EmptyState(message: 'Niciun utilizator găsit', icon: Icons.people_outlined);
                return LayoutBuilder(builder: (ctx, constraints) {
                  if (constraints.maxWidth > 700) return _buildTable(context, users);
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildCard(context, users[i]),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SizedBox(width: 240, height: 42, child: TextField(
          decoration: InputDecoration(
            hintText: 'Caută utilizator...',
            hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
            prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textGrey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.greenEmerald, width: 2)),
            filled: true, fillColor: AppTheme.bgGrey, contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          style: const TextStyle(fontSize: 13),
          onChanged: (v) => setState(() => _searchQuery = v),
        )),
        _drop<UserRole?>(label: 'Rol', value: _filterRole,
          items: [const DropdownMenuItem(value: null, child: Text('Toate rolurile')),
            ...UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label)))],
          onChanged: (v) => setState(() => _filterRole = v)),
        _drop<UserStatus?>(label: 'Status', value: _filterStatus,
          items: [const DropdownMenuItem(value: null, child: Text('Toate statusurile')),
            ...UserStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label)))],
          onChanged: (v) => setState(() => _filterStatus = v)),
      ]),
    );
  }

  Widget _drop<T>({required String label, required T value, required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged}) {
    return Container(
      height: 42, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppTheme.bgGrey, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.borderColor)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(value: value, items: items, onChanged: onChanged,
          hint: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppTheme.textDark),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.textGrey),
          dropdownColor: Colors.white, borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<UserModel> users) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(children: [
              SizedBox(width: 50),
              SizedBox(width: 14),
              Expanded(flex: 3, child: Text('Utilizator', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
              Expanded(flex: 3, child: Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
              SizedBox(width: 120, child: Text('Rol', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
              SizedBox(width: 100, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
              SizedBox(width: 110, child: Text('Înregistrat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
              SizedBox(width: 80, child: Text('Acțiuni', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
            ]),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          ...users.map((u) => _buildTableRow(context, u)),
        ]),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, UserModel u) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: _roleColor(u.role).withValues(alpha: 0.15),
          child: Text(
            u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U',
            style: TextStyle(color: _roleColor(u.role), fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u.fullName.isEmpty ? 'Utilizator' : u.fullName,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          if (u.departament != null)
            Text(u.departament!, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
        ])),
        Expanded(flex: 3, child: Text(u.email, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey), overflow: TextOverflow.ellipsis)),
        SizedBox(width: 120, child: StatusBadge(label: u.role.label, color: _roleColor(u.role))),
        SizedBox(width: 100, child: StatusBadge(label: u.status.label, color: _statusColor(u.status))),
        SizedBox(width: 110, child: Text(DateFormat('dd.MM.yyyy').format(u.createdAt),
          style: const TextStyle(fontSize: 12, color: AppTheme.textGrey))),
        SizedBox(width: 80, child: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textGrey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          itemBuilder: (_) => [
            ...UserRole.values.where((r) => r != u.role).map((r) =>
              PopupMenuItem(value: 'role_${r.name}', child: Row(children: [
                const Icon(Icons.manage_accounts_outlined, size: 16), const SizedBox(width: 8),
                Text('Setează ${r.label}'),
              ]))),
            const PopupMenuDivider(),
            ...UserStatus.values.where((s) => s != u.status).map((s) =>
              PopupMenuItem(value: 'status_${s.name}', child: Row(children: [
                Icon(Icons.toggle_on_outlined, size: 16, color: _statusColor(s)), const SizedBox(width: 8),
                Text('${s.label}', style: TextStyle(color: _statusColor(s))),
              ]))),
          ],
          onSelected: (val) async {
            if (val.startsWith('role_')) {
              final role = UserRole.values.firstWhere((r) => r.name == val.substring(5));
              await AuthService.updateUserRole(u.uid, role);
            } else if (val.startsWith('status_')) {
              final status = UserStatus.values.firstWhere((s) => s.name == val.substring(7));
              await AuthService.updateUserStatus(u.uid, status);
            }
            _loadData();
          },
        )),
      ]),
    );
  }

  Widget _buildCard(BuildContext context, UserModel u) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: _roleColor(u.role).withValues(alpha: 0.15),
          child: Text(u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U',
            style: TextStyle(color: _roleColor(u.role), fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(u.fullName.isEmpty ? 'Utilizator' : u.fullName,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          Text(u.email, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          const SizedBox(height: 6),
          Row(children: [
            StatusBadge(label: u.role.label, color: _roleColor(u.role)),
            const SizedBox(width: 8),
            StatusBadge(label: u.status.label, color: _statusColor(u.status)),
          ]),
        ])),
      ]),
    );
  }
}
