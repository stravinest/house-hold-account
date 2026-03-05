import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/payment_method_tab/payment_method_list.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

List<PaymentMethodStatistics> makePaymentMethods() {
  return [
    const PaymentMethodStatistics(
      paymentMethodId: 'pm-1',
      paymentMethodName: '신한카드',
      paymentMethodIcon: 'credit_card',
      paymentMethodColor: '#4A90E2',
      canAutoSave: false,
      amount: 200000,
      percentage: 66.7,
    ),
    const PaymentMethodStatistics(
      paymentMethodId: 'pm-2',
      paymentMethodName: '현금',
      paymentMethodIcon: 'payments',
      paymentMethodColor: '#4CAF50',
      canAutoSave: false,
      amount: 100000,
      percentage: 33.3,
    ),
  ];
}

Widget buildWidget({
  List<PaymentMethodStatistics>? statistics,
  bool loading = false,
}) {
  final stats = statistics ?? makePaymentMethods();

  return ProviderScope(
    overrides: [
      paymentMethodStatisticsProvider.overrideWith(
        (ref) async {
          if (loading) await Completer<void>().future;
          return stats;
        },
      ),
      paymentMethodDetailStateProvider.overrideWith(
        (ref) => const PaymentMethodDetailState(),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(child: PaymentMethodList()),
      ),
    ),
  );
}

void main() {
  group('PaymentMethodList 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodList), findsOneWidget);
    });

    testWidgets('결제수단 이름이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.text('신한카드'), findsOneWidget);
      expect(find.text('현금'), findsOneWidget);
    });

    testWidgets('데이터가 비어있으면 위젯이 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(statistics: []));
      await tester.pumpAndSettle();

      // Then - 빈 상태에서도 위젯 존재해야 함
      expect(find.byType(PaymentMethodList), findsOneWidget);
    });

    testWidgets('결제수단 항목이 ListView로 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('결제수단 항목이 탭 가능한 위젯으로 감싸져 있다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then - GestureDetector나 InkWell 등 탭 가능한 위젯이 존재해야 함
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('퍼센티지가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.textContaining('%'), findsWidgets);
    });
  });
}
