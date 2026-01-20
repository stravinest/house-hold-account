import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
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

  /// 고정비 카테고리 추가 다이얼로그 표시
  void _showAddFixedExpenseCategoryDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.fixedExpenseCategoryAdd),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.fixedExpenseCategoryName,
            hintText: l10n.fixedExpenseCategoryNameHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) =>
              _submitFixedExpenseCategory(dialogContext, nameController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                _submitFixedExpenseCategory(dialogContext, nameController),
            child: Text(l10n.commonAdd),
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
    final l10n = AppLocalizations.of(context)!;

    if (nameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, l10n.fixedExpenseCategoryNameRequired);
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

      SnackBarUtils.showSuccess(context, l10n.fixedExpenseCategoryAdded);

      ref.invalidate(fixedExpenseCategoriesProvider);
    } catch (e) {
      SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
    }
  }

  /// 고정비 카테고리 수정 다이얼로그
  void _showEditFixedExpenseCategoryDialog(FixedExpenseCategory category) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.fixedExpenseCategoryEdit),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.fixedExpenseCategoryName,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitEditFixedExpenseCategory(
            dialogContext,
            category,
            nameController,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => _submitEditFixedExpenseCategory(
              dialogContext,
              category,
              nameController,
            ),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  /// 고정비 카테고리 수정 제출
  Future<void> _submitEditFixedExpenseCategory(
    BuildContext dialogContext,
    FixedExpenseCategory category,
    TextEditingController nameController,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final newName = nameController.text.trim();

    if (newName.isEmpty) {
      SnackBarUtils.showError(context, l10n.fixedExpenseCategoryNameRequired);
      return;
    }

    if (newName == category.name) {
      Navigator.pop(dialogContext);
      return;
    }

    try {
      await ref
          .read(fixedExpenseCategoryNotifierProvider.notifier)
          .updateCategory(id: category.id, name: newName);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      SnackBarUtils.showSuccess(context, l10n.commonSuccess);

      ref.invalidate(fixedExpenseCategoriesProvider);
    } catch (e) {
      SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
    }
  }

  /// 고정비 카테고리 삭제
  Future<void> _deleteFixedExpenseCategory(
    FixedExpenseCategory category,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.fixedExpenseCategoryDelete),
        content: Text(l10n.fixedExpenseCategoryDeleteConfirm(category.name)),
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
          .read(fixedExpenseCategoryNotifierProvider.notifier)
          .deleteCategory(category.id);

      // 삭제된 카테고리가 선택되어 있었으면 선택 해제
      if (widget.selectedCategory?.id == category.id) {
        widget.onCategorySelected(null);
      }

      SnackBarUtils.showSuccess(context, l10n.fixedExpenseCategoryDeleted);

      ref.invalidate(fixedExpenseCategoriesProvider);
    } catch (e) {
      SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(fixedExpenseCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) => _buildFixedExpenseCategoryGrid(categories, l10n),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(l10n.errorWithMessage(e.toString())),
    );
  }

  Widget _buildFixedExpenseCategoryGrid(
    List<FixedExpenseCategory> categories,
    AppLocalizations l10n,
  ) {
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
          label: Text(l10n.fixedExpenseCategoryNone),
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
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: Text(l10n.commonAdd),
          onPressed: widget.enabled ? _showAddFixedExpenseCategoryDialog : null,
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
  Widget _buildEditModeChip(
    FixedExpenseCategory category,
    ColorScheme colorScheme,
  ) {
    return Container(
      height: 38, // ActionChip과 동일한 높이
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 카테고리 이름
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              category.name,
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          // 수정 버튼
          InkWell(
            onTap: () => _showEditFixedExpenseCategoryDialog(category),
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
            onTap: () => _deleteFixedExpenseCategory(category),
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
