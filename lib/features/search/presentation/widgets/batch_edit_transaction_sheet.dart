import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../payment_method/domain/entities/payment_method.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../../transaction/presentation/widgets/category_section_widget.dart';
import '../../../transaction/presentation/widgets/payment_method_selector_widget.dart';
import '../../../transaction/presentation/widgets/transaction_form_fields.dart';

/// 여러 거래를 한 번에 수정하는 Bottom Sheet
class BatchEditTransactionSheet extends ConsumerStatefulWidget {
  final List<Transaction> transactions;

  const BatchEditTransactionSheet({
    super.key,
    required this.transactions,
  });

  @override
  ConsumerState<BatchEditTransactionSheet> createState() =>
      _BatchEditTransactionSheetState();
}

class _BatchEditTransactionSheetState
    extends ConsumerState<BatchEditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _amountFocusNode = FocusNode();

  // 각 필드별 "변경" 토글
  bool _changeAmount = false;
  bool _changeTitle = false;
  bool _changeMemo = false;
  bool _changeCategory = false;
  bool _changePaymentMethod = false;

  Category? _selectedCategory;
  PaymentMethod? _selectedPaymentMethod;
  bool _isLoading = false;
  bool _categoryInitialized = false;

  // 선택된 거래들 중 가장 빈번한 타입
  late String _dominantType;
  // expense 타입이 포함되어 있는지
  late bool _hasExpenseType;

  @override
  void initState() {
    super.initState();
    _initializeWithMode();
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _amountController.dispose();
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  /// 리스트에서 최빈값(mode) 계산
  T _mode<T>(Iterable<T> values) {
    final counts = <T, int>{};
    for (final v in values) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    return counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  /// 선택된 거래들에서 최빈값을 계산하여 초기값 설정
  void _initializeWithMode() {
    final txns = widget.transactions;

    _dominantType = _mode(txns.map((t) => t.type));
    _hasExpenseType = txns.any((t) => t.type == 'expense');

    final modeAmount = _mode(txns.map((t) => t.amount));
    _amountController.text = NumberFormat('#,###').format(modeAmount);

    _titleController.text = _mode(txns.map((t) => t.title ?? ''));
    _memoController.text = _mode(txns.map((t) => t.memo ?? ''));
  }

  /// 카테고리 토글 시 최빈 카테고리 초기값 설정 (1회만)
  void _initializeCategoryIfNeeded() {
    if (_categoryInitialized) return;
    _categoryInitialized = true;

    final modeCatId = _mode(
      widget.transactions.map((t) => t.categoryId),
    );
    if (modeCatId == null) return;

    final categoriesAsync = _dominantType == 'expense'
        ? ref.read(expenseCategoriesProvider)
        : _dominantType == 'income'
            ? ref.read(incomeCategoriesProvider)
            : ref.read(savingCategoriesProvider);

    categoriesAsync.whenData((categories) {
      final cat = categories.cast<Category?>().firstWhere(
            (c) => c?.id == modeCatId,
            orElse: () => null,
          );
      if (cat != null && mounted) {
        setState(() => _selectedCategory = cat);
      }
    });
  }

  bool get _hasAnyFieldSelected =>
      _changeAmount ||
      _changeTitle ||
      _changeMemo ||
      _changeCategory ||
      _changePaymentMethod;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);

    if (!_hasAnyFieldSelected) {
      SnackBarUtils.showInfo(context, l10n.searchBatchEditNoFieldSelected);
      return;
    }

    if (_changeAmount &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updates = <String, dynamic>{};

      if (_changeAmount) {
        updates['amount'] = int.parse(
          _amountController.text.replaceAll(RegExp(r'[^\d]'), ''),
        );
      }
      if (_changeTitle) {
        final titleText = _titleController.text.trim();
        updates['title'] = titleText.isNotEmpty ? titleText : null;
      }
      if (_changeMemo) {
        final memoText = _memoController.text.trim();
        updates['memo'] = memoText.isNotEmpty ? memoText : null;
      }
      if (_changeCategory) {
        updates['category_id'] = _selectedCategory?.id;
      }
      if (_changePaymentMethod) {
        updates['payment_method_id'] = _selectedPaymentMethod?.id;
      }

      final ids = widget.transactions.map((t) => t.id).toList();
      final repository = ref.read(transactionRepositoryProvider);
      await repository.batchUpdateTransactions(ids: ids, updates: updates);

      if (mounted) {
        final successMsg = l10n.searchBatchEditSuccess(ids.length);
        Navigator.pop(context, true);
        SnackBarUtils.showSuccess(context, successMsg);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          l10n.errorWithMessage(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildFieldToggle({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Widget child,
  }) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: Spacing.xs),
            Text(
              l10n.searchBatchEditApplyChange,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        if (value) ...[
          const SizedBox(height: Spacing.xs),
          child,
        ],
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    final viewInsets = MediaQuery.of(context).viewInsets;
    final viewPadding = MediaQuery.of(context).viewPadding;
    final bottomPadding =
        viewInsets.bottom > 0 ? viewInsets.bottom : viewPadding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SheetHandle(),
              // 헤더
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.commonCancel),
                    ),
                    Text(
                      l10n.searchBatchEditTitle,
                      style:
                          Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed:
                          _isLoading || !_hasAnyFieldSelected
                              ? null
                              : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : Text(l10n.commonSave),
                    ),
                  ],
                ),
              ),
              // 선택된 거래 수 표시
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: Text(
                  l10n.searchSelectedCount(
                      widget.transactions.length),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
              ),
              const Divider(),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 금액
                      _buildFieldToggle(
                        label: l10n.searchBatchEditFieldAmount,
                        value: _changeAmount,
                        onChanged: (v) =>
                            setState(() => _changeAmount = v),
                        child: TextFormField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            AmountInputFormatter(locale),
                          ],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            suffixText: l10n.transactionAmountUnit,
                            suffixStyle:
                                const TextStyle(fontSize: 18),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          maxLength: 18,
                          validator: (v) =>
                              _changeAmount &&
                                      (v == null ||
                                          v.isEmpty ||
                                          v == '0')
                                  ? l10n.transactionAmountRequired
                                  : null,
                        ),
                      ),

                      // 제목
                      _buildFieldToggle(
                        label: l10n.searchBatchEditFieldTitle,
                        value: _changeTitle,
                        onChanged: (v) =>
                            setState(() => _changeTitle = v),
                        child: TextFormField(
                          controller: _titleController,
                          maxLines: 1,
                          maxLength: 40,
                          decoration: InputDecoration(
                            hintText: l10n.categoryNameHintExample,
                            prefixIcon: const Icon(Icons.edit),
                            border: const OutlineInputBorder(),
                            counterText: '',
                          ),
                        ),
                      ),

                      // 메모
                      _buildFieldToggle(
                        label: l10n.searchBatchEditFieldMemo,
                        value: _changeMemo,
                        onChanged: (v) =>
                            setState(() => _changeMemo = v),
                        child: TextFormField(
                          controller: _memoController,
                          maxLines: 3,
                          maxLength: 500,
                          decoration: InputDecoration(
                            hintText: l10n.transactionMemoHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),

                      // 카테고리
                      _buildFieldToggle(
                        label: l10n.searchBatchEditFieldCategory,
                        value: _changeCategory,
                        onChanged: (v) {
                          setState(() => _changeCategory = v);
                          if (v) _initializeCategoryIfNeeded();
                        },
                        child: CategorySectionWidget(
                          isFixedExpense: false,
                          selectedCategory: _selectedCategory,
                          selectedFixedExpenseCategory: null,
                          transactionType: _dominantType,
                          onCategorySelected: (c) =>
                              setState(() => _selectedCategory = c),
                          onFixedExpenseCategorySelected: (_) {},
                        ),
                      ),

                      // 결제수단 (expense 타입이 포함된 경우만)
                      if (_hasExpenseType)
                        _buildFieldToggle(
                          label:
                              l10n.searchBatchEditFieldPaymentMethod,
                          value: _changePaymentMethod,
                          onChanged: (v) => setState(
                              () => _changePaymentMethod = v),
                          child: PaymentMethodSelectorWidget(
                            selectedPaymentMethod:
                                _selectedPaymentMethod,
                            onPaymentMethodSelected: (m) => setState(
                                () => _selectedPaymentMethod = m),
                          ),
                        ),

                      SizedBox(height: bottomPadding + Spacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
