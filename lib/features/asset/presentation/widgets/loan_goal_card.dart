import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart' as tokens;
import '../../data/services/loan_calculator_service.dart';
import '../../domain/entities/asset_goal.dart';
import '../providers/asset_goal_provider.dart';

class LoanGoalCard extends ConsumerWidget {
  final AssetGoal goal;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LoanGoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final loanAmount = goal.loanAmount ?? 0;
    final targetDate = goal.targetDate;
    final startDate = goal.startDate;
    final monthlyPayment = _resolveMonthlyPayment();
    final progress = _resolveProgress();
    final remainingMonths = _resolveRemainingMonths();
    final actualRemainingBalance = ref.watch(
      loanRemainingBalanceProvider(goal),
    );
    final estimatedMaturity = ref.watch(loanEstimatedMaturityProvider(goal));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, l10n, colorScheme),
              const SizedBox(height: 12),
              _buildLoanAmountRow(context, l10n, loanAmount),
              const SizedBox(height: 12),
              _buildProgressSection(context, l10n, progress),
              const SizedBox(height: 12),
              _buildDetailsRow(
                context,
                l10n,
                colorScheme,
                monthlyPayment,
                remainingMonths,
                startDate,
                targetDate,
                actualRemainingBalance,
                estimatedMaturity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.tertiary.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance,
                size: 14,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.loanGoalTitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            goal.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            iconSize: 20,
            tooltip: l10n.tooltipEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            iconSize: 20,
            tooltip: l10n.tooltipDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
      ],
    );
  }

  Widget _buildLoanAmountRow(
    BuildContext context,
    AppLocalizations l10n,
    int loanAmount,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.loanGoalAmount,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatCurrency(loanAmount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (goal.extraRepaidAmount > 0)
              _buildChip(
                context,
                icon: Icons.add_circle_outline,
                label: l10n.loanExtraRepayment,
                isHighlighted: true,
              ),
            if (goal.repaymentMethod != null)
              _buildChip(
                context,
                icon: Icons.sync_alt,
                label: _repaymentMethodLabel(context, goal.repaymentMethod!),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    AppLocalizations l10n,
    double progress,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final progressColor = colorScheme.tertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.loanProgress,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${(clampedProgress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(tokens.BorderRadiusToken.sm),
          child: LinearProgressIndicator(
            value: clampedProgress,
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsRow(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    int? monthlyPayment,
    int remainingMonths,
    DateTime? startDate,
    DateTime? targetDate,
    int actualRemainingBalance,
    DateTime? estimatedMaturity,
  ) {
    final previousRate = goal.previousInterestRate;
    final currentRate = goal.annualInterestRate;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (monthlyPayment != null)
          _buildInfoItem(
            context,
            icon: Icons.calendar_month_outlined,
            label: l10n.loanMonthlyPayment,
            value: _formatCurrency(monthlyPayment),
          ),
        if (currentRate != null)
          _buildInfoItem(
            context,
            icon: Icons.percent,
            label: l10n.loanInterestRate,
            value: previousRate != null
                ? '${previousRate.toStringAsFixed(2)}% → ${currentRate.toStringAsFixed(2)}%'
                : '${currentRate.toStringAsFixed(2)}%',
          ),
        if (actualRemainingBalance > 0)
          _buildInfoItem(
            context,
            icon: Icons.account_balance_wallet_outlined,
            label: l10n.loanRemainingBalance,
            value: _formatCurrency(actualRemainingBalance),
          ),
        if (remainingMonths > 0)
          _buildInfoItem(
            context,
            icon: Icons.access_time,
            label: l10n.loanRemainingMonths,
            value: l10n.loanRemainingMonthsValue(remainingMonths),
          ),
        if (startDate != null)
          _buildInfoItem(
            context,
            icon: Icons.play_circle_outline,
            label: l10n.loanStartDate,
            value: DateFormat('yyyy.MM.dd').format(startDate),
          ),
        if (targetDate != null)
          _buildInfoItem(
            context,
            icon: Icons.flag_outlined,
            label: l10n.loanMaturityDate,
            value: DateFormat('yyyy.MM.dd').format(targetDate),
          ),
        if (estimatedMaturity != null)
          _buildInfoItem(
            context,
            icon: Icons.flag,
            label: l10n.loanNewEstimatedMaturity,
            value: DateFormat('yyyy.MM.dd').format(estimatedMaturity),
            isHighlighted: true,
          ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isHighlighted
        ? colorScheme.tertiary.withAlpha(20)
        : colorScheme.surfaceContainerHighest;
    final labelColor = isHighlighted
        ? colorScheme.tertiary
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: labelColor),
              const SizedBox(width: 3),
              Text(label, style: TextStyle(fontSize: 10, color: labelColor)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isHighlighted = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipColor = isHighlighted
        ? colorScheme.tertiary
        : colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: chipColor)),
        ],
      ),
    );
  }

  double _resolveProgress() {
    final startDate = goal.startDate;
    final targetDate = goal.targetDate;
    final loanAmount = goal.loanAmount ?? 0;
    final method =
        goal.repaymentMethod ?? RepaymentMethod.equalPrincipalInterest;
    if (startDate == null || loanAmount <= 0) return 0.0;

    final now = DateTime.now();
    final elapsedMonths =
        LoanCalculatorService.calculateMonthsBetween(startDate, now);
    if (elapsedMonths <= 0) return 0.0;

    int totalMonths = 0;
    if (targetDate != null) {
      totalMonths =
          LoanCalculatorService.calculateMonthsBetween(startDate, targetDate);
    }
    if (totalMonths <= 0) return 0.0;

    final cumulativeRepaid = LoanCalculatorService.calculateCumulativeRepaid(
      loanAmount: loanAmount,
      annualInterestRate: goal.annualInterestRate ?? 0.0,
      totalMonths: totalMonths,
      elapsedMonths: elapsedMonths,
      method: method,
    );

    final totalRepaid = cumulativeRepaid + goal.extraRepaidAmount;
    return (totalRepaid / loanAmount).clamp(0.0, 1.0);
  }

  int _resolveRemainingMonths() {
    final targetDate = goal.targetDate;
    if (targetDate == null) return 0;
    return LoanCalculatorService.calculateRemainingMonths(endDate: targetDate);
  }

  int? _resolveMonthlyPayment() {
    if (goal.isManualPayment && goal.monthlyPayment != null) {
      return goal.monthlyPayment;
    }
    final loanAmount = goal.loanAmount;
    final annualInterestRate = goal.annualInterestRate;
    final repaymentMethod = goal.repaymentMethod;
    final startDate = goal.startDate;
    final targetDate = goal.targetDate;

    if (loanAmount == null ||
        annualInterestRate == null ||
        repaymentMethod == null ||
        startDate == null ||
        targetDate == null) {
      return goal.monthlyPayment;
    }

    final totalMonths = LoanCalculatorService.calculateRemainingMonths(
      endDate: targetDate,
      currentDate: startDate,
    );
    if (totalMonths <= 0) return goal.monthlyPayment;

    return LoanCalculatorService.calculateMonthlyPayment(
      loanAmount: loanAmount,
      annualInterestRate: annualInterestRate,
      totalMonths: totalMonths,
      method: repaymentMethod,
    );
  }

  String _repaymentMethodLabel(BuildContext context, RepaymentMethod method) {
    final l10n = AppLocalizations.of(context);
    switch (method) {
      case RepaymentMethod.equalPrincipalInterest:
        return l10n.repaymentMethodEqualPrincipalInterest;
      case RepaymentMethod.equalPrincipal:
        return l10n.repaymentMethodEqualPrincipal;
      case RepaymentMethod.bullet:
        return l10n.repaymentMethodBullet;
      case RepaymentMethod.graduated:
        return l10n.repaymentMethodGraduated;
    }
  }

  String _formatCurrency(int amount) {
    return '₩${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}
