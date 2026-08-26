import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../models/adherence_summary.dart';
import '../services/adherence_service.dart';

class AdherenceScreen extends StatefulWidget {
  const AdherenceScreen({super.key, required this.api, required this.petId, required this.prescriptionId, required this.medication});
  final ApiClient api;
  final String petId;
  final String prescriptionId;
  final String medication;

  @override
  State<AdherenceScreen> createState() => _AdherenceScreenState();
}

class _AdherenceScreenState extends State<AdherenceScreen> {
  bool _loading = true;
  String? _error;
  AdherenceSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final summary = await AdherenceService(widget.api).summary(widget.petId, widget.prescriptionId);
      if (mounted) setState(() => _summary = summary);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _dt(DateTime value) => DateFormat('dd/MM/yyyy HH:mm').format(value.toLocal());

  String _delay(AdherenceEvent event) {
    final delay = event.delay;
    if (delay == null) return '';
    final minutes = delay.inMinutes;
    if (minutes.abs() < 1) return 'no horário';
    if (minutes > 0) return '$minutes min depois';
    return '${minutes.abs()} min antes';
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    return Scaffold(
      appBar: AppBar(title: Text('Adesão • ${widget.medication}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _load, child: const Text('Tentar novamente'))])))
              : summary == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(summary.adherencePercent == null ? 'Sem dados suficientes' : '${summary.adherencePercent!.toStringAsFixed(1)}% de adesão registrada', style: Theme.of(context).textTheme.headlineSmall),
                                  const SizedBox(height: 16),
                                  Wrap(spacing: 12, runSpacing: 12, children: [
                                    _Metric(label: 'Registradas', value: '${summary.recorded}'),
                                    _Metric(label: 'Tomadas', value: '${summary.taken}'),
                                    _Metric(label: 'No horário', value: '${summary.onTimeTaken}'),
                                    _Metric(label: 'Atrasadas >30 min', value: '${summary.lateTaken}'),
                                    _Metric(label: 'Omitidas', value: '${summary.skipped}'),
                                  ]),
                                  const SizedBox(height: 12),
                                  const Text('O percentual considera apenas doses registradas como tomadas ou omitidas. Ele não substitui avaliação veterinária.'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('Linha do tempo', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 10),
                          if (summary.events.isEmpty)
                            const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Nenhuma dose registrada neste tratamento.')))
                          else
                            ...summary.events.map((event) => Card(
                                  child: ListTile(
                                    leading: CircleAvatar(child: Icon(event.status == 'TAKEN' ? Icons.check : Icons.close)),
                                    title: Text(event.status == 'TAKEN' ? 'Dose tomada' : 'Dose omitida'),
                                    subtitle: Text('Prevista: ${_dt(event.scheduledAt)}${event.administeredAt == null ? '' : '\nAdministrada: ${_dt(event.administeredAt!)} • ${_delay(event)}'}${event.note?.isNotEmpty == true ? '\nObservação: ${event.note}' : ''}'),
                                    isThreeLine: event.administeredAt != null || event.note?.isNotEmpty == true,
                                  ),
                                )),
                        ],
                      ),
                    ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: Theme.of(context).textTheme.titleLarge), Text(label)]),
      );
}
