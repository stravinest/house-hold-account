import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
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
        final l10n = AppLocalizations.of(context)!;
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigator.pop();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(l10n.transactionExpenseAdded),
              duration: const Duration(seconds: 1),
            ),
          );
        });
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final categoriesAsync = ref.watch(categoryNotifierProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(Spacing.xl),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(BorderRadiusToken.lg),
        ),
        padding: EdgeInsets.all(Spacing.lg),
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
              SizedBox(height: Spacing.lg),

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
              SizedBox(height: Spacing.md),

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
              SizedBox(height: Spacing.md),

              categoriesAsync.when(
                data: (categories) {
                  final expenseCategories = categories
                      .where((c) => c.type == 'expense')
                      .toList();

                  return DropdownButtonFormField<Category>(
                    value: _selectedCategory,
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
                                Text(
                                  category.icon,
                                  style: TextStyle(fontSize: IconSize.sm),
                                ),
                                SizedBox(width: Spacing.sm),
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
                error: (_, __) => Text(l10n.transactionCategoryLoadError),
              ),
              SizedBox(height: Spacing.lg),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(l10n.commonCancel),
                  ),
                  SizedBox(width: Spacing.sm),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
