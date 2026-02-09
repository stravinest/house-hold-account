import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../payment_method/presentation/providers/payment_method_provider.dart';
import '../providers/transaction_provider.dart';

class QuickExpenseSheet extends ConsumerStatefulWidget {
  const QuickExpenseSheet({super.key});

  @override
  ConsumerState<QuickExpenseSheet> createState() => _QuickExpenseSheetState();
}

class _QuickExpenseSheetState extends ConsumerState<QuickExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _amountFocusNode = FocusNode();

  Category? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = '0';
    _amountFocusNode.addListener(_onAmountFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryNotifierProvider.notifier).loadCategories();
      ref.read(paymentMethodNotifierProvider.notifier).loadPaymentMethods();
    });
  }

  void _onAmountFocusChange() {
    if (_amountFocusNode.hasFocus) {
      if (_amountController.text == '0') {
        _amountController.clear();
      } else {
        _amountController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _amountController.text.length,
        );
      }
    } else {
      if (_amountController.text.isEmpty) {
        _amountController.text = '0';
      }
    }
  }

  @override
  void dispose() {
    _amountFocusNode.removeListener(_onAmountFocusChange);
    _amountFocusNode.dispose();
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;
    return true;
  }

  Future<void> _submit() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(transactionNotifierProvider.notifier);
      final paymentMethods = await ref.read(paymentMethodsProvider.future);
      final firstPaymentMethod = paymentMethods.isNotEmpty
          ? paymentMethods.first
          : null;

      await notifier.createTransaction(
        type: 'expense',
        amount: int.parse(_amountController.text.replaceAll(',', '')),
        title: _titleController.text,
        date: DateTime.now(),
        categoryId: _selectedCategory?.id,
        paymentMethodId: firstPaymentMethod?.id,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final navigator = Navigator.of(context);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigator.pop();
          SnackBarUtils.showSuccess(context, l10n.transactionExpenseAdded);
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(Spacing.xl),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(BorderRadiusToken.lg),
        ),
        padding: const EdgeInsets.all(Spacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.transactionQuickExpense,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Spacing.lg),

              TextFormField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.transactionAmount,
                  suffixText: l10n.transactionAmountUnit,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusToken.md),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || value == '0') {
                    return l10n.transactionAmountRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: Spacing.md),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.transactionTitle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusToken.md),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.transactionTitleRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: Spacing.md),

              categoriesAsync.when(
                data: (categories) {
                  final expenseCategories = categories
                      .where((c) => c.type == 'expense')
                      .toList();

                  return DropdownButtonFormField<Category>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: l10n.transactionCategory,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          BorderRadiusToken.md,
                        ),
                      ),
                    ),
                    items: expenseCategories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                CategoryIcon(
                                  icon: category.icon,
                                  name: category.name,
                                  color: category.color,
                                  size: CategoryIconSize.small,
                                ),
                                const SizedBox(width: Spacing.sm),
                                Text(category.name),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, stack) => Text(l10n.transactionCategoryLoadError),
              ),
              const SizedBox(height: Spacing.lg),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 80,
                    height: 40,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  SizedBox(
                    width: 80,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Text(l10n.commonSave),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
