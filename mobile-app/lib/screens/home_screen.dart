import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/pet.dart';
import 'pet_detail_screen.dart';
import 'pet_form_screen.dart';
import 'security_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api, required this.onLogout});
  final ApiClient api;
  final Future<void> Function() onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  String? _error;
  List<Pet> _pets = const [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await widget.api.getList('/pets');
      setState(() => _pets = raw.map((e) => Pet.fromJson(e as Map<String, dynamic>)).toList());
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addPet() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => PetFormScreen(api: widget.api)));
    if (created == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus pets'), actions: [
        IconButton(tooltip: 'Segurança da conta', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SecurityScreen(api: widget.api))), icon: const Icon(Icons.shield_outlined)),
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout)),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: _addPet, icon: const Icon(Icons.add), label: const Text('Adicionar pet')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _load, child: const Text('Tentar novamente'))])))
              : _pets.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.pets_outlined, size: 56), const SizedBox(height: 16), const Text('Você ainda não cadastrou nenhum pet.', textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton.icon(onPressed: _addPet, icon: const Icon(Icons.add), label: const Text('Cadastrar primeiro pet'))])))
                  : RefreshIndicator(onRefresh: _load, child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: _pets.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (context, index) {
                      final pet = _pets[index];
                      return Card(child: ListTile(leading: CircleAvatar(child: Icon(pet.species == 'CAT' ? Icons.cruelty_free : Icons.pets)), title: Text(pet.name), subtitle: Text([pet.species, if (pet.breed != null) pet.breed].join(' • ')), trailing: const Icon(Icons.chevron_right), onTap: () async { await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PetDetailScreen(api: widget.api, pet: pet))); await _load(); }));
                    })),
    );
  }
}
