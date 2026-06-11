import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../../core/models/property/property_model.dart';
import '../../../../core/models/document/document_model.dart';
import '../../../../core/models/transaction/transaction_model.dart';
import '../../../../core/models/contract/contract_model.dart';
import '../../../../core/models/auction/auction_model.dart';
import '../../../../core/services/document_service.dart';
import '../../../../core/services/other_services.dart';
import '../../../widgets/shared_widgets.dart';
import 'property_form.dart';

class PropertyDetailScreen extends StatefulWidget {
  final PropertyModel property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  Color get _statusColor {
    switch (widget.property.status) {
      case PropertyStatus.activ: return AppTheme.successGreen;
      case PropertyStatus.inactiv: return AppTheme.textGrey;
      case PropertyStatus.scosEvidenta: return AppTheme.errorRed;
      case PropertyStatus.inLitigiu: return AppTheme.warningOrange;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    final fmt = NumberFormat('#,##0.00', 'ro_RO');

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(p.denumire, overflow: TextOverflow.ellipsis),
        backgroundColor: AppTheme.greenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editare',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PropertyFormScreen(property: p)),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AppTheme.greenLight,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Detalii'),
            Tab(text: 'Documente'),
            Tab(text: 'Tranzacții'),
            Tab(text: 'Contracte'),
            Tab(text: 'Licitații'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildDetailsTab(p, fmt),
          _buildDocumentsTab(p.id),
          _buildTransactionsTab(p.id),
          _buildContractsTab(p.id),
          _buildAuctionsTab(p.id),
        ],
      ),
    );
  }

  // ── TAB 1: DETALII ──────────────────────────────────────────
  Widget _buildDetailsTab(PropertyModel p, NumberFormat fmt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(p.denumire, style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  StatusBadge(label: p.status.label, color: Colors.white),
                ]),
                const SizedBox(height: 8),
                Text(p.adresa, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                const SizedBox(height: 12),
                Row(children: [
                  _headerChip(p.tip.label, Icons.business_rounded),
                  const SizedBox(width: 8),
                  _headerChip(p.domeniuJuridic.label, Icons.gavel_rounded),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Info grid
          LayoutBuilder(builder: (ctx, constraints) {
            if (constraints.maxWidth > 600) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildInfoCard('Date cadastrale', [
                    _infoRow('Nr. cadastral', p.numarCadastral),
                    _infoRow('Nr. carte funciară', p.numarCarteF),
                    _infoRow('Suprafață', '${p.suprafata.toStringAsFixed(2)} mp'),
                    _infoRow('Localitate', p.localitate),
                  ])),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInfoCard('Date financiare', [
                    _infoRow('Valoare inventar', '${fmt.format(p.valoareInventar)} RON'),
                    _infoRow('Destinație', p.destinatie),
                    _infoRow('Înregistrat', DateFormat('dd.MM.yyyy').format(p.createdAt)),
                    _infoRow('Actualizat', DateFormat('dd.MM.yyyy').format(p.updatedAt)),
                  ])),
                ],
              );
            }
            return Column(children: [
              _buildInfoCard('Date cadastrale', [
                _infoRow('Nr. cadastral', p.numarCadastral),
                _infoRow('Nr. carte funciară', p.numarCarteF),
                _infoRow('Suprafață', '${p.suprafata.toStringAsFixed(2)} mp'),
                _infoRow('Localitate', p.localitate),
              ]),
              const SizedBox(height: 16),
              _buildInfoCard('Date financiare', [
                _infoRow('Valoare inventar', '${fmt.format(p.valoareInventar)} RON'),
                _infoRow('Destinație', p.destinatie),
                _infoRow('Înregistrat', DateFormat('dd.MM.yyyy').format(p.createdAt)),
              ]),
            ]);
          }),
          if (p.descriere != null && p.descriere!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard('Descriere', [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(p.descriere!, style: const TextStyle(fontSize: 14, color: AppTheme.textGrey, height: 1.5)),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _headerChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderColor),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textGrey, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── TAB 2: DOCUMENTE ────────────────────────────────────────
  Widget _buildDocumentsTab(String propertyId) {
    return StreamBuilder<List<DocumentModel>>(
      stream: DocumentService.getByProperty(propertyId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!;
        if (docs.isEmpty) return const EmptyState(message: 'Niciun document atașat', icon: Icons.folder_outlined);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _buildDocCard(docs[i]),
        );
      },
    );
  }

  Widget _buildDocCard(DocumentModel doc) {
    final statusColors = {
      DocumentStatus.neverificat: AppTheme.textGrey,
      DocumentStatus.inVerificare: AppTheme.warningOrange,
      DocumentStatus.verificat: AppTheme.successGreen,
      DocumentStatus.respins: AppTheme.errorRed,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppTheme.greenPale, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.insert_drive_file_rounded, color: AppTheme.greenEmerald, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc.denumire, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
            Text(doc.tip.label, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          ],
        )),
        StatusBadge(label: doc.status.label, color: statusColors[doc.status] ?? AppTheme.textGrey),
      ]),
    );
  }

  // ── TAB 3: TRANZACȚII ───────────────────────────────────────
  Widget _buildTransactionsTab(String propertyId) {
    return StreamBuilder<List<TransactionModel>>(
      stream: TransactionService.getAll(propertyId: propertyId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final txs = snap.data!;
        if (txs.isEmpty) return const EmptyState(message: 'Nicio tranzacție pentru acest bun', icon: Icons.swap_horiz_outlined);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: txs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _buildTxCard(txs[i]),
        );
      },
    );
  }

  Widget _buildTxCard(TransactionModel t) {
    final statusColors = {
      'initiata': AppTheme.textGrey,
      'aprobata': AppTheme.infoBlue,
      'inDerulare': AppTheme.warningOrange,
      'finalizata': AppTheme.successGreen,
      'anulata': AppTheme.errorRed,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppTheme.greenPale, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.swap_horiz_rounded, color: AppTheme.greenEmerald, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.tip.label, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
            Text('HCL: ${t.numarHcl} · ${DateFormat('dd.MM.yyyy').format(t.dataTransactie)}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          ],
        )),
        StatusBadge(label: t.status.label, color: statusColors[t.status.name] ?? AppTheme.textGrey),
      ]),
    );
  }

  // ── TAB 4: CONTRACTE ────────────────────────────────────────
  Widget _buildContractsTab(String propertyId) {
    return StreamBuilder<List<ContractModel>>(
      stream: ContractService.getAll(propertyId: propertyId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final contracts = snap.data!;
        if (contracts.isEmpty) return const EmptyState(message: 'Niciun contract pentru acest bun', icon: Icons.description_outlined);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: contracts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _buildContractCard(contracts[i]),
        );
      },
    );
  }

  Widget _buildContractCard(ContractModel c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(c.numarContract, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600))),
          StatusBadge(label: c.status.label, color: c.status == ContractStatus.activ ? AppTheme.successGreen : AppTheme.textGrey),
        ]),
        const SizedBox(height: 4),
        Text(c.parteContractanta, style: const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textGrey),
          const SizedBox(width: 4),
          Text('${DateFormat('dd.MM.yyyy').format(c.dataInceput)} – ${DateFormat('dd.MM.yyyy').format(c.dataFinal)}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          const Spacer(),
          Text('${c.valoare.toStringAsFixed(2)} ${c.valutaMoneda}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.greenEmerald)),
        ]),
      ]),
    );
  }

  // ── TAB 5: LICITAȚII ────────────────────────────────────────
  Widget _buildAuctionsTab(String propertyId) {
    return StreamBuilder<List<AuctionModel>>(
      stream: AuctionService.getAll(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final auctions = snap.data!.where((a) => a.propertyId == propertyId).toList();
        if (auctions.isEmpty) return const EmptyState(message: 'Nicio licitație pentru acest bun', icon: Icons.gavel_outlined);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: auctions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _buildAuctionCard(auctions[i]),
        );
      },
    );
  }

  Widget _buildAuctionCard(AuctionModel a) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(a.titlu, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600))),
          StatusBadge(label: a.status.label, color: a.status == AuctionStatus.activa ? AppTheme.successGreen : AppTheme.textGrey),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Text('Preț pornire: ${a.pretPornire.toStringAsFixed(0)} RON',
            style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          const Spacer(),
          Text(a.tipAtribuire.label, style: const TextStyle(fontSize: 12, color: AppTheme.infoBlue, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }
}
