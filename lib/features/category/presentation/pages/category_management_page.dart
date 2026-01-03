import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../providers/category_provider.dart';

class CategoryManagementPage extends ConsumerStatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  ConsumerState<CategoryManagementPage> createState() =>
      _CategoryManagementPageState();
}

class _CategoryManagementPageState
    extends ConsumerState<CategoryManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카테고리 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '지출'),
            Tab(text: '수입'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CategoryListView(type: 'expense'),
          _CategoryListView(type: 'income'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final type = _tabController.index == 0 ? 'expense' : 'income';
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
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return categoriesAsync.when(
      data: (categories) {
        final filtered = categories.where((c) => c.type == type).toList();
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '등록된 ${type == 'expense' ? '지출' : '수입'} 카테고리가 없습니다',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          onReorder: (oldIndex, newIndex) {
            // TODO: 순서 변경 구현
          },
          itemBuilder: (context, index) {
            final category = filtered[index];
            return _CategoryTile(
              key: ValueKey(category.id),
              category: category,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final Category category;

  const _CategoryTile({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _parseColor(category.color),
          child: Text(
            category.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(category.name),
        subtitle: category.isDefault ? const Text('기본 카테고리') : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!category.isDefault)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(context, category),
              ),
            if (!category.isDefault)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteConfirm(context, ref, category),
              ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return Color(int.parse(colorString));
    } catch (e) {
      return Colors.grey;
    }
  }

  void _showEditDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        type: category.type,
        category: category,
      ),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 삭제'),
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
                    .read(categoryNotifierProvider.notifier)
                    .deleteCategory(category.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('카테고리가 삭제되었습니다')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('삭제 실패: $e')),
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

class _CategoryDialog extends ConsumerStatefulWidget {
  final String type;
  final Category? category;

  const _CategoryDialog({
    required this.type,
    this.category,
  });

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String _selectedIcon = '';
  String _selectedColor = '#4CAF50';

  final List<String> _icons = [
    '', '', '', '', '', '', '', '',
    '', '', '', '', '', '', '', '',
  ];

  final List<String> _colors = [
    '#4CAF50', '#2196F3', '#F44336', '#FF9800',
    '#9C27B0', '#00BCD4', '#E91E63', '#795548',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? _icons.first;
    _selectedColor = widget.category?.color ?? _colors.first;
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
      title: Text(isEdit ? '카테고리 수정' : '카테고리 추가'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '카테고리 이름',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '카테고리 이름을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('아이콘'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icons.map((icon) {
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('색상'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colors.map((color) {
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(
                            int.parse(color.substring(1), radix: 16) + 0xFF000000),
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
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
        await ref.read(categoryNotifierProvider.notifier).updateCategory(
              id: widget.category!.id,
              name: _nameController.text,
              icon: _selectedIcon,
              color: _selectedColor,
            );
      } else {
        await ref.read(categoryNotifierProvider.notifier).createCategory(
              name: _nameController.text,
              icon: _selectedIcon,
              color: _selectedColor,
              type: widget.type,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.category != null
                ? '카테고리가 수정되었습니다'
                : '카테고리가 추가되었습니다'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }
}
