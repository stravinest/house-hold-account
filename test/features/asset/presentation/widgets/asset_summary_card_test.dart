import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/asset_summary_card.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('AssetSummaryCard 위젯 테스트', () {
    testWidgets('총 자산 금액이 올바르게 표시된다', (tester) async {
      // Given: 총 자산 1,000,000원
      const totalAmount = 1000000;
      const monthlyChange = 0;

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: AssetSummaryCard(
                totalAmount: totalAmount,
                monthlyChange: monthlyChange,
              ),
            ),
          ),
        ),
      );

      // Then: 금액이 천단위 구분자와 함께 표시되어야 함
      expect(find.textContaining('1,000,000'), findsOneWidget);
    });

    testWidgets('월 변동이 양수일 때 증가 아이콘과 녹색으로 표시된다', (tester) async {
      // Given: 이번 달 +50,000원 증가
      const totalAmount = 1000000;
      const monthlyChange = 50000;

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: AssetSummaryCard(
                totalAmount: totalAmount,
                monthlyChange: monthlyChange,
              ),
            ),
          ),
        ),
      );

      // Then: 위쪽 화살표 아이콘이 표시되어야 함
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.textContaining('+50,000'), findsOneWidget);
    });

    testWidgets('월 변동이 음수일 때 감소 아이콘과 빨간색으로 표시된다', (tester) async {
      // Given: 이번 달 -30,000원 감소
      const totalAmount = 1000000;
      const monthlyChange = -30000;

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: AssetSummaryCard(
                totalAmount: totalAmount,
                monthlyChange: monthlyChange,
              ),
            ),
          ),
        ),
      );

      // Then: 아래쪽 화살표 아이콘이 표시되어야 함
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(find.textContaining('-30,000'), findsOneWidget);
    });

    testWidgets('월 변동이 0일 때 증가 아이콘으로 표시된다', (tester) async {
      // Given: 이번 달 변동 없음
      const totalAmount = 1000000;
      const monthlyChange = 0;

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: AssetSummaryCard(
                totalAmount: totalAmount,
                monthlyChange: monthlyChange,
              ),
            ),
          ),
        ),
      );

      // Then: 위쪽 화살표 아이콘이 표시되어야 함
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.textContaining('+0'), findsOneWidget);
    });

    testWidgets('Container와 Column이 올바르게 렌더링된다', (tester) async {
      // Given
      const totalAmount = 500000;
      const monthlyChange = 10000;

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: AssetSummaryCard(
                totalAmount: totalAmount,
                monthlyChange: monthlyChange,
              ),
            ),
          ),
        ),
      );

      // Then: 위젯 구조가 올바르게 렌더링되어야 함
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(FittedBox), findsOneWidget);
    });

    testWidgets('큰 금액도 천단위 구분자와 함께 올바르게 표시된다', (tester) async {
      // Given: 큰 금액
      const totalAmount = 123456789;
      const monthlyChange = 0;

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: AssetSummaryCard(
                totalAmount: totalAmount,
                monthlyChange: monthlyChange,
              ),
            ),
          ),
        ),
      );

      // Then: 천단위 구분자가 포함된 금액이 표시되어야 함
      expect(find.textContaining('123,456,789'), findsOneWidget);
    });
  });
}
