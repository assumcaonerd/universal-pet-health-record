import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../models/pet.dart';

class PetDetailScreen extends StatefulWidget {
  const PetDetailScreen({super.key, required this.api, required this.pet});

  final ApiClient api;
  final Pet pet;

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _vaccinations = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final vaccinations = await widget.api.getList('/pets/${widget.pet.id}/vaccinations');
      setState(() => _vaccinations = vaccinations);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _date(dynamic value) {
    if (value is! String) return 'Data não informada';
    final parsed = DateTime.tryParse(value);
    return parsed == null ? 'Data não informada' : DateFormat('dd/MM/yyyy').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    return Scaffold(
      appBar: AppBar(title: Text(pet.name)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const CircleAvatar(radius: 30, child: Icon(Icons.pets, size: 30)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(pet.name, style: Theme.of(context).textTheme.headlineSmall),
                      Text([pet.species, if (pet.breed != null) pet.breed].join(' • ')),
                    ])),
                  ]),
                  const SizedBox(height: 20),
                  _InfoRow(label: 'Microchip', value: pet.microchip ?? 'Não informado'),
                  _InfoRow(label: 'Nascimento', value: pet.birthDate == null ? 'Não informado' : DateFormat('dd/MM/yyyy').format(pet.birthDate!.toLocal())),
                  _InfoRow(label: 'Versão do cadastro', value: '${pet.version}'),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Text('Carteira de vacinação', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))
            else if (_vaccinations.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Nenhuma vacina registrada ainda.')))
            else ..._vaccinations.map((raw) {
              final vaccine = raw as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.vaccines)),
                  title: Text(vaccine['vaccineName'] as String? ?? 'Vacina'),
                  subtitle: Text('Aplicada em ${_date(vaccine['dateAdministered'])}${vaccine['nextDueDate'] != null ? '\nPróxima dose: ${_date(vaccine['nextDueDate'])}' : ''}'),
                  isThreeLine: vaccine['nextDueDate'] != null,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [Expanded(child: Text(label)), Expanded(child: Text(value, textAlign: TextAlign.end))]),
      );
}
