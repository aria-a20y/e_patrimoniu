import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../../core/models/property/property_model.dart';
import '../../../../core/services/property_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../widgets/shared_widgets.dart';
import 'property_form.dart';
import 'property_detail.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});
  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  PropertyType? _filterTip;
  JuridicalDomain? _filterDomeniu;
  PropertyStatus? _filterStatus;
  String _searchQuery = '';
  Future<List<PropertyModel>>? _future;

  @override
  void initState() {
    super.initState();
    _future = PropertyService.getAll(tip: _filterTip, status: _filterStatus);
  }

  void _loadData() {
    setState(() {
      _future = PropertyService.getAll(tip: _filterTip, status: _filterStatus);
    });
  }

  Color _statusColor(PropertyStatus s) {
    switch (s) {
      case PropertyStatus.activ: return AppTheme.successGreen;
      case PropertyStatus.inactiv: return AppTheme.textGrey;
      case PropertyStatus.scosEvidenta: return AppTheme.errorRed;
      case PropertyStatus.inLitigiu: return AppTheme.warningOrange;
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
            child: FutureBuilder<List<PropertyModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('Eroare: ${snap.error}'));
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var props = snap.data ?? [];
                // Client-side: domeniu + search
                if (_filterDomeniu != null) props = props.where((p) => p.domeniuJuridic == _filterDomeniu).toList();
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  props = props.where((p) =>
                    p.denumire.toLowerCase().contains(q) ||
                    p.adresa.toLowerCase().contains(q) ||
                    p.numarCadastral.toLowerCase().contains(q) ||
                    p.numarCarteF.toLowerCase().contains(q)
                  ).toList();
                }
                if (props.isEmpty) {
                  return EmptyState(
                    message: 'Niciun bun imobiliar găsit',
                    icon: Icons.business_outlined,
                    actionLabel: '+ Adaugă bun imobiliar',
                    onAction: () => _openForm(context),
                  );
                }
                return _buildList(context, props);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppTheme.greenEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Adaugă bun imobiliar', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 42,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Caută denumire, adresă, nr. cadastral...',
                hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textGrey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.greenEmerald, width: 2)),
                filled: true,
                fillColor: AppTheme.bgGrey,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          _filterDropdown<PropertyType?>(
            label: 'Tip imobil',
            value: _filterTip,
            items: [
              const DropdownMenuItem(value: null, child: Text('Toate tipurile')),
              ...PropertyType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
            ],
            onChanged: (v) { _filterTip = v; _loadData(); },
          ),
          _filterDropdown<JuridicalDomain?>(
            label: 'Domeniu juridic',
            value: _filterDomeniu,
            items: [
              const DropdownMenuItem(value: null, child: Text('Toate domeniile')),
              ...JuridicalDomain.values.map((d) => DropdownMenuItem(value: d, child: Text(d.label))),
            ],
            onChanged: (v) => setState(() => _filterDomeniu = v),
          ),
          _filterDropdown<PropertyStatus?>(
            label: 'Status',
            value: _filterStatus,
            items: [
              const DropdownMenuItem(value: null, child: Text('Toate statusurile')),
              ...PropertyStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))),
            ],
            onChanged: (v) { _filterStatus = v; _loadData(); },
          ),
          if (_filterTip != null || _filterDomeniu != null || _filterStatus != null || _searchQuery.isNotEmpty)
            TextButton.icon(
              onPressed: () { _filterTip = null; _filterDomeniu = null; _filterStatus = null; _searchQuery = ''; _loadData(); },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Resetare filtre'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            ),
        ],
      ),
    );
  }

  Widget _filterDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppTheme.textDark),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.textGrey),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<PropertyModel> props) {
    return LayoutBuilder(builder: (ctx, constraints) {
      if (constraints.maxWidth < 700) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: props.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _buildCard(context, props[i]),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
          ),
          child: Column(
            children: [
              _buildTableHeader(),
              const Divider(height: 1, color: AppTheme.borderColor),
              ...props.map((p) => _buildTableRow(context, p)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('Denumire', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
          Expanded(flex: 2, child: Text('Tip imobil', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
          Expanded(flex: 3, child: Text('Adresă', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
          SizedBox(width: 80, child: Text('Suprafață', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
          SizedBox(width: 120, child: Text('Valoare inventar', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
          SizedBox(width: 80, child: Text('Status', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
          SizedBox(width: 80, child: Text('Acțiuni', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textGrey))),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, PropertyModel p) {
    return InkWell(
      onTap: () => _openDetail(context, p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.denumire, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textDark)),
                  Text('CF: ${p.numarCarteF}', style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Chip(
                label: Text(p.tip.label, style: const TextStyle(fontSize: 11)),
                backgroundColor: AppTheme.greenPale,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
            Expanded(flex: 3, child: Text(p.adresa, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey), overflow: TextOverflow.ellipsis)),
            SizedBox(width: 80, child: Text('${p.suprafata.toStringAsFixed(0)} mp', style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
            SizedBox(width: 120, child: Text('${_formatVal(p.valoareInventar)} RON', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textDark))),
            SizedBox(
              width: 80,
              child: StatusBadge(label: p.status.label, color: _statusColor(p.status)),
            ),
            SizedBox(
              width: 80,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    color: AppTheme.infoBlue,
                    tooltip: 'Detalii',
                    onPressed: () => _openDetail(context, p),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppTheme.greenEmerald,
                    tooltip: 'Editare',
                    onPressed: () => _openForm(context, property: p),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: AppTheme.errorRed,
                    tooltip: 'Ștergere',
                    onPressed: () => _delete(context, p),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, PropertyModel p) {
    return Card(
      child: InkWell(
        onTap: () => _openDetail(context, p),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(p.denumire, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark))),
                  StatusBadge(label: p.status.label, color: _statusColor(p.status)),
                ],
              ),
              const SizedBox(height: 8),
              Text(p.adresa, style: const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(label: Text(p.tip.label, style: const TextStyle(fontSize: 11)), backgroundColor: AppTheme.greenPale, visualDensity: VisualDensity.compact),
                  const SizedBox(width: 8),
                  Text('${p.suprafata.toStringAsFixed(0)} mp', style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                  const Spacer(),
                  Text('${_formatVal(p.valoareInventar)} RON', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.greenEmerald)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatVal(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  void _openForm(BuildContext context, {PropertyModel? property}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyFormScreen(property: property)));
  }

  void _openDetail(BuildContext context, PropertyModel p) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p)));
  }

  Future<void> _delete(BuildContext context, PropertyModel p) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Ștergere bun imobiliar',
      content: 'Sigur doriți să ștergeți "${p.denumire}"? Această acțiune nu poate fi anulată.',
      confirmLabel: 'Șterge',
    );
    if (confirmed == true) {
      await PropertyService.delete(p.id);
      _loadData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bun imobiliar șters'), backgroundColor: AppTheme.successGreen),
        );
      }
    }
  }
}
