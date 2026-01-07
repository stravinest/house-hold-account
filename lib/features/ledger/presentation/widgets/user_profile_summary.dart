import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../../../core/utils/color_utils.dart';

class UserProfileSummary extends ConsumerWidget {
  const UserProfileSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyTotal = ref.watch(monthlyTotalProvider);

    return monthlyTotal.when(
      data: (total) {
        final users = total['users'] as Map<String, dynamic>? ?? {};

        if (users.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: users.entries.map((entry) {
              final userData = entry.value as Map<String, dynamic>;
              final displayName = userData['displayName'] as String? ?? '사용자';
              final expense = userData['expense'] as int? ?? 0;
              final colorHex = userData['color'] as String? ?? '#A8D8EA';
              final color = ColorUtils.parseHexColor(colorHex);

              return UserChip(
                name: displayName,
                amount: expense,
                color: color,
              );
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
    final formatter = NumberFormat('#,###');

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
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                '-${formatter.format(amount)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
