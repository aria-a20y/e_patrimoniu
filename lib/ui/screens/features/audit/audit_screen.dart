import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../../core/services/audit_service.dart';
import '../../../../core/models/audit/audit_log_model.dart';
import '../../../widgets/shared_widgets.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});
  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  AuditAction? _filterAction;
  String _searchQuery = '';

  Color _actionColor(AuditAction a) {
    switch (a) {
      case AuditAction.adaugare: return AppTheme.successGreen;
      case AuditAction.modificare: return AppTheme.infoBlue;
      case AuditAction.stergere: return AppTheme.errorRed;
      case AuditAction.actualizareStatus: return AppTheme.warningOrange;
      case AuditAction.incarcarDocument: return const Color(0xFF7C3AED);
      case AuditAction.creareLicitatie: return AppTheme.warningOrange;
      case AuditAction.depunereOferta: return AppTheme.greenMid;
      case AuditAction.autentificare: return AppTheme.greenEmerald;
      case AuditAction.deconectare: return AppTheme.textGrey;
    }
  }

  IconData _actionIcon(AuditAction a) {
    switch (a) {
      case AuditAction.adaugare: return Icons.add_circle_outline;
      case AuditAction.modificare: return Icons.edit_outlined;
      case AuditAction.stergere: return Icons.delete_outline;
      case AuditAction.actualizareStatus: return Icons.update_outlined;
      case AuditAction.incarcarDocument: return Icons.upload_file_outlined;
      case AuditAction.creareLicitatie: return Icons.gavel_outlined;
      case AuditAction.depunereOferta: return Icons.price_change_outlined;
      case AuditAction.autentificare: return Icons.login_outlined;
      case AuditAction.deconectare: return Icons.logout_outlined;
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
            child: StreamBuilder<List<AuditLogModel>>(
              stream: AuditService.getLogs(actiune: _filterAction),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                var logs = snap.data!;
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  logs = logs.where((l) =>
                    l.userName.toLowerCase().contains(q) ||
                    l.detalii.toLowerCase().contains(q) ||
                    l.entitate.toLowerCase().contains(q)
                  ).toList();
                }
                if (logs.isEmpty) return const EmptyState(message: 'Nicio activitate înregistrată', icon: Icons.history_outlined);
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _buildLogTile(logs[i]),
                );
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
            hintText: 'Caută în jurnal...',
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
        Container(
          height: 42, padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: AppTheme.bgGrey, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.borderColor)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<AuditAction?>(
              value: _filterAction,
              items: [const DropdownMenuItem(value: null, child: Text('Toate acțiunile')),
                ...AuditAction.values.map((a) => DropdownMenuItem(value: a, child: Text(a.label)))],
              onChanged: (v) => setState(() => _filterAction = v),
              hint: const Text('Acțiune', style: TextStyle(fontSize: 13, color: AppTheme.textGrey)),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppTheme.textDark),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.textGrey),
              dropdownColor: Colors.white, borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.infoBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.infoBlue),
            SizedBox(width: 6),
            Text('Afișate ultimele 200 de înregistrări', style: TextStyle(fontSize: 12, color: AppTheme.infoBlue)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildLogTile(AuditLogModel log) {
    final color = _actionColor(log.actiune);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(_actionIcon(log.actiune), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  StatusBadge(label: log.actiune.label, color: color),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.bgGrey, borderRadius: BorderRadius.circular(8)),
                    child: Text(log.entitate, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey, fontWeight: FontWeight.w500)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(log.detalii, style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.4)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.person_outline, size: 13, color: AppTheme.textGrey),
                  const SizedBox(width: 4),
                  Text(log.userName.isEmpty ? 'Sistem' : log.userName,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGrey, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  const Icon(Icons.schedule_outlined, size: 13, color: AppTheme.textGrey),
                  const SizedBox(width: 4),
                  Text(DateFormat('dd.MM.yyyy HH:mm:ss').format(log.dataOra),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
