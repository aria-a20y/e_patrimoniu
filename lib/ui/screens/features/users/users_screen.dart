import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../../core/models/user/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../widgets/shared_widgets.dart';

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
