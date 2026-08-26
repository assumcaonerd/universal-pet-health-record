import '../core/api_client.dart';
import '../core/session_store.dart';

class AuthService {
  AuthService(this.api, this.sessionStore);

  final ApiClient api;
  final SessionStore sessionStore;

  Future<void> login({
    required String email,
    required String password,
    String? mfaCode,
    String? recoveryCode,
  }) async {
    final result = await api.post('/auth/login', {
      'email': email,
      'password': password,
      if (mfaCode != null && mfaCode.isNotEmpty) 'mfaCode': mfaCode,
      if (recoveryCode != null && recoveryCode.isNotEmpty) 'recoveryCode': recoveryCode,
    });
    await sessionStore.save(
      accessToken: result['accessToken'] as String,
      refreshToken: result['refreshToken'] as String,
      sessionId: result['sessionId'] as String?,
    );
  }

  Future<void> register({required String name, required String email, required String password}) async {
    final result = await api.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    await sessionStore.save(
      accessToken: result['accessToken'] as String,
      refreshToken: result['refreshToken'] as String,
      sessionId: result['sessionId'] as String?,
    );
  }

  Future<void> logout() async {
    final refresh = await sessionStore.refreshToken;
    if (refresh != null) {
      try {
        await api.post('/auth/logout', {'refreshToken': refresh});
      } catch (_) {}
    }
    await sessionStore.clear();
  }
}
