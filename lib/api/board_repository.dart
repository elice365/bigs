import 'dart:convert';

import 'package:bigs/api/bigs_api_client.dart';
import 'package:bigs/models/board_models.dart';
import 'package:bigs/models/paged_result.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Holds an in-memory file attachment for multipart upload.
class UploadFile {
  UploadFile({
    required this.name,
    required this.bytes,
  });

  final String name;
  final List<int> bytes;
}

/// Wraps API calls for board CRUD operations.
class BoardRepository {
  BoardRepository(this._client);

  final BigsApiClient _client;
  static const _originHeaderValue = 'https://front-mission.bigs.or.kr';

  Future<PagedResult<BoardSummary>> fetchBoards({
    required int page,
    required int size,
    required String token,
  }) async {
    final json = await _client.getJson(
      '/boards',
      queryParameters: {'page': page, 'size': size},
      token: token,
    );
    return PagedResult.fromJson(json, BoardSummary.fromJson);
  }

  Future<BoardDetail> fetchBoardDetail({
    required int id,
    required String token,
  }) async {
    final json = await _client.getJson(
      '/boards/$id',
      token: token,
    );
    return BoardDetail.fromJson(json);
  }

  Future<Map<String, String>> fetchCategories({
    required String token,
  }) async {
    final json = await _client.getJson(
      '/boards/categories',
      token: token,
    );
    return json.map(
      (key, value) => MapEntry(
        key,
        value as String? ?? key,
      ),
    );
  }

  Future<int> createBoard({
    required BoardInput input,
    required String token,
    UploadFile? file,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://front-mission.bigs.or.kr/boards'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Origin'] = _originHeaderValue;
    request.files.add(
      http.MultipartFile.fromString(
        'request',
        jsonEncode(input.toJson()),
        contentType: MediaType('application', 'json'),
      ),
    );

    if (file != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes,
          filename: file.name,
        ),
      );
    }

    final json = await _client.sendMultipart(request);
    return json['id'] as int? ?? 0;
  }

  Future<void> updateBoard({
    required int id,
    required BoardInput input,
    required String token,
    UploadFile? file,
  }) async {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('https://front-mission.bigs.or.kr/boards/$id'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Origin'] = _originHeaderValue;
    request.files.add(
      http.MultipartFile.fromString(
        'request',
        jsonEncode(input.toJson()),
        contentType: MediaType('application', 'json'),
      ),
    );

    if (file != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes,
          filename: file.name,
        ),
      );
    }

    await _client.sendMultipart(request);
  }

  Future<void> deleteBoard({
    required int id,
    required String token,
  }) {
    return _client.delete('/boards/$id', token: token);
  }
}
