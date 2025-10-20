import 'package:bigs/utils/jwt_utils.dart';

class AuthSession {
  AuthSession({
    required this.username,
    required this.name,
    required this.accessToken,
    required this.refreshToken,
    this.issuedAt,
    this.expiresAt,
  });

  final String username;
  final String name;
  final String accessToken;
  final String refreshToken;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  bool get hasExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now().toUtc());

  bool willExpireWithin(Duration duration) {
    if (expiresAt == null) return false;
    final now = DateTime.now().toUtc();
    return !expiresAt!.isAfter(now.add(duration));
  }

  Map<String, String> toStorage() => {
        'username': username,
        'name': name,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        if (issuedAt != null) 'issuedAt': issuedAt!.toIso8601String(),
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      };

  static AuthSession? fromTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    final payload = decodeJwtPayload(accessToken);
    if (payload == null) {
      return null;
    }

    final username = payload['username'] as String? ?? '';
    final name = payload['name'] as String? ?? '';
    final issuedAtSeconds = payload['iat'];
    final expiresAtSeconds = payload['exp'];

    DateTime? issuedAt;
    if (issuedAtSeconds is num) {
      issuedAt =
          DateTime.fromMillisecondsSinceEpoch(issuedAtSeconds.toInt() * 1000,
              isUtc: true);
    }
    DateTime? expiresAt;
    if (expiresAtSeconds is num) {
      expiresAt =
          DateTime.fromMillisecondsSinceEpoch(expiresAtSeconds.toInt() * 1000,
              isUtc: true);
    }

    if (username.isEmpty || name.isEmpty) {
      return null;
    }

    return AuthSession(
      username: username,
      name: name,
      accessToken: accessToken,
      refreshToken: refreshToken,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );
  }

  static AuthSession? fromStorage(Map<String, Object?> values) {
    final accessToken = values['accessToken'] as String?;
    final refreshToken = values['refreshToken'] as String?;
    final name = values['name'] as String?;
    final username = values['username'] as String?;
    if (accessToken == null ||
        refreshToken == null ||
        name == null ||
        username == null) {
      return null;
    }

    DateTime? issuedAt;
    final issuedAtRaw = values['issuedAt'] as String?;
    if (issuedAtRaw != null) {
      issuedAt = DateTime.tryParse(issuedAtRaw);
    }

    DateTime? expiresAt;
    final expiresAtRaw = values['expiresAt'] as String?;
    if (expiresAtRaw != null) {
      expiresAt = DateTime.tryParse(expiresAtRaw);
    }

    return AuthSession(
      username: username,
      name: name,
      accessToken: accessToken,
      refreshToken: refreshToken,
      issuedAt: issuedAt?.toUtc(),
      expiresAt: expiresAt?.toUtc(),
    );
  }
}
