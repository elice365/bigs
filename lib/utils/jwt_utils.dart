import 'dart:convert';

Map<String, dynamic>? decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    return null;
  }

  try {
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final result = jsonDecode(decoded);
    if (result is Map<String, dynamic>) {
      return result;
    }
    return null;
  } catch (_) {
    return null;
  }
}
