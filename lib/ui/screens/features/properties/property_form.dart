import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../../core/models/property/property_model.dart';
import '../../../../core/services/property_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../widgets/shared_widgets.dart';

class PropertyFormScreen extends StatefulWidget {
  final PropertyModel? property;
  const PropertyFormScreen({super.key, this.property});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _denumireCtl = TextEditingController();
  final _adresaCtl = TextEditingController();
  final _localitateCtl = TextEditingController();
  final _numarCadastralCtl = TextEditingController();
  final _numarCarteFCtl = TextEditingController();
  final _suprafataCtl = TextEditingController();
  final _valoareCtl = TextEditingController();
  final _destinatieCtl = TextEditingController();
  final _descriereCtl = TextEditingController();

  PropertyType _tip = PropertyType.teren;
  JuridicalDomain _domeniu = JuridicalDomain.public;
  PropertyStatus _status = PropertyStatus.activ;
  bool _loading = false;

  bool get _isEditing => widget.property != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.property!;
      _denumireCtl.text = p.denumire;
      _adresaCtl.text = p.adresa;
      _localitateCtl.text = p.localitate;
      _numarCadastralCtl.text = p.numarCadastral;
      _numarCarteFCtl.text = p.numarCarteF;
      _suprafataCtl.text = p.suprafata.toString();
      _valoareCtl.text = p.valoareInventar.toString();
      _destinatieCtl.text = p.destinatie;
      _descriereCtl.text = p.descriere ?? '';
      _tip = p.tip;
      _domeniu = p.domeniuJuridic;
      _status = p.status;
    }
  }

  @override
  void dispose() {
    _denumireCtl.dispose(); _adresaCtl.dispose(); _localitateCtl.dispose();
    _numarCadastralCtl.dispose(); _numarCarteFCtl.dispose();
    _suprafataCtl.dispose(); _valoareCtl.dispose();
    _destinatieCtl.dispose(); _descriereCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await AuthService.getCurrentUserModel();
      final uid = user?.uid ?? '';
      final uname = user?.fullName ?? '';

      if (_isEditing) {
        final updated = widget.property!.copyWith(
          denumire: _denumireCtl.text.trim(),
          adresa: _adresaCtl.text.trim(),
          localitate: _localitateCtl.text.trim(),
          numarCadastral: _numarCadastralCtl.text.trim(),
          numarCarteF: _numarCarteFCtl.text.trim(),
          suprafata: double.tryParse(_suprafataCtl.text) ?? 0,
          valoareInventar: double.tryParse(_valoareCtl.text) ?? 0,
          destinatie: _destinatieCtl.text.trim(),
          status: _status,
          domeniuJuridic: _domeniu,
          tip: _tip,
          descriere: _descriereCtl.text.trim(),
        );
        await PropertyService.update(updated, userId: uid, userName: uname);
      } else {
        final newProp = PropertyModel(
          id: '',
          denumire: _denumireCtl.text.trim(),
          tip: _tip,
          adresa: _adresaCtl.text.trim(),
          localitate: _localitateCtl.text.trim(),
          domeniuJuridic: _domeniu,
          numarCadastral: _numarCadastralCtl.text.trim(),
          numarCarteF: _numarCarteFCtl.text.trim(),
          suprafata: double.tryParse(_suprafataCtl.text) ?? 0,
          valoareInventar: double.tryParse(_valoareCtl.text) ?? 0,
          destinatie: _destinatieCtl.text.trim(),
          status: _status,
          descriere: _descriereCtl.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: uid,
        );
        await PropertyService.create(newProp, userId: uid, userName: uname);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing ? 'Bun imobiliar actualizat' : 'Bun imobiliar adăugat'),
        backgroundColor: AppTheme.successGreen,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Eroare: $e'),
        backgroundColor: AppTheme.errorRed,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgGrey,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editare bun imobiliar' : 'Adăugare bun imobiliar'),
        backgroundColor: AppTheme.greenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.greenLight, foregroundColor: Colors.white),
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isEditing ? 'Salvare modificări' : 'Adaugă bunul'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Informații generale', [
                    AppTextField(
                      label: 'Denumire bun imobiliar *',
                      controller: _denumireCtl,
                      validator: (v) => v?.trim().isEmpty == true ? 'Câmp obligatoriu' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: AppDropdownField<PropertyType>(
                        label: 'Tip imobil *',
                        value: _tip,
                        items: PropertyType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
                        onChanged: (v) => setState(() => _tip = v ?? PropertyType.teren),
                      )),
                      const SizedBox(width: 14),
                      Expanded(child: AppDropdownField<JuridicalDomain>(
                        label: 'Domeniu juridic *',
                        value: _domeniu,
                        items: JuridicalDomain.values.map((d) => DropdownMenuItem(value: d, child: Text(d.label))).toList(),
                        onChanged: (v) => setState(() => _domeniu = v ?? JuridicalDomain.public),
                      )),
                    ]),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Destinație *',
                      controller: _destinatieCtl,
                      validator: (v) => v?.trim().isEmpty == true ? 'Câmp obligatoriu' : null,
                    ),
                    const SizedBox(height: 14),
                    AppDropdownField<PropertyStatus>(
                      label: 'Status bun',
                      value: _status,
                      items: PropertyStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                      onChanged: (v) => setState(() => _status = v ?? PropertyStatus.activ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Localizare', [
                    AppTextField(
                      label: 'Adresă completă *',
                      controller: _adresaCtl,
                      validator: (v) => v?.trim().isEmpty == true ? 'Câmp obligatoriu' : null,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Localitate *',
                      controller: _localitateCtl,
                      validator: (v) => v?.trim().isEmpty == true ? 'Câmp obligatoriu' : null,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Date cadastrale', [
                    Row(children: [
                      Expanded(child: AppTextField(
                        label: 'Număr cadastral',
                        controller: _numarCadastralCtl,
                      )),
                      const SizedBox(width: 14),
                      Expanded(child: AppTextField(
                        label: 'Număr carte funciară',
                        controller: _numarCarteFCtl,
                      )),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: AppTextField(
                        label: 'Suprafață (mp) *',
                        controller: _suprafataCtl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v?.trim().isEmpty == true) return 'Câmp obligatoriu';
                          if (double.tryParse(v!) == null) return 'Valoare numerică';
                          return null;
                        },
                      )),
                      const SizedBox(width: 14),
                      Expanded(child: AppTextField(
                        label: 'Valoare de inventar (RON) *',
                        controller: _valoareCtl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v?.trim().isEmpty == true) return 'Câmp obligatoriu';
                          if (double.tryParse(v!) == null) return 'Valoare numerică';
                          return null;
                        },
                      )),
                    ]),
                  ]),
                  const SizedBox(height: 20),
                  _buildSection('Descriere', [
                    AppTextField(
                      label: 'Descriere / Note',
                      controller: _descriereCtl,
                      maxLines: 4,
                    ),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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
          Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderColor),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
