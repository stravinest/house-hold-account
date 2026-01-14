import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/payment_method.dart';
import '../providers/payment_method_provider.dart';

class PaymentMethodManagementPage extends ConsumerStatefulWidget {
  const PaymentMethodManagementPage({super.key});

  @override
  ConsumerState<PaymentMethodManagementPage> createState() =>
      _PaymentMethodManagementPageState();
}

class _PaymentMethodManagementPageState
    extends ConsumerState<PaymentMethodManagementPage> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 결제수단 데이터 새로 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentMethodNotifierProvider.notifier).loadPaymentMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodsAsync = ref.watch(paymentMethodNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('결제수단 관리')),
      body: paymentMethodsAsync.when(
        data: (paymentMethods) {
          if (paymentMethods.isEmpty) {
            return EmptyState(
              icon: Icons.credit_card_outlined,
              message: '등록된 결제수단이 없습니다',
              action: ElevatedButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('결제수단 추가'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: paymentMethods.length,
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
        title: Text(paymentMethod.name),
        subtitle: paymentMethod.isDefault ? const Text('기본 결제수단') : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context, paymentMethod),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirm(context, ref, paymentMethod),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, PaymentMethod paymentMethod) {
    showDialog(
      context: context,
      builder: (context) => _PaymentMethodDialog(paymentMethod: paymentMethod),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    PaymentMethod paymentMethod,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('결제수단 삭제'),
        content: Text(
          '\'${paymentMethod.name}\' 결제수단을 삭제하시겠습니까?\n\n'
          '이 결제수단으로 기록된 거래의 결제수단 정보가 삭제됩니다.',
        ),
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
                    const SnackBar(
                      content: Text('결제수단이 삭제되었습니다'),
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
    _nameController = TextEditingController(
      text: widget.paymentMethod?.name ?? '',
    );
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
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '결제수단 이름',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '결제수단 이름을 입력하세요';
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
        TextButton(onPressed: _submit, child: Text(isEdit ? '수정' : '추가')),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (widget.paymentMethod != null) {
        await ref
            .read(paymentMethodNotifierProvider.notifier)
            .updatePaymentMethod(
              id: widget.paymentMethod!.id,
              name: _nameController.text,
            );
      } else {
        await ref
            .read(paymentMethodNotifierProvider.notifier)
            .createPaymentMethod(
              name: _nameController.text,
              icon: '',
              color: _generateRandomColor(),
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.paymentMethod != null ? '결제수단이 수정되었습니다' : '결제수단이 추가되었습니다',
            ),
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
