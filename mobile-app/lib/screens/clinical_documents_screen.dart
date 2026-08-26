import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/clinical_attachment.dart';
import '../models/clinical_models.dart';
import '../models/pet.dart';
import '../services/document_service.dart';

class ClinicalDocumentsScreen extends StatefulWidget {
  const ClinicalDocumentsScreen({super.key, required this.api, required this.pet, required this.records});
  final ApiClient api;
  final Pet pet;
  final List<MedicalRecord> records;

  @override
  State<ClinicalDocumentsScreen> createState() => _ClinicalDocumentsScreenState();
}

class _ClinicalDocumentsScreenState extends State<ClinicalDocumentsScreen> {
  late final DocumentService _documents = DocumentService(widget.api);
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  List<ClinicalAttachment> _items = const [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try { _items = await _documents.list(widget.pet.id); }
    on ApiException catch (e) { _error = e.message; }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(withData: true, allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível ler o arquivo selecionado.')));
      return;
    }

    String? recordId;
    if (widget.records.isNotEmpty && mounted) {
      recordId = await showModalBottomSheet<String?>(context: context, builder: (context) => SafeArea(child: ListView(shrinkWrap: true, children: [
        const ListTile(title: Text('Vincular a um atendimento?'), subtitle: Text('Você pode deixar o documento apenas no prontuário geral ou associá-lo a um atendimento específico.')),
        ListTile(leading: const Icon(Icons.folder_outlined), title: const Text('Prontuário geral'), onTap: () => Navigator.pop(context, '')),
        ...widget.records.map((record) => ListTile(leading: const Icon(Icons.medical_information_outlined), title: Text(record.type), subtitle: Text(record.occurredAt.toLocal().toString()), onTap: () => Navigator.pop(context, record.id))),
      ])));
      if (!mounted) return;
      if (recordId == null) return;
      if (recordId.isEmpty) recordId = null;
    }

    setState(() { _uploading = true; _error = null; });
    try {
      await _documents.upload(petId: widget.pet.id, fileName: file.name, bytes: bytes, medicalRecordId: recordId);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento enviado e verificado com sucesso.')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _error = e.message.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _open(ClinicalAttachment item) async {
    try { await _documents.openDownload(widget.pet.id, item); }
    on ApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); }
  }

  String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exames e documentos')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _uploading ? null : _pickAndUpload, icon: const Icon(Icons.upload_file), label: Text(_uploading ? 'Enviando...' : 'Adicionar arquivo')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.pet.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Arquivos de até 50 MB. O SHA-256 é calculado no aparelho antes do envio e conferido pelo servidor depois do upload.'),
            ]))),
            if (_uploading) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator()),
            if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            if (_loading) const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Nenhum exame ou documento enviado ainda.')))
            else ..._items.map((item) => Card(child: ListTile(
              leading: CircleAvatar(child: Icon(item.mimeType == 'application/pdf' ? Icons.picture_as_pdf_outlined : Icons.description_outlined)),
              title: Text(item.fileName),
              subtitle: Text('${_size(item.sizeBytes)} • ${item.mimeType}${item.medicalRecordId != null ? '\nVinculado a atendimento clínico' : ''}'),
              isThreeLine: item.medicalRecordId != null,
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _open(item),
            ))),
          ],
        ),
      ),
    );
  }
}
