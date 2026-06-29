import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../../core/models/auction/auction_model.dart';
import '../../../../core/services/other_services.dart';
import '../../../../core/services/auth_service.dart';
import '../../../widgets/shared_widgets.dart';
import 'bidder_profile_screen.dart';

class AuctionsScreen extends StatefulWidget {
  const AuctionsScreen({super.key});
  @override
  State<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends State<AuctionsScreen> {
  AuctionStatus? _filterStatus;
  String _searchQuery = '';
  Future<List<AuctionModel>>? _future;

  @override
  void initState() {
    super.initState();
    _future = AuctionService.getAll();
  }

  void _loadData() {
    setState(() => _future = AuctionService.getAll());
  }

  Color _statusColor(AuctionStatus s) {
    switch (s) {
      case AuctionStatus.draft: return AppTheme.textGrey;
      case AuctionStatus.publicata: return AppTheme.infoBlue;
      case AuctionStatus.activa: return AppTheme.successGreen;
      case AuctionStatus.inchisa: return AppTheme.warningOrange;
      case AuctionStatus.atribuita: return AppTheme.greenDark;
      case AuctionStatus.anulata: return AppTheme.errorRed;
      case AuctionStatus.contestata: return const Color(0xFF9333EA);
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
            child: FutureBuilder<List<AuctionModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snap.hasError) return Center(child: Text('Eroare: ${snap.error}'));
                var auctions = snap.data ?? [];
                if (_filterStatus != null) auctions = auctions.where((a) => a.status == _filterStatus).toList();
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  auctions = auctions.where((a) => a.titlu.toLowerCase().contains(q) || a.propertyDenumire.toLowerCase().contains(q)).toList();
                }
                if (auctions.isEmpty) return EmptyState(
                  message: 'Nicio licitație găsită',
                  icon: Icons.gavel_outlined,
                  actionLabel: 'Adaugă licitație',
                  onAction: () => _showAddDialog(context),
                );
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: auctions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildAuctionCard(context, auctions[i]),
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
        label: const Text('Adaugă licitație', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
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
            hintText: 'Caută licitație...',
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
            child: DropdownButton<AuctionStatus?>(
              value: _filterStatus,
              items: [const DropdownMenuItem(value: null, child: Text('Toate statusurile')),
                ...AuctionStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label)))],
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

  Widget _buildAuctionCard(BuildContext context, AuctionModel a) {
    final now = DateTime.now();
    final isActive = a.status == AuctionStatus.activa;
    final timeLeft = a.dataFinal.difference(now);
    final fmt = DateFormat('dd.MM.yyyy HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isActive ? Border.all(color: AppTheme.successGreen.withValues(alpha: 0.4), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.successGreen.withValues(alpha: 0.04) : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _statusColor(a.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.gavel_rounded, color: _statusColor(a.status), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.titlu, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
              Text(a.propertyDenumire, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
            ])),
            StatusBadge(label: a.status.label, color: _statusColor(a.status)),
          ]),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _infoBlock('Tip', a.tipAtribuire.label),
              const SizedBox(width: 20),
              _infoBlock('Preț pornire', '${a.pretPornire.toStringAsFixed(0)} RON'),
              const SizedBox(width: 20),
              _infoBlock('Pas licitare', '${a.pasLicitare.toStringAsFixed(0)} RON'),
              const SizedBox(width: 20),
              _infoBlock('Garanție', '${a.garantieParticipare.toStringAsFixed(0)} RON'),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textGrey),
              const SizedBox(width: 4),
              Text('${fmt.format(a.dataInceput)} → ${fmt.format(a.dataFinal)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
            ]),
            if (isActive && timeLeft.isNegative == false) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppTheme.warningOrange),
                const SizedBox(width: 4),
                Text(
                  'Se închide în: ${timeLeft.inDays}z ${timeLeft.inHours.remainder(24)}h ${timeLeft.inMinutes.remainder(60)}m',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.warningOrange),
                ),
              ]),
            ],
            if (a.castigatorNume != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.emoji_events_rounded, size: 14, color: AppTheme.warningOrange),
                const SizedBox(width: 4),
                Text('Câștigător: ${a.castigatorNume} — ${a.ofertaCastigatoare?.toStringAsFixed(0)} RON',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.greenDark)),
              ]),
            ],
          ]),
        ),
        // Actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.borderColor)),
          ),
          child: Row(children: [
            TextButton.icon(
              onPressed: () => _showBids(context, a),
              icon: const Icon(Icons.list_alt_rounded, size: 16),
              label: const Text('Oferte'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.infoBlue),
            ),
            const Spacer(),
            if (a.status == AuctionStatus.draft)
              TextButton.icon(
                onPressed: () async {
                  await AuctionService.updateStatus(a.id, AuctionStatus.publicata);
                  _loadData();
                },
                icon: const Icon(Icons.publish_rounded, size: 16),
                label: const Text('Publică'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.successGreen),
              ),
            if (a.status == AuctionStatus.activa || a.status == AuctionStatus.publicata)
              ElevatedButton.icon(
                onPressed: () => _showDepunereOferta(context, a),
                icon: const Icon(Icons.how_to_vote_rounded, size: 16),
                label: const Text('Depune ofertă',
                  style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.greenEmerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            if (a.status == AuctionStatus.inchisa)
              ElevatedButton.icon(
                onPressed: () => _autoSelectWinner(context, a),
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Calculează câștigătorul',
                  style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey, fontWeight: FontWeight.w500)),
      Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
    ]);
  }

  void _showDepunereOferta(BuildContext context, AuctionModel a) {
    showDialog(
      context: context,
      builder: (ctx) => _DepunereOfertaDialog(auction: a, onBidSubmitted: _loadData),
    );
  }

  void _showBids(BuildContext context, AuctionModel a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Oferte: ${a.titlu}', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
        content: SizedBox(
          width: 540,
          height: 360,
          child: FutureBuilder<List<BidModel>>(
            future: AuctionService.getBids(a.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final bids = snap.data ?? [];
              if (bids.isEmpty) return const Center(child: Text('Nicio ofertă depusă', style: TextStyle(color: AppTheme.textGrey)));
              return ListView.separated(
                itemCount: bids.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderColor),
                itemBuilder: (_, i) {
                  final b = bids[i];
                  final isWinner = a.castigatorId != null && b.participantId == a.castigatorId;
                  return Container(
                    color: isWinner ? AppTheme.warningOrange.withValues(alpha: 0.04) : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: isWinner
                            ? AppTheme.warningOrange.withValues(alpha: 0.15)
                            : AppTheme.greenPale,
                        child: isWinner
                            ? const Icon(Icons.emoji_events_rounded, color: AppTheme.warningOrange, size: 16)
                            : Text('${i + 1}', style: const TextStyle(color: AppTheme.greenDark, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                      title: Text(b.participantNume, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(DateFormat('dd.MM.yyyy HH:mm').format(b.dataOra), style: const TextStyle(fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${b.valoare.toStringAsFixed(0)} RON',
                            style: TextStyle(
                              fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700,
                              color: isWinner ? AppTheme.warningOrange : AppTheme.greenEmerald,
                            )),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BidderProfileScreen(
                                    bid: b,
                                    auctionId: a.id,
                                    isWinner: isWinner,
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.infoBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Profil', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Închide'))],
      ),
    );
  }

  Future<void> _autoSelectWinner(BuildContext context, AuctionModel a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.auto_awesome_rounded, color: AppTheme.warningOrange, size: 22),
          SizedBox(width: 10),
          Text('Calculează câștigătorul', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
        content: const Text(
          'Sistemul va selecta automat câștigătorul: ofertantul cu cele mai multe criterii îndeplinite (minim 7 din 10). '
          'La egalitate, va câștiga cel cu oferta mai mare.\n\n'
          'Licitația va trece la statusul "Atribuită".',
          style: TextStyle(fontSize: 13, color: AppTheme.textGrey, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anulare', style: TextStyle(color: AppTheme.textGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningOrange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Calculează automat'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final result = await AuctionService.autoSelectWinner(a.id);
      _loadData();
      if (context.mounted) {
        final winner = result['winner'] as Map<String, dynamic>?;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(winner != null
            ? 'Câștigător desemnat: ${winner['name']} — ${(winner['bid'] as num).toStringAsFixed(0)} RON (${winner['metCount']}/10 criterii)'
            : 'Câștigător desemnat cu succes!'),
          backgroundColor: AppTheme.warningOrange,
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'),
          backgroundColor: AppTheme.errorRed,
          duration: const Duration(seconds: 5),
        ));
      }
    }
  }

  void _showAddDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titluCtl = TextEditingController();
    final propCtl = TextEditingController();
    final pretCtl = TextEditingController();
    final pasCtl = TextEditingController();
    final garantieCtl = TextEditingController();
    AuctionType tip = AuctionType.inchiriere;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Adaugă licitație', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AppTextField(label: 'Titlu licitație *', controller: titluCtl, validator: (v) => v?.trim().isEmpty == true ? 'Obligatoriu' : null),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Bun imobiliar *', controller: propCtl, validator: (v) => v?.trim().isEmpty == true ? 'Obligatoriu' : null),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AuctionType>(
                    value: tip,
                    decoration: InputDecoration(labelText: 'Tip atribuire *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                    items: AuctionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                    onChanged: (v) => setS(() => tip = v ?? tip),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: AppTextField(label: 'Preț pornire (RON) *', controller: pretCtl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Numeric' : null)),
                    const SizedBox(width: 10),
                    Expanded(child: AppTextField(label: 'Pas licitare (RON) *', controller: pasCtl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Numeric' : null)),
                  ]),
                  const SizedBox(height: 12),
                  AppTextField(label: 'Garanție participare (RON)', controller: garantieCtl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
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
                final auction = AuctionModel(
                  id: '', propertyId: 'unknown', propertyDenumire: propCtl.text.trim(),
                  titlu: titluCtl.text.trim(), tipAtribuire: tip,
                  pretPornire: double.tryParse(pretCtl.text) ?? 0,
                  pasLicitare: double.tryParse(pasCtl.text) ?? 0,
                  garantieParticipare: double.tryParse(garantieCtl.text) ?? 0,
                  dataInceput: DateTime.now(),
                  dataFinal: DateTime.now().add(const Duration(days: 14)),
                  status: AuctionStatus.draft,
                  createdAt: DateTime.now(), createdBy: user?.uid ?? '',
                );
                await AuctionService.create(auction);
                _loadData();
              },
              child: const Text('Adaugă'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog depunere ofertă (cu înregistrare automată) ──────────────────────
class _DepunereOfertaDialog extends StatefulWidget {
  final AuctionModel auction;
  final VoidCallback onBidSubmitted;
  const _DepunereOfertaDialog({required this.auction, required this.onBidSubmitted});

  @override
  State<_DepunereOfertaDialog> createState() => _DepunereOfertaDialogState();
}

class _DepunereOfertaDialogState extends State<_DepunereOfertaDialog> {
  bool _loading = true;
  bool _registered = false;
  bool _hasBid = false;
  bool _submitting = false;
  final _ofertaCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final results = await Future.wait([
      AuctionService.isRegistered(widget.auction.id),
      AuctionService.hasUserBid(widget.auction.id),
    ]);
    if (mounted) setState(() {
      _registered = results[0] as bool;
      _hasBid = results[1] as bool;
      _loading = false;
    });
  }

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      await AuctionService.registerAsParticipant(widget.auction.id);
      if (mounted) setState(() { _registered = true; _loading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ați fost înregistrat ca participant!'),
          backgroundColor: AppTheme.successGreen,
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Eroare: $e'),
          backgroundColor: AppTheme.errorRed,
        ));
      }
    }
  }

  Future<void> _submitBid() async {
    if (!_formKey.currentState!.validate()) return;
    final valoare = double.tryParse(_ofertaCtl.text.replaceAll(',', '.')) ?? 0;
    setState(() => _submitting = true);
    try {
      await AuctionService.submitBid(widget.auction.id, valoare);
      if (mounted) Navigator.pop(context);
      widget.onBidSubmitted();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ofertă de ${valoare.toStringAsFixed(0)} RON depusă cu succes!'),
          backgroundColor: AppTheme.successGreen,
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Eroare: $e'),
          backgroundColor: AppTheme.errorRed,
        ));
      }
    }
  }

  @override
  void dispose() {
    _ofertaCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.auction;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.how_to_vote_rounded, color: AppTheme.greenEmerald, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(a.titlu,
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16),
          overflow: TextOverflow.ellipsis)),
      ]),
      content: SizedBox(
        width: 460,
        child: _loading
          ? const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator()))
          : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Info licitație
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.bgGrey,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(children: [
                  _infoRow('Tip atribuire', a.tipAtribuire.label),
                  _infoRow('Preț pornire', '${a.pretPornire.toStringAsFixed(0)} RON'),
                  _infoRow('Pas licitare', '${a.pasLicitare.toStringAsFixed(0)} RON'),
                  _infoRow('Garanție', '${a.garantieParticipare.toStringAsFixed(0)} RON'),
                  _infoRow('Bun imobiliar', a.propertyDenumire),
                ]),
              ),
              const SizedBox(height: 16),
              if (_hasBid) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.infoBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.how_to_vote_rounded, color: AppTheme.infoBlue, size: 20),
                    SizedBox(width: 10),
                    Expanded(child: Text(
                      'Ați depus deja o ofertă la această licitație.\nFiecare participant poate depune o singură ofertă.',
                      style: TextStyle(fontSize: 13, color: AppTheme.infoBlue, height: 1.5),
                    )),
                  ]),
                ),
              ] else if (!_registered) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: AppTheme.warningOrange, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(child: Text(
                      'Trebuie să vă înregistrați ca participant înainte de a depune o ofertă.',
                      style: TextStyle(fontSize: 13, color: AppTheme.warningOrange, height: 1.4),
                    )),
                  ]),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _register,
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Înregistrare ca participant',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.infoBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.check_circle, color: AppTheme.successGreen, size: 16),
                    SizedBox(width: 8),
                    Text('Sunteți înregistrat ca participant.',
                      style: TextStyle(fontSize: 12, color: AppTheme.successGreen)),
                  ]),
                ),
                const SizedBox(height: 14),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _ofertaCtl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Valoarea ofertei (RON) *',
                      suffixText: 'RON',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.greenEmerald, width: 2)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.errorRed)),
                      filled: true, fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    validator: (v) {
                      final val = double.tryParse(v?.replaceAll(',', '.') ?? '');
                      if (val == null || val <= 0) return 'Introduceți o valoare numerică pozitivă';
                      if (val < a.pretPornire) {
                        return 'Oferta trebuie să fie cel puțin ${a.pretPornire.toStringAsFixed(0)} RON';
                      }
                      final rest = (val - a.pretPornire) % a.pasLicitare;
                      if (rest > 0.01) {
                        return 'Oferta trebuie să respecte pasul de ${a.pasLicitare.toStringAsFixed(0)} RON';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Minim: ${a.pretPornire.toStringAsFixed(0)} RON · Pas: ${a.pasLicitare.toStringAsFixed(0)} RON',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                ),
              ],
            ]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anulare', style: TextStyle(color: AppTheme.textGrey)),
        ),
        if (_registered && !_hasBid)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.greenEmerald, foregroundColor: Colors.white),
            onPressed: _submitting ? null : _submitBid,
            child: _submitting
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Depune oferta', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 120,
          child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey))),
        Expanded(child: Text(value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark))),
      ]),
    );
  }
}
