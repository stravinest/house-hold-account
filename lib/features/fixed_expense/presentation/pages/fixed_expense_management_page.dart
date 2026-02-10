import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/dialog_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/icon_picker.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/fixed_expense_category.dart';
import '../providers/fixed_expense_category_provider.dart';
import '../providers/fixed_expense_settings_provider.dart';

/// 고정비 관리 페이지
class FixedExpenseManagementPage extends ConsumerStatefulWidget {
  const FixedExpenseManagementPage({super.key});

  @override
  ConsumerState<FixedExpenseManagementPage> createState() =>
      _FixedExpenseManagementPageState();
}

class _FixedExpenseManagementPageState
    extends ConsumerState<FixedExpenseManagementPage> {
  @override
  void initState() {
    super.initState();
    // autoDispose provider는 페이지 재진입 시 자동으로 새 인스턴스를 생성하여 데이터를 로드하고,
    // Realtime subscription이 변경사항을 감지하므로 수동 refresh가 불필요합니다.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fixedExpenseManagement)),
      body: CenteredContent(
        maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // 고정비 설정 카드
            const _SettingsCard(),
            const SizedBox(height: 24),
            // 고정비 카테고리 섹션
            SectionHeader(title: l10n.fixedExpenseCategoryTitle),
            const SizedBox(height: 8),
            const _CategoryListView(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        tooltip: l10n.fixedExpenseCategoryAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const _CategoryDialog());
  }
}

/// 고정비 설정 카드
class _SettingsCard extends ConsumerWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settingsAsync = ref.watch(fixedExpenseSettingsNotifierProvider);

    return Card(
      child: settingsAsync.when(
        data: (settings) {
          final includeInExpense = settings?.includeInExpense ?? false;
          return Column(
            children: [
              SwitchListTile(
                title: Text(l10n.fixedExpenseIncludeInExpense),
                subtitle: Text(
                  includeInExpense
                      ? l10n.fixedExpenseIncludeInExpenseOn
                      : l10n.fixedExpenseIncludeInExpenseOff,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: includeInExpense,
                onChanged: (value) async {
                  try {
                    await ref
                        .read(fixedExpenseSettingsNotifierProvider.notifier)
                        .updateIncludeInExpense(value);
                    if (context.mounted) {
                      SnackBarUtils.showSuccess(
                        context,
                        value
                            ? l10n.fixedExpenseIncludedSnackbar
                            : l10n.fixedExpenseExcludedSnackbar,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      SnackBarUtils.showError(
                        context,
                        l10n.fixedExpenseSettingsFailed(e.toString()),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
        loading: () => ListTile(
          title: Text(l10n.fixedExpenseIncludeInExpense),
          trailing: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, _) => ListTile(
          title: Text(l10n.fixedExpenseSettingsLoadFailed),
          subtitle: Text('$e'),
        ),
      ),
    );
  }
}

/// 고정비 카테고리 목록
class _CategoryListView extends ConsumerWidget {
  const _CategoryListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(fixedExpenseCategoryNotifierProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: EmptyState(
                icon: Icons.repeat_outlined,
                message: l10n.fixedExpenseCategoryEmpty,
                subtitle: l10n.fixedExpenseCategoryEmptySubtitle,
              ),
            ),
          );
        }

        return Column(
          children: categories.map((category) {
            return _CategoryTile(
              key: ValueKey(category.id),
              category: category,
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.errorWithMessage(e.toString())),
        ),
      ),
    );
  }
}

/// 고정비 카테고리 타일
class _CategoryTile extends ConsumerWidget {
  final FixedExpenseCategory category;

  const _CategoryTile({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CategoryIcon(
          icon: category.icon,
          name: category.name,
          color: category.color,
          size: CategoryIconSize.medium,
        ),
        title: Text(category.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l10n.commonEdit,
              onPressed: () => _showEditDialog(context, category),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: l10n.commonDelete,
              onPressed: () => _showDeleteConfirm(context, ref, category),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, FixedExpenseCategory category) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(category: category),
    );
  }

  Future<void> _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    FixedExpenseCategory category,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed =
        await DialogUtils.showFixedExpenseCategoryDeleteConfirmation(
          context,
          categoryName: category.name,
        );

    if (confirmed == true) {
      try {
        await ref
            .read(fixedExpenseCategoryNotifierProvider.notifier)
            .deleteCategory(category.id);
        if (context.mounted) {
          SnackBarUtils.showSuccess(context, l10n.categoryDeleted);
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarUtils.showError(
            context,
            l10n.categoryDeleteFailed(e.toString()),
          );
        }
      }
    }
  }
}

/// 고정비 카테고리 추가/수정 다이얼로그
class _CategoryDialog extends ConsumerStatefulWidget {
  final FixedExpenseCategory? category;

  const _CategoryDialog({this.category});

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedColor;
  late String _selectedIcon;
  bool _isSubmitting = false;

  String _generateRandomColor() {
    return CategoryColorPalette.palette[
        Random().nextInt(CategoryColorPalette.palette.length)];
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedColor = widget.category?.color ?? _generateRandomColor();
    _selectedIcon = widget.category?.icon ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.category != null;

    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusToken.xl),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      title: Column(
        children: [
          Text(
            isEdit ? l10n.fixedExpenseCategoryEdit : l10n.fixedExpenseCategoryAdd,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Spacing.md),
          CategoryIcon(
            icon: _selectedIcon,
            name: _nameController.text.isNotEmpty
                ? _nameController.text
                : '?',
            color: _selectedColor,
            size: CategoryIconSize.large,
          ),
        ],
      ),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이름 입력
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.categoryName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      TextFormField(
                        controller: _nameController,
                        autofocus: true,
                        maxLength: 20,
                        decoration: InputDecoration(
                          hintText: l10n.fixedExpenseCategoryNameHint,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(BorderRadiusToken.md),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(BorderRadiusToken.md),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(BorderRadiusToken.md),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          counterText: '',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.categoryNameRequired;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // 색상 선택
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ColorPicker(
                    palette: CategoryColorPalette.palette,
                    selectedColor: _selectedColor,
                    onColorSelected: (color) {
                      setState(() => _selectedColor = color);
                    },
                  ),
                ),
                const SizedBox(height: Spacing.md),
                // 아이콘 선택
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: IconPicker(
                    selectedIcon: _selectedIcon,
                    selectedColor: _selectedColor,
                    filterGroup: 'fixed',
                    onIconSelected: (icon) {
                      setState(() => _selectedIcon = icon);
                    },
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Divider(height: 1, color: colorScheme.outlineVariant),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isEdit ? l10n.commonEdit : l10n.commonAdd,
                  style: const TextStyle(fontSize: 14),
                ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final l10n = AppLocalizations.of(context);

    try {
      if (widget.category != null) {
        await ref
            .read(fixedExpenseCategoryNotifierProvider.notifier)
            .updateCategory(
              id: widget.category!.id,
              name: _nameController.text.trim(),
              icon: _selectedIcon,
              color: _selectedColor,
            );
      } else {
        await ref
            .read(fixedExpenseCategoryNotifierProvider.notifier)
            .createCategory(
              name: _nameController.text.trim(),
              icon: _selectedIcon,
              color: _selectedColor,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        SnackBarUtils.showSuccess(
          context,
          widget.category != null ? l10n.categoryUpdated : l10n.categoryAdded,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
