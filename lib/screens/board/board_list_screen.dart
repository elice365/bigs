import 'package:bigs/models/board_models.dart';
import 'package:bigs/providers/auth_provider.dart';
import 'package:bigs/providers/board_provider.dart';
import 'package:bigs/screens/board/board_detail_screen.dart';
import 'package:bigs/screens/board/board_form_screen.dart';
import 'package:bigs/widgets/board_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class BoardListScreen extends StatefulWidget {
  const BoardListScreen({super.key});

  @override
  State<BoardListScreen> createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen> {
  final ScrollController _boardScrollController = ScrollController();

  /// 스크린 초기화 시 첫 페이지와 카테고리를 요청한다.
  @override
  void initState() {
    super.initState();
    _boardScrollController.addListener(_handleInfiniteScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final boardProvider = context.read<BoardProvider>();
      boardProvider.initializeIfNeeded();
    });
  }

  @override
  void dispose() {
    _boardScrollController
      ..removeListener(_handleInfiniteScroll)
      ..dispose();
    super.dispose();
  }

  /// 무한 스크롤 영역에서 하단에 도달하면 다음 페이지를 불러온다.
  void _handleInfiniteScroll() {
    if (!_boardScrollController.hasClients) return;
    final maxScroll = _boardScrollController.position.maxScrollExtent;
    final current = _boardScrollController.offset;
    if (current > maxScroll - 200) {
      context.read<BoardProvider>().fetchNextBoards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, BoardProvider>(
      builder: (context, auth, boardProvider, _) {
        final session = auth.session;
        return Scaffold(
          appBar: AppBar(
            title: const Text('BIGS 게시판'),
            actions: [
              if (session != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        session.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        session.username,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
                ),
              IconButton(
                tooltip: '로그아웃',
                onPressed: () async {
                  await auth.signOut();
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openCreateBoardForm(context, boardProvider),
            icon: const Icon(Icons.create),
            label: const Text('새 글 작성'),
          ),
          body: _buildBody(boardProvider),
        );
      },
    );
  }

  /// 현재 상태를 기반으로 본문 UI를 구축한다.
  Widget _buildBody(BoardProvider boardProvider) {
    final boards = boardProvider.boards;
    final isLoading = boardProvider.isLoading && boards.isEmpty;

    if (!boardProvider.isInitialized && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (boards.isEmpty && boardProvider.errorMessage != null) {
      return Center(
        child: Text(boardProvider.errorMessage!),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final listView = RefreshIndicator(
          onRefresh: boardProvider.reloadBoards,
          child: ListView.builder(
            controller: _boardScrollController,
            itemCount: boards.length + (boardProvider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= boards.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final board = boards[index];
              return BoardCard(
                board: board,
                categoryLabel:
                    boardProvider.resolveCategoryLabel(board.category),
                isSelected: isWide &&
                    boardProvider.selectedBoard?.id == board.id,
                onTap: () =>
                    _handleBoardSelection(context, boardProvider, board),
              );
            },
          ),
        );

        if (!isWide) {
          return listView;
        }

        return Row(
          children: [
            Expanded(flex: 2, child: listView),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 3,
              child: boardProvider.selectedBoard != null
                  ? BoardDetailPanel(
                      detail: boardProvider.selectedBoard!,
                      categoryLabel: boardProvider
                          .resolveCategoryLabel(
                              boardProvider.selectedBoard!.category),
                      onEdit: () => _openEditBoardForm(
                        context,
                        boardProvider,
                        boardProvider.selectedBoard!,
                      ),
                      onDelete: () => _confirmBoardDeletion(
                        context,
                        boardProvider,
                        boardProvider.selectedBoard!.id,
                      ),
                    )
                  : Center(
                      child: Text(
                        boards.isEmpty
                            ? '등록된 게시글이 없습니다.'
                            : '게시글을 선택해주세요.',
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  /// 모바일과 데스크톱을 구분해 게시글 상세 화면을 연다.
  Future<void> _handleBoardSelection(
    BuildContext context,
    BoardProvider provider,
    BoardSummary board,
  ) async {
    final isWide = MediaQuery.of(context).size.width >= 900;
    if (isWide) {
      await provider.loadBoardDetail(board.id);
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BoardDetailScreen(boardId: board.id),
        ),
      );
    }
  }

  /// 게시글 작성 폼을 띄우고 완료 시 목록을 새로 고친다.
  Future<void> _openCreateBoardForm(
    BuildContext context,
    BoardProvider provider,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BoardFormScreen(
          onSubmit: (input, file) => provider.createBoard(
            input: input,
            file: file,
          ),
          categories: provider.categories,
        ),
      ),
    );
    if (result == true) {
      await provider.reloadBoards();
    }
  }

  /// 게시글 수정 폼을 띄운다.
  Future<void> _openEditBoardForm(
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
      await provider.reloadBoards();
      await provider.loadBoardDetail(detail.id);
    }
  }

  /// 삭제 여부를 묻는 다이얼로그를 표시하고 결과에 따라 처리한다.
  Future<void> _confirmBoardDeletion(
    BuildContext context,
    BoardProvider provider,
    int boardId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final success = await provider.deleteBoard(boardId);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('게시글이 삭제되었습니다.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? '삭제에 실패했습니다.'),
        ),
      );
    }
  }
}

class BoardDetailPanel extends StatelessWidget {
  const BoardDetailPanel({
    super.key,
    required this.detail,
    required this.categoryLabel,
    this.onEdit,
    this.onDelete,
  });

  final BoardDetail detail;
  final String categoryLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  static final _dateFormat = DateFormat('yyyy.MM.dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              Chip(
                label: Text(categoryLabel),
                side: BorderSide.none,
              ),
              Text(
                _dateFormat.format(detail.createdAt.toLocal()),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            detail.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            detail.content,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          if (detail.imageUrl != null && detail.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                _resolveImageUrl(detail.imageUrl!),
                fit: BoxFit.cover,
              ),
            ),
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('수정'),
                  ),
                if (onDelete != null) ...[
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('삭제'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 상대 경로인 경우 절대 URL로 변환한다.
  String _resolveImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) return imageUrl;
    return 'https://front-mission.bigs.or.kr$imageUrl';
  }
}
