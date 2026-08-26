import '../core/api_client.dart';

class PetAccessGrant {
  const PetAccessGrant({required this.token, required this.id, required this.level, required this.expiresAt, required this.maxUses});
  final String token;
  final String id;
  final String level;
  final DateTime expiresAt;
  final int maxUses;

  factory PetAccessGrant.fromJson(Map<String, dynamic> json) {
    final grant = json['grant'] as Map<String, dynamic>;
    return PetAccessGrant(
      token: json['token'] as String,
      id: grant['id'] as String,
      level: grant['level'] as String,
      expiresAt: DateTime.parse(grant['expiresAt'] as String),
      maxUses: grant['maxUses'] as int,
    );
  }
}

class ShareService {
  ShareService(this.api);
  final ApiClient api;

  Future<PetAccessGrant> create(String petId, {String level = 'READ', int expiresInMinutes = 15, int maxUses = 1}) async {
    final json = await api.post('/access-grants/pets/$petId', {
      'level': level,
      'expiresInMinutes': expiresInMinutes,
      'maxUses': maxUses,
    }, authenticated: true);
    return PetAccessGrant.fromJson(json);
  }

  Future<void> revoke(String grantId) async {
    await api.delete('/access-grants/$grantId');
  }
}
