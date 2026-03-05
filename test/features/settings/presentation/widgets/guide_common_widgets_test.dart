import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/presentation/widgets/guide_common_widgets.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(body: child),
  );
}

void main() {
  group('GuideInfoBanner 위젯 테스트', () {
    testWidgets('전달된 텍스트가 표시되어야 한다', (tester) async {
      // Given
      const testText = '이것은 안내 배너 텍스트입니다.';

      // When
      await tester.pumpWidget(
        _buildTestApp(const GuideInfoBanner(text: testText)),
      );
      await tester.pump();

      // Then
      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('info_outline 아이콘이 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(
        _buildTestApp(const GuideInfoBanner(text: '테스트')),
      );
      await tester.pump();

      // Then
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('Container 위젯으로 감싸져 있어야 한다', (tester) async {
      // When
      await tester.pumpWidget(
        _buildTestApp(const GuideInfoBanner(text: '테스트')),
      );
      await tester.pump();

      // Then
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('빈 문자열도 표시할 수 있어야 한다', (tester) async {
      // When
      await tester.pumpWidget(
        _buildTestApp(const GuideInfoBanner(text: '')),
      );
      await tester.pump();

      // Then - 오류 없이 렌더링되어야 한다
      expect(find.byType(GuideInfoBanner), findsOneWidget);
    });
  });

  group('GuideStepHeader 위젯 테스트', () {
    testWidgets('전달된 stepLabel 텍스트가 표시되어야 한다', (tester) async {
      // Given
      const stepLabel = 'Step 1: 결제수단 선택';

      // When
      await tester.pumpWidget(
        _buildTestApp(const GuideStepHeader(stepLabel: stepLabel)),
      );
      await tester.pump();

      // Then
      expect(find.text(stepLabel), findsOneWidget);
    });

    testWidgets('굵은 폰트 스타일이 적용되어야 한다', (tester) async {
      // Given
      const stepLabel = 'Step 2: 설정';

      // When
      await tester.pumpWidget(
        _buildTestApp(const GuideStepHeader(stepLabel: stepLabel)),
      );
      await tester.pump();

      // Then
      final textWidget = tester.widget<Text>(find.text(stepLabel));
      expect(textWidget.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('Text 위젯으로 렌더링되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(
        _buildTestApp(const GuideStepHeader(stepLabel: '헤더')),
      );
      await tester.pump();

      // Then
      expect(find.byType(Text), findsAtLeastNWidgets(1));
    });
  });

  group('GuideStepCard 위젯 테스트', () {
    testWidgets('child 위젯을 올바르게 표시해야 한다', (tester) async {
      // Given
      const childText = '카드 내용 텍스트';

      // When
      await tester.pumpWidget(
        _buildTestApp(
          const GuideStepCard(
            child: Text(childText),
          ),
        ),
      );
      await tester.pump();

      // Then
      expect(find.text(childText), findsOneWidget);
    });

    testWidgets('Container로 감싸진 카드 레이아웃이어야 한다', (tester) async {
      // When
      await tester.pumpWidget(
        _buildTestApp(
          const GuideStepCard(child: Text('내용')),
        ),
      );
      await tester.pump();

      // Then
      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('복잡한 child 위젯도 렌더링할 수 있어야 한다', (tester) async {
      // When
      await tester.pumpWidget(
        _buildTestApp(
          const GuideStepCard(
            child: Column(
              children: [
                Text('줄 1'),
                Text('줄 2'),
                Icon(Icons.check),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // Then
      expect(find.text('줄 1'), findsOneWidget);
      expect(find.text('줄 2'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
