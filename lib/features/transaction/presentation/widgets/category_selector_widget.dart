import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/category_icon.dart';
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
  bool _isEditMode = false;

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
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    var isLoading = false;

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
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) {
          Future<void> submit() async {
            if (isLoading) return;
            setDialogState(() => isLoading = true);
            try {
              await _submitCategory(dialogContext, nameController);
            } finally {
              if (dialogContext.mounted) {
                setDialogState(() => isLoading = false);
              }
            }
          }

          return AlertDialog(
            title: Text(l10n.categoryAddType(typeLabel)),
            content: TextField(
              controller: nameController,
              autofocus: true,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: l10n.categoryName,
                hintText: l10n.categoryNameHintExample,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: isLoading ? null : (_) => submit(),
            ),
            actions: [
              TextButton(
                onPressed:
                    isLoading ? null : () => Navigator.pop(dialogContext),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: isLoading ? null : () => submit(),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.commonAdd),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 카테고리 생성 제출
  Future<void> _submitCategory(
    BuildContext dialogContext,
    TextEditingController nameController,
  ) async {
    final l10n = AppLocalizations.of(context);
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

  /// 카테고리 수정 다이얼로그
  void _showEditCategoryDialog(Category category) {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: category.name);
    var isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) {
          Future<void> submit() async {
            if (isLoading) return;
            setDialogState(() => isLoading = true);
            try {
              await _submitEditCategory(
                  dialogContext, category, nameController);
            } finally {
              if (dialogContext.mounted) {
                setDialogState(() => isLoading = false);
              }
            }
          }

          return AlertDialog(
            title: Text(l10n.categoryEdit),
            content: TextField(
              controller: nameController,
              autofocus: true,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: l10n.categoryName,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: isLoading ? null : (_) => submit(),
            ),
            actions: [
              TextButton(
                onPressed:
                    isLoading ? null : () => Navigator.pop(dialogContext),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: isLoading ? null : () => submit(),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.commonSave),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 카테고리 수정 제출
  Future<void> _submitEditCategory(
    BuildContext dialogContext,
    Category category,
    TextEditingController nameController,
  ) async {
    final l10n = AppLocalizations.of(context);
    final newName = nameController.text.trim();

    if (newName.isEmpty) {
      SnackBarUtils.showError(context, l10n.categoryNameRequired);
      return;
    }

    if (newName == category.name) {
      Navigator.pop(dialogContext);
      return;
    }

    try {
      await ref
          .read(categoryNotifierProvider.notifier)
          .updateCategory(id: category.id, name: newName);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      SnackBarUtils.showSuccess(context, l10n.commonSuccess);

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
    final l10n = AppLocalizations.of(context);
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
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
      error: (e, _) => Text('${AppLocalizations.of(context).commonError}: $e'),
    );
  }

  Widget _buildSkeletonChips() {
    return const Wrap(
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
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    // 편집 모드: 칩들과 완료 버튼을 별도 줄로 분리
    if (_isEditMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories
                .map((category) => _buildEditModeChip(category, colorScheme))
                .toList(),
          ),
          const SizedBox(height: 8),
          ActionChip(
            avatar: const Icon(Icons.check, size: 18),
            label: Text(l10n.commonDone),
            onPressed: widget.enabled
                ? () => setState(() => _isEditMode = false)
                : null,
          ),
        ],
      );
    }

    // 기본 모드
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
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
            avatar: CategoryIcon(
              icon: category.icon,
              name: category.name,
              color: category.color,
              size: CategoryIconSize.small,
            ),
            label: Text(category.name),
            onSelected: widget.enabled
                ? (_) => widget.onCategorySelected(category)
                : null,
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: Text(l10n.commonAdd),
          onPressed: widget.enabled ? _showAddCategoryDialog : null,
        ),
        ActionChip(
          avatar: const Icon(Icons.edit_outlined, size: 18),
          label: Text(l10n.commonEdit),
          onPressed: widget.enabled
              ? () => setState(() => _isEditMode = true)
              : null,
        ),
      ],
    );
  }

  /// 편집 모드용 카테고리 칩
  Widget _buildEditModeChip(Category category, ColorScheme colorScheme) {
    return Container(
      height: 38, // ActionChip과 동일한 높이
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 카테고리 아이콘 + 이름
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoryIcon(
                  icon: category.icon,
                  name: category.name,
                  color: category.color,
                  size: CategoryIconSize.small,
                ),
                const SizedBox(width: 4),
                Text(
                  category.name,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
          // 수정 버튼
          InkWell(
            onTap: () => _showEditCategoryDialog(category),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 38,
              alignment: Alignment.center,
              child: Icon(
                Icons.edit_outlined,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
          ),
          // 삭제 버튼
          InkWell(
            onTap: () => _deleteCategory(category),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 38,
              alignment: Alignment.center,
              child: Icon(Icons.close, size: 16, color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
