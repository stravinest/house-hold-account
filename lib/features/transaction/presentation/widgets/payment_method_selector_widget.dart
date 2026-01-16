import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.paymentMethodAdd),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.paymentMethodName,
            hintText: l10n.paymentMethodNameHintExample,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) =>
              _submitPaymentMethod(dialogContext, nameController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                _submitPaymentMethod(dialogContext, nameController),
            child: Text(l10n.commonAdd),
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
    final l10n = AppLocalizations.of(context)!;
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.paymentMethodNameRequired),
          duration: const Duration(seconds: 1),
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
          SnackBar(
            content: Text(l10n.paymentMethodAdded),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  /// 결제수단 삭제
  Future<void> _deletePaymentMethod(PaymentMethod method) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.paymentMethodDeleteConfirmTitle),
        content: Text(l10n.paymentMethodDeleteConfirm(method.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonDelete),
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
      if (widget.selectedPaymentMethod.id == method.id) {
        widget.onPaymentMethodSelected(null);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.paymentMethodDeleted),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
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
      data: (paymentMethods) =>
          _buildPaymentMethodChips(context, paymentMethods),
      loading: () => _buildSkeletonChips(),
      error: (e, _) => Text('${AppLocalizations.of(context)!.commonError}: $e'),
    );
  }

  Widget _buildSkeletonChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SkeletonBox(width: 80, height: 32, borderRadius: 16),
        SkeletonBox(width: 100, height: 32, borderRadius: 16),
        SkeletonBox(width: 90, height: 32, borderRadius: 16),
        SkeletonBox(width: 70, height: 32, borderRadius: 16),
        SkeletonBox(width: 85, height: 32, borderRadius: 16),
      ],
    );
  }

  Widget _buildPaymentMethodChips(
    BuildContext context,
    List<PaymentMethod> paymentMethods,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 선택 해제 옵션
        FilterChip(
          selected: widget.selectedPaymentMethod == null,
          showCheckmark: false,
          label: Text(l10n.transactionNone),
          onSelected: widget.enabled
              ? (_) => widget.onPaymentMethodSelected(null)
              : null,
        ),
        ...paymentMethods.map((method) {
          final isSelected = widget.selectedPaymentMethod.id == method.id;
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
          label: Text(l10n.commonAdd),
          onPressed: widget.enabled ? _showAddPaymentMethodDialog : null,
        ),
      ],
    );
  }
}
