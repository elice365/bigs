import 'package:bigs/models/board_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BoardCard extends StatelessWidget {
  BoardCard({
    super.key,
    required this.board,
    required this.categoryLabel,
    this.onTap,
    this.isSelected = false,
  });

  final BoardSummary board;
  final String categoryLabel;
  final VoidCallback? onTap;
  final bool isSelected;

  final DateFormat _dateFormat = DateFormat('yyyy.MM.dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(categoryLabel),
                    side: BorderSide.none,
                    backgroundColor: theme.colorScheme.primaryContainer
                        .withAlpha((255 * 0.3).round()),
                  ),
                  const Spacer(),
                  Text(
                    _dateFormat.format(board.createdAt.toLocal()),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                board.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
