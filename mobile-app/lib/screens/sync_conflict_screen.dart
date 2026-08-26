import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/api_client.dart';
import '../core/offline_store.dart';
import '../models/pet.dart';
import '../services/offline_sync_service.dart';

class SyncConflictScreen extends StatefulWidget {
  const SyncConflictScreen({super.key, required this.api, required this.store, required this.conflicts});
  final ApiClient api;
  final OfflineStore store;
  final List<SyncConflict> conflicts;

  @override
  State<SyncConflictScreen> createState() => _SyncConflictScreenState();
}

class _SyncConflictScreenState extends State<SyncConflictScreen> {
  final Map<String, Pet?> _serverPets = {};
  final Set<String> _loading = {};

  @override
  void initState() {
    super.initState();
    for (final conflict in widget.conflicts) {
      _loadServerPet(conflict);
    }
  }

  Future<void> _loadServerPet(SyncConflict conflict) async {
    final id = conflict.event.entityId;
    setState(() => _loading.add(id));
    try {
      final json = await widget.api.getObject('/pets/$id');
      _serverPets[id] = Pet.fromJson(json);
    } catch (_) {
      _serverPets[id] = null;
    } finally {
      if (mounted) setState(() => _loading.remove(id));
    }
  }

  Future<void> _useServer(SyncConflict conflict) async {
    final server = _serverPets[conflict.event.entityId];
    if (server == null) return;
    await widget.store.removeEvent(conflict.event.clientEventId);
    await widget.store.upsertCachedPet(server);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _reapplyLocal(SyncConflict conflict) async {
    final server = _serverPets[conflict.event.entityId];
    if (server == null) return;
    final event = conflict.event;
    final replacement = PendingSyncEvent(
      clientEventId: const Uuid().v4(),
      deviceId: event.deviceId,
      entityType: event.entityType,
      entityId: event.entityId,
      operation: event.operation,
      version: server.version + 1,
      payload: event.payload,
    );
    await widget.store.replaceEvent(event.clientEventId, replacement);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conflitos de sincronização')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.conflicts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final conflict = widget.conflicts[index];
          final server = _serverPets[conflict.event.entityId];
          final loading = _loading.contains(conflict.event.entityId);
          final local = conflict.event.payload;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Alteração pendente', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(_reason(conflict.reason)),
                const SizedBox(height: 12),
                if (loading) const LinearProgressIndicator(),
                if (!loading && server != null) ...[
                  Text('Servidor: versão ${server.version}', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  _row('Nome', server.name, local['name']),
                  _row('Espécie', server.species, local['species']),
                  _row('Raça', server.breed, local['breed']),
                  _row('Microchip', server.microchip, local['microchip']),
                  const SizedBox(height: 12),
                  const Text('Escolha qual caminho seguir. Nenhuma opção é aplicada automaticamente.'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => _useServer(conflict), child: const Text('Usar servidor'))),
                    const SizedBox(width: 12),
                    Expanded(child: FilledButton(onPressed: () => _reapplyLocal(conflict), child: const Text('Reaplicar minha alteração'))),
                  ]),
                ],
                if (!loading && server == null) ...[
                  const Text('Não foi possível carregar a versão atual do servidor.'),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: () => _loadServerPet(conflict), child: const Text('Tentar novamente')),
                ],
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, Object? server, Object? local) {
    final s = server?.toString() ?? 'não informado';
    final l = local?.toString() ?? 'sem alteração local';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text('Servidor: $s'),
        Text('Neste aparelho: $l'),
      ]),
    );
  }

  String _reason(String reason) => const {
    'STALE_VERSION': 'Este aparelho editou uma versão antiga do cadastro.',
    'VERSION_GAP': 'Há versões intermediárias no servidor que este aparelho ainda não recebeu.',
    'CONCURRENT_VERSION': 'Outro dispositivo enviou uma alteração para a mesma versão.',
    'OPTIMISTIC_LOCK_FAILED': 'O cadastro mudou no servidor enquanto a sincronização era aplicada.',
    'VERSION_REQUIRED': 'A alteração local não contém uma versão válida para sincronização.',
  }[reason] ?? 'O servidor encontrou uma divergência de versão.';
}
