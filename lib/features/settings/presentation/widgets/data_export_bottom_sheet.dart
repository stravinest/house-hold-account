import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../transaction/data/repositories/transaction_repository.dart';
import '../../data/services/export_service.dart';

class DataExportBottomSheet extends ConsumerStatefulWidget {
  const DataExportBottomSheet({super.key});

  @override
  ConsumerState<DataExportBottomSheet> createState() =>
      _DataExportBottomSheetState();
}

class _DataExportBottomSheetState extends ConsumerState<DataExportBottomSheet> {
  late DateTime _startDate;
  late DateTime _endDate;
  String? _transactionType; // null = all
  bool _includeCategory = true;
  bool _includePaymentMethod = true;
  bool _includeMemo = true;
  bool _includeAuthor = false;
  bool _includeFixedExpense = false;
  ExportFileFormat _fileFormat = ExportFileFormat.xlsx;
  bool _isExporting = false;

  final _dateFormat = DateFormat('yyyy.MM.dd');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  void _setQuickPeriod(String period) {
    final now = DateTime.now();
    setState(() {
      switch (period) {
        case 'thisMonth':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'lastMonth':
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0);
          break;
        case 'recent3Months':
          _startDate = DateTime(now.year, now.month - 2, 1);
          _endDate = DateTime(now.year, now.month + 1, 0);
          break;
        case 'thisYear':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, 12, 31);
          break;
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year, 12, 31),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    final ledgerId = ref.read(selectedLedgerIdProvider);
    if (ledgerId == null) return;

    setState(() => _isExporting = true);

    try {
      final repository = TransactionRepository();
      final transactions = await repository.getTransactionsByDateRange(
        ledgerId: ledgerId,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) return;

      if (transactions.isEmpty) {
        SnackBarUtils.showInfo(context, l10n.exportNoData);
        setState(() => _isExporting = false);
        return;
      }

      final options = ExportOptions(
        startDate: _startDate,
        endDate: _endDate,
        transactionType: _transactionType,
        includeCategory: _includeCategory,
        includePaymentMethod: _includePaymentMethod,
        includeMemo: _includeMemo,
        includeAuthor: _includeAuthor,
        includeFixedExpense: _includeFixedExpense,
        format: _fileFormat,
      );

      await ExportService.exportAndShare(transactions, options, l10n: l10n);

      if (!mounted) return;
      Navigator.pop(context);
      SnackBarUtils.showSuccess(context, l10n.exportSuccess);
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, l10n.exportFailed(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.md,
                Spacing.sm,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.exportTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: l10n.commonClose,
                  ),
                ],
              ),
            ),
            const Divider(),
            // 컨텐츠
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
                children: [
                  const SizedBox(height: Spacing.sm),
                  // 내보내기 기간
                  _buildSectionTitle(l10n.exportPeriod),
                  const SizedBox(height: Spacing.sm),
                  _buildDateRangeSelector(context, l10n),
                  const SizedBox(height: Spacing.sm),
                  _buildQuickPeriodButtons(l10n),
                  const SizedBox(height: Spacing.lg),

                  // 거래 유형
                  _buildSectionTitle(l10n.exportTransactionType),
                  const SizedBox(height: Spacing.sm),
                  _buildTransactionTypeChips(l10n, colorScheme),
                  const SizedBox(height: Spacing.lg),

                  // 포함 항목
                  _buildSectionTitle(l10n.exportIncludeItems),
                  const SizedBox(height: Spacing.xs),
                  _buildIncludeItems(l10n),
                  const SizedBox(height: Spacing.lg),

                  // 파일 형식
                  _buildSectionTitle(l10n.exportFileFormat),
                  const SizedBox(height: Spacing.sm),
                  _buildFileFormatSelector(colorScheme),
                  const SizedBox(height: Spacing.lg),
                ],
              ),
            ),
            // 푸터
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF0F0EC))),
              ),
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPadding),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isExporting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF44483E),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isExporting ? null : _export,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download, size: 16),
                      label: Text(l10n.exportButton),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _DateButton(
            label: l10n.exportFrom,
            value: _dateFormat.format(_startDate),
            onTap: () => _selectDate(context, true),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Spacing.sm),
          child: Text('~'),
        ),
        Expanded(
          child: _DateButton(
            label: l10n.exportTo,
            value: _dateFormat.format(_endDate),
            onTap: () => _selectDate(context, false),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPeriodButtons(AppLocalizations l10n) {
    return Wrap(
      spacing: Spacing.xs,
      children: [
        _QuickButton(
          label: l10n.exportThisMonth,
          onTap: () => _setQuickPeriod('thisMonth'),
        ),
        _QuickButton(
          label: l10n.exportLastMonth,
          onTap: () => _setQuickPeriod('lastMonth'),
        ),
        _QuickButton(
          label: l10n.exportRecent3Months,
          onTap: () => _setQuickPeriod('recent3Months'),
        ),
        _QuickButton(
          label: l10n.exportThisYear,
          onTap: () => _setQuickPeriod('thisYear'),
        ),
      ],
    );
  }

  Widget _buildTransactionTypeChips(
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    final types = <String?, String>{
      null: l10n.exportTypeAll,
      'expense': l10n.exportTypeExpense,
      'income': l10n.exportTypeIncome,
      'asset': l10n.exportTypeAsset,
    };

    return Wrap(
      spacing: Spacing.sm,
      children: types.entries.map((entry) {
        final isSelected = _transactionType == entry.key;
        return FilterChip(
          label: Text(entry.value),
          selected: isSelected,
          onSelected: (_) {
            setState(() => _transactionType = entry.key);
          },
        );
      }).toList(),
    );
  }

  Widget _buildIncludeItems(AppLocalizations l10n) {
    return Column(
      children: [
        CheckboxListTile(
          title: Text(l10n.exportIncludeCategory),
          value: _includeCategory,
          onChanged: (v) => setState(() => _includeCategory = v ?? true),
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: Text(l10n.exportIncludePaymentMethod),
          value: _includePaymentMethod,
          onChanged: (v) => setState(() => _includePaymentMethod = v ?? true),
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: Text(l10n.exportIncludeMemo),
          value: _includeMemo,
          onChanged: (v) => setState(() => _includeMemo = v ?? true),
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: Text(l10n.exportIncludeAuthor),
          value: _includeAuthor,
          onChanged: (v) => setState(() => _includeAuthor = v ?? false),
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: Text(l10n.exportIncludeFixedExpense),
          value: _includeFixedExpense,
          onChanged: (v) => setState(() => _includeFixedExpense = v ?? false),
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildFileFormatSelector(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _FormatOption(
            label: '.xlsx',
            subtitle: 'Excel',
            isSelected: _fileFormat == ExportFileFormat.xlsx,
            onTap: () => setState(() => _fileFormat = ExportFileFormat.xlsx),
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: _FormatOption(
            label: '.csv',
            subtitle: 'CSV',
            isSelected: _fileFormat == ExportFileFormat.csv,
            onTap: () => setState(() => _fileFormat = ExportFileFormat.csv),
          ),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}

class _FormatOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              label == '.xlsx'
                  ? Icons.table_chart_outlined
                  : Icons.description_outlined,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
