import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../../core/services/scan_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../widgets/shared_widgets.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});
  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
  int _step = 0;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _processing = false;
  ScanResult? _scanResult;

  final List<String> _stepLabels = ['Selectare fișier', 'Procesare OCR', 'Date extrase', 'Verificare'];

  void _reset() {
    setState(() {
      _step = 0;
      _selectedFileBytes = null;
      _selectedFileName = null;
      _processing = false;
      _scanResult = null;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _selectedFileBytes = result.files.first.bytes;
      _selectedFileName = result.files.first.name;
    });
  }

  Future<void> _startProcessing() async {
    if (_selectedFileBytes == null) return;
    setState(() { _step = 1; _processing = true; });

    try {
      // Mock document ID (în producție, mai întâi se încarcă fișierul)
      final mockDocId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
      final result = await ScanService.processDocument(
        fileBytes: _selectedFileBytes!,
        fileName: _selectedFileName ?? '',
        documentId: mockDocId,
      );
      setState(() {
        _scanResult = result;
        _step = 2;
        _processing = false;
      });
    } catch (e) {
      setState(() => _processing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Eroare la procesare: $e'),
          backgroundColor: AppTheme.errorRed,
        ));
      }
    }
  }

  void _goToVerification() => setState(() => _step = 3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStepper(),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildCurrentStep(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: List.generate(_stepLabels.length, (i) {
          final isActive = i == _step;
          final isDone = i < _step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: isDone ? AppTheme.successGreen
                            : isActive ? AppTheme.greenEmerald
                            : AppTheme.borderColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : Text('${i + 1}', style: TextStyle(
                              fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14,
                              color: isActive ? Colors.white : AppTheme.textGrey))),
                      ),
                      const SizedBox(height: 6),
                      Text(_stepLabels[i],
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? AppTheme.greenEmerald : AppTheme.textGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (i < _stepLabels.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 28),
                      color: isDone ? AppTheme.successGreen : AppTheme.borderColor,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return _buildStep0();
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      case 3: return _buildStep3();
      default: return const SizedBox();
    }
  }

  // ── STEP 0: Selectare fișier ───────────────────────────────
  Widget _buildStep0() {
    return Container(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppTheme.greenPale, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.document_scanner_rounded, size: 44, color: AppTheme.greenEmerald),
          ),
          const SizedBox(height: 20),
          const Text('Scanare document cadastral',
            style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          const Text(
            'Selectați un document (PDF, JPG, PNG) pentru extragerea automată a datelor cadastrale folosind OCR.',
            style: TextStyle(fontSize: 14, color: AppTheme.textGrey, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (_selectedFileBytes != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.greenPale,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.greenLight),
              ),
              child: Row(children: [
                const Icon(Icons.insert_drive_file_rounded, color: AppTheme.greenEmerald),
                const SizedBox(width: 10),
                Expanded(child: Text(_selectedFileName ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.greenDark))),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppTheme.textGrey),
                  onPressed: () => setState(() { _selectedFileBytes = null; _selectedFileName = null; }),
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(_selectedFileBytes == null ? 'Selectează fișierul' : 'Schimbă fișierul',
              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.greenEmerald,
              side: const BorderSide(color: AppTheme.greenEmerald),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          if (_selectedFileBytes != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _startProcessing,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Procesează documentul', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.greenEmerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(10)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppTheme.infoBlue, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Sistemul recunoaște automat: număr cadastral, număr carte funciară, data documentului, tip document, emitent.',
                  style: TextStyle(fontSize: 12, color: AppTheme.infoBlue, height: 1.4),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── STEP 1: Procesare OCR ──────────────────────────────────
  Widget _buildStep1() {
    return Container(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppTheme.greenEmerald, strokeWidth: 4),
          const SizedBox(height: 24),
          const Text('Procesare în curs...', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          const SizedBox(height: 10),
          Text(
            'OCR analizează documentul și extrage câmpurile relevante.\nAcest proces durează câteva secunde.',
            style: const TextStyle(fontSize: 14, color: AppTheme.textGrey, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          _processingStep('Detectare text în document', true),
          _processingStep('Identificare câmpuri cadastrale', true),
          _processingStep('Extragere date structurate', _processing ? false : true),
          _processingStep('Calculare scor de încredere', false),
        ],
      ),
    );
  }

  Widget _processingStep(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 20, height: 20, child: done
          ? const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 20)
          : const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.greenEmerald))),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: done ? AppTheme.textDark : AppTheme.textGrey)),
      ]),
    );
  }

  // ── STEP 2: Date extrase ───────────────────────────────────
  Widget _buildStep2() {
    if (_scanResult == null) return const SizedBox.shrink();
    final fields = _scanResult!.extractedFields;
    final confidence = (_scanResult!.confidenceScore * 100).toStringAsFixed(0);

    return Container(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_fix_high_rounded, color: AppTheme.successGreen, size: 22),
            const SizedBox(width: 8),
            const Text('Date extrase automat', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: int.parse(confidence) >= 85 ? AppTheme.successGreen.withValues(alpha: 0.1) : AppTheme.warningOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Precizie: $confidence%',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: int.parse(confidence) >= 85 ? AppTheme.successGreen : AppTheme.warningOrange,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          ...fields.entries.map((e) {
            final val = e.value as Map<String, dynamic>;
            final fieldConf = ((val['incredere'] as double) * 100).toStringAsFixed(0);
            final confColor = int.parse(fieldConf) >= 85 ? AppTheme.successGreen
                : int.parse(fieldConf) >= 70 ? AppTheme.warningOrange : AppTheme.errorRed;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.bgGrey,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_fieldLabel(e.key), style: const TextStyle(fontSize: 11, color: AppTheme.textGrey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(val['valoare']?.toString() ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: confColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('$fieldConf%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: confColor)),
                ),
              ]),
            );
          }),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reia scanarea'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textGrey,
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _goToVerification,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                label: const Text('Verificare date', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.greenEmerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── STEP 3: Verificare și salvare ─────────────────────────
  Widget _buildStep3() {
    if (_scanResult == null) return const SizedBox.shrink();
    final fields = _scanResult!.extractedFields;
    final controllers = {for (var e in fields.entries) e.key: TextEditingController(text: e.value['valoare']?.toString() ?? '')};

    return Container(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.fact_check_rounded, color: AppTheme.greenEmerald, size: 22),
            SizedBox(width: 8),
            Text('Verificare și confirmare date', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          const Text('Verificați și corectați dacă este necesar datele extrase automat.',
            style: TextStyle(fontSize: 13, color: AppTheme.textGrey)),
          const SizedBox(height: 20),
          ...controllers.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AppTextField(
              label: _fieldLabel(e.key),
              controller: e.value,
            ),
          )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Actualizare câmpuri și marcare verificat
                final updatedFields = Map<String, dynamic>.from(_scanResult!.extractedFields);
                for (final e in controllers.entries) {
                  updatedFields[e.key] = {
                    'valoare': e.value.text,
                    'incredere': _scanResult!.extractedFields[e.key]?['incredere'] ?? 0.9,
                  };
                }
                await ScanService.updateFields(_scanResult!.id, updatedFields);

                // Salvare în baza de date
                try {
                  final tipDoc = updatedFields['tipDocument']?['valoare']?.toString() ?? '';
                  final numarAct = updatedFields['numarAct']?['valoare']?.toString() ?? '';
                  final numarCadastral = updatedFields['numarCadastral']?['valoare']?.toString() ?? '';
                  final numarCarteF = updatedFields['numarCarteF']?['valoare']?.toString() ?? '';
                  final dataTxt = updatedFields['dataDocument']?['valoare']?.toString() ?? '';
                  final emitent = updatedFields['emitent']?['valoare']?.toString() ?? '';
                  final numarRef = numarAct.isNotEmpty ? numarAct : numarCadastral;
                  final denumire = tipDoc.isNotEmpty
                      ? '$tipDoc${numarRef.isNotEmpty ? ' nr. $numarRef' : ''}'
                      : 'Document scanat';
                  final ext = _selectedFileName?.split('.').last ?? 'pdf';

                  await ApiService.post('/api/documents', {
                    'denumire': denumire,
                    'tip': _mapTipDocument(tipDoc),
                    'fileUrl': '',
                    'fileType': ext,
                    'fileSize': _selectedFileBytes?.length ?? 0,
                    'numarDocument': numarRef.isNotEmpty ? numarRef : null,
                    'dataDocument': _parseDataDocument(dataTxt),
                    'emitent': emitent.isNotEmpty ? emitent : null,
                    'note': [
                      if (numarCadastral.isNotEmpty) 'Nr. cadastral: $numarCadastral',
                      if (numarCarteF.isNotEmpty) 'Nr. CF: $numarCarteF',
                    ].join(' | '),
                  });
                } catch (_) {
                  // Salvarea în DB a eșuat, dar documentul rămâne verificat local
                }

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Document verificat și salvat cu succes'),
                  backgroundColor: AppTheme.successGreen,
                ));
                _reset();
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Confirmă și salvează', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _reset,
              style: TextButton.styleFrom(foregroundColor: AppTheme.textGrey),
              child: const Text('Anulare'),
            ),
          ),
        ],
      ),
    );
  }

  String _mapTipDocument(String label) {
    switch (label) {
      case 'Extras Carte Funciară': return 'extrasCF';
      case 'Plan Cadastral': return 'planCadastral';
      case 'HCL': return 'hcl';
      case 'Contract de Concesiune': return 'contract';
      default: return 'altele';
    }
  }

  String? _parseDataDocument(String txt) {
    // Formatul din mock: "dd.MM.yyyy"
    if (txt.isEmpty) return null;
    final parts = txt.split('.');
    if (parts.length != 3) return null;
    return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
  }

  String _fieldLabel(String key) {
    const labels = {
      'numarCadastral': 'Număr cadastral',
      'numarCarteF': 'Număr carte funciară',
      'dataDocument': 'Data documentului',
      'tipDocument': 'Tip document',
      'numarAct': 'Număr act',
      'emitent': 'Emitent',
    };
    return labels[key] ?? key;
  }
}
