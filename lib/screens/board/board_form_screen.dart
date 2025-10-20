import 'package:bigs/api/board_repository.dart';
import 'package:bigs/models/board_models.dart';
import 'package:bigs/utils/image_compressor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

typedef BoardSubmitCallback = Future<dynamic> Function(
  BoardInput input,
  UploadFile? file,
);

class BoardFormScreen extends StatefulWidget {
  const BoardFormScreen({
    super.key,
    required this.onSubmit,
    required this.categories,
    this.initialInput,
    this.existingImageUrl,
  });

  final BoardSubmitCallback onSubmit;
  final Map<String, String> categories;
  final BoardInput? initialInput;
  final String? existingImageUrl;

  @override
  State<BoardFormScreen> createState() => _BoardFormScreenState();
}

class _BoardFormScreenState extends State<BoardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  String? _selectedCategory;
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.initialInput?.title ?? '');
    _contentController =
        TextEditingController(text: widget.initialInput?.content ?? '');
    _selectedCategory = widget.initialInput?.category;
    if (_selectedCategory == null && widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.keys.first;
    }
  }

  @override
  void didUpdateWidget(BoardFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedCategory != null &&
        widget.categories.containsKey(_selectedCategory)) {
      return;
    }
    if (widget.categories.isNotEmpty) {
      setState(() {
        _selectedCategory = widget.categories.keys.first;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = widget.categories;
    final isEditMode = widget.initialInput != null;
    final currentCategory =
        categories.containsKey(_selectedCategory) ? _selectedCategory : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '게시글 수정' : '새 게시글 작성'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '제목을 입력해주세요.';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: currentCategory,
                  decoration: const InputDecoration(
                    labelText: '카테고리',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting ? null : (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '카테고리를 선택해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  minLines: 6,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: '내용',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '내용을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  '대표 이미지 (선택)',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_selectedFile == null ? '이미지 선택' : '다시 선택'),
                    ),
                    const SizedBox(width: 12),
                    if (_selectedFile != null)
                      Expanded(
                        child: Text(
                          _selectedFile!.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else if (widget.existingImageUrl != null &&
                        widget.existingImageUrl!.isNotEmpty)
                      Expanded(
                        child: Text(
                          '현재 이미지 유지',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    if (_selectedFile != null)
                      IconButton(
                        tooltip: '선택 취소',
                        onPressed: _isSubmitting ? null : _removeFile,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
                if (_selectedFile == null &&
                    widget.existingImageUrl != null &&
                    widget.existingImageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _absoluteImageUrl(widget.existingImageUrl!),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    child: Text(isEditMode ? '수정하기' : '등록하기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    setState(() {
      _selectedFile = result.files.first;
    });
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedCategory == null) {
      setState(() {
        _errorMessage = '카테고리를 선택해주세요.';
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      UploadFile? uploadFile;
      final selectedFile = _selectedFile;
      if (selectedFile != null) {
        final bytes = selectedFile.bytes;
        if (bytes == null) {
          setState(() {
            _errorMessage = '파일을 로드하지 못했습니다. 다시 시도해주세요.';
          });
          return;
        }

        final compressed = await ImageCompressor.compressIfNeeded(
          bytes,
          originalName: selectedFile.name,
          extension: selectedFile.extension,
        );

        final uploadBytes = compressed?.bytes ?? bytes;
        final uploadName = compressed?.suggestedName ?? selectedFile.name;

        uploadFile = UploadFile(
          name: uploadName,
          bytes: uploadBytes,
        );
      }
      final input = BoardInput(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory!,
      );
      final result = await widget.onSubmit(input, uploadFile);
      if (!mounted) return;
      if (result == null || result == false) {
        setState(() {
          _errorMessage = '요청 처리에 실패했습니다.';
        });
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '요청 처리 중 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _absoluteImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) return imageUrl;
    return 'https://front-mission.bigs.or.kr$imageUrl';
  }
}
