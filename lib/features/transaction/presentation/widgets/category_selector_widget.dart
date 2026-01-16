import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_provider.dart';

/// 카테고리 선택 결과
class CategorySelectionResult {
  final Category? selectedCategory;
  final bool wasDeleted;

  const CategorySelectionResult({
    this.selectedCategory,
    this.wasDeleted = false,
  });
}

/// 일반 카테고리 선택 위젯
///
/// 카테고리 목록을 Chip 형태로 표시하고 선택/추가/삭제 기능을 제공합니다.
class CategorySelectorWidget extends ConsumerStatefulWidget {
  /// 현재 선택된 카테고리
  final Category? selectedCategory;

  /// 거래 타입 ('expense', 'income', 'asset')
  final String transactionType;

  /// 카테고리 선택 시 콜백
  final ValueChanged<Category?> onCategorySelected;

  /// 위젯 활성화 여부
  final bool enabled;

  const CategorySelectorWidget({
    super.key,
    required this.selectedCategory,
    required this.transactionType,
    required this.onCategorySelected,
    this.enabled = true,
  });

  @override
  ConsumerState<CategorySelectorWidget> createState() =>
      _CategorySelectorWidgetState();
}

class _CategorySelectorWidgetState
    extends ConsumerState<CategorySelectorWidget> {
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

  /// 카테고리 추가 다이얼로그 표시
  void _showAddCategoryDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    String typeLabel;
    switch (widget.transactionType) {
      case 'expense':
        typeLabel = l10n.transactionExpense;
        break;
      case 'income':
        typeLabel = l10n.transactionIncome;
        break;
      default:
        typeLabel = l10n.transactionAsset;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.categoryAddType(typeLabel)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.categoryName,
            hintText: l10n.categoryNameHintExample,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitCategory(dialogContext, nameController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => _submitCategory(dialogContext, nameController),
            child: Text(l10n.commonAdd),
          ),
        ],
      ),
    );
  }

  /// 카테고리 생성 제출
  Future<void> _submitCategory(
    BuildContext dialogContext,
    TextEditingController nameController,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (nameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, l10n.categoryNameRequired);
      return;
    }

    try {
      final newCategory = await ref
          .read(categoryNotifierProvider.notifier)
          .createCategory(
            name: nameController.text.trim(),
            icon: '',
            color: _generateRandomColor(),
            type: widget.transactionType,
          );

      widget.onCategorySelected(newCategory);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      SnackBarUtils.showSuccess(context, l10n.categoryAdded);

      ref.invalidate(categoriesProvider);
      ref.invalidate(incomeCategoriesProvider);
      ref.invalidate(expenseCategoriesProvider);
      ref.invalidate(savingCategoriesProvider);
    } catch (e) {
      SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
    }
  }

  /// 카테고리 삭제
  Future<void> _deleteCategory(Category category) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.categoryDeleteConfirmTitle),
        content: Text(l10n.categoryDeleteConfirm(category.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(categoryNotifierProvider.notifier)
          .deleteCategory(category.id);

      // 삭제된 카테고리가 선택되어 있었으면 선택 해제
      if (widget.selectedCategory?.id == category.id) {
        widget.onCategorySelected(null);
      }

      SnackBarUtils.showSuccess(context, l10n.categoryDeleted);

      ref.invalidate(categoriesProvider);
      ref.invalidate(incomeCategoriesProvider);
      ref.invalidate(expenseCategoriesProvider);
      ref.invalidate(savingCategoriesProvider);
    } catch (e) {
      SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = widget.transactionType == 'expense'
        ? ref.watch(expenseCategoriesProvider)
        : widget.transactionType == 'income'
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(savingCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) => _buildCategoryGrid(context, categories),
      loading: () => _buildSkeletonChips(),
      error: (e, _) => Text('${AppLocalizations.of(context)!.commonError}: $e'),
    );
  }

  Widget _buildSkeletonChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SkeletonBox(width: 80, height: 32, borderRadius: 16),
        SkeletonBox(width: 100, height: 32, borderRadius: 16),
        SkeletonBox(width: 90, height: 32, borderRadius: 16),
        SkeletonBox(width: 70, height: 32, borderRadius: 16),
        SkeletonBox(width: 85, height: 32, borderRadius: 16),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context, List<Category> categories) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 선택 안함 옵션
        FilterChip(
          selected: widget.selectedCategory == null,
          showCheckmark: false,
          label: Text(l10n.transactionNone),
          onSelected: widget.enabled
              ? (_) => widget.onCategorySelected(null)
              : null,
        ),
        ...categories.map((category) {
          final isSelected = widget.selectedCategory?.id == category.id;
          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (category.icon.isNotEmpty) ...[
                  Text(category.icon),
                  const SizedBox(width: 4),
                ],
                Text(category.name),
              ],
            ),
            onSelected: widget.enabled
                ? (_) => widget.onCategorySelected(category)
                : null,
            onDeleted: widget.enabled ? () => _deleteCategory(category) : null,
            deleteIcon: const Icon(Icons.close, size: 18),
          );
        }),
        // 카테고리 추가 버튼
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: Text(l10n.commonAdd),
          onPressed: widget.enabled ? _showAddCategoryDialog : null,
        ),
      ],
    );
  }
}
