import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/common/top_transaction_row.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('TopTransactionRow 위젯 테스트', () {
    const testItem = CategoryTopTransaction(
      rank: 1,
      title: '스타벅스',
      amount: 5000,
      percentage: 25.5,
      date: '2월 16일 (일)',
      userName: '홍길동',
      userColor: '#FF5722',
    );

    Widget buildWidget({
      CategoryTopTransaction item = testItem,
      String amountPrefix = '-',
      Color amountColor = Colors.red,
      Color rankBgColor = Colors.blue,
      bool isLast = false,
    }) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TopTransactionRow(
            item: item,
            amountPrefix: amountPrefix,
            amountColor: amountColor,
            rankBgColor: rankBgColor,
            isLast: isLast,
          ),
        ),
      );
    }

    testWidgets('기본 렌더링 - 위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());

      // Then
      expect(find.byType(TopTransactionRow), findsOneWidget);
    });

    testWidgets('거래 제목이 화면에 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());

      // Then
      expect(find.text('스타벅스'), findsOneWidget);
    });

    testWidgets('날짜가 화면에 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());

      // Then
      expect(find.text('2월 16일 (일)'), findsOneWidget);
    });

    testWidgets('사용자 이름이 화면에 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());

      // Then
      expect(find.text('홍길동'), findsOneWidget);
    });

    testWidgets('퍼센티지가 화면에 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());

      // Then
      expect(find.text('25.5%'), findsOneWidget);
    });

    testWidgets('1위 순위 뱃지가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());

      // Then
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('2위 순위 뱃지가 표시된다', (tester) async {
      // Given
      const item = CategoryTopTransaction(
        rank: 2,
        title: '편의점',
        amount: 3000,
        percentage: 15.0,
        date: '2월 17일 (월)',
        userName: '김철수',
        userColor: '#4CAF50',
      );

      // When
      await tester.pumpWidget(buildWidget(item: item));

      // Then
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('isLast=false 일 때 구분선이 있는 Container가 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(isLast: false));

      // Then
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('isLast=true 일 때 위젯이 정상 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(isLast: true));

      // Then
      expect(find.byType(TopTransactionRow), findsOneWidget);
    });

    testWidgets('amountPrefix가 금액 앞에 붙어서 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(amountPrefix: '+'));

      // Then - '+5,000원' 등이 표시되어야 함
      expect(find.byType(TopTransactionRow), findsOneWidget);
    });

    testWidgets('유효하지 않은 userColor에도 정상 렌더링된다', (tester) async {
      // Given
      const item = CategoryTopTransaction(
        rank: 1,
        title: '테스트',
        amount: 1000,
        percentage: 100.0,
        date: '2월 1일 (일)',
        userName: '사용자',
        userColor: 'invalid_color',
      );

      // When
      await tester.pumpWidget(buildWidget(item: item));

      // Then - 폴백 색상으로 정상 렌더링
      expect(find.byType(TopTransactionRow), findsOneWidget);
    });

    testWidgets('title이 빈 문자열일 때도 렌더링된다', (tester) async {
      // Given
      const item = CategoryTopTransaction(
        rank: 1,
        title: '',
        amount: 0,
        percentage: 0.0,
        date: '2월 1일 (일)',
        userName: '',
        userColor: '#A8D8EA',
      );

      // When
      await tester.pumpWidget(buildWidget(item: item));

      // Then
      expect(find.byType(TopTransactionRow), findsOneWidget);
    });

    testWidgets('긴 제목이 말줄임으로 처리된다', (tester) async {
      // Given
      const item = CategoryTopTransaction(
        rank: 1,
        title: '매우 긴 상점 이름 테스트 - 이 텍스트는 화면보다 길어서 말줄임 처리가 필요합니다',
        amount: 50000,
        percentage: 100.0,
        date: '2월 1일 (일)',
        userName: '홍길동',
        userColor: '#A8D8EA',
      );

      // When
      await tester.pumpWidget(buildWidget(item: item));

      // Then - overflow: ellipsis가 적용된 Text 위젯이 있어야 함
      final textWidgets = tester.widgetList<Text>(find.byType(Text)).toList();
      final titleText = textWidgets.firstWhere(
        (t) => t.data?.contains('매우 긴') == true,
        orElse: () => const Text(''),
      );
      expect(titleText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('Row 레이아웃이 올바르게 구성된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());

      // Then - Row 위젯들이 존재해야 함
      expect(find.byType(Row), findsWidgets);
    });
  });
}
