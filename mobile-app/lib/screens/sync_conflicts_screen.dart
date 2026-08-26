import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/offline_store.dart';
import '../models/pet.dart';
import '../services/offline_sync_service.dart';

class SyncConflictsScreen extends StatefulWidget {
  const SyncConflictsScreen({super.key, required this.api, required this.store});
  final ApiClient api;
  final OfflineStore store;

  @override
  State<SyncConflictsScreen> createState() => _SyncConflictsScreenState();
}

class _SyncConflictsScreenState extends State<SyncConflictsScreen> {
  bool _loading = true;
  String? _error;
  List<SyncConflict> _conflicts = const [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await OfflineSyncService(widget.api, widget.store).flush();
      if (mounted) setState(() => _conflicts = result.conflicts);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Pet?> _serverPet(String id) async {
    try {
      final json = await widget.api.getObject('/pets/$id');
      return Pet.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _keepServer(SyncConflict conflict) async {
    final server = await _serverPet(conflict.event.entityId);
    if (server == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível carregar a versão do servidor.')));
      return;
    }
    await widget.store.removeEvent(conflict.event.clientEventId);
    await widget.store.upsertCachedPet(server);
    if (mounted) {
      setState(() => _conflicts = _conflicts.where((c) => c.event.clientEventId != conflict.event.clientEventId).toList());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Versão do servidor mantida.')));
    }
  }

  Future<void> _retryLocal(SyncConflict conflict) async {
    final server = await _serverPet(conflict.event.entityId);
    if (server == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível carregar a versão atual do servidor.')));
      return;
    }
    final replacement = PendingSyncEvent(
      clientEventId: conflict.event.clientEventId,
      deviceId: conflict.event.deviceId,
      entityType: conflict.event.entityType,
      entityId: conflict.event.entityId,
      operation: conflict.event.operation,
      version: server.version + 1,
      payload: conflict.event.payload,
    );
    await widget.store.replaceEvent(conflict.event.clientEventId, replacement);
    final result = await OfflineSyncService(widget.api, widget.store).flush();
    if (mounted) {
      setState(() => _conflicts = result.conflicts);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.conflicts.isEmpty ? 'Alteração local sincronizada.' : 'O conflito ainda precisa de revisão.')));
    }
  }

  Future<void> _details(SyncConflict conflict) async {
    final localPets = await widget.store.loadPets();
    final local = localPets.where((p) => p.id == conflict.event.entityId).cast<Pet?>().firstWhere((p) => p != null, orElse: () => null);
    final server = await _serverPet(conflict.event.entityId);
    if (!mounted) return;
    showDialog<void>(context: context, builder: (context) => AlertDialog(
      title: const Text('Comparar versões'),
      content: SizedBox(width: 520, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Motivo: ${conflict.reason}'), const SizedBox(height: 16),
        _versionCard('Neste aparelho', local, conflict.event.payload, conflict.event.version), const SizedBox(height: 12),
        _versionCard('No servidor', server, const {}, server?.version),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
    ));
  }

  Widget _versionCard(String title, Pet? pet, Map<String, dynamic> payload, int? version) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8),
    Text('Versão: ${version ?? '-'}'),
    Text('Nome: ${payload['name'] ?? pet?.name ?? '-'}'),
    Text('Espécie: ${payload['species'] ?? pet?.species ?? '-'}'),
    Text('Raça: ${payload.containsKey('breed') ? (payload['breed'] ?? 'Não informada') : (pet?.breed ?? 'Não informada')}'),
    Text('Microchip: ${payload.containsKey('microchip') ? (payload['microchip'] ?? 'Não informado') : (pet?.microchip ?? 'Não informado')}'),
  ])));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Conflitos de sincronização'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!))) : _conflicts.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Nenhum conflito pendente.'))) : ListView.separated(
      padding: const EdgeInsets.all(16), itemCount: _conflicts.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (context, index) {
        final conflict = _conflicts[index];
        return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Alteração pendente', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 6),
          Text('Motivo: ${conflict.reason}'), Text('Versão local: ${conflict.event.version}'), Text('Versão do servidor: ${conflict.serverVersion ?? '-'}'),
          const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton(onPressed: () => _details(conflict), child: const Text('Comparar')),
            FilledButton.tonal(onPressed: () => _keepServer(conflict), child: const Text('Manter servidor')),
            FilledButton(onPressed: () => _retryLocal(conflict), child: const Text('Tentar minha alteração')),
          ]),
        ]));
      },
    ),
  );
}
