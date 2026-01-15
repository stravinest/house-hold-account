import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../fixed_expense/domain/entities/fixed_expense_category.dart';
import '../../../fixed_expense/presentation/providers/fixed_expense_category_provider.dart';

/// 고정비 카테고리 선택 위젯
///
/// 고정비 카테고리 목록을 Chip 형태로 표시하고 선택/추가/삭제 기능을 제공합니다.
class FixedExpenseCategorySelectorWidget extends ConsumerStatefulWidget {
  /// 현재 선택된 고정비 카테고리
  final FixedExpenseCategory? selectedCategory;

  /// 카테고리 선택 시 콜백
  final ValueChanged<FixedExpenseCategory?> onCategorySelected;

  /// 위젯 활성화 여부
  final bool enabled;

  const FixedExpenseCategorySelectorWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.enabled = true,
  });

  @override
  ConsumerState<FixedExpenseCategorySelectorWidget> createState() =>
      _FixedExpenseCategorySelectorWidgetState();
}

class _FixedExpenseCategorySelectorWidgetState
    extends ConsumerState<FixedExpenseCategorySelectorWidget> {
  // 랜덤 색상 생성
  String _generateRandomColor() {
    final colors = [
      '#4CAF50',
      '#2196F3',
      '#F44336',
      '#FF9800',
      '#9C27B0',
      '#00BCD4',
      '#E91E63',
      '#795548',
      '#607D8B',
      '#3F51B5',
      '#009688',
      '#CDDC39',
    ];
    return colors[(DateTime.now().millisecondsSinceEpoch % colors.length)];
  }

  /// 고정비 카테고리 추가 다이얼로그 표시
  void _showAddFixedExpenseCategoryDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('고정비 카테고리 추가'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '카테고리 이름',
            hintText: '예: 월세, 통신비',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) =>
              _submitFixedExpenseCategory(dialogContext, nameController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () =>
                _submitFixedExpenseCategory(dialogContext, nameController),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  /// 고정비 카테고리 생성 제출
  Future<void> _submitFixedExpenseCategory(
    BuildContext dialogContext,
    TextEditingController nameController,
  ) async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카테고리 이름을 입력해주세요'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      final newCategory = await ref
          .read(fixedExpenseCategoryNotifierProvider.notifier)
          .createCategory(
            name: nameController.text.trim(),
            icon: '',
            color: _generateRandomColor(),
          );

      widget.onCategorySelected(newCategory);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('고정비 카테고리가 추가되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      ref.invalidate(fixedExpenseCategoriesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  /// 고정비 카테고리 삭제
  Future<void> _deleteFixedExpenseCategory(
    FixedExpenseCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('고정비 카테고리 삭제'),
        content: Text('\'${category.name}\' 카테고리를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(fixedExpenseCategoryNotifierProvider.notifier)
          .deleteCategory(category.id);

      // 삭제된 카테고리가 선택되어 있었으면 선택 해제
      if (widget.selectedCategory?.id == category.id) {
        widget.onCategorySelected(null);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('고정비 카테고리가 삭제되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      ref.invalidate(fixedExpenseCategoriesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(fixedExpenseCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) => _buildFixedExpenseCategoryGrid(categories),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('오류: $e'),
    );
  }

  Widget _buildFixedExpenseCategoryGrid(List<FixedExpenseCategory> categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 선택 안함 옵션
        FilterChip(
          selected: widget.selectedCategory == null,
          showCheckmark: false,
          label: const Text('선택 안함'),
          onSelected: widget.enabled
              ? (_) => widget.onCategorySelected(null)
              : null,
        ),
        ...categories.map((category) {
          final isSelected = widget.selectedCategory?.id == category.id;
          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            label: Text(category.name),
            onSelected: widget.enabled
                ? (_) => widget.onCategorySelected(category)
                : null,
            onDeleted: widget.enabled
                ? () => _deleteFixedExpenseCategory(category)
                : null,
            deleteIcon: const Icon(Icons.close, size: 18),
          );
        }),
        // 고정비 카테고리 추가 버튼
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('추가'),
          onPressed: widget.enabled ? _showAddFixedExpenseCategoryDialog : null,
        ),
      ],
    );
  }
}
