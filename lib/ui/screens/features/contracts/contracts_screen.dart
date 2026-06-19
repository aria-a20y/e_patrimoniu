import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../../core/models/contract/contract_model.dart';
import '../../../../core/services/other_services.dart';
import '../../../../core/services/auth_service.dart';
import '../../../widgets/shared_widgets.dart';

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});
  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  String _searchQuery = '';
  ContractStatus? _filterStatus;
  Future<List<ContractModel>>? _future;

  @override
  void initState() {
    super.initState();
    _future = ContractService.getAll();
  }

  void _loadData() {
    setState(() => _future = ContractService.getAll());
  }

  Color _statusColor(ContractStatus s) {
    switch (s) {
      case ContractStatus.activ: return AppTheme.successGreen;
      case ContractStatus.prelungit: return AppTheme.infoBlue;
      case ContractStatus.reziliat: return AppTheme.errorRed;
      case ContractStatus.expirat: return AppTheme.textGrey;
      case ContractStatus.finalizat: return AppTheme.greenDark;
      case ContractStatus.anulat: return AppTheme.errorRed;
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
            child: FutureBuilder<List<ContractModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snap.hasError) return Center(child: Text('Eroare: ${snap.error}'));
                var contracts = snap.data ?? [];
                if (_filterStatus != null) contracts = contracts.where((c) => c.status == _filterStatus).toList();
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  contracts = contracts.where((c) =>
                    c.numarContract.toLowerCase().contains(q) ||
                    c.parteContractanta.toLowerCase().contains(q) ||
                    c.propertyDenumire.toLowerCase().contains(q)
                  ).toList();
                }
                if (contracts.isEmpty) return EmptyState(
                  message: 'Niciun contract găsit',
                  icon: Icons.description_outlined,
                  actionLabel: 'Adaugă contract',
                  onAction: () => _showAddDialog(context),
                );
                return LayoutBuilder(builder: (ctx, constraints) {
                  if (constraints.maxWidth > 700) return _buildTable(context, contracts);
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: contracts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildCard(context, contracts[i]),
                  );
                });
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
        label: const Text('Adaugă contract', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
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
            hintText: 'Caută contract...',
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
            child: DropdownButton<ContractStatus?>(
              value: _filterStatus,
              items: [const DropdownMenuItem(value: null, child: Text('Toate statusurile')),
                ...ContractStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label)))],
              onChanged: (v) => setState(() => _filterStatus = v),
              hint: const Text('Status', style: TextStyle(fontSize: 13, color: AppTheme.textGrey)),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppTheme.textDark),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.textGrey),
              dropdownColor: Colors.white, borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildTable(BuildContext context, List<ContractModel> contracts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(children: [
              Expanded(flex: 2, child: Text('Nr. contract', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
              Expanded(flex: 3, child: Text('Parte contractantă', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
              Expanded(flex: 3, child: Text('Bun imobiliar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
              SizedBox(width: 180, child: Text('Perioadă', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
              SizedBox(width: 120, child: Text('Valoare', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
              SizedBox(width: 80, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
              SizedBox(width: 60),
            ]),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          ...contracts.map((c) => _buildTableRow(context, c)),
        ]),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, ContractModel c) {
    final daysLeft = c.dataFinal.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysLeft >= 0 && daysLeft <= 30;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isExpiringSoon ? AppTheme.warningOrange.withValues(alpha: 0.03) : null,
        border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(children: [
        Expanded(flex: 2, child: Text(c.numarContract, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark))),
        Expanded(flex: 3, child: Text(c.parteContractanta, style: const TextStyle(fontSize: 13, color: AppTheme.textGrey), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 3, child: Text(c.propertyDenumire, style: const TextStyle(fontSize: 13, color: AppTheme.textGrey), overflow: TextOverflow.ellipsis)),
        SizedBox(width: 180, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${DateFormat('dd.MM.yyyy').format(c.dataInceput)} – ${DateFormat('dd.MM.yyyy').format(c.dataFinal)}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          if (isExpiringSoon)
            Text('Expiră în $daysLeft zile!', style: const TextStyle(fontSize: 11, color: AppTheme.warningOrange, fontWeight: FontWeight.w600)),
        ])),
        SizedBox(width: 120, child: Text('${c.valoare.toStringAsFixed(2)} ${c.valutaMoneda}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.greenEmerald))),
        SizedBox(width: 80, child: StatusBadge(label: c.status.label, color: _statusColor(c.status))),
        SizedBox(width: 60, child: PopupMenuButton<ContractStatus>(
          icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textGrey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          itemBuilder: (_) => ContractStatus.values.where((s) => s != c.status)
            .map((s) => PopupMenuItem(value: s, child: Text('→ ${s.label}'))).toList(),
          onSelected: (newStatus) async {
            await ContractService.updateStatus(c.id, newStatus);
            _loadData();
          },
        )),
      ]),
    );
  }

  Widget _buildCard(BuildContext context, ContractModel c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(c.numarContract, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark))),
          StatusBadge(label: c.status.label, color: _statusColor(c.status)),
        ]),
        const SizedBox(height: 6),
        Text(c.parteContractanta, style: const TextStyle(fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w500)),
        Text(c.propertyDenumire, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textGrey),
          const SizedBox(width: 4),
          Text('${DateFormat('dd.MM.yyyy').format(c.dataInceput)} – ${DateFormat('dd.MM.yyyy').format(c.dataFinal)}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          const Spacer(),
          Text('${c.valoare.toStringAsFixed(2)} ${c.valutaMoneda}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.greenEmerald)),
        ]),
      ]),
    );
  }

  void _showAddDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final numarCtl = TextEditingController();
    final parteCtl = TextEditingController();
    final propCtl = TextEditingController();
    final valoareCtl = TextEditingController();
    DateTime dataInceput = DateTime.now();
    DateTime dataFinal = DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Adaugă contract', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AppTextField(label: 'Număr contract *', controller: numarCtl, validator: (v) => v?.trim().isEmpty == true ? 'Obligatoriu' : null),
                const SizedBox(height: 12),
                AppTextField(label: 'Parte contractantă *', controller: parteCtl, validator: (v) => v?.trim().isEmpty == true ? 'Obligatoriu' : null),
                const SizedBox(height: 12),
                AppTextField(label: 'Bun imobiliar *', controller: propCtl, validator: (v) => v?.trim().isEmpty == true ? 'Obligatoriu' : null),
                const SizedBox(height: 12),
                AppTextField(label: 'Valoare (RON) *', controller: valoareCtl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Valoare numerică' : null),
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
              final c = ContractModel(
                id: '', propertyId: 'unknown', propertyDenumire: propCtl.text.trim(),
                numarContract: numarCtl.text.trim(), parteContractanta: parteCtl.text.trim(),
                dataInceput: dataInceput, dataFinal: dataFinal,
                valoare: double.tryParse(valoareCtl.text) ?? 0, valutaMoneda: 'RON',
                status: ContractStatus.activ, createdAt: DateTime.now(), createdBy: user?.uid ?? '',
              );
              await ContractService.create(c);
              _loadData();
            },
            child: const Text('Adaugă'),
          ),
        ],
      ),
    );
  }
}
