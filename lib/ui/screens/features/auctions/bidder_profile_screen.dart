import 'package:flutter/material.dart';
import '../../../../core/models/auction/auction_model.dart';
import '../../../../core/models/user/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/other_services.dart';
import '../../../theme/app_theme.dart';

/// Afișează profilul unui ofertant cu cele 10 criterii de evaluare.
/// Minimum 7 criterii îndeplinite = ofertant acceptat.
/// Admin poate edita criteriile direct din acest ecran.
class BidderProfileScreen extends StatefulWidget {
  final BidModel bid;
  final String auctionId;
  final bool isWinner;

  const BidderProfileScreen({
    super.key,
    required this.bid,
    required this.auctionId,
    required this.isWinner,
  });

  @override
  State<BidderProfileScreen> createState() => _BidderProfileScreenState();
}

class _BidderProfileScreenState extends State<BidderProfileScreen> {
  List<BidCriterion>? _criteria;
  bool _loading = true;
  bool _editMode = false;
  bool _saving = false;
  bool _isAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        AuctionService.getBidCriteria(widget.auctionId, widget.bid.id),
        AuthService.getCurrentUserModel(),
      ]);
      final criteria = results[0] as List<BidCriterion>;
      final user = results[1] as UserModel?;

      // Dacă nu există criterii în DB, inițializăm cu toate neîndeplinite
      final full = List.generate(10, (i) {
        final idx = i + 1;
        final existing = criteria.where((c) => c.criterionIndex == idx);
        return existing.isNotEmpty
            ? existing.first
            : BidCriterion(criterionIndex: idx, isMet: false);
      });

      if (mounted) {
        setState(() {
          _criteria = full;
          _isAdmin = user?.role == UserRole.administrator || user?.role == UserRole.functionar;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _saveCriteria() async {
    if (_criteria == null) return;
    setState(() => _saving = true);
    try {
      await AuctionService.updateCriteria(widget.auctionId, widget.bid.id, _criteria!);
      if (mounted) {
        setState(() { _editMode = false; _saving = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Criterii salvate cu succes!'),
          backgroundColor: AppTheme.successGreen,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Eroare la salvare: $e'),
          backgroundColor: AppTheme.errorRed,
        ));
      }
    }
  }

  void _toggleCriterion(int index, bool value) {
    if (_criteria == null) return;
    setState(() {
      _criteria = _criteria!.map((c) {
        if (c.criterionIndex == index) {
          return BidCriterion(criterionIndex: c.criterionIndex, isMet: value);
        }
        return c;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profil Ofertant',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.textDark,
          ),
        ),
        actions: [
          if (_isAdmin && !_loading && _error == null) ...[
            if (_editMode) ...[
              TextButton(
                onPressed: () => setState(() => _editMode = false),
                child: const Text('Anulare', style: TextStyle(color: AppTheme.textGrey)),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveCriteria,
                  icon: _saving
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 16),
                  label: const Text('Salvează', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: () => setState(() => _editMode = true),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Editează criterii', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.infoBlue),
                ),
              ),
          ],
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
                    const SizedBox(height: 12),
                    Text('Eroare: $_error', style: const TextStyle(color: AppTheme.textGrey)),
                  ]),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final criteria = _criteria ?? [];
    final metCount = criteria.where((c) => c.isMet).length;
    final isAccepted = metCount >= 7;
    final isFullWinner = metCount == 10;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner edit mode
          if (_editMode)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.infoBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.edit_note_rounded, color: AppTheme.infoBlue, size: 18),
                SizedBox(width: 10),
                Expanded(child: Text(
                  'Mod editare: bifați criteriile îndeplinite de ofertant, apoi apăsați Salvează.',
                  style: TextStyle(fontSize: 12, color: AppTheme.infoBlue, height: 1.4),
                )),
              ]),
            ),

          // Card profil ofertant
          _ProfileCard(
            bid: widget.bid,
            isWinner: widget.isWinner,
            metCount: metCount,
            isAccepted: isAccepted,
            isFullWinner: isFullWinner,
          ),
          const SizedBox(height: 20),

          // Secțiune criterii
          Row(children: [
            const Text(
              'Criterii de evaluare',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isAccepted ? AppTheme.successGreen : AppTheme.errorRed).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$metCount / 10',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isAccepted ? AppTheme.successGreen : AppTheme.errorRed,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            'Minim 7 din 10 criterii trebuie îndeplinite pentru acceptare. '
            'Câștigătorul unic trebuie să le îndeplinească pe toate 10.',
            style: const TextStyle(fontSize: 12, color: AppTheme.textGrey, height: 1.5),
          ),
          const SizedBox(height: 14),

          if (criteria.isEmpty)
            const _EmptyCriteria()
          else
            ...criteria.map((c) => _editMode
                ? _CriterionTileEditable(
                    criterion: c,
                    onChanged: (val) => _toggleCriterion(c.criterionIndex, val),
                  )
                : _CriterionTile(criterion: c)),

          const SizedBox(height: 20),

          // Rezumat scor
          _ScoreSummaryCard(
            metCount: metCount,
            isAccepted: isAccepted,
            isFullWinner: isFullWinner,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card cu informații ofertant
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final BidModel bid;
  final bool isWinner;
  final int metCount;
  final bool isAccepted;
  final bool isFullWinner;

  const _ProfileCard({
    required this.bid,
    required this.isWinner,
    required this.metCount,
    required this.isAccepted,
    required this.isFullWinner,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isFullWinner
        ? AppTheme.warningOrange
        : isAccepted
            ? AppTheme.successGreen
            : AppTheme.errorRed;
    final statusLabel = isFullWinner
        ? 'Câștigător unic (10/10)'
        : isAccepted
            ? 'Acceptat ($metCount/10)'
            : 'Respins ($metCount/10 < 7)';
    final statusIcon = isFullWinner
        ? Icons.emoji_events_rounded
        : isAccepted
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child: Icon(Icons.person_rounded, color: statusColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bid.participantNume,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${bid.participantId}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                      ),
                    ],
                  ),
                ),
                if (isWinner)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.warningOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: AppTheme.warningOrange, size: 14),
                        SizedBox(width: 4),
                        Text('Câștigător',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.warningOrange,
                          )),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(children: [
                  _field('Ofertă depusă', '${bid.valoare.toStringAsFixed(0)} RON'),
                  const SizedBox(width: 24),
                  _field('Ofertă validată', bid.validata ? 'Da' : 'Nu'),
                  const SizedBox(width: 24),
                  _field('Ofertă respinsă', bid.respinsa ? 'Da' : 'Nu'),
                ]),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    Icon(statusIcon, color: statusColor, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
      Text(value, style: const TextStyle(
        fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile criteriu — read-only
// ─────────────────────────────────────────────────────────────────────────────
class _CriterionTile extends StatelessWidget {
  final BidCriterion criterion;
  const _CriterionTile({required this.criterion});

  @override
  Widget build(BuildContext context) {
    final met = criterion.isMet;
    final color = met ? AppTheme.successGreen : AppTheme.errorRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: met
            ? AppTheme.successGreen.withValues(alpha: 0.2)
            : AppTheme.borderColor),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${criterion.criterionIndex}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            criterion.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: met ? AppTheme.textDark : AppTheme.textGrey,
            ),
          ),
        ),
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: color,
          size: 20,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile criteriu — editabil (pentru admin)
// ─────────────────────────────────────────────────────────────────────────────
class _CriterionTileEditable extends StatelessWidget {
  final BidCriterion criterion;
  final ValueChanged<bool> onChanged;

  const _CriterionTileEditable({
    required this.criterion,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final met = criterion.isMet;
    final color = met ? AppTheme.successGreen : AppTheme.textGrey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: met ? AppTheme.successGreen.withValues(alpha: 0.4) : AppTheme.borderColor,
          width: met ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onChanged(!met),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${criterion.criterionIndex}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                criterion.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: met ? AppTheme.textDark : AppTheme.textGrey,
                ),
              ),
            ),
            Checkbox(
              value: met,
              onChanged: (val) => onChanged(val ?? false),
              activeColor: AppTheme.successGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card rezumat scor
// ─────────────────────────────────────────────────────────────────────────────
class _ScoreSummaryCard extends StatelessWidget {
  final int metCount;
  final bool isAccepted;
  final bool isFullWinner;

  const _ScoreSummaryCard({
    required this.metCount,
    required this.isAccepted,
    required this.isFullWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rezultat evaluare',
            style: TextStyle(
              fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: metCount / 10,
              minHeight: 12,
              backgroundColor: AppTheme.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFullWinner
                    ? AppTheme.warningOrange
                    : isAccepted
                        ? AppTheme.successGreen
                        : AppTheme.errorRed,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Text(
              '$metCount / 10 criterii îndeplinite',
              style: const TextStyle(
                fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
            const Spacer(),
            _badge(7, metCount >= 7),
            const SizedBox(width: 8),
            _badge(10, metCount == 10),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _legendDot(AppTheme.successGreen), const SizedBox(width: 4),
            const Text('Minim 7 = Acceptat', style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
            const SizedBox(width: 16),
            _legendDot(AppTheme.warningOrange), const SizedBox(width: 4),
            const Text('Toate 10 = Câștigător unic', style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
          ]),
        ],
      ),
    );
  }

  Widget _badge(int threshold, bool achieved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: achieved
            ? (threshold == 10 ? AppTheme.warningOrange : AppTheme.successGreen).withValues(alpha: 0.12)
            : AppTheme.bgGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: achieved
              ? (threshold == 10 ? AppTheme.warningOrange : AppTheme.successGreen).withValues(alpha: 0.4)
              : AppTheme.borderColor,
        ),
      ),
      child: Text(
        threshold == 10 ? 'Câștigător' : 'Minim $threshold',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: achieved
              ? (threshold == 10 ? AppTheme.warningOrange : AppTheme.successGreen)
              : AppTheme.textGrey,
        ),
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state — niciun criteriu în DB
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyCriteria extends StatelessWidget {
  const _EmptyCriteria();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.assignment_outlined, size: 40, color: AppTheme.textGrey),
        SizedBox(height: 12),
        Text('Niciun criteriu înregistrat',
          style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textGrey)),
        SizedBox(height: 4),
        Text('Criteriile de evaluare nu au fost completate pentru această ofertă.',
          style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
          textAlign: TextAlign.center),
      ]),
    );
  }
}
