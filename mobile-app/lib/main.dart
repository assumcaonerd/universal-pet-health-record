import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'core/offline_store.dart';
import 'core/session_store.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  runApp(const PetHealthApp());
}

class PetHealthApp extends StatefulWidget {
  const PetHealthApp({super.key});

  @override
  State<PetHealthApp> createState() => _PetHealthAppState();
}

class _PetHealthAppState extends State<PetHealthApp> {
  late final SessionStore _sessionStore;
  late final ApiClient _api;
  late final AuthService _auth;
  bool _checkingSession = true;
  bool _authenticated = false;
  bool _showRegister = false;

  @override
  void initState() {
    super.initState();
    _sessionStore = SessionStore();
    _api = ApiClient(
      baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000/api'),
      sessionStore: _sessionStore,
    );
    _auth = AuthService(_api, _sessionStore);
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = await _sessionStore.accessToken;
    if (!mounted) return;
    setState(() {
      _authenticated = token != null && token.isNotEmpty;
      _checkingSession = false;
    });
  }

  void _authenticatedNow() {
    setState(() {
      _authenticated = true;
      _showRegister = false;
    });
  }

  Future<void> _logout() async {
    await _auth.logout();
    await OfflineStore().clearAccountScopedData();
    if (!mounted) return;
    setState(() => _authenticated = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pet Health Record',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2D6A4F),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        cardTheme: const CardThemeData(margin: EdgeInsets.zero),
      ),
      home: _checkingSession
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _authenticated
              ? HomeScreen(api: _api, onLogout: _logout)
              : _showRegister
                  ? RegisterScreen(
                      authService: _auth,
                      onAuthenticated: _authenticatedNow,
                      onBack: () => setState(() => _showRegister = false),
                    )
                  : LoginScreen(
                      authService: _auth,
                      onAuthenticated: _authenticatedNow,
                      onRegister: () => setState(() => _showRegister = true),
                    ),
    );
  }
}
