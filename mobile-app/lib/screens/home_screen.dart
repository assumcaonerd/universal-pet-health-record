import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/offline_store.dart';
import '../models/pet.dart';
import '../services/offline_sync_service.dart';
import 'pet_detail_screen.dart';
import 'pet_form_screen.dart';
import 'reminders_screen.dart';
import 'security_screen.dart';
import 'sync_conflict_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api, required this.onLogout});
  final ApiClient api;
  final Future<void> Function() onLogout;
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OfflineStore _offline = OfflineStore();
  bool _loading = true, _offlineMode = false;
  int _pending = 0;
  String? _error;
  List<Pet> _pets = const [];
  List<SyncConflict> _conflicts = const [];
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { setState(() { _loading = true; _error = null; }); try { final sync = await OfflineSyncService(widget.api, _offline).flush(); final raw = await widget.api.getList('/pets'); final pets = raw.map((e) => Pet.fromJson(e as Map<String, dynamic>)).toList(); await _offline.savePets(pets); if (mounted) setState(() { _pets = pets; _offlineMode = false; _pending = sync.remaining; _conflicts = sync.conflicts; }); } catch (_) { final cached = await _offline.loadPets(); final queue = await _offline.queue(); if (mounted) setState(() { _pets = cached; _offlineMode = true; _pending = queue.length; if (cached.isEmpty) _error = 'Sem conexão e ainda não há prontuário salvo neste aparelho.'; }); } finally { if (mounted) setState(() => _loading = false); } }
  Future<void> _openConflicts() async { if (_conflicts.isEmpty) return; final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => SyncConflictScreen(api: widget.api, store: _offline, conflicts: _conflicts))); if (changed == true) await _load(); }
  Future<void> _addPet() async { final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => PetFormScreen(api: widget.api))); if (created == true) await _load(); }
  void _openReminders() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RemindersScreen(pets: _pets, api: widget.api)));

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meus pets'), actions: [IconButton(tooltip: 'Cuidados e lembretes', onPressed: _pets.isEmpty ? null : _openReminders, icon: const Icon(Icons.notifications_active_outlined)), IconButton(tooltip: 'Segurança da conta', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SecurityScreen(api: widget.api))), icon: const Icon(Icons.shield_outlined)), IconButton(tooltip: 'Sincronizar', onPressed: _load, icon: const Icon(Icons.sync)), IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout))]),
    floatingActionButton: FloatingActionButton.extended(onPressed: _offlineMode ? null : _addPet, icon: const Icon(Icons.add), label: const Text('Adicionar pet')),
    body: Column(children: [
      if (_conflicts.isNotEmpty) MaterialBanner(content: Text('${_conflicts.length} conflito(s) de sincronização precisam da sua escolha.'), leading: const Icon(Icons.warning_amber_rounded), actions: [TextButton(onPressed: _openConflicts, child: const Text('Resolver agora'))]) else if (_offlineMode || _pending > 0) MaterialBanner(content: Text(_offlineMode ? 'Modo offline. Exibindo dados protegidos salvos neste aparelho.${_pending > 0 ? ' $_pending alteração(ões) aguardando sincronização.' : ''}' : '$_pending alteração(ões) aguardando sincronização.'), leading: Icon(_offlineMode ? Icons.cloud_off : Icons.sync_problem), actions: [TextButton(onPressed: _load, child: const Text('Tentar sincronizar'))]),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _load, child: const Text('Tentar novamente'))]))) : _pets.isEmpty ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.pets_outlined, size: 56), const SizedBox(height: 16), const Text('Você ainda não cadastrou nenhum pet.', textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: _offlineMode ? null : _addPet, icon: const Icon(Icons.add), label: const Text('Cadastrar primeiro pet'))]))) : RefreshIndicator(onRefresh: _load, child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: _pets.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (context, index) { final pet = _pets[index]; return Card(child: ListTile(leading: CircleAvatar(child: Icon(pet.species == 'CAT' ? Icons.cruelty_free : Icons.pets)), title: Text(pet.name), subtitle: Text([pet.species, if (pet.breed != null) pet.breed, if (_offlineMode) 'offline'].join(' • ')), trailing: const Icon(Icons.chevron_right), onTap: () async { await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PetDetailScreen(api: widget.api, pet: pet))); await _load(); })); })))
    ]),
  );
}
