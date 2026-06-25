import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/transaction/transaction_model.dart';
import '../../../theme/app_theme.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  Color _statusColor(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.initiata:   return AppTheme.textGrey;
      case TransactionStatus.aprobata:   return AppTheme.infoBlue;
      case TransactionStatus.inDerulare: return AppTheme.warningOrange;
      case TransactionStatus.finalizata: return AppTheme.successGreen;
      case TransactionStatus.anulata:    return AppTheme.errorRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy');
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.greenDark,
        foregroundColor: Colors.white,
        title: Text(
          'Tranzacţie ${transaction.numarHcl}',
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          transaction.tip.label,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(transaction.status).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _statusColor(transaction.status).withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          transaction.status.label,
                          style: TextStyle(color: _statusColor(transaction.status), fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    transaction.propertyDenumire,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nr. HCL: ${transaction.numarHcl}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Details card
            _buildCard(
              title: 'Detalii tranzacţie',
              icon: Icons.swap_horiz_rounded,
              children: [
                _row('Tip', transaction.tip.label),
                _row('Număr HCL', transaction.numarHcl),
                _row('Data tranzacţiei', fmt.format(transaction.dataTransactie)),
                _row('Status', transaction.status.label, valueColor: _statusColor(transaction.status)),
                _row('Creat la', fmt.format(transaction.createdAt)),
                _row('Creat de', transaction.createdBy),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Proprietate asociată',
              icon: Icons.business_rounded,
              children: [
                _row('Denumire', transaction.propertyDenumire),
                _row('ID Proprietate', transaction.propertyId),
              ],
            ),
            if (transaction.descriere.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCard(
                title: 'Descriere',
                icon: Icons.info_outline_rounded,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      transaction.descriere,
                      style: const TextStyle(color: AppTheme.textDark, fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            ],
            if (transaction.note != null && transaction.note!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCard(
                title: 'Note',
                icon: Icons.note_alt_outlined,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      transaction.note!,
                      style: const TextStyle(color: AppTheme.textDark, fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
          Row(
            children: [
              Icon(icon, color: AppTheme.greenEmerald, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
            ],
          ),
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
          SizedBox(
            width: 160,
            child: Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13, fontFamily: 'Inter')),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Inter'),
            ),
          ),
        ],
      ),
    );
  }
}
