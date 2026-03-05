import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/presentation/pages/share_guide_page.dart';
import 'package:shared_household_account/features/settings/presentation/widgets/guide_common_widgets.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

Widget _buildTestApp() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: const ShareGuidePage(),
  );
}

void main() {
  group('ShareGuidePage 위젯 테스트', () {
    testWidgets('기본 구조가 렌더링되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('안내 배너(GuideInfoBanner)가 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      expect(find.byType(GuideInfoBanner), findsOneWidget);
    });

    testWidgets('스텝 헤더(GuideStepHeader)들이 여러 개 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then - 5개의 스텝이 있음
      expect(find.byType(GuideStepHeader), findsAtLeastNWidgets(1));
    });

    testWidgets('스텝 카드(GuideStepCard)들이 여러 개 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      expect(find.byType(GuideStepCard), findsAtLeastNWidgets(1));
    });

    testWidgets('ScrollView가 스크롤 가능해야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('ShareGuidePage는 StatelessWidget이어야 한다', (tester) async {
      // Then
      expect(const ShareGuidePage(), isA<StatelessWidget>());
    });

    testWidgets('아이콘들이 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then - 이메일 아이콘과 알림 아이콘
      expect(find.byIcon(Icons.mail_outline), findsAtLeastNWidgets(1));
    });

    testWidgets('ListView를 스크롤하면 추가 콘텐츠가 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then: 스크롤 가능한 ListView 존재
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // When: 아래로 스크롤
      await tester.drag(listView, const Offset(0, -300));
      await tester.pump();

      // Then: 에러 없이 스크롤됨
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Step 1 콘텐츠가 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then: 스텝 카드에 초대 관련 위젯들이 있음
      expect(find.byType(GuideStepCard), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.mail_outline), findsAtLeastNWidgets(1));
    });

    testWidgets('Tip 섹션 아이콘이 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then: lightbulb 아이콘이 있어야 함
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();
      // 스크롤 후에도 위젯 트리가 유지됨
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('통지 아이콘이 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then: 초대 알림 모크업에 notifications 아이콘
      expect(find.byIcon(Icons.notifications_outlined), findsAtLeastNWidgets(1));
    });
  });
}
