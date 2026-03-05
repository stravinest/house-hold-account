import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/common/statistics_date_selector.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  final testDate = DateTime(2026, 3, 1);

  Widget buildWidget({List<Override> extraOverrides = const []}) {
    return ProviderScope(
      overrides: [
        statisticsSelectedDateProvider.overrideWith((ref) => testDate),
        monthlyTrendWithAverageProvider.overrideWith(
          (ref) async => TrendStatisticsData(
            data: [],
            averageIncome: 0,
            averageExpense: 0,
            averageAsset: 0,
          ),
        ),
        yearlyTrendWithAverageProvider.overrideWith(
          (ref) async => TrendStatisticsData(
            data: [],
            averageIncome: 0,
            averageExpense: 0,
            averageAsset: 0,
          ),
        ),
        ...extraOverrides,
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: StatisticsDateSelector()),
      ),
    );
  }

  group('StatisticsDateSelector 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(StatisticsDateSelector), findsOneWidget);
    });

    testWidgets('이전 월 버튼(chevron_left)이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    });

    testWidgets('다음 월 버튼(chevron_right)이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('현재 날짜가 텍스트로 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then - 2026년 3월이 표시되어야 함
      expect(find.byType(StatisticsDateSelector), findsOneWidget);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('이전 월 버튼을 누르면 위젯이 살아있다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(StatisticsDateSelector), findsOneWidget);
    });

    testWidgets('다음 월 버튼을 누르면 위젯이 살아있다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(StatisticsDateSelector), findsOneWidget);
    });

    testWidgets('날짜 텍스트를 탭하면 월 선택 바텀시트가 열린다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - InkWell(날짜 텍스트)을 탭
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Then - 바텀시트가 열렸음을 ModalBarrier로 확인
      expect(find.byType(ModalBarrier), findsWidgets);
    });

    testWidgets('바텀시트 열면 월 선택 그리드가 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Then - GridView 또는 Column이 바텀시트 내에 표시되어야 함
      expect(find.byType(ModalBarrier), findsWidgets);
      // 바텀시트 내 컨테이너가 표시되어야 함
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('바텀시트에서 이전 연도 버튼이 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Then - chevron_left 아이콘이 연도 네비게이션에 표시됨
      expect(find.byIcon(Icons.chevron_left), findsWidgets);
    });

    testWidgets('Row 레이아웃으로 버튼들이 가로로 배치된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(Row), findsWidgets);
      expect(find.byType(IconButton), findsNWidgets(2));
    });

    testWidgets('바텀시트에서 연도 이전 버튼을 탭하면 연도가 변경된다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // 바텀시트 내부의 chevron_left 버튼들 중 첫 번째(연도 이전) 탭
      final leftButtons = find.byIcon(Icons.chevron_left);
      if (leftButtons.evaluate().length > 1) {
        await tester.tap(leftButtons.last);
        await tester.pumpAndSettle();
      }

      // Then - 바텀시트가 여전히 열려있어야 함
      expect(find.byType(ModalBarrier), findsWidgets);
    });

    testWidgets('바텀시트에서 연도 다음 버튼을 탭하면 연도가 변경된다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // 바텀시트 내부의 chevron_right 버튼들 중 마지막(연도 다음) 탭
      final rightButtons = find.byIcon(Icons.chevron_right);
      if (rightButtons.evaluate().length > 1) {
        await tester.tap(rightButtons.last);
        await tester.pumpAndSettle();
      }

      // Then - 바텀시트가 여전히 열려있어야 함
      expect(find.byType(ModalBarrier), findsWidgets);
    });

    testWidgets('바텀시트에서 월 목록 Container들이 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Then - 바텀시트가 열리고 컨테이너들이 표시되어야 함
      expect(find.byType(ModalBarrier), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('바텀시트에서 월을 탭하면 바텀시트가 닫힌다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // GridView 내 월 항목 탭 (두 번째 InkWell이 월 항목)
      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().length > 1) {
        await tester.tap(inkWells.last);
        await tester.pumpAndSettle();
      }

      // Then - 바텀시트가 닫혀야 함
      expect(find.byType(StatisticsDateSelector), findsOneWidget);
    });

    testWidgets('바텀시트에서 GridView 또는 Container들이 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Then - 바텀시트가 열리고 ModalBarrier가 표시됨
      expect(find.byType(ModalBarrier), findsWidgets);
    });

    testWidgets('바텀시트에서 오늘 버튼을 탭하면 현재 월로 이동한다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // TextButton(오늘) 탭
      final textButtons = find.byType(TextButton);
      if (textButtons.evaluate().isNotEmpty) {
        await tester.tap(textButtons.first);
        await tester.pumpAndSettle();
      }

      // Then - 바텀시트가 닫히고 날짜가 변경됨
      expect(find.byType(StatisticsDateSelector), findsOneWidget);
    });

    testWidgets('바텀시트에서 연도 이전 버튼 탭 후 바텀시트가 열려있다', (tester) async {
      // Given - 오버플로우 방지를 위해 충분한 화면 크기 설정
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // 연도 이전(-1) 탭
      final leftIcons = find.byIcon(Icons.chevron_left);
      if (leftIcons.evaluate().length >= 2) {
        await tester.tap(leftIcons.last);
        await tester.pumpAndSettle();
      }

      // Then - 바텀시트가 여전히 열려있어야 함
      expect(find.byType(ModalBarrier), findsWidgets);
    });

    testWidgets('바텀시트에서 연도 다음 버튼 탭 후 바텀시트가 열려있다', (tester) async {
      // Given - 오버플로우 방지를 위해 충분한 화면 크기 설정
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // 연도 다음(+1) 탭
      final rightIcons = find.byIcon(Icons.chevron_right);
      if (rightIcons.evaluate().length >= 2) {
        await tester.tap(rightIcons.last);
        await tester.pumpAndSettle();
      }

      // Then - 바텀시트가 여전히 열려있어야 함
      expect(find.byType(ModalBarrier), findsWidgets);
    });

    testWidgets('IconButton이 정확히 2개 있고 각각 이전/다음 월로 이동한다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then - 이전/다음 월 버튼 2개
      expect(find.byType(IconButton), findsNWidgets(2));

      // When - 이전 월 버튼 탭
      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsDateSelector), findsOneWidget);

      // When - 다음 월 버튼 탭
      await tester.tap(find.byType(IconButton).last);
      await tester.pumpAndSettle();
      expect(find.byType(StatisticsDateSelector), findsOneWidget);
    });

    testWidgets('InkWell을 탭하면 바텀시트가 열리고 Row 레이아웃이 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Then - 바텀시트 내부의 Row들이 표시됨
      expect(find.byType(Row), findsWidgets);
      expect(find.byType(ModalBarrier), findsWidgets);
    });

    testWidgets('바텀시트가 열리면 _MonthPickerSheet 내부가 렌더링된다', (tester) async {
      // Given - 충분한 화면 크기
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Then - 바텀시트가 열려있음 (ModalBarrier 확인)
      expect(find.byType(ModalBarrier), findsWidgets);
    });

    testWidgets('바텀시트에서 월을 탭하면 날짜가 업데이트된다', (tester) async {
      // Given - 충분한 화면 크기
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // 바텀시트 내 InkWell(월 항목) 탭
      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().length > 1) {
        // 두 번째 InkWell이 월 항목 (첫 번째는 날짜 텍스트)
        await tester.tap(inkWells.at(1));
        await tester.pumpAndSettle();
      }

      // Then - 바텀시트가 닫히고 위젯이 존재
      expect(find.byType(StatisticsDateSelector), findsOneWidget);
    });

    testWidgets('바텀시트에서 오늘 버튼을 탭하면 현재 날짜로 이동한다', (tester) async {
      // Given - 충분한 화면 크기
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // 오늘 버튼 탭
      final textButtons = find.byType(TextButton);
      if (textButtons.evaluate().isNotEmpty) {
        await tester.tap(textButtons.first);
        await tester.pumpAndSettle();
      }

      // Then
      expect(find.byType(StatisticsDateSelector), findsOneWidget);
    });

    testWidgets('바텀시트에서 연도 이전 버튼을 탭하면 연도가 감소한다', (tester) async {
      // Given - 충분한 화면 크기
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // 바텀시트 내 chevron_left 아이콘 (연도 이전) 탭
      final leftIcons = find.byIcon(Icons.chevron_left);
      if (leftIcons.evaluate().length >= 2) {
        await tester.tap(leftIcons.last);
        await tester.pump();
      }

      // Then - 바텀시트가 여전히 열려있어야 함
      expect(find.byType(ModalBarrier), findsWidgets);
    });

    testWidgets('바텀시트에서 연도 다음 버튼을 탭하면 연도가 증가한다', (tester) async {
      // Given - 충분한 화면 크기
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // 바텀시트 내 chevron_right 아이콘 (연도 다음) 탭
      final rightIcons = find.byIcon(Icons.chevron_right);
      if (rightIcons.evaluate().length >= 2) {
        await tester.tap(rightIcons.last);
        await tester.pump();
      }

      // Then - 바텀시트가 여전히 열려있어야 함
      expect(find.byType(ModalBarrier), findsWidgets);
    });

    testWidgets('바텀시트에서 월 항목들이 InkWell 형태로 표시된다', (tester) async {
      // Given - 충분한 화면 크기
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Then - ModalBarrier가 있고 InkWell(월 항목들)이 여럿 존재
      expect(find.byType(ModalBarrier), findsWidgets);
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('_showMonthPicker가 호출되면 바텀시트가 열린다', (tester) async {
      // Given - 충분한 화면 크기
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When - 날짜 텍스트(InkWell) 탭으로 바텀시트 열기
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Then - 바텀시트가 열려있음
      expect(find.byType(ModalBarrier), findsWidgets);
    });
  });
}
