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
    final l10n = AppLocalizations.of(context);
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
    final l10n = AppLocalizations.of(context);
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
          padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 80),
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
        padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 80),
        itemCount: 5,
        itemBuilder: (context, index) {
          return const Card(
            margin: EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  Expanded(child: SkeletonLine(height: 18)),
                  SizedBox(width: 8),
                  SkeletonBox(
                    width: 40,
                    height: 40,
                    borderRadius: BorderRadiusToken.md,
                  ),
                  SizedBox(width: 8),
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
        title: Text(
          category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await DialogUtils.showCategoryDeleteConfirmation(
      context,
      categoryName: category.name,
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
  late String _selectedColor;
  late String _selectedIcon;
  bool _isSubmitting = false;

  String _generateRandomColor() {
    return CategoryColorPalette.palette[
        Random().nextInt(CategoryColorPalette.palette.length)];
  }

  /// 카테고리 타입에 대응하는 iconGroups 키
  String get _iconGroupKey {
    switch (widget.type) {
      case 'expense':
        return 'expense';
      case 'income':
        return 'income';
      case 'asset':
        return 'asset';
      default:
        return 'expense';
    }
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
            isEdit ? l10n.categoryEdit : l10n.categoryAdd,
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
                          hintText: l10n.categoryNameHint,
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
                    filterGroup: _iconGroupKey,
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
            .read(categoryNotifierProvider.notifier)
            .updateCategory(
              id: widget.category!.id,
              name: _nameController.text.trim(),
              icon: _selectedIcon,
              color: _selectedColor,
            );
      } else {
        await ref
            .read(categoryNotifierProvider.notifier)
            .createCategory(
              name: _nameController.text.trim(),
              icon: _selectedIcon,
              color: _selectedColor,
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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
