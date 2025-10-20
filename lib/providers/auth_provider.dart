import 'package:bigs/api/auth_repository.dart';
import 'package:bigs/api/api_exception.dart';
import 'package:bigs/models/auth_session.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository, this._storage);

  final AuthRepository _repository;
  final SharedPreferences _storage;
  Future<bool>? _ongoingRefresh;

  AuthSession? _session;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  AuthSession? get session => _session;
  bool get isAuthenticated => _session != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  /// 복원된 세션이 있으면 메모리에 로드한다.
  Future<void> loadSession() async {
    if (_isInitialized) return;
    final stored = {
      'username': _storage.getString(_SessionStorageKeys.username),
      'name': _storage.getString(_SessionStorageKeys.name),
      'accessToken': _storage.getString(_SessionStorageKeys.accessToken),
      'refreshToken': _storage.getString(_SessionStorageKeys.refreshToken),
      'issuedAt': _storage.getString(_SessionStorageKeys.issuedAt),
      'expiresAt': _storage.getString(_SessionStorageKeys.expiresAt),
    };
    final session = AuthSession.fromStorage(stored);
    if (session != null) {
      _session = session;
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// 자격 증명으로 로그인하고 세션을 저장한다.
  Future<bool> signIn({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final response =
          await _repository.signIn(username: username, password: password);
      final accessToken = response['accessToken'] as String?;
      final refreshToken = response['refreshToken'] as String?;
      if (accessToken == null || refreshToken == null) {
        _errorMessage = '로그인 응답이 올바르지 않습니다.';
        _setLoading(false);
        return false;
      }

      final session = AuthSession.fromTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      if (session == null) {
        _errorMessage = '토큰 정보를 확인할 수 없습니다.';
        _setLoading(false);
        return false;
      }

      _session = session;
      await _persistSession(session);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = '로그인에 실패했습니다. 다시 시도해주세요.';
    }
    _setLoading(false);
    return false;
  }

  /// 새 사용자를 등록한다.
  Future<bool> signUp({
    required String username,
    required String name,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    try {
      await _repository.signUp(
        username: username,
        name: name,
        password: password,
        confirmPassword: confirmPassword,
      );
      _errorMessage = null;
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = '회원가입에 실패했습니다. 다시 시도해주세요.';
    } finally {
      _setLoading(false);
    }
    return false;
  }

  /// 토큰 만료가 임박했으면 리프레시 토큰으로 갱신한다.
  Future<bool> refreshIfNeeded({Duration buffer = const Duration(seconds: 30)}) async {
    final session = _session;
    if (session == null) return false;
    if (!session.willExpireWithin(buffer)) {
      return true;
    }

    if (_ongoingRefresh != null) {
      return await _ongoingRefresh!;
    }

    final refreshFuture = _performRefresh(session);
    _ongoingRefresh = refreshFuture;
    try {
      return await refreshFuture;
    } finally {
      if (identical(_ongoingRefresh, refreshFuture)) {
        _ongoingRefresh = null;
      }
    }
  }

  /// 세션을 제거하고 저장소를 비운다.
  Future<void> signOut() async {
    _session = null;
    await _storage.remove(_SessionStorageKeys.username);
    await _storage.remove(_SessionStorageKeys.name);
    await _storage.remove(_SessionStorageKeys.accessToken);
    await _storage.remove(_SessionStorageKeys.refreshToken);
    await _storage.remove(_SessionStorageKeys.issuedAt);
    await _storage.remove(_SessionStorageKeys.expiresAt);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  /// 디스크에 세션 정보를 기록한다.
  Future<void> _persistSession(AuthSession session) async {
    await _storage.setString(_SessionStorageKeys.username, session.username);
    await _storage.setString(_SessionStorageKeys.name, session.name);
    await _storage.setString(
        _SessionStorageKeys.accessToken, session.accessToken);
    await _storage.setString(
        _SessionStorageKeys.refreshToken, session.refreshToken);
    if (session.issuedAt != null) {
      await _storage.setString(
        _SessionStorageKeys.issuedAt,
        session.issuedAt!.toIso8601String(),
      );
    }
    if (session.expiresAt != null) {
      await _storage.setString(
        _SessionStorageKeys.expiresAt,
        session.expiresAt!.toIso8601String(),
      );
    }
  }

  Future<bool> _performRefresh(AuthSession session) async {
    try {
      final response = await _repository.refresh(session.refreshToken);
      final accessToken = response['accessToken'] as String?;
      final refreshToken = response['refreshToken'] as String?;
      if (accessToken == null || refreshToken == null) {
        return false;
      }

      final refreshed = AuthSession.fromTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      if (refreshed == null) {
        return false;
      }

      if (!identical(_session, session)) {
        return true;
      }

      _session = refreshed;
      await _persistSession(refreshed);
      notifyListeners();
      return true;
    } on ApiException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

abstract class _SessionStorageKeys {
  static const username = 'username';
  static const name = 'name';
  static const accessToken = 'accessToken';
  static const refreshToken = 'refreshToken';
  static const issuedAt = 'issuedAt';
  static const expiresAt = 'expiresAt';
}
