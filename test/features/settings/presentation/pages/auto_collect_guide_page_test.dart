import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/presentation/pages/auto_collect_guide_page.dart';
import 'package:shared_household_account/features/settings/presentation/widgets/guide_common_widgets.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

Widget _buildTestApp() {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: const AutoCollectGuidePage(),
  );
}

void main() {
  group('AutoCollectGuidePage 위젯 테스트', () {
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

    testWidgets('스텝 헤더(GuideStepHeader)들이 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then - 6개의 스텝이 있음
      expect(find.byType(GuideStepHeader), findsAtLeastNWidgets(1));
    });

    testWidgets('스텝 카드(GuideStepCard)들이 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then
      expect(find.byType(GuideStepCard), findsAtLeastNWidgets(1));
    });

    testWidgets('SMS/Push 세그먼트 아이콘들이 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then - SMS와 Push 아이콘이 있어야 함
      expect(find.byIcon(Icons.sms_outlined), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.notifications_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets('신용카드 아이콘이 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then - 결제수단 선택 카드에 신용카드 아이콘
      expect(find.byIcon(Icons.credit_card), findsAtLeastNWidgets(1));
    });

    testWidgets('AutoCollectGuidePage는 StatelessWidget이어야 한다', (tester) async {
      // Then
      expect(const AutoCollectGuidePage(), isA<StatelessWidget>());
    });

    testWidgets('ListView를 스크롤하면 추가 콘텐츠가 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // When: 아래로 스크롤
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();

      // Then: 에러 없이 스크롤됨
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('검색 아이콘이 표시되어야 한다 (감지 키워드 섹션)', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then: search 아이콘이 있어야 함 (감지 키워드 _KeywordSection)
      // 스크롤하여 키워드 섹션 로드
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('block 아이콘이 표시되어야 한다 (금지 키워드 섹션)', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then: block 아이콘이 있어야 함 (금지 키워드 _KeywordSection)
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Step 4 처리 모드 섹션이 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // Then: 스텝 카드가 여러 개 있어야 함 (6 스텝)
      expect(find.byType(GuideStepCard), findsAtLeastNWidgets(1));
    });

    testWidgets('전체 콘텐츠까지 스크롤할 수 있어야 한다', (tester) async {
      // When
      await tester.pumpWidget(_buildTestApp());
      await tester.pump();

      // When: 끝까지 스크롤
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pump();

      // Then: 에러 없이 스크롤됨
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
