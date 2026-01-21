import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/dialog_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../domain/entities/category.dart';
import '../providers/category_provider.dart';

class CategoryManagementPage extends ConsumerStatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  ConsumerState<CategoryManagementPage> createState() =>
      _CategoryManagementPageState();
}

class _CategoryManagementPageState extends ConsumerState<CategoryManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // autoDispose provider는 페이지 재진입 시 자동으로 새 인스턴스를 생성하여 데이터를 로드하고,
    // Realtime subscription이 변경사항을 감지하므로 수동 refresh가 불필요합니다.
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoryManagement),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.transactionExpense),
            Tab(text: l10n.transactionIncome),
            Tab(text: l10n.transactionAsset),
          ],
        ),
      ),
      body: CenteredContent(
        maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
        child: TabBarView(
          controller: _tabController,
          children: const [
            _CategoryListView(type: 'expense'),
            _CategoryListView(type: 'income'),
            _CategoryListView(type: 'asset'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final types = ['expense', 'income', 'asset'];
    final type = types[_tabController.index];
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(type: type),
    );
  }
}

class _CategoryListView extends ConsumerWidget {
  final String type;

  const _CategoryListView({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return categoriesAsync.when(
      data: (categories) {
        final filtered = categories.where((c) => c.type == type).toList();
        if (filtered.isEmpty) {
          final typeName = type == 'expense'
              ? l10n.transactionExpense
              : type == 'income'
              ? l10n.transactionIncome
              : l10n.transactionAsset;
          return EmptyState(
            icon: Icons.category_outlined,
            message: l10n.categoryEmpty(typeName),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(Spacing.md),
          cacheExtent: 500, // 성능 최적화: 스크롤 시 미리 렌더링
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final category = filtered[index];
            return _CategoryTile(
              key: ValueKey(category.id),
              category: category,
            );
          },
        );
      },
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(Spacing.md),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  const Expanded(child: SkeletonLine(height: 18)),
                  const SizedBox(width: 8),
                  SkeletonBox(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadiusToken.md,
                  ),
                  const SizedBox(width: 8),
                  SkeletonBox(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadiusToken.md,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      error: (e, _) => Center(child: Text(l10n.errorWithMessage(e.toString()))),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final Category category;

  const _CategoryTile({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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

  void _showEditDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) =>
          _CategoryDialog(type: category.type, category: category),
    );
  }

  Future<void> _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await DialogUtils.showConfirmation(
      context,
      title: l10n.categoryDeleteConfirmTitle,
      message: '\'${category.name}\'\n\n${l10n.categoryDeleteConfirmMessage}',
      confirmText: l10n.commonDelete,
    );

    if (confirmed == true) {
      try {
        await ref
            .read(categoryNotifierProvider.notifier)
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

class _CategoryDialog extends ConsumerStatefulWidget {
  final String type;
  final Category? category;

  const _CategoryDialog({required this.type, this.category});

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
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.category != null;

    return AlertDialog(
      title: Text(isEdit ? l10n.categoryEdit : l10n.categoryAdd),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.categoryName,
            hintText: l10n.categoryNameHint,
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

    final l10n = AppLocalizations.of(context)!;

    try {
      if (widget.category != null) {
        await ref
            .read(categoryNotifierProvider.notifier)
            .updateCategory(
              id: widget.category!.id,
              name: _nameController.text,
            );
      } else {
        await ref
            .read(categoryNotifierProvider.notifier)
            .createCategory(
              name: _nameController.text,
              icon: '',
              color: _generateRandomColor(),
              type: widget.type,
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
