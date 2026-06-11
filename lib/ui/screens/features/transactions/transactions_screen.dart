import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../../core/models/transaction/transaction_model.dart';
import '../../../../core/services/other_services.dart';
import '../../../../core/services/auth_service.dart';
import '../../../widgets/shared_widgets.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';
  TransactionStatus? _filterStatus;
  TransactionType? _filterTip;

  Color _statusColor(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.initiata: return AppTheme.textGrey;
      case TransactionStatus.aprobata: return AppTheme.infoBlue;
      case TransactionStatus.inDerulare: return AppTheme.warningOrange;
      case TransactionStatus.finalizata: return AppTheme.successGreen;
      case TransactionStatus.anulata: return AppTheme.errorRed;
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
            child: StreamBuilder<List<TransactionModel>>(
              stream: TransactionService.getAll(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                var txs = snap.data!;
                if (_filterStatus != null) txs = txs.where((t) => t.status == _filterStatus).toList();
                if (_filterTip != null) txs = txs.where((t) => t.tip == _filterTip).toList();
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  txs = txs.where((t) => t.propertyDenumire.toLowerCase().contains(q) || t.numarHcl.toLowerCase().contains(q) || t.descriere.toLowerCase().contains(q)).toList();
                }
                if (txs.isEmpty) return EmptyState(
                  message: 'Nicio tranzacție găsită',
                  icon: Icons.swap_horiz_outlined,
                  actionLabel: 'Adaugă tranzacție',
                  onAction: () => _showAddDialog(context),
                );
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: txs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _buildTxCard(context, txs[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppTheme.greenEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Adaugă tranzacție', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Wrap(
        spacing: 12, runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 240, height: 42,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Caută...',
                hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textGrey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.greenEmerald, width: 2)),
                filled: true, fillColor: AppTheme.bgGrey,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          _filterDrop<TransactionStatus?>(
            label: 'Status',
            value: _filterStatus,
            items: [const DropdownMenuItem(value: null, child: Text('Toate statusurile')),
              ...TransactionStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label)))],
            onChanged: (v) => setState(() => _filterStatus = v),
          ),
          _filterDrop<TransactionType?>(
            label: 'Tip',
            value: _filterTip,
            items: [const DropdownMenuItem(value: null, child: Text('Toate tipurile')),
              ...TransactionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label)))],
            onChanged: (v) => setState(() => _filterTip = v),
          ),
        ],
      ),
    );
  }

  Widget _filterDrop<T>({required String label, required T value, required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged}) {
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

  Widget _buildTxCard(BuildContext context, TransactionModel t) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.greenPale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t.tip.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.greenDark, fontFamily: 'Inter')),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(t.propertyDenumire,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                overflow: TextOverflow.ellipsis)),
              StatusBadge(label: t.status.label, color: _statusColor(t.status)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.descriere.isEmpty ? '—' : t.descriere,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textGrey, height: 1.4)),
                const SizedBox(height: 12),
                Row(children: [
                  _metaChip(Icons.article_outlined, 'HCL: ${t.numarHcl}'),
                  const SizedBox(width: 8),
                  _metaChip(Icons.calendar_today_outlined, DateFormat('dd.MM.yyyy').format(t.dataTransactie)),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textGrey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    itemBuilder: (_) => TransactionStatus.values
                      .where((s) => s != t.status)
                      .map((s) => PopupMenuItem(value: s.name, child: Text('→ ${s.label}')))
                      .toList(),
                    onSelected: (statusName) async {
                      final newStatus = TransactionStatus.values.firstWhere((s) => s.name == statusName);
                      final user = await AuthService.getCurrentUserModel();
                      await TransactionService.updateStatus(t.id, newStatus, userId: user?.uid ?? '', userName: user?.fullName ?? '');
                    },
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: AppTheme.textGrey),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
    ]);
  }

  void _showAddDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final descrCtl = TextEditingController();
    final hclCtl = TextEditingController();
    final propCtl = TextEditingController();
    TransactionType tip = TransactionType.transfer;
    DateTime data = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Adaugă tranzacție', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AppTextField(label: 'Bun imobiliar *', controller: propCtl, validator: (v) => v?.trim().isEmpty == true ? 'Obligatoriu' : null),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TransactionType>(
                    value: tip,
                    decoration: InputDecoration(
                      labelText: 'Tip tranzacție *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true, fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    items: TransactionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setS(() => tip = v ?? tip),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Număr HCL *', controller: hclCtl, validator: (v) => v?.trim().isEmpty == true ? 'Obligatoriu' : null),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Descriere', controller: descrCtl, maxLines: 3),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulare', style: TextStyle(color: AppTheme.textGrey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenEmerald, foregroundColor: Colors.white),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final user = await AuthService.getCurrentUserModel();
                final tx = TransactionModel(
                  id: '', propertyId: 'unknown', propertyDenumire: propCtl.text.trim(),
                  tip: tip, descriere: descrCtl.text.trim(), numarHcl: hclCtl.text.trim(),
                  dataTransactie: data, status: TransactionStatus.initiata, documentIds: [],
                  createdAt: DateTime.now(), createdBy: user?.uid ?? '',
                );
                await TransactionService.create(tx, userId: user?.uid ?? '', userName: user?.fullName ?? '');
              },
              child: const Text('Adaugă'),
            ),
          ],
        ),
      ),
    );
  }
}
