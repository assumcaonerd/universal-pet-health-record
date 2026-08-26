import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/offline_store.dart';
import '../services/clinical_service.dart';
import '../services/offline_sync_service.dart';

class AllergyFormScreen extends StatefulWidget {
  const AllergyFormScreen({super.key, required this.api, required this.petId});
  final ApiClient api;
  final String petId;

  @override
  State<AllergyFormScreen> createState() => _AllergyFormScreenState();
}

class _AllergyFormScreenState extends State<AllergyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _allergen = TextEditingController();
  final _reaction = TextEditingController();
  String _severity = 'MODERATE';
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    final allergen = _allergen.text.trim();
    final reaction = _reaction.text.trim();
    try {
      await ClinicalService(widget.api).addAllergy(widget.petId, allergen: allergen, reaction: reaction, severity: _severity);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException {
      try {
        await OfflineSyncService(widget.api, OfflineStore()).queueAllergyCreate(widget.petId, allergen: allergen, reaction: reaction.isEmpty ? null : reaction, severity: _severity);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sem conexão. A alergia foi salva neste aparelho e será sincronizada depois.')));
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Registrar alergia')),
    body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(20), children: [
      TextFormField(controller: _allergen, decoration: const InputDecoration(labelText: 'Alérgeno ou substância'), validator: (v) => v == null || v.trim().isEmpty ? 'Informe a substância' : null),
      const SizedBox(height: 16),
      TextFormField(controller: _reaction, maxLines: 3, decoration: const InputDecoration(labelText: 'Reação observada (opcional)')),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(initialValue: _severity, decoration: const InputDecoration(labelText: 'Gravidade'), items: const [DropdownMenuItem(value: 'MILD', child: Text('Leve')), DropdownMenuItem(value: 'MODERATE', child: Text('Moderada')), DropdownMenuItem(value: 'SEVERE', child: Text('Grave')), DropdownMenuItem(value: 'LIFE_THREATENING', child: Text('Risco de vida'))], onChanged: (v) => setState(() => _severity = v ?? 'MODERATE')),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      const SizedBox(height: 24),
      FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.health_and_safety), label: Text(_saving ? 'Salvando...' : 'Registrar alergia')),
    ])),
  );
}
