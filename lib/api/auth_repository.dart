import 'package:bigs/api/bigs_api_client.dart';

class AuthRepository {
  AuthRepository(this._client);

  final BigsApiClient _client;

  Future<void> signUp({
    required String username,
    required String name,
    required String password,
    required String confirmPassword,
  }) async {
    await _client.postJson('/auth/signup', {
      'username': username,
      'name': name,
      'password': password,
      'confirmPassword': confirmPassword,
    });
  }

  Future<Map<String, dynamic>> signIn({
    required String username,
    required String password,
  }) {
    return _client.postJson('/auth/signin', {
      'username': username,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) {
    return _client.postJson('/auth/refresh', {
      'refreshToken': refreshToken,
    });
  }
}
