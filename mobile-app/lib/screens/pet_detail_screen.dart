import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/offline_store.dart';
import '../models/clinical_models.dart';
import '../models/pet.dart';
import '../services/clinical_service.dart';
import 'allergy_form_screen.dart';
import 'clinical_documents_screen.dart';
import 'pet_edit_screen.dart';
import 'pet_share_screen.dart';

class PetDetailScreen extends StatefulWidget {
  const PetDetailScreen({super.key, required this.api, required this.pet});
  final ApiClient api;
  final Pet pet;

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  late final ClinicalService _clinical = ClinicalService(widget.api);
  final OfflineStore _offline = OfflineStore();
  bool _loading = true;
  bool _offlineClinical = false;
  DateTime? _cachedAt;
  List<dynamic> _vaccinations = const [];
  List<Prescription> _prescriptions = const [];
  List<Allergy> _allergies = const [];
  List<MedicalRecord> _records = const [];
  final Map<String, String> _errors = {};

  @override
  void initState() { super.initState(); _loadAll(); }

  Future<void> _loadAll() async {
    if (mounted) setState(() { _loading = true; _errors.clear(); });
    await Future.wait([_loadVaccinations(), _loadPrescriptions(), _loadAllergies(), _loadRecords()]);

    if (_errors.isEmpty) {
      final snapshot = ClinicalSnapshot(
        petId: widget.pet.id,
        savedAt: DateTime.now(),
        vaccinations: _vaccinations.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        prescriptions: _prescriptions,
        allergies: _allergies,
        records: _records,
      );
      await _offline.saveClinicalSnapshot(snapshot);
      _offlineClinical = false;
      _cachedAt = snapshot.savedAt;
    } else {
      final snapshot = await _offline.loadClinicalSnapshot(widget.pet.id);
      if (snapshot != null) {
        if (_errors.containsKey('vaccinations')) _vaccinations = snapshot.vaccinations;
        if (_errors.containsKey('prescriptions')) _prescriptions = snapshot.prescriptions;
        if (_errors.containsKey('allergies')) _allergies = snapshot.allergies;
        if (_errors.containsKey('records')) _records = snapshot.records;
        _errors.clear();
        _offlineClinical = true;
        _cachedAt = snapshot.savedAt;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadVaccinations() async { try { _vaccinations = await widget.api.getList('/pets/${widget.pet.id}/vaccinations'); } on ApiException catch (e) { _errors['vaccinations'] = e.message; } }
  Future<void> _loadPrescriptions() async { try { _prescriptions = await _clinical.prescriptions(widget.pet.id); } on ApiException catch (e) { _errors['prescriptions'] = e.message; } }
  Future<void> _loadAllergies() async { try { _allergies = await _clinical.allergies(widget.pet.id); } on ApiException catch (e) { _errors['allergies'] = e.message; } }
  Future<void> _loadRecords() async { try { _records = await _clinical.medicalRecords(widget.pet.id); } on ApiException catch (e) { _errors['records'] = e.message; } }

  Future<void> _edit() async { final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => PetEditScreen(api: widget.api, pet: widget.pet))); if (changed == true && mounted) Navigator.of(context).pop(true); }
  Future<void> _share() async { await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PetShareScreen(api: widget.api, pet: widget.pet))); }
  Future<void> _documents() async { await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClinicalDocumentsScreen(api: widget.api, pet: widget.pet, records: _records))); }
  Future<void> _addAllergy() async {
    if (_offlineClinical) { _needConnection('registrar uma nova alergia'); return; }
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => AllergyFormScreen(api: widget.api, petId: widget.pet.id)));
    if (changed == true) await _loadAllergiesAndCache();
  }

  Future<void> _loadAllergiesAndCache() async { await _loadAll(); }

  void _needConnection(String action) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('É necessário estar online para $action. Os dados clínicos salvos continuam disponíveis para consulta.')));
  }

  Future<void> _deactivateAllergy(Allergy allergy) async {
    if (_offlineClinical) { _needConnection('alterar o estado de uma alergia'); return; }
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Marcar alergia como inativa?'), content: Text('O registro de ${allergy.allergen} continuará no histórico.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Desativar'))]));
    if (confirmed != true) return;
    try { await _clinical.deactivateAllergy(widget.pet.id, allergy.id); await _loadAll(); } on ApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Excluir pet?'), content: Text('Isso removerá ${widget.pet.name} e seus dados vinculados. Esta ação não pode ser desfeita.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir'))]));
    if (confirmed != true) return;
    try { await widget.api.delete('/pets/${widget.pet.id}'); await _offline.clearClinicalSnapshot(widget.pet.id); if (mounted) Navigator.of(context).pop(true); } on ApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
  }

  String _dateValue(dynamic value) { if (value is! String) return 'Data não informada'; final parsed = DateTime.tryParse(value); return parsed == null ? 'Data não informada' : _date(parsed); }
  String _date(DateTime value) => DateFormat('dd/MM/yyyy').format(value.toLocal());
  String _dateTime(DateTime value) => DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());
  String _severity(String value) => const {'MILD': 'Leve', 'MODERATE': 'Moderada', 'SEVERE': 'Grave', 'LIFE_THREATENING': 'Risco de vida'}[value] ?? value;

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final activeAllergies = _allergies.where((a) => a.active).toList();
    final inactiveAllergies = _allergies.where((a) => !a.active).toList();
    return Scaffold(
      appBar: AppBar(title: Text(pet.name), actions: [
        IconButton(onPressed: _offlineClinical ? () => _needConnection('abrir exames e documentos') : _documents, tooltip: 'Exames e documentos', icon: const Icon(Icons.folder_copy_outlined)),
        IconButton(onPressed: _offlineClinical ? () => _needConnection('gerar um compartilhamento temporário') : _share, tooltip: 'Compartilhar prontuário', icon: const Icon(Icons.qr_code_2)),
        IconButton(onPressed: _loadAll, tooltip: 'Atualizar prontuário', icon: const Icon(Icons.refresh)),
        PopupMenuButton<String>(onSelected: (value) { if (value == 'edit') _edit(); if (value == 'delete') _delete(); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Editar cadastro')), PopupMenuItem(value: 'delete', child: Text('Excluir pet'))]),
      ]),
      body: RefreshIndicator(onRefresh: _loadAll, child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
        if (_offlineClinical) Card(child: ListTile(leading: const Icon(Icons.cloud_off), title: const Text('Prontuário em modo offline'), subtitle: Text(_cachedAt == null ? 'Exibindo cópia protegida salva neste aparelho.' : 'Cópia protegida salva em ${_dateTime(_cachedAt!)}. Alterações clínicas exigem conexão.'))),
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [CircleAvatar(radius: 32, child: Icon(pet.species == 'CAT' ? Icons.cruelty_free : Icons.pets, size: 32)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(pet.name, style: Theme.of(context).textTheme.headlineSmall), Text([pet.species, if (pet.breed != null) pet.breed].join(' • '))]))]),
          const SizedBox(height: 20), _InfoRow(label: 'Microchip', value: pet.microchip ?? 'Não informado'), _InfoRow(label: 'Nascimento', value: pet.birthDate == null ? 'Não informado' : _date(pet.birthDate!)), _InfoRow(label: 'Versão do cadastro', value: '${pet.version}'),
        ]))),
        if (_loading) const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: LinearProgressIndicator()), const SizedBox(height: 12),
        _SectionHeader(title: 'Alergias', icon: Icons.warning_amber_rounded, actionLabel: _offlineClinical ? null : 'Registrar', onAction: _offlineClinical ? null : _addAllergy),
        if (_errors['allergies'] != null) _ErrorCard(message: _errors['allergies']!) else if (activeAllergies.isEmpty) const _EmptyCard(text: 'Nenhuma alergia ativa registrada.') else ...activeAllergies.map((allergy) => Card(child: ListTile(leading: CircleAvatar(child: Icon(allergy.severity == 'LIFE_THREATENING' || allergy.severity == 'SEVERE' ? Icons.priority_high : Icons.health_and_safety_outlined)), title: Text(allergy.allergen), subtitle: Text('${_severity(allergy.severity)}${allergy.reaction?.isNotEmpty == true ? '\nReação: ${allergy.reaction}' : ''}'), isThreeLine: allergy.reaction?.isNotEmpty == true, trailing: _offlineClinical ? null : PopupMenuButton<String>(onSelected: (_) => _deactivateAllergy(allergy), itemBuilder: (_) => const [PopupMenuItem(value: 'deactivate', child: Text('Marcar como inativa'))])))),
        if (inactiveAllergies.isNotEmpty) ExpansionTile(title: Text('Alergias inativas (${inactiveAllergies.length})'), children: inactiveAllergies.map((a) => ListTile(title: Text(a.allergen), subtitle: Text('${_severity(a.severity)} • registrada em ${_date(a.createdAt)}'))).toList()),
        const SizedBox(height: 20), const _SectionHeader(title: 'Prescrições', icon: Icons.medication_outlined),
        if (_errors['prescriptions'] != null) _ErrorCard(message: _errors['prescriptions']!) else if (_prescriptions.isEmpty) const _EmptyCard(text: 'Nenhuma prescrição registrada.') else ..._prescriptions.map((rx) => Card(child: ExpansionTile(leading: const CircleAvatar(child: Icon(Icons.medication)), title: Text(rx.medication), subtitle: Text('${rx.dosage} • ${rx.frequency}'), childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16), children: [_InfoRow(label: 'Prescrita em', value: _date(rx.prescribedAt)), if (rx.duration?.isNotEmpty == true) _InfoRow(label: 'Duração', value: rx.duration!), if (rx.instructions?.isNotEmpty == true) Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(top: 8), child: Text('Orientações: ${rx.instructions}')))]))),
        const SizedBox(height: 20), const _SectionHeader(title: 'Carteira de vacinação', icon: Icons.vaccines_outlined),
        if (_errors['vaccinations'] != null) _ErrorCard(message: _errors['vaccinations']!) else if (_vaccinations.isEmpty) const _EmptyCard(text: 'Nenhuma vacina registrada ainda.') else ..._vaccinations.map((raw) { final vaccine = raw as Map<String, dynamic>; return Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.vaccines)), title: Text(vaccine['vaccineName'] as String? ?? 'Vacina'), subtitle: Text('Aplicada em ${_dateValue(vaccine['dateAdministered'])}${vaccine['nextDueDate'] != null ? '\nPróxima dose: ${_dateValue(vaccine['nextDueDate'])}' : ''}${vaccine['batchNumber'] != null ? '\nLote: ${vaccine['batchNumber']}' : ''}'), isThreeLine: vaccine['nextDueDate'] != null || vaccine['batchNumber'] != null)); }),
        const SizedBox(height: 20), const _SectionHeader(title: 'Histórico clínico', icon: Icons.history_edu_outlined),
        if (_errors['records'] != null) _ErrorCard(message: _errors['records']!) else if (_records.isEmpty) const _EmptyCard(text: 'Nenhum atendimento clínico registrado.') else ..._records.map((record) => Card(child: ExpansionTile(leading: const CircleAvatar(child: Icon(Icons.medical_information_outlined)), title: Text(record.type), subtitle: Text('${_date(record.occurredAt)} • versão ${record.currentVersion}'), childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16), children: [if (record.diagnosis?.isNotEmpty == true) _ClinicalText(label: 'Diagnóstico', value: record.diagnosis!), if (record.treatment?.isNotEmpty == true) _ClinicalText(label: 'Tratamento', value: record.treatment!), if (record.notes?.isNotEmpty == true) _ClinicalText(label: 'Observações', value: record.notes!), if (record.versions.length > 1) ExpansionTile(tilePadding: EdgeInsets.zero, title: Text('Histórico de versões (${record.versions.length})'), children: record.versions.reversed.map((version) => ListTile(contentPadding: EdgeInsets.zero, title: Text('Versão ${version.version} • ${_date(version.createdAt)}'), subtitle: Text(version.reason?.isNotEmpty == true ? version.reason! : 'Sem justificativa informada'))).toList())]))),
      ])),
    );
  }
}

class _SectionHeader extends StatelessWidget { const _SectionHeader({required this.title, required this.icon, this.actionLabel, this.onAction}); final String title; final IconData icon; final String? actionLabel; final VoidCallback? onAction; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Icon(icon), const SizedBox(width: 8), Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)), if (onAction != null) TextButton.icon(onPressed: onAction, icon: const Icon(Icons.add), label: Text(actionLabel ?? 'Adicionar'))])); }
class _InfoRow extends StatelessWidget { const _InfoRow({required this.label, required this.value}); final String label; final String value; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(label)), const SizedBox(width: 12), Expanded(child: Text(value, textAlign: TextAlign.end))])); }
class _ClinicalText extends StatelessWidget { const _ClinicalText({required this.label, required this.value}); final String label; final String value; @override Widget build(BuildContext context) => Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: Theme.of(context).textTheme.labelLarge), const SizedBox(height: 4), Text(value)]))); }
class _EmptyCard extends StatelessWidget { const _EmptyCard({required this.text}); final String text; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [const Icon(Icons.info_outline), const SizedBox(width: 12), Expanded(child: Text(text))]))); }
class _ErrorCard extends StatelessWidget { const _ErrorCard({required this.message}); final String message; @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error), const SizedBox(width: 12), Expanded(child: Text(message))]))); }
