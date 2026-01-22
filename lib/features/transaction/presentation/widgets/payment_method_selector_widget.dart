import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_utils.dart';
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
  bool _isEditMode = false;

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
    final l10n = AppLocalizations.of(context);
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
    final l10n = AppLocalizations.of(context);
    if (nameController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, l10n.paymentMethodNameRequired);
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
        SnackBarUtils.showSuccess(context, l10n.paymentMethodAdded);
      }

      ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    }
  }

  /// 결제수단 수정 다이얼로그
  void _showEditPaymentMethodDialog(PaymentMethod method) {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: method.name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.paymentMethodEdit),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.paymentMethodName,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) =>
              _submitEditPaymentMethod(dialogContext, method, nameController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                _submitEditPaymentMethod(dialogContext, method, nameController),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  /// 결제수단 수정 제출
  Future<void> _submitEditPaymentMethod(
    BuildContext dialogContext,
    PaymentMethod method,
    TextEditingController nameController,
  ) async {
    final l10n = AppLocalizations.of(context);
    final newName = nameController.text.trim();

    if (newName.isEmpty) {
      SnackBarUtils.showError(context, l10n.paymentMethodNameRequired);
      return;
    }

    if (newName == method.name) {
      Navigator.pop(dialogContext);
      return;
    }

    try {
      await ref
          .read(paymentMethodNotifierProvider.notifier)
          .updatePaymentMethod(id: method.id, name: newName);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }

      SnackBarUtils.showSuccess(context, l10n.commonSuccess);

      ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
    }
  }

  /// 결제수단 삭제
  Future<void> _deletePaymentMethod(PaymentMethod method) async {
    final l10n = AppLocalizations.of(context);
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
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
      if (widget.selectedPaymentMethod?.id == method.id) {
        widget.onPaymentMethodSelected(null);
      }

      if (mounted) {
        SnackBarUtils.showSuccess(context, l10n.paymentMethodDeleted);
      }

      ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
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
      error: (e, _) => Text('${AppLocalizations.of(context).commonError}: $e'),
    );
  }

  Widget _buildSkeletonChips() {
    return const Wrap(
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
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    // 편집 모드: 칩들과 완료 버튼을 별도 줄로 분리
    if (_isEditMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: paymentMethods
                .map((method) => _buildEditModeChip(method, colorScheme))
                .toList(),
          ),
          const SizedBox(height: 8),
          ActionChip(
            avatar: const Icon(Icons.check, size: 18),
            label: Text(l10n.commonDone),
            onPressed: widget.enabled
                ? () => setState(() => _isEditMode = false)
                : null,
          ),
        ],
      );
    }

    // 기본 모드
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          selected: widget.selectedPaymentMethod == null,
          showCheckmark: false,
          label: Text(l10n.transactionNone),
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
          );
        }),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: Text(l10n.commonAdd),
          onPressed: widget.enabled ? _showAddPaymentMethodDialog : null,
        ),
        ActionChip(
          avatar: const Icon(Icons.edit_outlined, size: 18),
          label: Text(l10n.commonEdit),
          onPressed: widget.enabled
              ? () => setState(() => _isEditMode = true)
              : null,
        ),
      ],
    );
  }

  /// 편집 모드용 결제수단 칩
  Widget _buildEditModeChip(PaymentMethod method, ColorScheme colorScheme) {
    return Container(
      height: 38, // ActionChip과 동일한 높이
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 결제수단 이름
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              method.name,
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          // 수정 버튼
          InkWell(
            onTap: () => _showEditPaymentMethodDialog(method),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 38,
              alignment: Alignment.center,
              child: Icon(
                Icons.edit_outlined,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
          ),
          // 삭제 버튼
          InkWell(
            onTap: () => _deletePaymentMethod(method),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 38,
              alignment: Alignment.center,
              child: Icon(Icons.close, size: 16, color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
