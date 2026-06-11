import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;
  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: AppTheme.greenPale, borderRadius: BorderRadius.circular(28)),
              child: const Icon(Icons.construction_rounded, color: AppTheme.greenEmerald, size: 54),
            ),
            const SizedBox(height: 24),
            const Text('Disponibil în curând', style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text(
              'Modulul "$title" este în curs de dezvoltare\nși va fi disponibil în versiunile viitoare.',
              style: const TextStyle(fontSize: 15, color: AppTheme.textGrey, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.greenPale,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.greenLight.withValues(alpha: 0.4)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.email_outlined, color: AppTheme.greenEmerald, size: 18),
                SizedBox(width: 8),
                Text('suport@epatrimoniu.ro', style: TextStyle(color: AppTheme.greenDark, fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
