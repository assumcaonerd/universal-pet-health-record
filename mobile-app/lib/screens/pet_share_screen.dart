import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/api_client.dart';
import '../models/pet.dart';
import '../services/share_service.dart';

class PetShareScreen extends StatefulWidget {
  const PetShareScreen({super.key, required this.api, required this.pet});
  final ApiClient api;
  final Pet pet;

  @override
  State<PetShareScreen> createState() => _PetShareScreenState();
}

class _PetShareScreenState extends State<PetShareScreen> {
  String _level = 'READ';
  int _minutes = 15;
  int _uses = 1;
  bool _loading = false;
  String? _error;
  PetAccessGrant? _grant;

  Future<void> _create() async {
    setState(() { _loading = true; _error = null; });
    try {
      final grant = await ShareService(widget.api).create(widget.pet.id, level: _level, expiresInMinutes: _minutes, maxUses: _uses);
      if (mounted) setState(() => _grant = grant);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revoke() async {
    final grant = _grant;
    if (grant == null) return;
    setState(() => _loading = true);
    try {
      await ShareService(widget.api).revoke(grant.id);
      if (mounted) setState(() => _grant = null);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grant = _grant;
    return Scaffold(
      appBar: AppBar(title: const Text('Compartilhar prontuário')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(widget.pet.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Crie um acesso temporário. O QR contém um token secreto: mostre somente à pessoa ou profissional que deve acessar o prontuário.'),
        const SizedBox(height: 24),
        if (grant == null) ...[
          DropdownButtonFormField<String>(value: _level, decoration: const InputDecoration(labelText: 'Permissão'), items: const [DropdownMenuItem(value: 'READ', child: Text('Somente leitura')), DropdownMenuItem(value: 'WRITE', child: Text('Leitura e registro clínico'))], onChanged: (v) => setState(() => _level = v ?? 'READ')),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(value: _minutes, decoration: const InputDecoration(labelText: 'Validade'), items: const [DropdownMenuItem(value: 5, child: Text('5 minutos')), DropdownMenuItem(value: 15, child: Text('15 minutos')), DropdownMenuItem(value: 30, child: Text('30 minutos')), DropdownMenuItem(value: 60, child: Text('60 minutos'))], onChanged: (v) => setState(() => _minutes = v ?? 15)),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(value: _uses, decoration: const InputDecoration(labelText: 'Quantidade máxima de usos'), items: const [DropdownMenuItem(value: 1, child: Text('1 uso')), DropdownMenuItem(value: 2, child: Text('2 usos')), DropdownMenuItem(value: 5, child: Text('5 usos')), DropdownMenuItem(value: 10, child: Text('10 usos'))], onChanged: (v) => setState(() => _uses = v ?? 1)),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: _loading ? null : _create, icon: const Icon(Icons.qr_code_2), label: Text(_loading ? 'Gerando...' : 'Gerar QR temporário')),
        ] else ...[
          Center(child: QrImageView(data: grant.token, version: QrVersions.auto, size: 260, semanticsLabel: 'QR temporário de acesso ao prontuário')),
          const SizedBox(height: 20),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            _row('Permissão', grant.level == 'WRITE' ? 'Leitura e escrita' : 'Somente leitura'),
            _row('Validade', '${grant.expiresAt.toLocal()}'),
            _row('Máximo de usos', '${grant.maxUses}'),
          ]))),
          const SizedBox(height: 12),
          const Text('O token não será recuperável depois que você sair desta tela. Se não precisar mais dele, revogue agora.', textAlign: TextAlign.center),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 20),
          OutlinedButton.icon(onPressed: _loading ? null : _revoke, icon: const Icon(Icons.block), label: const Text('Revogar acesso agora')),
        ],
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text(label)), Expanded(child: Text(value, textAlign: TextAlign.end))]));
}
