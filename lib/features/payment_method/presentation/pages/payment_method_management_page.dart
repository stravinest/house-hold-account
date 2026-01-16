import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final paymentMethodsAsync = ref.watch(paymentMethodNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentMethodManagement)),
      body: paymentMethodsAsync.when(
        data: (paymentMethods) {
          if (paymentMethods.isEmpty) {
            return EmptyState(
              icon: Icons.credit_card_outlined,
              message: l10n.paymentMethodEmpty,
              action: ElevatedButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.paymentMethodAdd),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(Spacing.md),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SkeletonLine(height: 18),
                          if (index == 0) ...[
                            const SizedBox(height: 8),
                            const SkeletonLine(width: 60, height: 14),
                          ],
                        ],
                      ),
                    ),
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
        error: (e, _) =>
            Center(child: Text(l10n.errorWithMessage(e.toString()))),
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(paymentMethod.name),
        subtitle: paymentMethod.isDefault
            ? Text(l10n.paymentMethodDefault)
            : null,
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.paymentMethodDeleteConfirmTitle),
        content: Text(
          '\'${paymentMethod.name}\'\n\n'
          '${l10n.paymentMethodDeleteConfirmMessage}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
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
                    SnackBar(
                      content: Text(l10n.paymentMethodDeleted),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.paymentMethodDeleteFailed(e.toString()),
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
            child: Text(l10n.commonDelete),
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
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.paymentMethod != null;

    return AlertDialog(
      title: Text(isEdit ? l10n.paymentMethodEdit : l10n.paymentMethodAdd),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.paymentMethodName,
            hintText: l10n.paymentMethodNameHint,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.paymentMethodNameRequired;
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
              widget.paymentMethod != null
                  ? l10n.paymentMethodUpdated
                  : l10n.paymentMethodAdded,
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
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
}
