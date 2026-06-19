import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../../theme/app_theme.dart';
import '../../../../core/models/document/document_model.dart';
import '../../../../core/services/document_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../widgets/shared_widgets.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  DocumentType? _filterTip;
  DocumentStatus? _filterStatus;
  String _searchQuery = '';
  bool _uploading = false;
  Future<List<DocumentModel>>? _future;

  @override
  void initState() {
    super.initState();
    _future = DocumentService.getAll();
  }

  void _loadData() {
    setState(() => _future = DocumentService.getAll());
  }

  Color _statusColor(DocumentStatus s) {
    switch (s) {
      case DocumentStatus.neverificat: return AppTheme.textGrey;
      case DocumentStatus.inVerificare: return AppTheme.warningOrange;
      case DocumentStatus.verificat: return AppTheme.successGreen;
      case DocumentStatus.respins: return AppTheme.errorRed;
    }
  }

  IconData _fileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'jpg': case 'jpeg': case 'png': return Icons.image_rounded;
      case 'doc': case 'docx': return Icons.description_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  Color _fileColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf': return const Color(0xFFDC2626);
      case 'jpg': case 'jpeg': case 'png': return const Color(0xFF7C3AED);
      case 'doc': case 'docx': return const Color(0xFF2563EB);
      default: return AppTheme.textGrey;
    }
  }

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final fileBytes = result.files.first.bytes;
    if (fileBytes == null) return;
    final name = result.files.first.name;

    if (!mounted) return;
    final tip = await _showTipDialog();
    if (tip == null) return;

    setState(() => _uploading = true);
    try {
      final user = await AuthService.getCurrentUserModel();
      await DocumentService.uploadDocument(
        fileBytes: fileBytes,
        fileName: name,
        denumire: name,
        tip: tip,
        uploadedBy: user?.uid ?? '',
      );
      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Document încărcat cu succes'),
          backgroundColor: AppTheme.successGreen,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Eroare la încărcare: $e'),
          backgroundColor: AppTheme.errorRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<DocumentType?> _showTipDialog() {
    DocumentType selected = DocumentType.altele;
    return showDialog<DocumentType>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tip document', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
        content: StatefulBuilder(
          builder: (ctx, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            children: DocumentType.values.map((t) => RadioListTile<DocumentType>(
              title: Text(t.label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
              value: t,
              groupValue: selected,
              activeColor: AppTheme.greenEmerald,
              onChanged: (v) => setS(() => selected = v ?? DocumentType.altele),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulare')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenEmerald),
            onPressed: () => Navigator.pop(ctx, selected),
            child: const Text('Confirmare', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      body: Column(
        children: [
          _buildFiltersBar(),
          if (_uploading)
            const LinearProgressIndicator(backgroundColor: AppTheme.greenPale, color: AppTheme.greenEmerald),
          Expanded(
            child: FutureBuilder<List<DocumentModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snap.hasError) return Center(child: Text('Eroare: ${snap.error}'));
                var docs = snap.data ?? [];
                if (_filterTip != null) docs = docs.where((d) => d.tip == _filterTip).toList();
                if (_filterStatus != null) docs = docs.where((d) => d.status == _filterStatus).toList();
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  docs = docs.where((d) => d.denumire.toLowerCase().contains(q) || d.tip.label.toLowerCase().contains(q)).toList();
                }
                if (docs.isEmpty) return EmptyState(
                  message: 'Niciun document găsit',
                  icon: Icons.folder_outlined,
                  actionLabel: 'Încarcă document',
                  onAction: _uploadDocument,
                );
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _buildDocTile(docs[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _uploadDocument,
        backgroundColor: AppTheme.greenEmerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Încarcă document', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
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
                hintText: 'Caută documente...',
                hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textGrey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.greenEmerald, width: 2)),
                filled: true,
                fillColor: AppTheme.bgGrey,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          _filterDrop<DocumentType?>(
            label: 'Tip document',
            value: _filterTip,
            items: [
              const DropdownMenuItem(value: null, child: Text('Toate tipurile')),
              ...DocumentType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
            ],
            onChanged: (v) => setState(() => _filterTip = v),
          ),
          _filterDrop<DocumentStatus?>(
            label: 'Status',
            value: _filterStatus,
            items: [
              const DropdownMenuItem(value: null, child: Text('Toate statusurile')),
              ...DocumentStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))),
            ],
            onChanged: (v) => setState(() => _filterStatus = v),
          ),
        ],
      ),
    );
  }

  Widget _filterDrop<T>({required String label, required T value, required List<DropdownMenuItem<T>> items, required void Function(T?) onChanged}) {
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
          value: value, items: items, onChanged: onChanged,
          hint: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textGrey)),
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppTheme.textDark),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppTheme.textGrey),
          dropdownColor: Colors.white, borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildDocTile(DocumentModel doc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _fileColor(doc.fileType).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_fileIcon(doc.fileType), color: _fileColor(doc.fileType), size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc.denumire,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
              overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Text(doc.tip.label, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
              const Text(' · ', style: TextStyle(color: AppTheme.textGrey)),
              Text(doc.fileType.toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _fileColor(doc.fileType))),
              const Text(' · ', style: TextStyle(color: AppTheme.textGrey)),
              Text(_formatSize(doc.fileSize), style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          StatusBadge(label: doc.status.label, color: _statusColor(doc.status)),
          const SizedBox(height: 4),
          Text(DateFormat('dd.MM.yyyy').format(doc.uploadedAt),
            style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
        ]),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.textGrey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'view', child: Row(children: [
              Icon(Icons.open_in_new_rounded, size: 16), SizedBox(width: 8), Text('Deschide'),
            ])),
            const PopupMenuItem(value: 'verify', child: Row(children: [
              Icon(Icons.verified_outlined, size: 16, color: AppTheme.successGreen), SizedBox(width: 8), Text('Marchează verificat'),
            ])),
            const PopupMenuItem(value: 'delete', child: Row(children: [
              Icon(Icons.delete_outline, size: 16, color: AppTheme.errorRed), SizedBox(width: 8), Text('Șterge', style: TextStyle(color: AppTheme.errorRed)),
            ])),
          ],
          onSelected: (action) async {
            if (action == 'verify') {
              await DocumentService.updateStatus(doc.id, DocumentStatus.verificat);
              _loadData();
            } else if (action == 'delete') {
              if (!mounted) return;
              final ok = await showConfirmDialog(context, title: 'Ștergere document', content: 'Sigur doriți să ștergeți "${doc.denumire}"?');
              if (ok == true) {
                await DocumentService.delete(doc.id, doc.fileUrl);
                _loadData();
              }
            }
          },
        ),
      ]),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / 1048576).toStringAsFixed(1)}MB';
  }
}
