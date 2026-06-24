import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../../core/services/property_service.dart';
import '../../../../core/services/other_services.dart';
import '../../../../core/models/transaction/transaction_model.dart';
import '../../../../core/models/auction/auction_model.dart';
import '../../../widgets/shared_widgets.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int)? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ── cache pentru a nu reface toate requesturile la rebuild ──
  Future<Map<String, dynamic>>? _propStatsFuture;
  Future<Map<String, int>>? _txStatsFuture;
  Future<int>? _contractCountFuture;
  Future<int>? _auctionCountFuture;
  Future<List<TransactionModel>>? _recentTxFuture;
  Future<List<AuctionModel>>? _recentAuctionFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _propStatsFuture    = PropertyService.getStats();
      _txStatsFuture      = TransactionService.getStats();
      _contractCountFuture = ContractService.getActiveCount();
      _auctionCountFuture  = AuctionService.getActiveCount();
      _recentTxFuture     = TransactionService.getAll();
      _recentAuctionFuture = AuctionService.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(),
              const SizedBox(height: 24),
              _buildStatsRow(),
              const SizedBox(height: 24),
              _buildChartsRow(),
              const SizedBox(height: 24),
              _buildRecentSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bun venit în e-Patrimoniu',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Evidența bunurilor imobiliare ale unității administrativ-teritoriale',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 22),
            onPressed: _refresh,
            tooltip: 'Reîncarcă',
          ),
          const Icon(Icons.account_balance_rounded, color: Colors.white24, size: 56),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _propStatsFuture!,
        _txStatsFuture!,
        _contractCountFuture!,
        _auctionCountFuture!,
      ]),
      builder: (context, snap) {
        final props = snap.data?[0] as Map<String, dynamic>? ?? {};
        final txs = snap.data?[1] as Map<String, int>? ?? {};
        final contracts = snap.data?[2] as int? ?? 0;
        final auctions = snap.data?[3] as int? ?? 0;
        final totalVal = (props['totalValoare'] ?? 0.0) as double;
        final formattedVal = _formatCurrency(totalVal);

        return LayoutBuilder(builder: (ctx, constraints) {
          final cols = constraints.maxWidth < 600 ? 2 : (constraints.maxWidth < 900 ? 2 : 5);
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ));
          }
          return GridView.count(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StatCard(
                label: 'Bunuri Imobile',
                value: '${props['total'] ?? 0}',
                subtitle: 'Active: ${props['active'] ?? 0}',
                icon: Icons.business_rounded,
                color: AppTheme.greenEmerald,
                onTap: () => widget.onNavigate?.call(1),
              ),
              StatCard(
                label: 'Tranzacții',
                value: '${txs['total'] ?? 0}',
                subtitle: 'În derulare: ${txs['inDerulare'] ?? 0}',
                icon: Icons.swap_horiz_rounded,
                color: AppTheme.greenMid,
                onTap: () => widget.onNavigate?.call(4),
              ),
              StatCard(
                label: 'Contracte',
                value: '$contracts',
                subtitle: 'Active',
                icon: Icons.description_rounded,
                color: const Color(0xFF2563EB),
                onTap: () => widget.onNavigate?.call(5),
              ),
              StatCard(
                label: 'Licitații',
                value: '$auctions',
                subtitle: 'Active / în desfășurare',
                icon: Icons.gavel_rounded,
                color: const Color(0xFFF59E0B),
                onTap: () => widget.onNavigate?.call(6),
              ),
              StatCard(
                label: 'Valoare Patrimoniu',
                value: formattedVal,
                subtitle: 'RON valoare inventar',
                icon: Icons.account_balance_wallet_rounded,
                color: AppTheme.greenDark,
                isWide: true,
                onTap: () => widget.onNavigate?.call(1),
              ),
            ],
          );
        });
      },
    );
  }

  String _formatCurrency(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(2);
  }

  Widget _buildChartsRow() {
    return LayoutBuilder(builder: (ctx, constraints) {
      if (constraints.maxWidth < 700) {
        return Column(
          children: [
            _buildPropertyChart(),
            const SizedBox(height: 16),
            _buildValueChart(),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildPropertyChart()),
          const SizedBox(width: 16),
          Expanded(child: _buildValueChart()),
        ],
      );
    });
  }

  Widget _buildPropertyChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bunuri imobile după tip',
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: FutureBuilder<Map<String, dynamic>>(
              future: _propStatsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final byType = snap.data?['byType'] as Map? ?? {'teren': 0, 'cladire': 0, 'spatiu': 0, 'constructie': 0};
                final total = (byType['teren'] ?? 0) + (byType['cladire'] ?? 0) + (byType['spatiu'] ?? 0) + (byType['constructie'] ?? 0);
                if (total == 0) {
                  return const Center(child: Text('Nicio înregistrare', style: TextStyle(color: AppTheme.textGrey)));
                }
                return Row(
                  children: [
                    Expanded(
                      child: PieChart(PieChartData(
                        sections: [
                          PieChartSectionData(value: (byType['teren'] ?? 0).toDouble(), title: 'Teren', color: AppTheme.greenEmerald, radius: 65, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                          PieChartSectionData(value: (byType['cladire'] ?? 0).toDouble(), title: 'Clădire', color: AppTheme.greenMid, radius: 65, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                          PieChartSectionData(value: (byType['spatiu'] ?? 0).toDouble(), title: 'Spațiu', color: AppTheme.greenLight, radius: 65, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                          PieChartSectionData(value: (byType['constructie'] ?? 0).toDouble(), title: 'Constr.', color: AppTheme.greenDark, radius: 65, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                      )),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _legend('Teren', AppTheme.greenEmerald, byType['teren'] ?? 0),
                        _legend('Clădire', AppTheme.greenMid, byType['cladire'] ?? 0),
                        _legend('Spațiu', AppTheme.greenLight, byType['spatiu'] ?? 0),
                        _legend('Construcție', AppTheme.greenDark, byType['constructie'] ?? 0),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text('$label ($count)', style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
        ],
      ),
    );
  }

  Widget _buildValueChart() {
    final data = [85.0, 88.0, 92.0, 89.0, 95.0, 100.0, 105.0, 110.0, 115.0, 120.0, 122.0, 125.0];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Evoluția valorii patrimoniului',
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 4),
          const Text('Valori în milioane RON', style: TextStyle(fontSize: 12, color: AppTheme.textGrey)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.borderColor, strokeWidth: 1),
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (v, meta) {
                      const months = ['Ian', 'Feb', 'Mar', 'Apr', 'Mai', 'Iun', 'Iul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      final idx = v.toInt();
                      if (idx < 0 || idx >= months.length) return const SizedBox();
                      return Text(months[idx], style: const TextStyle(fontSize: 10, color: AppTheme.textGrey));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: AppTheme.greenEmerald,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: AppTheme.greenEmerald.withValues(alpha: 0.08)),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSection() {
    return LayoutBuilder(builder: (ctx, constraints) {
      if (constraints.maxWidth < 700) {
        return Column(
          children: [
            _buildRecentTransactions(),
            const SizedBox(height: 16),
            _buildRecentAuctions(),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildRecentTransactions()),
          const SizedBox(width: 16),
          Expanded(child: _buildRecentAuctions()),
        ],
      );
    });
  }

  Widget _buildRecentTransactions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Tranzacții recente', icon: Icons.swap_horiz_rounded),
          const SizedBox(height: 12),
          FutureBuilder<List<TransactionModel>>(
            future: _recentTxFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Text('Eroare: ${snap.error}', style: const TextStyle(color: AppTheme.errorRed, fontSize: 12));
              }
              final txs = (snap.data ?? []).take(5).toList();
              if (txs.isEmpty) return const Text('Nicio tranzacție', style: TextStyle(color: AppTheme.textGrey));
              return Column(
                children: txs.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: _txStatusColor(t.status.name), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.tip.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textDark)),
                            Text(t.propertyDenumire, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _txStatusColor(t.status.name).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(t.status.label, style: TextStyle(fontSize: 10, color: _txStatusColor(t.status.name), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAuctions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Licitații recente', icon: Icons.gavel_rounded),
          const SizedBox(height: 12),
          FutureBuilder<List<AuctionModel>>(
            future: _recentAuctionFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Text('Eroare: ${snap.error}', style: const TextStyle(color: AppTheme.errorRed, fontSize: 12));
              }
              final auctions = (snap.data ?? []).take(5).toList();
              if (auctions.isEmpty) return const Text('Nicio licitație', style: TextStyle(color: AppTheme.textGrey));
              return Column(
                children: auctions.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.gavel_rounded, size: 16, color: AppTheme.greenMid),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.titlu, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textDark), overflow: TextOverflow.ellipsis),
                            Text('${a.pretPornire.toStringAsFixed(0)} RON pornire', style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _auctionStatusColor(a.status.name).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(a.status.label, style: TextStyle(fontSize: 10, color: _auctionStatusColor(a.status.name), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _txStatusColor(String status) {
    switch (status) {
      case 'initiata': return AppTheme.textGrey;
      case 'aprobata': return AppTheme.infoBlue;
      case 'inDerulare': return AppTheme.warningOrange;
      case 'finalizata': return AppTheme.successGreen;
      case 'anulata': return AppTheme.errorRed;
      default: return AppTheme.textGrey;
    }
  }

  Color _auctionStatusColor(String status) {
    switch (status) {
      case 'activa': return AppTheme.successGreen;
      case 'publicata': return AppTheme.infoBlue;
      case 'atribuita': return AppTheme.greenDark;
      case 'anulata': return AppTheme.errorRed;
      case 'contestata': return AppTheme.warningOrange;
      default: return AppTheme.textGrey;
    }
  }
}
