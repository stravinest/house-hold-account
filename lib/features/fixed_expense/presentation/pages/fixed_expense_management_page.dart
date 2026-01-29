import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/dialog_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
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
          padding: const EdgeInsets.all(16),
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
    final confirmed = await DialogUtils.showFixedExpenseCategoryDeleteConfirmation(
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

  static const List<String> _colorPalette = [
    '#FF6B6B',
    '#4ECDC4',
    '#FFE66D',
    '#95E1D3',
    '#A8DADC',
    '#F4A261',
    '#E76F51',
    '#2A9D8F',
    '#4CAF50',
    '#2196F3',
    '#9C27B0',
    '#00BCD4',
    '#E91E63',
    '#795548',
    '#607D8B',
    '#8BC34A',
  ];

  String _generateRandomColor() {
    return _colorPalette[Random().nextInt(_colorPalette.length)];
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
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

    return AlertDialog(
      title: Text(
        isEdit ? l10n.fixedExpenseCategoryEdit : l10n.fixedExpenseCategoryAdd,
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.categoryName,
            hintText: l10n.fixedExpenseCategoryNameHint,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.categoryNameRequired;
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(isEdit ? l10n.commonEdit : l10n.commonAdd),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);

    try {
      if (widget.category != null) {
        await ref
            .read(fixedExpenseCategoryNotifierProvider.notifier)
            .updateCategory(
              id: widget.category!.id,
              name: _nameController.text,
            );
      } else {
        await ref
            .read(fixedExpenseCategoryNotifierProvider.notifier)
            .createCategory(
              name: _nameController.text,
              color: _generateRandomColor(),
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
    }
  }
}
