import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/contract/contract_model.dart';
import '../../../theme/app_theme.dart';

class ContractDetailScreen extends StatelessWidget {
  final ContractModel contract;
  const ContractDetailScreen({super.key, required this.contract});

  Color _statusColor(ContractStatus s) {
    switch (s) {
      case ContractStatus.activ:     return AppTheme.successGreen;
      case ContractStatus.prelungit: return AppTheme.infoBlue;
      case ContractStatus.reziliat:  return AppTheme.errorRed;
      case ContractStatus.expirat:   return AppTheme.textGrey;
      case ContractStatus.finalizat: return AppTheme.greenDark;
      case ContractStatus.anulat:    return AppTheme.errorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt  = DateFormat('dd.MM.yyyy');
    final fmtV = NumberFormat('#,##0.00', 'ro_RO');
    final daysLeft = contract.dataFinal.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysLeft >= 0 && daysLeft <= 30;

    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.greenDark,
        foregroundColor: Colors.white,
        title: Text(
          contract.numarContract,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(contract.status).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _statusColor(contract.status).withValues(alpha: 0.7)),
                        ),
                        child: Text(
                          contract.status.label,
                          style: TextStyle(color: _statusColor(contract.status), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (isExpiringSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.warningOrange.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.7)),
                          ),
                          child: Text(
                            'Expiră în $daysLeft zile',
                            style: const TextStyle(color: AppTheme.warningOrange, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    contract.numarContract,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contract.parteContractanta,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Valoare card
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Valoare',
                    value: '${fmtV.format(contract.valoare)} ${contract.valutaMoneda}',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppTheme.greenEmerald,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    label: 'Durată',
                    value: '${contract.dataFinal.difference(contract.dataInceput).inDays ~/ 30} luni',
                    icon: Icons.calendar_today_rounded,
                    color: AppTheme.infoBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Detalii card
            _buildCard(
              title: 'Detalii contract',
              icon: Icons.description_rounded,
              children: [
                _row('Număr contract', contract.numarContract),
                _row('Parte contractantă', contract.parteContractanta),
                _row('Data început', fmt.format(contract.dataInceput)),
                _row('Data final', fmt.format(contract.dataFinal)),
                _row('Valoare', '${fmtV.format(contract.valoare)} ${contract.valutaMoneda}'),
                _row('Status', contract.status.label, valueColor: _statusColor(contract.status)),
                _row('Creat la', fmt.format(contract.createdAt)),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Proprietate asociată',
              icon: Icons.business_rounded,
              children: [
                _row('Denumire', contract.propertyDenumire),
                if (contract.transactionId != null)
                  _row('ID Tranzacţie', contract.transactionId!),
              ],
            ),
            if (contract.note != null && contract.note!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCard(
                title: 'Note',
                icon: Icons.note_alt_outlined,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(contract.note!, style: const TextStyle(color: AppTheme.textDark, fontSize: 14, height: 1.5)),
                  ),
                ],
              ),
            ],
            if (contract.documentUrl != null && contract.documentUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCard(
                title: 'Document ataşat',
                icon: Icons.attach_file_rounded,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.errorRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(contract.documentUrl!, style: const TextStyle(color: AppTheme.infoBlue, fontSize: 13, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({required String label, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: AppTheme.textDark, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter'), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppTheme.greenEmerald, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 160, child: Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13, fontFamily: 'Inter'))),
          Expanded(child: Text(value, style: TextStyle(color: valueColor ?? AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Inter'))),
        ],
      ),
    );
  }
}
