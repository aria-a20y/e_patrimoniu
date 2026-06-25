import 'package:flutter/material.dart';
import '../../../../core/models/auction/auction_model.dart';
import '../../../../core/services/other_services.dart';
import '../../../theme/app_theme.dart';

/// Afișează profilul unui ofertant cu cele 10 criterii de evaluare.
/// Minimum 7 criterii îndeplinite = ofertant acceptat.
/// Toate 10 = câștigător unic.
class BidderProfileScreen extends StatelessWidget {
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
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.borderColor),
        ),
      ),
      body: FutureBuilder<List<BidCriterion>>(
        future: AuctionService.getBidCriteria(auctionId, bid.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
                  const SizedBox(height: 12),
                  Text('Eroare: ${snap.error}',
                    style: const TextStyle(color: AppTheme.textGrey)),
                ],
              ),
            );
          }

          final criteria = snap.data ?? [];
          final metCount = criteria.where((c) => c.isMet).length;
          final isAccepted = metCount >= 7;
          final isFullWinner = metCount == 10;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Card profil ofertant ──────────────────────────────────
                _ProfileCard(
                  bid: bid,
                  isWinner: isWinner,
                  metCount: metCount,
                  isAccepted: isAccepted,
                  isFullWinner: isFullWinner,
                ),
                const SizedBox(height: 20),

                // ── Secțiune criterii ─────────────────────────────────────
                const Text(
                  'Criterii de evaluare',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
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
                  ...criteria.map((c) => _CriterionTile(criterion: c)),

                const SizedBox(height: 20),

                // ── Rezumat ───────────────────────────────────────────────
                _ScoreSummaryCard(
                  metCount: metCount,
                  isAccepted: isAccepted,
                  isFullWinner: isFullWinner,
                ),
              ],
            ),
          );
        },
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
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
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
                // Status acceptare
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
// Tile pentru un criteriu
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
          // Progress bar
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
          // Legend
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
