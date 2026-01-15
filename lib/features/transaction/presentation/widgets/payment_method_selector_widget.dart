import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../payment_method/domain/entities/payment_method.dart';
import '../../../payment_method/presentation/providers/payment_method_provider.dart';

/// 결제수단 선택 위젯
///
/// 결제수단 목록을 Chip 형태로 표시하고 선택/추가/삭제 기능을 제공합니다.
class PaymentMethodSelectorWidget extends ConsumerStatefulWidget {
  /// 현재 선택된 결제수단
  final PaymentMethod? selectedPaymentMethod;

  /// 결제수단 선택 시 콜백
  final ValueChanged<PaymentMethod?> onPaymentMethodSelected;

  /// 위젯 활성화 여부
  final bool enabled;

  const PaymentMethodSelectorWidget({
    super.key,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodSelected,
    this.enabled = true,
  });

  @override
  ConsumerState<PaymentMethodSelectorWidget> createState() =>
      _PaymentMethodSelectorWidgetState();
}

class _PaymentMethodSelectorWidgetState
    extends ConsumerState<PaymentMethodSelectorWidget> {
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

  /// 결제수단 추가 다이얼로그 표시
  void _showAddPaymentMethodDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('결제수단 추가'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '결제수단 이름',
            hintText: '예: 신용카드, 현금',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) =>
              _submitPaymentMethod(dialogContext, nameController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () =>
                _submitPaymentMethod(dialogContext, nameController),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  /// 결제수단 생성 제출
  Future<void> _submitPaymentMethod(
    BuildContext dialogContext,
    TextEditingController nameController,
  ) async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('결제수단 이름을 입력해주세요'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      final newPaymentMethod = await ref
          .read(paymentMethodNotifierProvider.notifier)
          .createPaymentMethod(
            name: nameController.text.trim(),
            icon: '',
            color: _generateRandomColor(),
          );

      widget.onPaymentMethodSelected(newPaymentMethod);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('결제수단이 추가되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  /// 결제수단 삭제
  Future<void> _deletePaymentMethod(PaymentMethod method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('결제수단 삭제'),
        content: Text('\'${method.name}\' 결제수단을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(paymentMethodNotifierProvider.notifier)
          .deletePaymentMethod(method.id);

      // 삭제된 결제수단이 선택되어 있었으면 선택 해제
      if (widget.selectedPaymentMethod?.id == method.id) {
        widget.onPaymentMethodSelected(null);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('결제수단이 삭제되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      ref.invalidate(paymentMethodsProvider);
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

  @override
  Widget build(BuildContext context) {
    final paymentMethodsAsync = ref.watch(paymentMethodNotifierProvider);

    return paymentMethodsAsync.when(
      data: (paymentMethods) => _buildPaymentMethodChips(paymentMethods),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('오류: $e'),
    );
  }

  Widget _buildPaymentMethodChips(List<PaymentMethod> paymentMethods) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 선택 해제 옵션
        FilterChip(
          selected: widget.selectedPaymentMethod == null,
          showCheckmark: false,
          label: const Text('선택 안함'),
          onSelected: widget.enabled
              ? (_) => widget.onPaymentMethodSelected(null)
              : null,
        ),
        ...paymentMethods.map((method) {
          final isSelected = widget.selectedPaymentMethod?.id == method.id;
          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            label: Text(method.name),
            onSelected: widget.enabled
                ? (_) => widget.onPaymentMethodSelected(method)
                : null,
            onDeleted: widget.enabled
                ? () => _deletePaymentMethod(method)
                : null,
            deleteIcon: const Icon(Icons.close, size: 18),
          );
        }),
        // 결제수단 추가 버튼
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('추가'),
          onPressed: widget.enabled ? _showAddPaymentMethodDialog : null,
        ),
      ],
    );
  }
}
