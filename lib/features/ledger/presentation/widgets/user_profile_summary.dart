import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/number_format_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';

class UserProfileSummary extends ConsumerWidget {
  const UserProfileSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final monthlyTotal = ref.watch(monthlyTotalProvider);

    return monthlyTotal.when(
      data: (total) {
        // 안전한 타입 변환
        final usersRaw = total['users'];
        if (usersRaw == null || usersRaw is! Map) {
          return const SizedBox.shrink();
        }
        final users = Map<String, dynamic>.from(usersRaw);

        if (users.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: users.entries.map((entry) {
              final userDataRaw = entry.value;
              if (userDataRaw is! Map) {
                return const SizedBox.shrink();
              }
              final userData = Map<String, dynamic>.from(userDataRaw);
              final displayName =
                  userData['displayName'] as String? ?? l10n.ledgerUser;
              final expense = userData['expense'] as int? ?? 0;
              final colorHex = userData['color'] as String? ?? '#A8D8EA';
              final color = ColorUtils.parseHexColor(colorHex);

              return UserChip(name: displayName, amount: expense, color: color);
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox(height: 60),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class UserChip extends StatelessWidget {
  final String name;
  final int amount;
  final Color color;

  const UserChip({
    super.key,
    required this.name,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: Theme.of(context).textTheme.labelSmall),
              Text(
                '-${NumberFormatUtils.currency.format(amount)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
