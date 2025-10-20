import 'package:bigs/api/api_exception.dart';
import 'package:bigs/api/board_repository.dart';
import 'package:bigs/models/board_models.dart';
import 'package:flutter/foundation.dart';

import 'auth_provider.dart';

class BoardProvider extends ChangeNotifier {
  BoardProvider(this._repository);

  final BoardRepository _repository;

  AuthProvider? _auth;
  List<BoardSummary> _boards = const [];
  Map<String, String> _categories = const {};
  BoardDetail? _selectedBoard;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _errorMessage;
  bool _isInitialized = false;

  static const int pageSize = 10;

  List<BoardSummary> get boards => _boards;
  Map<String, String> get categories => _categories;
  BoardDetail? get selectedBoard => _selectedBoard;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;

  void updateAuth(AuthProvider auth) {
    if (!identical(_auth, auth)) {
      _auth = auth;
      if (!auth.isAuthenticated) {
        _resetBoardState();
      }
    }
  }

  /// 최초 한 번 카테고리와 게시글 목록을 가져온다.
  Future<void> initializeIfNeeded() async {
    if (_isInitialized || !_isAuthReady) {
      return;
    }
    try {
      await _auth?.refreshIfNeeded();
      await Future.wait([
        fetchCategories(),
        fetchInitialBoards(),
      ]);
      _isInitialized = true;
      notifyListeners();
    } catch (_) {
      // 개별 메서드들이 오류 처리를 담당함.
    }
  }

  /// 서버에서 카테고리 리스트를 받아온다.
  Future<void> fetchCategories() async {
    if (!_isAuthReady) return;
    try {
      final token = await _ensureValidToken();
      final categories = await _repository.fetchCategories(token: token);
      _categories = categories;
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      await _updateErrorState(error,
          fallbackMessage: '카테고리를 불러오는 중 오류가 발생했습니다.');
    }
  }

  /// 첫 페이지를 새로 로드한다.
  Future<void> fetchInitialBoards() async {
    if (!_isAuthReady) return;
    _boards = [];
    _currentPage = 0;
    _hasMore = true;
    notifyListeners();
    await _fetchBoardPage(reset: true);
  }

  /// 추가 페이지를 이어서 가져온다.
  Future<void> fetchNextBoards() {
    if (!_hasMore || _isLoading) {
      return Future.value();
    }
    _currentPage += 1;
    return _fetchBoardPage();
  }

  /// 전체 목록을 초기 상태에서 다시 받아온다.
  Future<void> reloadBoards() async {
    await fetchInitialBoards();
  }

  /// 단일 게시글 상세 정보를 로드한다.
  Future<BoardDetail?> loadBoardDetail(int id) async {
    if (!_isAuthReady) return null;
    try {
      final token = await _ensureValidToken();
      final detail =
          await _repository.fetchBoardDetail(id: id, token: token);
      _selectedBoard = detail;
      _errorMessage = null;
      notifyListeners();
      return detail;
    } catch (error) {
      await _updateErrorState(error,
          fallbackMessage: '게시글을 불러오지 못했습니다.');
      return null;
    }
  }

  /// 새 게시글을 생성한다.
  Future<int?> createBoard({
    required BoardInput input,
    UploadFile? file,
  }) async {
    if (!_isAuthReady) return null;
    _setLoading(true);
    try {
      final token = await _ensureValidToken();
      final id = await _repository.createBoard(
        input: input,
        token: token,
        file: file,
      );
      await fetchInitialBoards();
      return id;
    } catch (error) {
      await _updateErrorState(error,
          fallbackMessage: '게시글 등록에 실패했습니다.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 기존 게시글을 수정한다.
  Future<bool> updateBoard({
    required int id,
    required BoardInput input,
    UploadFile? file,
  }) async {
    if (!_isAuthReady) return false;
    _setLoading(true);
    try {
      final token = await _ensureValidToken();
      await _repository.updateBoard(
        id: id,
        input: input,
        token: token,
        file: file,
      );
      await fetchInitialBoards();
      return true;
    } catch (error) {
      await _updateErrorState(error,
          fallbackMessage: '게시글 수정에 실패했습니다.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 게시글을 삭제한다.
  Future<bool> deleteBoard(int id) async {
    if (!_isAuthReady) return false;
    _setLoading(true);
    try {
      final token = await _ensureValidToken();
      await _repository.deleteBoard(id: id, token: token);
      _boards = _boards.where((board) => board.id != id).toList();
      if (_selectedBoard?.id == id) {
        _selectedBoard = null;
      }
      notifyListeners();
      return true;
    } catch (error) {
      await _updateErrorState(error,
          fallbackMessage: '게시글 삭제에 실패했습니다.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 카테고리 코드에 대응하는 한글 라벨을 반환한다.
  String resolveCategoryLabel(String code) {
    return _categories[code] ?? code;
  }

  /// API에서 게시글 목록을 조회한다.
  Future<void> _fetchBoardPage({bool reset = false}) async {
    if (!_isAuthReady) {
      return;
    }
    _setLoading(true);
    try {
      final token = await _ensureValidToken();
      final page = reset ? 0 : _currentPage;
      final result = await _repository.fetchBoards(
        page: page,
        size: pageSize,
        token: token,
      );

      if (reset) {
        _boards = result.items;
      } else {
        _boards = [..._boards, ...result.items];
      }
      _currentPage = result.pageNumber;

      _hasMore = !result.isLast;
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      await _updateErrorState(error,
          fallbackMessage: '게시글 목록을 불러오는 중 오류가 발생했습니다.');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  bool get _isAuthReady => _auth != null && _auth!.isAuthenticated;

  /// API 토큰을 점검하고 필요하면 갱신한다.
  Future<String> _ensureValidToken() async {
    final auth = _auth;
    if (auth == null) {
      throw StateError('로그인이 필요합니다.');
    }
    final refreshed = await auth.refreshIfNeeded();
    final token = auth.session?.accessToken;
    final hasExpired = auth.session?.hasExpired ?? true;
    if (token == null || token.isEmpty || (!refreshed && hasExpired)) {
      await auth.signOut();
      throw StateError('세션이 만료되었습니다. 다시 로그인해주세요.');
    }
    return token;
  }

  /// 오류를 사용자에게 노출 가능한 메시지로 변환한다.
  Future<void> _updateErrorState(
    Object error, {
    required String fallbackMessage,
  }) async {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        _errorMessage = '세션이 만료되었습니다. 다시 로그인해주세요.';
        await _auth?.signOut();
        return;
      }
      _errorMessage = error.message;
    } else if (error is StateError) {
      _errorMessage = error.message;
    } else {
      _errorMessage = fallbackMessage;
    }
    notifyListeners();
  }

  /// 로그아웃 시 내부 상태를 초기화한다.
  void _resetBoardState() {
    _boards = const [];
    _categories = const {};
    _selectedBoard = null;
    _currentPage = 0;
    _hasMore = true;
    _errorMessage = null;
    _isInitialized = false;
    notifyListeners();
  }
}
