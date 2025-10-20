import 'dart:convert';

import 'package:bigs/api/api_exception.dart';
import 'package:http/http.dart' as http;

class BigsApiClient {
  BigsApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _baseUrl = 'https://front-mission.bigs.or.kr';
  static const _originHeaderValue = 'https://front-mission.bigs.or.kr';

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final uri = Uri.parse('$_baseUrl$path');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(
      queryParameters:
          queryParameters.map((key, value) => MapEntry(key, '$value')),
    );
  }

  Map<String, String> _headers({String? token}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Origin': _originHeaderValue,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    String? token,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final response = await _client.get(uri, headers: _headers(token: token));
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final uri = _buildUri(path);
    final response = await _client.post(
      uri,
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final uri = _buildUri(path);
    final response = await _client.patch(
      uri,
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    String? token,
  }) async {
    final uri = _buildUri(path);
    final response =
        await _client.delete(uri, headers: _headers(token: token));
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> sendMultipart(
    http.MultipartRequest request,
  ) async {
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final status = response.statusCode;
    if (status < 200 || status >= 300) {
      String message = '요청에 실패했습니다. (HTTP $status)';
      if (response.body.isNotEmpty) {
        try {
          final json = jsonDecode(response.body);
          if (json is Map<String, dynamic>) {
            message = json['message'] as String? ?? message;
          }
        } catch (_) {
          message = response.body;
        }
      }
      throw ApiException(status, message);
    }

    if (response.body.isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {'data': decoded};
  }

  void close() => _client.close();
}
