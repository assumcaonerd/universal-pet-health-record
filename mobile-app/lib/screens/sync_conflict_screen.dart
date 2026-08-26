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
  late List<SyncConflict> _conflicts;

  @override
  void initState() {
    super.initState();
    _conflicts = List<SyncConflict>.from(widget.conflicts);
    for (final conflict in _conflicts) {
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
    _removeResolved(conflict, 'Versão do servidor mantida.');
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
    final result = await OfflineSyncService(widget.api, widget.store).flush();
    if (result.conflicts.isEmpty) {
      _removeResolved(conflict, 'Sua alteração foi reaplicada sobre a versão mais recente.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _conflicts.removeWhere((c) => c.event.clientEventId == conflict.event.clientEventId);
      _conflicts.addAll(result.conflicts.where((c) => !_conflicts.any((existing) => existing.event.clientEventId == c.event.clientEventId)));
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ainda existe divergência. Revise novamente antes de aplicar.')));
  }

  void _removeResolved(SyncConflict conflict, String message) {
    if (!mounted) return;
    setState(() => _conflicts.removeWhere((c) => c.event.clientEventId == conflict.event.clientEventId));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    if (_conflicts.isEmpty) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Conflitos de sincronização (${_conflicts.length})')),
      body: _conflicts.isEmpty
          ? const Center(child: Text('Nenhum conflito pendente.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _conflicts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final conflict = _conflicts[index];
                final server = _serverPets[conflict.event.entityId];
                final loading = _loading.contains(conflict.event.entityId);
                final local = conflict.event.payload;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.sync_problem),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Alteração pendente', style: Theme.of(context).textTheme.titleMedium)),
                      ]),
                      const SizedBox(height: 6),
                      Text(_reason(conflict.reason)),
                      const SizedBox(height: 4),
                      Text('Versão deste aparelho: ${conflict.event.version} • servidor: ${conflict.serverVersion ?? server?.version ?? '-'}'),
                      const SizedBox(height: 12),
                      if (loading) const LinearProgressIndicator(),
                      if (!loading && server != null) ...[
                        _ComparisonTable(server: server, local: local),
                        const SizedBox(height: 12),
                        const Text('Escolha conscientemente qual versão deve prevalecer. Nenhuma alteração é aplicada automaticamente.'),
                        const SizedBox(height: 12),
                        Wrap(spacing: 10, runSpacing: 10, children: [
                          OutlinedButton.icon(onPressed: () => _useServer(conflict), icon: const Icon(Icons.cloud_done_outlined), label: const Text('Manter servidor')),
                          FilledButton.icon(onPressed: () => _reapplyLocal(conflict), icon: const Icon(Icons.phone_android), label: const Text('Reaplicar minha alteração')),
                        ]),
                      ],
                      if (!loading && server == null) ...[
                        const Text('Não foi possível carregar a versão atual do servidor. Nenhuma decisão foi aplicada.'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(onPressed: () => _loadServerPet(conflict), icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
                      ],
                    ]),
                  ),
                );
              },
            ),
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

class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.server, required this.local});
  final Pet server;
  final Map<String, dynamic> local;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, List<Object?>>>[
      MapEntry('Nome', [server.name, local['name']]),
      MapEntry('Espécie', [server.species, local['species']]),
      MapEntry('Raça', [server.breed, local.containsKey('breed') ? local['breed'] : null]),
      MapEntry('Microchip', [server.microchip, local.containsKey('microchip') ? local['microchip'] : null]),
      MapEntry('Nascimento', [server.birthDate?.toIso8601String(), local.containsKey('birthDate') ? local['birthDate'] : null]),
    ];
    return Column(children: [
      Row(children: const [Expanded(flex: 2, child: Text('Campo', style: TextStyle(fontWeight: FontWeight.w700))), Expanded(flex: 3, child: Text('Servidor', style: TextStyle(fontWeight: FontWeight.w700))), Expanded(flex: 3, child: Text('Neste aparelho', style: TextStyle(fontWeight: FontWeight.w700)))]),
      const Divider(),
      ...rows.map((entry) {
        final serverValue = _format(entry.value[0]);
        final localValue = entry.value[1] == null && !local.containsKey(_payloadKey(entry.key)) ? 'sem alteração local' : _format(entry.value[1]);
        final changed = localValue != 'sem alteração local' && localValue != serverValue;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 2, child: Text(entry.key)),
            Expanded(flex: 3, child: Text(serverValue)),
            Expanded(flex: 3, child: Text(localValue, style: changed ? TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary) : null)),
          ]),
        );
      }),
    ]);
  }

  static String _format(Object? value) => value?.toString().trim().isNotEmpty == true ? value.toString() : 'não informado';
  static String _payloadKey(String label) => const {'Nome': 'name', 'Espécie': 'species', 'Raça': 'breed', 'Microchip': 'microchip', 'Nascimento': 'birthDate'}[label] ?? '';
}
