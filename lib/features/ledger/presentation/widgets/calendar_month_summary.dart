import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../../share/presentation/providers/share_provider.dart';
import '../../../../core/utils/color_utils.dart';

/// 요약 위젯 공통 상수
class SummaryConstants {
  /// 사용자별 금액 표시 행 높이 (UserAmountIndicator 높이 + padding)
  static const double userIndicatorRowHeight = 14.0;
}

/// 요약 유형 (수입, 지출, 합계)
enum SummaryType { income, expense, balance }

/// 월별 수입/지출 요약 위젯
///
/// 상단에 표시되는 수입, 지출, 합계 요약 정보를 보여줍니다.
/// 공유 가계부의 경우 사용자별 금액도 함께 표시됩니다.
class CalendarMonthSummary extends ConsumerWidget {
  final DateTime focusedDate;
  final int memberCount;

  const CalendarMonthSummary({
    super.key,
    required this.focusedDate,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // 실제 데이터 연동
    final monthlyTotalAsync = ref.watch(monthlyTotalProvider);

    final income = monthlyTotalAsync.valueOrNull?['income'] ?? 0;
    final expense = monthlyTotalAsync.valueOrNull?['expense'] ?? 0;
    final balance = income - expense;
    // 안전한 타입 변환 - Map<dynamic, dynamic>을 Map<String, dynamic>으로 변환
    final rawUsers = monthlyTotalAsync.valueOrNull?['users'];
    final users = rawUsers != null
        ? Map<String, dynamic>.from(rawUsers as Map)
        : <String, dynamic>{};

    // 공유 가계부일 때 모든 멤버 데이터 보강 (거래 없는 멤버도 표시)
    final membersAsync = ref.watch(currentLedgerMembersProvider);
    final members = membersAsync.valueOrNull ?? [];
    final enrichedUsers = Map<String, dynamic>.from(users);

    if (memberCount >= 2) {
      for (final member in members) {
        if (!enrichedUsers.containsKey(member.userId)) {
          // 거래가 없는 멤버 기본값 추가
          enrichedUsers[member.userId] = {
            'displayName': member.displayName ?? l10n.user,
            'income': 0,
            'expense': 0,
            'asset': 0,
            'color': member.color ?? '#A8D8EA',
          };
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SummaryColumn(
                label: l10n.transactionIncome,
                totalAmount: income,
                color: colorScheme.primary,
                users: enrichedUsers,
                type: SummaryType.income,
                memberCount: memberCount,
              ),
            ),
            Container(width: 1, color: colorScheme.outlineVariant),
            Expanded(
              child: SummaryColumn(
                label: l10n.transactionExpense,
                totalAmount: expense,
                color: colorScheme.error,
                users: enrichedUsers,
                type: SummaryType.expense,
                memberCount: memberCount,
              ),
            ),
            Container(width: 1, color: colorScheme.outlineVariant),
            Expanded(
              child: SummaryColumn(
                label: l10n.summaryBalance,
                totalAmount: balance,
                color: colorScheme.onSurface,
                users: enrichedUsers,
                type: SummaryType.balance,
                memberCount: memberCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 수입/지출/합계 열 위젯 (공통)
///
/// 월별, 주별, 일별 요약에서 공통으로 사용됩니다.
class SummaryColumn extends StatelessWidget {
  final String label;
  final int totalAmount;
  final Color color;
  final Map<String, dynamic> users;
  final SummaryType type;
  final int memberCount;

  const SummaryColumn({
    super.key,
    required this.label,
    required this.totalAmount,
    required this.color,
    required this.users,
    required this.type,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'ko_KR');
    final colorScheme = Theme.of(context).colorScheme;

    // 유저별 금액 계산
    final userAmounts = <MapEntry<Color, int>>[];
    for (final entry in users.entries) {
      // 안전한 타입 변환
      final userData = entry.value is Map
          ? Map<String, dynamic>.from(entry.value as Map)
          : <String, dynamic>{};
      final income = userData['income'] as int? ?? 0;
      final expense = userData['expense'] as int? ?? 0;

      int amount;
      switch (type) {
        case SummaryType.income:
          amount = income;
          break;
        case SummaryType.expense:
          amount = expense;
          break;
        case SummaryType.balance:
          amount = income - expense;
          break;
      }

      // 공유 가계부(2명)일 때는 0이어도 항상 표시
      // 개인 가계부일 때는 기존 로직: 합계는 0이 아닌 경우, 수입/지출은 0보다 큰 경우만
      final shouldShow = memberCount >= 2
          ? true
          : (type == SummaryType.balance ? amount != 0 : amount > 0);
      if (shouldShow) {
        final colorHex = userData['color'] as String? ?? '#A8D8EA';
        userAmounts.add(MapEntry(ColorUtils.parseHexColor(colorHex), amount));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        // 총액
        Text(
          '${totalAmount < 0 ? '-' : ''}${formatter.format(totalAmount.abs())}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        // 유저별 표시 (세로 배치)
        // 공유 가계부(2명)일 때는 항상 2줄 높이를 고정하여 레이아웃 변동 방지
        if (memberCount >= 2) ...[
          const SizedBox(height: 2),
          // 고정 높이: userIndicatorRowHeight(14.0) * 2명 = 28.0
          SizedBox(
            height: 2 * SummaryConstants.userIndicatorRowHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: userAmounts.isEmpty
                  ? []
                  : userAmounts
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: UserAmountIndicator(
                              color: entry.key,
                              amount: entry.value,
                            ),
                          ),
                        )
                        .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

/// 유저별 금액 인디케이터 (공통)
class UserAmountIndicator extends StatelessWidget {
  final Color color;
  final int amount;

  const UserAmountIndicator({
    super.key,
    required this.color,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'ko_KR');
    final isNegative = amount < 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 2),
        Text(
          '${isNegative ? '-' : ''}${formatter.format(amount.abs())}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 9,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
