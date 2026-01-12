import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    // 화면 진입 시 데이터 새로 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fixedExpenseCategoryNotifierProvider.notifier).loadCategories();
      ref.read(fixedExpenseSettingsNotifierProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고정비 관리'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 고정비 설정 카드
          const _SettingsCard(),
          const SizedBox(height: 24),
          // 고정비 카테고리 섹션
          const _SectionHeader(title: '고정비 카테고리'),
          const SizedBox(height: 8),
          const _CategoryListView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CategoryDialog(),
    );
  }
}

/// 섹션 헤더
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// 고정비 설정 카드
class _SettingsCard extends ConsumerWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(fixedExpenseSettingsNotifierProvider);

    return Card(
      child: settingsAsync.when(
        data: (settings) {
          final includeInExpense = settings?.includeInExpense ?? false;
          return Column(
            children: [
              SwitchListTile(
                title: const Text('고정비를 지출에 편입'),
                subtitle: Text(
                  includeInExpense
                      ? '고정비가 달력과 통계의 지출에 포함됩니다'
                      : '고정비가 달력과 통계의 지출에서 제외됩니다',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: includeInExpense,
                onChanged: (value) async {
                  try {
                    await ref
                        .read(fixedExpenseSettingsNotifierProvider.notifier)
                        .updateIncludeInExpense(value);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value ? '고정비가 지출에 포함됩니다' : '고정비가 지출에서 제외됩니다',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('설정 변경 실패: $e'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
        loading: () => const ListTile(
          title: Text('고정비를 지출에 편입'),
          trailing: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, _) => ListTile(
          title: const Text('설정 로드 실패'),
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
    final categoriesAsync = ref.watch(fixedExpenseCategoryNotifierProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.repeat_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '등록된 고정비 카테고리가 없습니다',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+ 버튼을 눌러 카테고리를 추가하세요',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
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
          child: Text('오류: $e'),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(category.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context, category),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
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

  void _showDeleteConfirm(
      BuildContext context, WidgetRef ref, FixedExpenseCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('고정비 카테고리 삭제'),
        content: Text('\'${category.name}\' 카테고리를 삭제하시겠습니까?\n\n'
            '이 카테고리로 기록된 거래는 삭제되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(fixedExpenseCategoryNotifierProvider.notifier)
                    .deleteCategory(category.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('카테고리가 삭제되었습니다'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('삭제 실패: $e'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
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
    '#FF6B6B', '#4ECDC4', '#FFE66D', '#95E1D3',
    '#A8DADC', '#F4A261', '#E76F51', '#2A9D8F',
    '#4CAF50', '#2196F3', '#9C27B0', '#00BCD4',
    '#E91E63', '#795548', '#607D8B', '#8BC34A',
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
    final isEdit = widget.category != null;

    return AlertDialog(
      title: Text(isEdit ? '고정비 카테고리 수정' : '고정비 카테고리 추가'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '카테고리 이름',
            hintText: '예: 월세, 보험료, 구독료',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '카테고리 이름을 입력하세요';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(isEdit ? '수정' : '추가'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.category != null
                ? '카테고리가 수정되었습니다'
                : '카테고리가 추가되었습니다'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
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
}
