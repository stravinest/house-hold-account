import 'package:equatable/equatable.dart';

/// 고정비 설정 엔티티
class FixedExpenseSettings extends Equatable {
  final String id;
  final String ledgerId;
  final String userId;
  final bool includeInExpense; // 지출 편입 여부
  final DateTime createdAt;
  final DateTime updatedAt;

  const FixedExpenseSettings({
    required this.id,
    required this.ledgerId,
    required this.userId,
    required this.includeInExpense,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    ledgerId,
    userId,
    includeInExpense,
    createdAt,
    updatedAt,
  ];
}
