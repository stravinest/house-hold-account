import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/payment_method.dart';
import '../providers/payment_method_provider.dart';

class PaymentMethodManagementPage extends ConsumerWidget {
  const PaymentMethodManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentMethodsAsync = ref.watch(paymentMethodNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('결제수단 관리'),
      ),
      body: paymentMethodsAsync.when(
        data: (paymentMethods) {
          if (paymentMethods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '등록된 결제수단이 없습니다',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('결제수단 추가'),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: paymentMethods.length,
            onReorder: (oldIndex, newIndex) {
              // TODO: 순서 변경 구현
            },
            itemBuilder: (context, index) {
              final paymentMethod = paymentMethods[index];
              return _PaymentMethodTile(
                key: ValueKey(paymentMethod.id),
                paymentMethod: paymentMethod,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _PaymentMethodDialog(),
    );
  }
}

class _PaymentMethodTile extends ConsumerWidget {
  final PaymentMethod paymentMethod;

  const _PaymentMethodTile({super.key, required this.paymentMethod});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _parseColor(paymentMethod.color),
          child: paymentMethod.icon.isNotEmpty
              ? Text(
                  paymentMethod.icon,
                  style: const TextStyle(fontSize: 20),
                )
              : const Icon(Icons.credit_card, color: Colors.white),
        ),
        title: Text(paymentMethod.name),
        subtitle: paymentMethod.isDefault ? const Text('기본 결제수단') : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context, paymentMethod),
            ),
            if (!paymentMethod.isDefault)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteConfirm(context, ref, paymentMethod),
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

  void _showEditDialog(BuildContext context, PaymentMethod paymentMethod) {
    showDialog(
      context: context,
      builder: (context) => _PaymentMethodDialog(paymentMethod: paymentMethod),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, WidgetRef ref, PaymentMethod paymentMethod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('결제수단 삭제'),
        content: Text('\'${paymentMethod.name}\' 결제수단을 삭제하시겠습니까?\n\n'
            '이 결제수단으로 기록된 거래의 결제수단 정보가 삭제됩니다.'),
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
                    .read(paymentMethodNotifierProvider.notifier)
                    .deletePaymentMethod(paymentMethod.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('결제수단이 삭제되었습니다')),
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

class _PaymentMethodDialog extends ConsumerStatefulWidget {
  final PaymentMethod? paymentMethod;

  const _PaymentMethodDialog({this.paymentMethod});

  @override
  ConsumerState<_PaymentMethodDialog> createState() =>
      _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends ConsumerState<_PaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String _selectedIcon = '';
  String _selectedColor = '#4CAF50';

  final List<String> _icons = [
    '', '', '', '', '', '', '', '',
  ];

  final List<String> _colors = [
    '#4CAF50', '#2196F3', '#F44336', '#FF9800',
    '#9C27B0', '#00BCD4', '#E91E63', '#795548',
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.paymentMethod?.name ?? '');
    _selectedIcon = widget.paymentMethod?.icon ?? '';
    _selectedColor = widget.paymentMethod?.color ?? _colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.paymentMethod != null;

    return AlertDialog(
      title: Text(isEdit ? '결제수단 수정' : '결제수단 추가'),
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
                  labelText: '결제수단 이름',
                  hintText: '예: 우리카드, 신한카드, 현금',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '결제수단 이름을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('아이콘 (선택)'),
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
                        child: icon.isEmpty
                            ? const Icon(Icons.credit_card, size: 20)
                            : Text(icon, style: const TextStyle(fontSize: 20)),
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
                            int.parse(color.substring(1), radix: 16) +
                                0xFF000000),
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
      if (widget.paymentMethod != null) {
        await ref.read(paymentMethodNotifierProvider.notifier).updatePaymentMethod(
              id: widget.paymentMethod!.id,
              name: _nameController.text,
              icon: _selectedIcon,
              color: _selectedColor,
            );
      } else {
        await ref.read(paymentMethodNotifierProvider.notifier).createPaymentMethod(
              name: _nameController.text,
              icon: _selectedIcon,
              color: _selectedColor,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.paymentMethod != null
                ? '결제수단이 수정되었습니다'
                : '결제수단이 추가되었습니다'),
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
