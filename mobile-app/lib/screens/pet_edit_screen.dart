import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/pet.dart';

class PetEditScreen extends StatefulWidget {
  const PetEditScreen({super.key, required this.api, required this.pet});
  final ApiClient api;
  final Pet pet;

  @override
  State<PetEditScreen> createState() => _PetEditScreenState();
}

class _PetEditScreenState extends State<PetEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _breed;
  late final TextEditingController _microchip;
  late String _species;
  DateTime? _birthDate;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.pet.name);
    _breed = TextEditingController(text: widget.pet.breed ?? '');
    _microchip = TextEditingController(text: widget.pet.microchip ?? '');
    _species = widget.pet.species;
    _birthDate = widget.pet.birthDate;
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() { _saving = true; _error = null; });
    try {
      await widget.api.patch('/pets/${widget.pet.id}', {
        'name': _name.text.trim(),
        'species': _species,
        'breed': _breed.text.trim().isEmpty ? null : _breed.text.trim(),
        'microchip': _microchip.text.trim().isEmpty ? null : _microchip.text.trim(),
        'birthDate': _birthDate?.toIso8601String(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Editar pet')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nome')),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(value: _species, decoration: const InputDecoration(labelText: 'Espécie'), items: const [
            DropdownMenuItem(value: 'DOG', child: Text('Cachorro')),
            DropdownMenuItem(value: 'CAT', child: Text('Gato')),
            DropdownMenuItem(value: 'BIRD', child: Text('Ave')),
            DropdownMenuItem(value: 'RABBIT', child: Text('Coelho')),
            DropdownMenuItem(value: 'OTHER', child: Text('Outro')),
          ], onChanged: (value) => setState(() => _species = value ?? _species)),
          const SizedBox(height: 16),
          TextField(controller: _breed, decoration: const InputDecoration(labelText: 'Raça')),
          const SizedBox(height: 16),
          TextField(controller: _microchip, decoration: const InputDecoration(labelText: 'Microchip')),
          const SizedBox(height: 16),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('Nascimento'), subtitle: Text(_birthDate == null ? 'Não informado' : '${_birthDate!.day.toString().padLeft(2,'0')}/${_birthDate!.month.toString().padLeft(2,'0')}/${_birthDate!.year}'), trailing: const Icon(Icons.calendar_month), onTap: () async {
            final picked = await showDatePicker(context: context, firstDate: DateTime(1980), lastDate: DateTime.now(), initialDate: _birthDate ?? DateTime.now().subtract(const Duration(days: 365)));
            if (picked != null) setState(() => _birthDate = picked);
          }),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          const SizedBox(height: 24),
          FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Salvando...' : 'Salvar alterações')),
        ]),
      );
}
