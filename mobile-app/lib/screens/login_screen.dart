import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authService, required this.onAuthenticated, required this.onRegister});

  final AuthService authService;
  final VoidCallback onAuthenticated;
  final VoidCallback onRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _secondFactor = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final factor = _secondFactor.text.trim().toUpperCase();
    try {
      await widget.authService.login(
        email: _email.text.trim(),
        password: _password.text,
        mfaCode: RegExp(r'^\d{6}$').hasMatch(factor) ? factor : null,
        recoveryCode: RegExp(r'^[A-Z0-9]{4}-[A-Z0-9]{4}$').hasMatch(factor) ? factor : null,
      );
      widget.onAuthenticated();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Não foi possível entrar agora.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.pets_rounded, size: 64),
                  const SizedBox(height: 20),
                  Text('Prontuário do seu pet', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Vacinas, histórico e documentos em um só lugar.', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail')),
                  const SizedBox(height: 16),
                  TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _secondFactor,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 9,
                    decoration: const InputDecoration(labelText: 'MFA ou código de recuperação', hintText: '123456 ou ABCD-1234', counterText: ''),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(onPressed: _loading ? null : _submit, child: Text(_loading ? 'Entrando...' : 'Entrar')),
                  const SizedBox(height: 12),
                  TextButton(onPressed: widget.onRegister, child: const Text('Criar minha conta')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
