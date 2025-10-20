import 'package:bigs/models/board_models.dart';
import 'package:bigs/providers/board_provider.dart';
import 'package:bigs/screens/board/board_form_screen.dart';
import 'package:bigs/screens/board/board_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BoardDetailScreen extends StatefulWidget {
  const BoardDetailScreen({super.key, required this.boardId});

  final int boardId;

  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  BoardDetail? _boardDetail;
  bool _isLoading = true;
  String? _errorMessage;

  /// 최초 마운트가 끝난 뒤 상세 정보를 불러온다.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBoardDetail();
    });
  }

  /// 서버에서 게시글 상세 정보를 가져와 상태를 갱신한다.
  Future<void> _fetchBoardDetail() async {
    final provider = context.read<BoardProvider>();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    await provider.initializeIfNeeded();
    final detail = await provider.loadBoardDetail(widget.boardId);
    if (!mounted) return;
    setState(() {
      _boardDetail = detail;
      _isLoading = false;
      if (detail == null) {
        _errorMessage = '게시글을 불러오지 못했습니다.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BoardProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: _isLoading ? null : _fetchBoardDetail,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '수정',
            onPressed: _boardDetail == null
                ? null
                : () => _openEditForm(context, provider, _boardDetail!),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '삭제',
            onPressed: _boardDetail == null
                ? null
                : () => _showDeleteConfirmation(context, provider),
          ),
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(BoardProvider provider) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_boardDetail == null) {
      return const SizedBox.shrink();
    }
    final label = provider.resolveCategoryLabel(_boardDetail!.category);
    return SingleChildScrollView(
      child: BoardDetailPanel(
        detail: _boardDetail!,
        categoryLabel: label,
      ),
    );
  }

  /// 수정 폼을 띄워 변경 사항을 저장한다.
  Future<void> _openEditForm(
    BuildContext context,
    BoardProvider provider,
    BoardDetail detail,
  ) async {
    final initialInput = BoardInput(
      title: detail.title,
      content: detail.content,
      category: detail.category,
    );
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BoardFormScreen(
          initialInput: initialInput,
          existingImageUrl: detail.imageUrl,
          categories: provider.categories,
          onSubmit: (input, file) => provider.updateBoard(
            id: detail.id,
            input: input,
            file: file,
          ),
        ),
      ),
    );
    if (updated == true) {
      await _fetchBoardDetail();
    }
  }

  /// 삭제 여부를 확인하고 승인 시 게시글을 삭제한다.
  Future<void> _showDeleteConfirmation(
    BuildContext context,
    BoardProvider provider,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await provider.deleteBoard(widget.boardId);
    if (!mounted) return;
    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('게시글이 삭제되었습니다.')),
      );
      navigator.pop(true);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? '삭제에 실패했습니다.'),
        ),
      );
    }
  }
}
