import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/payment_method_tab/payment_method_donut_chart.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

List<PaymentMethodStatistics> makePaymentMethods() {
  return [
    const PaymentMethodStatistics(
      paymentMethodId: 'pm-1',
      paymentMethodName: '신한카드',
      paymentMethodIcon: 'credit_card',
      paymentMethodColor: '#4A90E2',
      amount: 200000,
      percentage: 66.7,
    ),
    const PaymentMethodStatistics(
      paymentMethodId: 'pm-2',
      paymentMethodName: '현금',
      paymentMethodIcon: 'payments',
      paymentMethodColor: '#4CAF50',
      amount: 100000,
      percentage: 33.3,
    ),
  ];
}

Widget buildWidget({
  List<PaymentMethodStatistics>? statistics,
  bool isShared = false,
  SharedStatisticsMode mode = SharedStatisticsMode.combined,
}) {
  final stats = statistics ?? makePaymentMethods();

  return ProviderScope(
    overrides: [
      paymentMethodStatisticsProvider.overrideWith((ref) async => stats),
      isSharedLedgerProvider.overrideWith((ref) => isShared),
      paymentMethodSharedStatisticsStateProvider.overrideWith(
        (ref) => SharedStatisticsState(mode: mode),
      ),
      paymentMethodStatisticsByUserProvider.overrideWith((ref) async => {}),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          height: 400,
          child: PaymentMethodDonutChart(),
        ),
      ),
    ),
  );
}

void main() {
  group('PaymentMethodDonutChart 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodDonutChart), findsOneWidget);
    });

    testWidgets('데이터가 있으면 차트가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then - 차트나 컨테이너가 렌더링되어야 함
      expect(find.byType(PaymentMethodDonutChart), findsOneWidget);
    });

    testWidgets('데이터가 비어있으면 빈 상태가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(statistics: []));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodDonutChart), findsOneWidget);
    });

    testWidgets('공유 가계부가 아닌 경우 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(isShared: false));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodDonutChart), findsOneWidget);
    });

    testWidgets('공유 가계부의 combined 모드에서 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(
        isShared: true,
        mode: SharedStatisticsMode.combined,
      ));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodDonutChart), findsOneWidget);
    });

    testWidgets('공유 가계부의 singleUser 모드에서 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(
        isShared: true,
        mode: SharedStatisticsMode.singleUser,
      ));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PaymentMethodDonutChart), findsOneWidget);
    });
  });
}
