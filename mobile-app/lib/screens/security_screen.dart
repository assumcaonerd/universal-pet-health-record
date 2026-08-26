import 'package:flutter/material.dart';
import '../core/api_client.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _security;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await widget.api.getObject('/account/security');
      setState(() => _security = result);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestVerification() async {
    try {
      await widget.api.post('/account/email-verification/request', {}, authenticated: true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-mail de verificação solicitado.')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _security;
    return Scaffold(
      appBar: AppBar(title: const Text('Segurança da conta')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), const SizedBox(height: 12), FilledButton(onPressed: _load, child: const Text('Tentar novamente'))])))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    Card(child: Column(children: [
                      SwitchListTile(value: data?['emailVerified'] == true, onChanged: null, title: const Text('E-mail verificado'), subtitle: Text(data?['emailVerified'] == true ? 'Conta confirmada' : 'Verificação pendente')),
                      if (data?['emailVerified'] != true) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: _requestVerification, icon: const Icon(Icons.mark_email_read_outlined), label: const Text('Enviar verificação')))),
                      SwitchListTile(value: data?['mfaEnabled'] == true, onChanged: null, title: const Text('Autenticação em duas etapas'), subtitle: Text(data?['mfaEnabled'] == true ? 'MFA ativado' : 'MFA desativado')),
                      ListTile(leading: const Icon(Icons.key), title: const Text('Códigos de recuperação'), trailing: Text('${data?['remainingRecoveryCodes'] ?? 0}')),
                      ListTile(leading: const Icon(Icons.devices), title: const Text('Sessões ativas'), trailing: Text('${data?['activeSessions'] ?? 0}')),
                    ])),
                    const SizedBox(height: 20),
                    Text('Atividade recente', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    ...((data?['recentSecurityEvents'] as List?) ?? const []).map((event) {
                      final e = event as Map<String, dynamic>;
                      return Card(child: ListTile(leading: const Icon(Icons.shield_outlined), title: Text(e['action']?.toString() ?? 'Evento de segurança'), subtitle: Text(e['createdAt']?.toString() ?? '')));
                    }),
                  ]),
                ),
    );
  }
}
